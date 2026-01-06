import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/lead_repository.dart';
import '../../domain/models/lead.dart';
import '../../domain/models/user.dart';
import '../../core/errors/failures.dart';
import '../providers/auth_provider.dart';
import 'lead_list_provider.dart';

class DashboardStats {
  final int totalLeads;
  final int newLeads;
  final int inTalkLeads;
  final int interestedLeads;
  final int convertedLeads;
  final int notInterestedLeads;
  final int indiaLeads;
  final int usaLeads;
  final int leadsToday;
  final int leadsThisWeek;
  final int priorityLeads;
  final int followUpLeads;
  final int leadsContactedToday;
  final int pendingFollowUps;
  final bool isLoading;
  final Failure? error;

  const DashboardStats({
    this.totalLeads = 0,
    this.newLeads = 0,
    this.inTalkLeads = 0,
    this.interestedLeads = 0,
    this.convertedLeads = 0,
    this.notInterestedLeads = 0,
    this.indiaLeads = 0,
    this.usaLeads = 0,
    this.leadsToday = 0,
    this.leadsThisWeek = 0,
    this.priorityLeads = 0,
    this.followUpLeads = 0,
    this.leadsContactedToday = 0,
    this.pendingFollowUps = 0,
    this.isLoading = false,
    this.error,
  });

