import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/models/lead.dart';
import '../../domain/models/user.dart';
import '../../core/utils/status_color_utils.dart';
import '../providers/lead_filter_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/user_list_provider.dart';
import '../providers/lead_list_provider.dart';

class LeadFilterPanel extends ConsumerStatefulWidget {
  const LeadFilterPanel({super.key});

  @override
  ConsumerState<LeadFilterPanel> createState() => _LeadFilterPanelState();
}

class _LeadFilterPanelState extends ConsumerState<LeadFilterPanel> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final filterState = ref.watch(leadFilterProvider);
    final authState = ref.watch(authProvider);
    final isAdmin = authState.isAdmin;
    final user = authState.user;

    return Card(
      margin: const EdgeInsets.all(8),
      child: Column(
        children: [
          // Header with toggle
          ListTile(
            leading: const Icon(Icons.filter_list),
            title: const Text('Filters'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (filterState.hasFilters)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${filterState.activeFilterCount} active',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                ),
              ],
            ),
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
          ),
          // Filter content
          if (_isExpanded) ...[
            const Divider(height: 1),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                  // Status Filter (Multi-select)
                  _buildStatusFilter(filterState),
                  const SizedBox(height: 16),
                  // Assigned User Filter (Admin only)
                  if (isAdmin && user?.region != null)
                    _buildAssignedUserFilter(user!.region!),
                  if (isAdmin && user?.region != null)
                    const SizedBox(height: 16),
                  // Region Filter (Admin only)
                  if (isAdmin) _buildRegionFilter(filterState),
                  if (isAdmin) const SizedBox(height: 16),
                  // Date Range Filter with Presets
                  _buildDateRangeFilter(filterState),
                  const SizedBox(height: 16),
                  // Follow-up Filter
                  _buildFollowUpFilter(filterState),
                  const SizedBox(height: 16),
                  // Priority Filter (moved to main panel, but keep here for consistency)
                  // Note: Priority filter is now in the main dashboard row
                      // Clear Filters Button
                      if (filterState.hasFilters)
                        OutlinedButton.icon(
                          onPressed: () {
                            ref.read(leadFilterProvider.notifier).clearFilters();
                            ref.read(leadListProvider.notifier).refresh();
                          },
                          icon: const Icon(Icons.clear_all, size: 18),
                          label: const Text('Clear All Filters'),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusFilter(LeadFilterState filterState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: LeadStatus.values.map((status) {
            final isSelected = filterState.statuses.contains(status);
            return FilterChip(
              label: Text(
                status.displayName,
                style: TextStyle(
                  color: isSelected
                      ? StatusColorUtils.getStatusTextColor(status)
                      : null,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              selectedColor: StatusColorUtils.getStatusBackgroundColor(status),
              checkmarkColor: StatusColorUtils.getStatusTextColor(status),
              onSelected: (selected) {
                ref.read(leadFilterProvider.notifier).toggleStatus(status);
                ref.read(leadListProvider.notifier).refresh();
              },
            );
          }).toList(),
        ),
        if (filterState.statuses.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: TextButton(
              onPressed: () {
                ref.read(leadFilterProvider.notifier).setStatuses([]);
                ref.read(leadListProvider.notifier).refresh();
              },
              child: const Text('Clear Status'),
            ),
          ),
      ],
    );
  }

  Widget _buildAssignedUserFilter(UserRegion region) {
    final userListState = ref.watch(userListProvider(region));

    return DropdownButtonFormField<String?>(
      value: ref.watch(leadFilterProvider).assignedTo,
      decoration: InputDecoration(
        labelText: 'Assigned To',
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
      ),
      items: [
        const DropdownMenuItem<String?>(
          value: null,
          child: Text('All Users'),
        ),
        if (userListState.isLoading)
          const DropdownMenuItem<String>(
            value: 'loading',
            enabled: false,
            child: Text('Loading users...'),
          )
        else
          ...userListState.users.map((user) {
            return DropdownMenuItem<String>(
              value: user.uid,
              child: Text(user.name),
            );
          }),
      ],
      onChanged: (userId) {
        ref.read(leadFilterProvider.notifier).setAssignedTo(userId);
        ref.read(leadListProvider.notifier).refresh();
      },
    );
  }

  Widget _buildRegionFilter(LeadFilterState filterState) {
    return DropdownButtonFormField<UserRegion?>(
      value: filterState.region,
      decoration: InputDecoration(
        labelText: 'Region',
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
      ),
      items: [
        const DropdownMenuItem<UserRegion?>(
          value: null,
          child: Text('All Regions'),
        ),
        ...UserRegion.values.map((region) {
          return DropdownMenuItem<UserRegion>(
            value: region,
            child: Text(region.name.toUpperCase()),
          );
        }),
      ],
      onChanged: (region) {
        ref.read(leadFilterProvider.notifier).setRegion(region);
        ref.read(leadListProvider.notifier).refresh();
      },
    );
  }

  Widget _buildDateRangeFilter(LeadFilterState filterState) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Created Date Range',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        // Preset buttons
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildPresetButton(
              'Today',
              DateRangePreset.today,
              filterState.datePreset == DateRangePreset.today,
            ),
            _buildPresetButton(
              'Last 7 Days',
              DateRangePreset.last7Days,
              filterState.datePreset == DateRangePreset.last7Days,
            ),
            _buildPresetButton(
              'Last 30 Days',
              DateRangePreset.last30Days,
              filterState.datePreset == DateRangePreset.last30Days,
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Custom date range
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: filterState.createdFrom ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    ref.read(leadFilterProvider.notifier).setDateRange(
                          date,
                          filterState.createdTo,
                        );
                    ref.read(leadListProvider.notifier).refresh();
                  }
                },
                icon: const Icon(Icons.calendar_today, size: 18),
                label: Text(
                  filterState.createdFrom != null
                      ? dateFormat.format(filterState.createdFrom!)
                      : 'From Date',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: filterState.createdTo ?? DateTime.now(),
                    firstDate: filterState.createdFrom ?? DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    ref.read(leadFilterProvider.notifier).setDateRange(
                          filterState.createdFrom,
                          date,
                        );
                    ref.read(leadListProvider.notifier).refresh();
                  }
                },
                icon: const Icon(Icons.calendar_today, size: 18),
                label: Text(
                  filterState.createdTo != null
                      ? dateFormat.format(filterState.createdTo!)
                      : 'To Date',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          ],
        ),
        if (filterState.createdFrom != null || filterState.createdTo != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: TextButton(
              onPressed: () {
                ref.read(leadFilterProvider.notifier).setDateRange(null, null);
                ref.read(leadListProvider.notifier).refresh();
              },
              child: const Text('Clear Date Range'),
            ),
          ),
      ],
    );
  }

  Widget _buildPresetButton(String label, DateRangePreset preset, bool isSelected) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        ref.read(leadFilterProvider.notifier).setDateRangePreset(preset);
        ref.read(leadListProvider.notifier).refresh();
      },
    );
  }

  Widget _buildFollowUpFilter(LeadFilterState filterState) {
    return DropdownButtonFormField<FollowUpFilter>(
      value: filterState.followUpFilter,
      decoration: InputDecoration(
        labelText: 'Follow-up Status',
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
      ),
      items: FollowUpFilter.values.map((filter) {
        String label;
        switch (filter) {
          case FollowUpFilter.all:
            label = 'All';
            break;
          case FollowUpFilter.dueToday:
            label = 'Due Today';
            break;
          case FollowUpFilter.overdue:
            label = 'Overdue';
            break;
          case FollowUpFilter.upcoming:
            label = 'Upcoming';
            break;
        }
        return DropdownMenuItem<FollowUpFilter>(
          value: filter,
          child: Text(label),
        );
      }).toList(),
      onChanged: (filter) {
        ref.read(leadFilterProvider.notifier).setFollowUpFilter(filter!);
        ref.read(leadListProvider.notifier).refresh();
      },
    );
  }
}
