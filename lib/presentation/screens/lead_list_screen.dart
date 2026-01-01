import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/lead.dart';
import '../providers/lead_list_provider.dart';
import '../providers/lead_filter_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/status_dropdown.dart';
import '../widgets/lead_filter_panel.dart';
import '../widgets/priority_star_toggle.dart';
import '../widgets/compact_last_contacted.dart';
import '../widgets/lead_card_action_buttons.dart';
import '../widgets/offline_banner.dart';
import '../widgets/pending_sync_indicator.dart';
import '../widgets/lead_tile_info/assigned_user_badge.dart';
import '../widgets/lead_tile_info/lead_source_badge.dart';
import '../widgets/lead_tile_info/location_display.dart';
import '../widgets/lead_tile_info/lazy_follow_up_count_badge.dart';
import '../widgets/lead_tile_info/days_since_creation.dart';
import '../widgets/lead_tile_info/region_badge.dart';
import '../widgets/lead_tile_info/lazy_next_scheduled_followup.dart';
import '../widgets/lead_tile_info/conversion_probability_indicator.dart';
import '../widgets/lead_tile_info/lazy_last_activity_summary.dart';
import 'lead_create_screen.dart';
import 'lead_detail_screen.dart';
import '../../core/utils/phone_number_formatter.dart';

class LeadListScreen extends ConsumerStatefulWidget {
  const LeadListScreen({super.key});

  @override
  ConsumerState<LeadListScreen> createState() => _LeadListScreenState();
}

