import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/lead.dart';
import '../../domain/models/user.dart';

enum FollowUpFilter {
  all,
  dueToday, // Needs follow-up (no follow-up in last 7 days)
  overdue, // No follow-up in more than 14 days
  upcoming, // Has recent follow-up (within last 7 days)
}

enum DateRangePreset {
  today,
  last7Days,
  last30Days,
  custom,
}

enum LeadSortOption {
  newestFirst, // Default: updatedAt DESC
  lastContacted, // lastContactedAt DESC
  priorityFirst, // isPriority DESC, then updatedAt DESC
  oldestFirst, // createdAt ASC
}

class LeadFilterState {
  final List<LeadStatus> statuses; // Multi-select
  final String? assignedTo;
  final String? searchQuery;
  final UserRegion? region;
  final DateTime? createdFrom;
  final DateTime? createdTo;
  final DateRangePreset? datePreset;
  final FollowUpFilter followUpFilter;
  final bool? isPriority; // null = all, true = starred only, false = non-starred only
  final LeadSortOption sortOption;

  const LeadFilterState({
    this.statuses = const [],
    this.assignedTo,
    this.searchQuery,
    this.region,
    this.createdFrom,
    this.createdTo,
    this.datePreset,
    this.followUpFilter = FollowUpFilter.all,
    this.isPriority,
    this.sortOption = LeadSortOption.newestFirst,
  });

  LeadFilterState copyWith({
    List<LeadStatus>? statuses,
    String? assignedTo,
    String? searchQuery,
    UserRegion? region,
    DateTime? createdFrom,
    DateTime? createdTo,
    DateRangePreset? datePreset,
    FollowUpFilter? followUpFilter,
    bool? isPriority,
    LeadSortOption? sortOption,
    bool clearStatuses = false,
    bool clearAssignedTo = false,
    bool clearSearchQuery = false,
    bool clearRegion = false,
    bool clearDateRange = false,
    bool clearFollowUpFilter = false,
    bool clearPriority = false,
  }) {
    return LeadFilterState(
      statuses: clearStatuses ? const [] : (statuses ?? this.statuses),
      assignedTo: clearAssignedTo ? null : (assignedTo ?? this.assignedTo),
      searchQuery: clearSearchQuery ? null : (searchQuery ?? this.searchQuery),
      region: clearRegion ? null : (region ?? this.region),
      createdFrom: clearDateRange ? null : (createdFrom ?? this.createdFrom),
      createdTo: clearDateRange ? null : (createdTo ?? this.createdTo),
      datePreset: clearDateRange ? null : (datePreset ?? this.datePreset),
      followUpFilter: clearFollowUpFilter
          ? FollowUpFilter.all
          : (followUpFilter ?? this.followUpFilter),
      isPriority: clearPriority ? null : (isPriority ?? this.isPriority),
      sortOption: sortOption ?? this.sortOption,
    );
  }

  bool get hasFilters =>
      statuses.isNotEmpty ||
      assignedTo != null ||
      searchQuery != null ||
      region != null ||
      createdFrom != null ||
      createdTo != null ||
      followUpFilter != FollowUpFilter.all ||
      isPriority != null ||
      sortOption != LeadSortOption.newestFirst;

  int get activeFilterCount {
    int count = 0;
    if (statuses.isNotEmpty) count++;
    if (assignedTo != null) count++;
    if (searchQuery != null && searchQuery!.isNotEmpty) count++;
    if (region != null) count++;
    if (createdFrom != null || createdTo != null) count++;
    if (followUpFilter != FollowUpFilter.all) count++;
    if (isPriority != null) count++;
    if (sortOption != LeadSortOption.newestFirst) count++;
    return count;
  }
}

class LeadFilterNotifier extends StateNotifier<LeadFilterState> {
  LeadFilterNotifier() : super(const LeadFilterState());

  void toggleStatus(LeadStatus status) {
    final currentStatuses = List<LeadStatus>.from(state.statuses);
    if (currentStatuses.contains(status)) {
      currentStatuses.remove(status);
    } else {
      currentStatuses.add(status);
    }
    state = state.copyWith(statuses: currentStatuses, clearStatuses: currentStatuses.isEmpty);
  }

  void setStatuses(List<LeadStatus> statuses) {
    state = state.copyWith(statuses: statuses, clearStatuses: statuses.isEmpty);
  }

  void setAssignedTo(String? assignedTo) {
    state = state.copyWith(assignedTo: assignedTo, clearAssignedTo: assignedTo == null);
  }

  void setSearchQuery(String? query) {
    state = state.copyWith(searchQuery: query, clearSearchQuery: query == null || query.isEmpty);
  }

  void setRegion(UserRegion? region) {
    state = state.copyWith(region: region, clearRegion: region == null);
  }

  void setDateRangePreset(DateRangePreset preset) {
    final now = DateTime.now();
    DateTime? from;
    DateTime? to;

    switch (preset) {
      case DateRangePreset.today:
        from = DateTime(now.year, now.month, now.day);
        to = now;
        break;
      case DateRangePreset.last7Days:
        from = now.subtract(const Duration(days: 7));
        to = now;
        break;
      case DateRangePreset.last30Days:
        from = now.subtract(const Duration(days: 30));
        to = now;
        break;
      case DateRangePreset.custom:
        // Keep existing custom dates
        from = state.createdFrom;
        to = state.createdTo;
        break;
    }

    state = state.copyWith(
      createdFrom: from,
      createdTo: to,
      datePreset: preset == DateRangePreset.custom ? null : preset,
      clearDateRange: preset == DateRangePreset.custom && from == null && to == null,
    );
  }

  void setDateRange(DateTime? from, DateTime? to) {
    state = state.copyWith(
      createdFrom: from,
      createdTo: to,
      datePreset: from == null && to == null ? null : DateRangePreset.custom,
      clearDateRange: from == null && to == null,
    );
  }

  void setFollowUpFilter(FollowUpFilter filter) {
    state = state.copyWith(
      followUpFilter: filter,
      clearFollowUpFilter: filter == FollowUpFilter.all,
    );
  }

  void setIsPriority(bool? isPriority) {
    state = state.copyWith(
      isPriority: isPriority,
      clearPriority: isPriority == null,
    );
  }

  void setSortOption(LeadSortOption sortOption) {
    state = state.copyWith(sortOption: sortOption);
  }

  void clearFilters() {
    state = const LeadFilterState();
  }
}

final leadFilterProvider = StateNotifierProvider<LeadFilterNotifier, LeadFilterState>((ref) {
  return LeadFilterNotifier();
});

