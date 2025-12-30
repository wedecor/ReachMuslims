import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/lead_list_provider.dart';
import '../providers/lead_filter_provider.dart';
import '../widgets/lead_filter_panel.dart';
import '../widgets/status_dropdown.dart';
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
import '../../domain/models/lead.dart';
import 'lead_create_screen.dart';
import 'lead_detail_screen.dart';
import '../../core/utils/phone_number_formatter.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Load dashboard stats and leads
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          try {
            await ref.read(dashboardProvider.notifier).loadStats();
            await ref.read(leadListProvider.notifier).loadLeads(refresh: true);
          } catch (e) {
            debugPrint('Error loading dashboard: $e');
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      ref.read(leadListProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isAdmin = user?.isAdmin ?? false;
    final stats = ref.watch(dashboardProvider);
    final leadListState = ref.watch(leadListProvider);
    final filterState = ref.watch(leadFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
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
                  ref.read(leadListProvider.notifier).refresh();
                  ref.read(dashboardProvider.notifier).refresh();
                });
              },
              tooltip: 'Create Lead',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(dashboardProvider.notifier).refresh();
              ref.read(leadListProvider.notifier).refresh();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          OfflineBanner(),
          PendingSyncIndicator(),
          // KPI Metrics Section
          if (stats.isLoading && stats.totalLeads == 0)
            const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            )
          else
            _buildKPISection(context, stats),
          
          // Quick Stats Section
          if (!stats.isLoading || stats.totalLeads > 0)
            _buildQuickStatsSection(context, stats),
          
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, phone, or location',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(leadFilterProvider.notifier).setSearchQuery(null);
                          ref.read(leadListProvider.notifier).refresh();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              onChanged: (value) {
                ref.read(leadFilterProvider.notifier).setSearchQuery(value.isEmpty ? null : value);
                // Debounce search
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (_searchController.text == value && mounted) {
                    ref.read(leadListProvider.notifier).refresh();
                  }
                });
              },
            ),
          ),
          
          // Filters and Sort Row
          _buildFiltersAndSortRow(context, filterState, isAdmin),
          
          // Advanced Filters Panel
          const LeadFilterPanel(),
          
          // Lead List
          Expanded(
            child: _buildLeadList(leadListState, filterState),
          ),
        ],
      ),
    );
  }

  Widget _buildKPISection(BuildContext context, DashboardStats stats) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: colorScheme.surfaceContainerHighest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Key Metrics',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildKPICard(
                  context,
                  title: 'Total Leads',
                  value: stats.totalLeads.toString(),
                  icon: Icons.people_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                _buildKPICard(
                  context,
                  title: 'New Leads',
                  value: stats.newLeads.toString(),
                  icon: Icons.new_releases_outlined,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(width: 12),
                _buildKPICard(
                  context,
                  title: 'Follow-up',
                  value: stats.followUpLeads.toString(),
                  icon: Icons.history_outlined,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
                const SizedBox(width: 12),
                _buildKPICard(
                  context,
                  title: 'Converted',
                  value: stats.convertedLeads.toString(),
                  icon: Icons.check_circle_outline,
                  color: Theme.of(context).colorScheme.primaryContainer,
                ),
                const SizedBox(width: 12),
                _buildKPICard(
                  context,
                  title: 'Starred',
                  value: stats.priorityLeads.toString(),
                  icon: Icons.star_outline,
                  color: Theme.of(context).colorScheme.tertiaryContainer,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKPICard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      width: 140,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsSection(BuildContext context, DashboardStats stats) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      color: colorScheme.primaryContainer,
      child: Row(
        children: [
          Expanded(
            child: _buildQuickStatItem(
              context,
              icon: Icons.phone_callback_outlined,
              label: 'Contacted Today',
              value: stats.leadsContactedToday.toString(),
            ),
          ),
          Container(width: 1, height: 30, color: colorScheme.primary.withOpacity(0.3)),
          Expanded(
            child: _buildQuickStatItem(
              context,
              icon: Icons.schedule_outlined,
              label: 'Pending Follow-ups',
              value: stats.pendingFollowUps.toString(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 20, color: colorScheme.onPrimaryContainer),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onPrimaryContainer.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFiltersAndSortRow(
    BuildContext context,
    LeadFilterState filterState,
    bool isAdmin,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: Row(
        children: [
          // Priority Filter
          Expanded(
            child: SegmentedButton<bool?>(
              segments: const [
                ButtonSegment<bool?>(value: null, label: Text('All')),
                ButtonSegment<bool?>(value: true, label: Text('Starred')),
                ButtonSegment<bool?>(value: false, label: Text('Other')),
              ],
              selected: {filterState.isPriority},
              onSelectionChanged: (Set<bool?> selected) {
                final value = selected.first;
                ref.read(leadFilterProvider.notifier).setIsPriority(value);
                ref.read(leadListProvider.notifier).refresh();
              },
            ),
          ),
          const SizedBox(width: 8),
          // Sort Dropdown
          DropdownButton<LeadSortOption>(
            value: filterState.sortOption,
            items: const [
              DropdownMenuItem(
                value: LeadSortOption.newestFirst,
                child: Text('Newest'),
              ),
              DropdownMenuItem(
                value: LeadSortOption.lastContacted,
                child: Text('Last Contacted'),
              ),
              DropdownMenuItem(
                value: LeadSortOption.priorityFirst,
                child: Text('Priority'),
              ),
              DropdownMenuItem(
                value: LeadSortOption.oldestFirst,
                child: Text('Oldest'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                ref.read(leadFilterProvider.notifier).setSortOption(value);
                ref.read(leadListProvider.notifier).refresh();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLeadList(LeadListState state, LeadFilterState filterState) {
    if (state.isLoading && state.leads.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.leads.isEmpty) {
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

    if (state.leads.isEmpty) {
      if (filterState.hasFilters) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.filter_alt_off,
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'No leads match your filters',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  ref.read(leadFilterProvider.notifier).clearFilters();
                  ref.read(leadListProvider.notifier).refresh();
                },
                child: const Text('Clear Filters'),
              ),
            ],
          ),
        );
      } else {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.people_outline,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No leads found',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        );
      }
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(leadListProvider.notifier).refresh(),
      child: ListView.builder(
        controller: _scrollController,
        itemCount: state.leads.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= state.leads.length) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final lead = state.leads[index];
          return _buildLeadItem(lead);
        },
      ),
    );
  }

  Widget _buildLeadItem(Lead lead) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
          padding: const EdgeInsets.all(12.0),
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
  }
}