class _LeadListScreenState extends ConsumerState<LeadListScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  bool _hasSearchText = false;
  Timer? _searchDebounceTimer;
  final _scrollControllers = [
    ScrollController(),
    ScrollController(),
    ScrollController(),
    ScrollController(),
  ];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    for (final controller in _scrollControllers) {
      controller.addListener(() => _onScroll(controller));
    }
    _searchController.addListener(() {
      final hasText = _searchController.text.isNotEmpty;
      if (hasText != _hasSearchText) {
        setState(() {
          _hasSearchText = hasText;
        });
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(leadListProvider.notifier).loadLeads(refresh: true);
    });
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _searchController.dispose();
    _tabController.dispose();
    for (final controller in _scrollControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onScroll(ScrollController controller) {
    if (controller.position.pixels >=
        controller.position.maxScrollExtent * 0.9) {
      ref.read(leadListProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final leadListState = ref.watch(leadListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leads'),
        actions: [
          // Allow all authenticated users to create leads
          if (authState.isAuthenticated)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LeadCreateScreen(),
                  ),
                ).then((_) {
                  // Refresh list after creating lead
                  ref.read(leadListProvider.notifier).refresh();
                });
              },
              tooltip: 'Create Lead',
            ),
        ],
      ),
      body: Column(
        children: [
          OfflineBanner(),
          PendingSyncIndicator(),
          // Search bar
          Builder(
            builder: (context) {
              final theme = Theme.of(context);
              final colorScheme = theme.colorScheme;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: InputDecoration(
                    hintText: 'Search by name or phone',
                    hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                    prefixIcon: Icon(
                      Icons.search,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    suffixIcon: _hasSearchText
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _hasSearchText = false;
                              });
                              ref.read(leadFilterProvider.notifier).setSearchQuery(null);
                              ref.read(leadListProvider.notifier).refresh();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: colorScheme.outline.withValues(alpha: 0.5),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: colorScheme.outline.withValues(alpha: 0.5),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _hasSearchText = value.isNotEmpty;
                    });
                    ref.read(leadFilterProvider.notifier).setSearchQuery(value.isEmpty ? null : value);
                    // Debounce search - cancel previous timer
                    _searchDebounceTimer?.cancel();
                    _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
                      if (_searchController.text == value && mounted) {
                        ref.read(leadListProvider.notifier).refresh();
                      }
                    });
                  },
                ),
              );
            },
          ),
          // Advanced Filters Panel
          const LeadFilterPanel(),
          // Status Tabs
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'New'),
              Tab(text: 'Follow Up'),
              Tab(text: 'In Talk'),
              Tab(text: 'Converted'),
            ],
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
            indicatorColor: Theme.of(context).colorScheme.primary,
          ),
          // Tabbed Lead Lists
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFilteredLeadList(leadListState, LeadStatus.newLead, _scrollControllers[0]),
                _buildFilteredLeadList(leadListState, LeadStatus.followUp, _scrollControllers[1]),
                _buildFilteredLeadList(leadListState, LeadStatus.inTalk, _scrollControllers[2]),
                _buildFilteredLeadList(leadListState, LeadStatus.converted, _scrollControllers[3]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilteredLeadList(
    LeadListState state,
    LeadStatus status,
    ScrollController scrollController,
  ) {
    // Filter leads by status
    // Note: Search is already applied in the repository, so we just filter by status here
    final filteredLeads = state.leads.where((lead) => lead.status == status).toList();

    if (state.isLoading && filteredLeads.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && filteredLeads.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error: ${state.error!.message}',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(leadListProvider.notifier).refresh();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (filteredLeads.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No ${status.displayName} leads found',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(leadListProvider.notifier).refresh(),
      child: ListView.builder(
        controller: scrollController,
        itemCount: filteredLeads.length,
        itemBuilder: (context, index) {
          final lead = filteredLeads[index];
          return _buildLeadItem(lead);
        },
      ),
    );
  }

  Widget _buildLeadItem(Lead lead) {
    try {
      final isMobile = MediaQuery.of(context).size.width < 600;
      final card = Card(
        margin: EdgeInsets.symmetric(
          horizontal: isMobile ? 4 : 8,
          vertical: isMobile ? 2 : 4,
        ),
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: () {
            try {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LeadDetailScreen(lead: lead),
                ),
              );
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error opening lead: ${e.toString()}'),
                    backgroundColor: Theme.of(context).colorScheme.errorContainer,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(
              MediaQuery.of(context).size.width < 600 ? 8.0 : 12.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Star icon (left) + Lead Name (bold) + Status badge (right)
                Row(
                  children: [
                    PriorityStarToggle(lead: lead),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        lead.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusDropdown(lead: lead),
                  ],
                ),
                const SizedBox(height: 8),
                // Second row: Phone number and region badge
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        PhoneNumberFormatter.formatPhoneNumber(lead.phone, region: lead.region),
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    RegionBadge(lead: lead),
                  ],
                ),
                const SizedBox(height: 8),
                // Third row: Badges (Assigned User, Source, Follow-up Count)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    AssignedUserBadge(lead: lead),
                    LeadSourceBadge(lead: lead),
                    LazyFollowUpCountBadge(leadId: lead.id),
                  ],
                ),
                const SizedBox(height: 8),
                // Fourth row: Location and Days Since Creation
                Row(
                  children: [
                    Expanded(
                      child: LocationDisplay(lead: lead),
                    ),
                    const SizedBox(width: 8),
                    DaysSinceCreation(lead: lead),
                  ],
                ),
                const SizedBox(height: 8),
                // Fifth row: Last Activity and Next Scheduled Follow-up
                Row(
                  children: [
                  Expanded(
                    child: LazyLastActivitySummary(lead: lead),
                  ),
                  const SizedBox(width: 8),
                  LazyNextScheduledFollowUp(leadId: lead.id),
                  ],
                ),
                const SizedBox(height: 8),
                // Sixth row: Conversion Probability Indicator
                ConversionProbabilityIndicator(lead: lead),
                // Last contacted indicator (compact)
                const SizedBox(height: 8),
                CompactLastContacted(leadId: lead.id),
                // Bottom action section: Large Call and WhatsApp buttons
                const SizedBox(height: 12),
                LeadCardActionButtons(lead: lead),
              ],
            ),
          ),
        ),
      );

      return card;
    } catch (e) {
      debugPrint('Error building lead item: $e');
      // Return a fallback card if rendering fails
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text('Error displaying lead: ${lead.name}'),
        ),
      );
    }
  }
}