  DashboardStats copyWith({
    int? totalLeads,
    int? newLeads,
    int? inTalkLeads,
    int? interestedLeads,
    int? convertedLeads,
    int? notInterestedLeads,
    int? indiaLeads,
    int? usaLeads,
    int? leadsToday,
    int? leadsThisWeek,
    int? priorityLeads,
    int? followUpLeads,
    int? leadsContactedToday,
    int? pendingFollowUps,
    bool? isLoading,
    Failure? error,
    bool clearError = false,
  }) {
    return DashboardStats(
      totalLeads: totalLeads ?? this.totalLeads,
      newLeads: newLeads ?? this.newLeads,
      inTalkLeads: inTalkLeads ?? this.inTalkLeads,
      interestedLeads: interestedLeads ?? this.interestedLeads,
      convertedLeads: convertedLeads ?? this.convertedLeads,
      notInterestedLeads: notInterestedLeads ?? this.notInterestedLeads,
      indiaLeads: indiaLeads ?? this.indiaLeads,
      usaLeads: usaLeads ?? this.usaLeads,
      leadsToday: leadsToday ?? this.leadsToday,
      leadsThisWeek: leadsThisWeek ?? this.leadsThisWeek,
      priorityLeads: priorityLeads ?? this.priorityLeads,
      followUpLeads: followUpLeads ?? this.followUpLeads,
      leadsContactedToday: leadsContactedToday ?? this.leadsContactedToday,
      pendingFollowUps: pendingFollowUps ?? this.pendingFollowUps,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class DashboardNotifier extends StateNotifier<DashboardStats> {
  final LeadRepository _leadRepository;
  final Ref _ref;

  DashboardNotifier(this._leadRepository, this._ref) : super(const DashboardStats());

  Future<void> loadStats() async {
    try {
      final authState = _ref.read(authProvider);
      
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
      final region = isAdmin ? user.region : null; // region is nullable for pending users

      state = state.copyWith(isLoading: true, clearError: true);
      
      // Load all stats in parallel with individual error handling
      final results = await Future.wait([
        _leadRepository.getTotalLeadsCount(
          userId: userId,
          isAdmin: isAdmin,
          region: region,
        ).catchError((e) {
          debugPrint('Error getting total leads count: $e');
          return 0;
        }),
        _leadRepository.getLeadsCountByStatus(
          userId: userId,
          isAdmin: isAdmin,
          status: LeadStatus.newLead,
          region: region,
        ),
        _leadRepository.getLeadsCountByStatus(
          userId: userId,
          isAdmin: isAdmin,
          status: LeadStatus.followUp,
          region: region,
        ),
        _leadRepository.getLeadsCountByStatus(
          userId: userId,
          isAdmin: isAdmin,
          status: LeadStatus.inTalk,
          region: region,
        ),
        _leadRepository.getLeadsCountByStatus(
          userId: userId,
          isAdmin: isAdmin,
          status: LeadStatus.interested,
          region: region,
        ),
        _leadRepository.getLeadsCountByStatus(
          userId: userId,
          isAdmin: isAdmin,
          status: LeadStatus.converted,
          region: region,
        ),
        _leadRepository.getLeadsCountByStatus(
          userId: userId,
          isAdmin: isAdmin,
          status: LeadStatus.notInterested,
          region: region,
        ),
        _leadRepository.getLeadsCountByRegion(
          userId: userId,
          isAdmin: isAdmin,
          region: UserRegion.india,
        ),
        _leadRepository.getLeadsCountByRegion(
          userId: userId,
          isAdmin: isAdmin,
          region: UserRegion.usa,
        ),
        _leadRepository.getLeadsCreatedToday(
          userId: userId,
          isAdmin: isAdmin,
          region: region,
        ),
        _leadRepository.getLeadsCreatedThisWeek(
          userId: userId,
          isAdmin: isAdmin,
          region: region,
        ),
        _leadRepository.getPriorityLeadsCount(
          userId: userId,
          isAdmin: isAdmin,
          region: region,
        ).catchError((e) {
          debugPrint('Error getting priority leads count: $e');
          return 0;
        }),
        _leadRepository.getFollowUpLeadsCount(
          userId: userId,
          isAdmin: isAdmin,
          region: region,
        ).catchError((e) {
          debugPrint('Error getting follow-up leads count: $e');
          return 0;
        }),
      ]);

      // Calculate quick stats using dedicated count methods
      final quickStatsResults = await Future.wait([
        // Leads contacted today - use dedicated count method
        _leadRepository.getLeadsContactedTodayCount(
          userId: userId,
          isAdmin: isAdmin,
          region: region,
        ).catchError((e) {
          debugPrint('Error getting leads contacted today count: $e');
          return 0; // Return 0 on error to prevent dashboard from breaking
        }),
      ]);

      final leadsContactedToday = quickStatsResults[0];

      // Pending follow-ups: approximation (total - follow-up leads)
      // This is a rough estimate - exact count would require checking all follow-up histories
      final pendingFollowUps = results[0] > results[12] 
          ? (results[0] - results[12]).clamp(0, results[0])
          : 0;

      state = DashboardStats(
        totalLeads: results[0],
        newLeads: results[1],
        inTalkLeads: results[3], // newLead[1], followUp[2], inTalk[3]
        interestedLeads: results[4], // interested[4]
        convertedLeads: results[5], // converted[5]
        notInterestedLeads: results[6], // notInterested[6]
        indiaLeads: results[7], // india[7]
        usaLeads: results[8], // usa[8]
        leadsToday: results[9], // leadsToday[9]
        leadsThisWeek: results[10], // leadsThisWeek[10]
        priorityLeads: results[11], // priorityLeads[11]
        followUpLeads: results[12], // followUpLeads[12]
        leadsContactedToday: leadsContactedToday,
        pendingFollowUps: pendingFollowUps,
        isLoading: false,
      );
    } catch (e, stackTrace) {
      // Log the error for debugging
      debugPrint('Dashboard error: $e');
      debugPrint('Stack trace: $stackTrace');
      
      state = state.copyWith(
        isLoading: false,
        error: e is Failure ? e : FirestoreFailure('Failed to load dashboard stats: ${e.toString()}'),
      );
    }
  }

  Future<void> refresh() async {
    await loadStats();
  }
}

final dashboardProvider = StateNotifierProvider<DashboardNotifier, DashboardStats>((ref) {
  final leadRepository = ref.watch(leadRepositoryProvider);
  return DashboardNotifier(leadRepository, ref);
});

