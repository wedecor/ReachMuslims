import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/lead.dart';
import '../../domain/repositories/lead_repository.dart';
import '../../domain/repositories/follow_up_repository.dart';
import '../../data/repositories/lead_repository_impl.dart';
import '../../data/repositories/follow_up_repository_impl.dart';
import '../../core/errors/failures.dart';
import '../providers/auth_provider.dart';
import 'lead_filter_provider.dart';

final leadRepositoryProvider = Provider<LeadRepository>((ref) {
  return LeadRepositoryImpl();
});

final followUpRepositoryForFilterProvider = Provider<FollowUpRepository>((ref) {
  return FollowUpRepositoryImpl();
});

class LeadListState {
  final List<Lead> leads;
  final bool isLoading;
  final bool isLoadingMore;
  final Failure? error;
  final bool hasMore;
  final String? lastDocumentId;

  const LeadListState({
    this.leads = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.hasMore = true,
    this.lastDocumentId,
  });

  LeadListState copyWith({
    List<Lead>? leads,
    bool? isLoading,
    bool? isLoadingMore,
    Failure? error,
    bool? hasMore,
    String? lastDocumentId,
    bool clearError = false,
  }) {
    return LeadListState(
      leads: leads ?? this.leads,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
      hasMore: hasMore ?? this.hasMore,
      lastDocumentId: lastDocumentId ?? this.lastDocumentId,
    );
  }
}

class LeadListNotifier extends StateNotifier<LeadListState> {
  final LeadRepository _leadRepository;
  final Ref _ref;

  LeadListNotifier(this._leadRepository, this._ref) : super(const LeadListState());

  Future<List<Lead>> _applyFollowUpFilter(
    List<Lead> leads,
    FollowUpFilter filter,
  ) async {
    if (filter == FollowUpFilter.all) {
      return leads;
    }

    final followUpRepository = _ref.read(followUpRepositoryForFilterProvider);
    final now = DateTime.now();

    final filteredLeads = <Lead>[];

    for (final lead in leads) {
      try {
        final followUps = await followUpRepository.getFollowUps(lead.id);
        
        if (followUps.isEmpty) {
          // No follow-ups - treat as overdue
          if (filter == FollowUpFilter.overdue || filter == FollowUpFilter.dueToday) {
            filteredLeads.add(lead);
          }
          continue;
        }

        // Get most recent follow-up
        final mostRecent = followUps.first; // Already sorted DESC
        final daysSinceFollowUp = now.difference(mostRecent.createdAt).inDays;

        switch (filter) {
          case FollowUpFilter.dueToday:
            // Needs follow-up today (no follow-up in last 7 days)
            if (daysSinceFollowUp >= 7) {
              filteredLeads.add(lead);
            }
            break;
          case FollowUpFilter.overdue:
            // No follow-up in more than 14 days
            if (daysSinceFollowUp > 14) {
              filteredLeads.add(lead);
            }
            break;
          case FollowUpFilter.upcoming:
            // Has recent follow-up (within last 7 days)
            if (daysSinceFollowUp < 7) {
              filteredLeads.add(lead);
            }
            break;
          case FollowUpFilter.all:
            // Should not reach here
            break;
        }
      } catch (e) {
        // If we can't fetch follow-ups, include the lead for dueToday/overdue (fail open)
        if (filter == FollowUpFilter.dueToday || filter == FollowUpFilter.overdue) {
          filteredLeads.add(lead);
        }
      }
    }

      return filteredLeads;
    }

  List<Lead> _applySorting(List<Lead> leads, LeadSortOption sortOption) {
    final sortedLeads = List<Lead>.from(leads);
    
    switch (sortOption) {
      case LeadSortOption.newestFirst:
        sortedLeads.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
      case LeadSortOption.lastContacted:
        sortedLeads.sort((a, b) {
          // Leads with lastContactedAt come first, then by date DESC
          if (a.lastContactedAt == null && b.lastContactedAt == null) {
            return b.updatedAt.compareTo(a.updatedAt);
          }
          if (a.lastContactedAt == null) return 1;
          if (b.lastContactedAt == null) return -1;
          return b.lastContactedAt!.compareTo(a.lastContactedAt!);
        });
        break;
      case LeadSortOption.priorityFirst:
        sortedLeads.sort((a, b) {
          // Priority leads first, then by updatedAt DESC
          if (a.isPriority && !b.isPriority) return -1;
          if (!a.isPriority && b.isPriority) return 1;
          return b.updatedAt.compareTo(a.updatedAt);
        });
        break;
      case LeadSortOption.oldestFirst:
        sortedLeads.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
    }
    
    return sortedLeads;
  }

