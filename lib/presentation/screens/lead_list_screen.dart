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
import '../widgets/lead_tile_info/notes_preview.dart';
import '../widgets/lead_tile_info/status_change_time.dart';
import '../widgets/lead_tile_info/last_updated_time.dart';
import '../widgets/lead_tile_info/record_age.dart';
import '../widgets/lead_tile_info/last_contacted_by_method.dart';
import '../widgets/lead_tile_info/gender_badge.dart';
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
    ScrollController(),
    ScrollController(),
  ];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
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

  void _autoSwitchToTabWithLeads(LeadListState leadListState, LeadFilterState filterState) {
    // Auto-switch if any filters are active
    if (!filterState.hasFilters) return;
    
    // If status filter is active and only one status is selected, switch to that tab
    if (filterState.statuses.isNotEmpty && filterState.statuses.length == 1) {
      final selectedStatus = filterState.statuses.first;
      final statusTabs = [
        LeadStatus.newLead,
        LeadStatus.inTalk,
        LeadStatus.followUp,
        LeadStatus.interested,
        LeadStatus.notInterested,
        LeadStatus.converted,
      ];
      final tabIndex = statusTabs.indexOf(selectedStatus);
      if (tabIndex != -1 && tabIndex != _tabController.index) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _tabController.index != tabIndex) {
            _tabController.animateTo(tabIndex);
          }
        });
        return;
      }
    }
    
    // For other filters, check which tab has leads
    final hasNonStatusFilters = filterState.region != null ||
        filterState.assignedTo != null ||
        (filterState.searchQuery != null && filterState.searchQuery!.isNotEmpty) ||
        filterState.createdFrom != null ||
        filterState.createdTo != null ||
        filterState.followUpFilter != FollowUpFilter.all ||
        filterState.isPriority != null;
    
    if (!hasNonStatusFilters) return;

    final statusTabs = [
      LeadStatus.newLead,
      LeadStatus.followUp,
      LeadStatus.interested,
      LeadStatus.inTalk,
      LeadStatus.notInterested,
      LeadStatus.converted,
    ];

    // Count leads per status after applying filters
    final leadsPerStatus = <LeadStatus, int>{};
    var allFilteredLeads = leadListState.leads;

    // Apply region filter if active
    if (filterState.region != null) {
      allFilteredLeads = allFilteredLeads.where((lead) => lead.region == filterState.region).toList();
    }
    if (filterState.assignedTo != null) {
      allFilteredLeads = allFilteredLeads.where((lead) => lead.assignedTo == filterState.assignedTo).toList();
    }
    if (filterState.isPriority != null) {
      allFilteredLeads = allFilteredLeads.where((lead) => lead.isPriority == filterState.isPriority).toList();
    }
    if (filterState.gender != null) {
      allFilteredLeads = allFilteredLeads.where((lead) => lead.gender == filterState.gender).toList();
    }

    // Count leads per status
    for (final status in statusTabs) {
      leadsPerStatus[status] = allFilteredLeads.where((lead) => lead.status == status).length;
    }

    // Check current tab - if it has leads, don't switch
    final currentStatus = statusTabs[_tabController.index];
    final currentTabLeadsCount = leadsPerStatus[currentStatus] ?? 0;
    
    // If current tab has leads, stay on it
    if (currentTabLeadsCount > 0) return;

    // Find the first tab with leads (prioritize New, Follow Up, In Talk, Converted)
    for (final status in statusTabs) {
      final count = leadsPerStatus[status] ?? 0;
      if (count > 0) {
        final tabIndex = statusTabs.indexOf(status);
        if (tabIndex != -1 && tabIndex != _tabController.index) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _tabController.index != tabIndex) {
              _tabController.animateTo(tabIndex);
            }
          });
        }
        return;
      }
    }
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
    final filterState = ref.watch(leadFilterProvider);

    // Auto-switch to tab with leads when filters change and leads are loaded
    if (!leadListState.isLoading && leadListState.leads.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _autoSwitchToTabWithLeads(leadListState, filterState);
      });
    }

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
              Tab(text: 'In Talk'),
              Tab(text: 'Follow Up'),
              Tab(text: 'Interested'),
              Tab(text: 'Not Interested'),
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
                _buildFilteredLeadList(leadListState, LeadStatus.inTalk, _scrollControllers[1]),
                _buildFilteredLeadList(leadListState, LeadStatus.followUp, _scrollControllers[2]),
                _buildFilteredLeadList(leadListState, LeadStatus.interested, _scrollControllers[3]),
                _buildFilteredLeadList(leadListState, LeadStatus.notInterested, _scrollControllers[4]),
                _buildFilteredLeadList(leadListState, LeadStatus.converted, _scrollControllers[5]),
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
    // Get current filter state to check if any filters are active
    final filterState = ref.watch(leadFilterProvider);
    
    // If ANY filter is active (except status filter in panel), show ALL matching leads
    // This prevents confusion: "I filtered by region, show me all leads in that region"
    // If NO filters are active, use tab status filtering
    List<Lead> filteredLeads;
    
    // Start with all leads from state
    filteredLeads = state.leads;
    
    // Apply region filter if active
    if (filterState.region != null) {
      filteredLeads = filteredLeads.where((lead) => lead.region == filterState.region).toList();
    }
    
    // Apply assignedTo filter if active
    if (filterState.assignedTo != null) {
      filteredLeads = filteredLeads.where((lead) => lead.assignedTo == filterState.assignedTo).toList();
    }
    
    // Apply priority filter if active
    if (filterState.isPriority != null) {
      filteredLeads = filteredLeads.where((lead) => lead.isPriority == filterState.isPriority).toList();
    }
    
    // Apply gender filter if active
    if (filterState.gender != null) {
      filteredLeads = filteredLeads.where((lead) => lead.gender == filterState.gender).toList();
    }
    
    // Apply status filtering
    if (filterState.statuses.isNotEmpty) {
      // Status filter is active in filter panel - show leads that match BOTH:
      // 1. The filter panel status selection
      // 2. The current tab's status
      // This ensures leads are segregated properly
      filteredLeads = filteredLeads.where((lead) => 
        filterState.statuses.contains(lead.status) && lead.status == status
      ).toList();
    } else {
      // No status filter in panel - use tab status (segregate by tabs)
      filteredLeads = filteredLeads.where((lead) => lead.status == status).toList();
    }

    if (state.isLoading && filteredLeads.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Only show error if we have an actual error AND this tab should have data
    // If status filter is active and this tab's status is not in the filter, show empty state instead of error
    bool shouldShowError = false;
    if (state.error != null && filteredLeads.isEmpty && !state.isLoading) {
      if (filterState.statuses.isNotEmpty) {
        // Status filter is active - only show error if this tab's status is in the filter
        shouldShowError = filterState.statuses.contains(status);
      } else {
        // No status filter - this tab should show data, so show error if there is one
        shouldShowError = true;
      }
    }

    if (shouldShowError) {
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
      // If tab is empty but we have more data available and no status filter is active,
      // aggressively load more data to find leads for this status
      // This ensures we load all available records across all statuses
      if (state.hasMore && 
          !state.isLoading && 
          !state.isLoadingMore && 
          filterState.statuses.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // Load more data in batches until we find leads for this status or run out
          ref.read(leadListProvider.notifier).loadMore();
        });
      }
      
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              filterState.hasFilters ? Icons.filter_alt_off : Icons.inbox_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              filterState.hasFilters
                  ? 'No leads found matching the selected filters'
                  : 'No ${status.displayName} leads found',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (filterState.hasFilters)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: TextButton(
                  onPressed: () {
                    ref.read(leadFilterProvider.notifier).clearFilters();
                    ref.read(leadListProvider.notifier).refresh();
                  },
                  child: const Text('Clear Filters'),
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
                // Third row: Badges (Gender, Assigned User, Source, Follow-up Count)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    GenderBadge(lead: lead),
                    AssignedUserBadge(lead: lead),
                    LeadSourceBadge(lead: lead),
                    LazyFollowUpCountBadge(leadId: lead.id),
                  ],
                ),
                const SizedBox(height: 8),
                // Fourth row: Location and Record Age
                Row(
                  children: [
                    Expanded(
                      child: LocationDisplay(lead: lead),
                    ),
                    const SizedBox(width: 8),
                    RecordAge(lead: lead),
                  ],
                ),
                const SizedBox(height: 8),
                // Notes Preview Row
                NotesPreview(leadId: lead.id),
                const SizedBox(height: 8),
                // Fifth row: Status Change Time and Last Updated
                Row(
                  children: [
                    Expanded(
                      child: StatusChangeTime(leadId: lead.id, currentStatus: lead.status),
                    ),
                    const SizedBox(width: 8),
                    LastUpdatedTime(lead: lead),
                  ],
                ),
                const SizedBox(height: 8),
                // Sixth row: Last Contacted by Method (Phone/WhatsApp)
                LastContactedByMethod(lead: lead),
                const SizedBox(height: 8),
                // Seventh row: Next Scheduled Follow-up
                LazyNextScheduledFollowUp(leadId: lead.id),
                const SizedBox(height: 8),
                // Eighth row: Conversion Probability Indicator
                ConversionProbabilityIndicator(lead: lead),
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