  Future<void> loadLeads({bool refresh = false}) async {
    if (refresh) {
      state = state.copyWith(isLoading: true, clearError: true, lastDocumentId: null);
    } else if (state.isLoading || state.isLoadingMore) {
      return; // Already loading
    }

    final authState = _ref.read(authProvider);
    final filterState = _ref.read(leadFilterProvider);

    if (!authState.isAuthenticated || authState.user == null) {
      state = state.copyWith(
        isLoading: false,
        error: const AuthFailure('User not authenticated'),
      );
      return;
    }

    final user = authState.user!;
    final userId = user.uid;
    final isAdmin = user.isAdmin;

    try {
      if (refresh) {
        state = state.copyWith(isLoading: true, clearError: true, lastDocumentId: null);
      } else {
        state = state.copyWith(isLoadingMore: true, clearError: true);
      }

      var leads = await _leadRepository.getLeads(
        userId: userId,
        isAdmin: isAdmin,
        region: filterState.region,
        statuses: filterState.statuses.isNotEmpty ? filterState.statuses : null,
        assignedTo: filterState.assignedTo,
        searchQuery: filterState.searchQuery,
        createdFrom: filterState.createdFrom,
        createdTo: filterState.createdTo,
        limit: 20,
        lastDocumentId: refresh ? null : state.lastDocumentId,
      );

      // Apply follow-up filter (in-memory)
      if (filterState.followUpFilter != FollowUpFilter.all) {
        leads = await _applyFollowUpFilter(leads, filterState.followUpFilter);
      }

      // Apply priority filter (in-memory)
      if (filterState.isPriority != null) {
        leads = leads.where((lead) => lead.isPriority == filterState.isPriority).toList();
      }

      // Apply sorting (in-memory)
      leads = _applySorting(leads, filterState.sortOption);

      if (refresh) {
        state = LeadListState(
          leads: leads,
          isLoading: false,
          hasMore: leads.length >= 20,
          lastDocumentId: leads.isNotEmpty ? leads.last.id : null,
        );
      } else {
        final updatedLeads = [...state.leads, ...leads];
        state = state.copyWith(
          leads: updatedLeads,
          isLoadingMore: false,
          hasMore: leads.length >= 20,
          lastDocumentId: leads.isNotEmpty ? leads.last.id : null,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: e is Failure ? e : FirestoreFailure('Failed to load leads: ${e.toString()}'),
      );
    }
  }

  Future<void> refresh() async {
    await loadLeads(refresh: true);
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore || state.isLoading) {
      return;
    }
    await loadLeads(refresh: false);
  }

  Future<void> updateStatus(String leadId, LeadStatus status) async {
    try {
      // Optimistic update
      final updatedLeads = state.leads.map((lead) {
        if (lead.id == leadId) {
          return Lead(
            id: lead.id,
            name: lead.name,
            phone: lead.phone,
            location: lead.location,
            region: lead.region,
            status: status,
            assignedTo: lead.assignedTo,
            assignedToName: lead.assignedToName,
            createdAt: lead.createdAt,
            updatedAt: DateTime.now(),
          );
        }
        return lead;
      }).toList();

      state = state.copyWith(leads: updatedLeads);

      // Update in Firestore
      await _leadRepository.updateLeadStatus(leadId, status);

      // Reload to get server timestamp
      await refresh();
    } catch (e) {
      // Revert optimistic update on error
      await refresh();
      state = state.copyWith(
        error: e is Failure ? e : FirestoreFailure('Failed to update status: ${e.toString()}'),
      );
    }
  }
}

final leadListProvider = StateNotifierProvider<LeadListNotifier, LeadListState>((ref) {
  final leadRepository = ref.watch(leadRepositoryProvider);
  return LeadListNotifier(leadRepository, ref);
});

