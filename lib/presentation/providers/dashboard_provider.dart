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
  final int convertedLeads;
  final int notInterestedLeads;
  final int indiaLeads;
  final int usaLeads;
  final int leadsToday;
  final int leadsThisWeek;
  final bool isLoading;
  final Failure? error;

  const DashboardStats({
    this.totalLeads = 0,
    this.newLeads = 0,
    this.inTalkLeads = 0,
    this.convertedLeads = 0,
    this.notInterestedLeads = 0,
    this.indiaLeads = 0,
    this.usaLeads = 0,
    this.leadsToday = 0,
    this.leadsThisWeek = 0,
    this.isLoading = false,
    this.error,
  });

  DashboardStats copyWith({
    int? totalLeads,
    int? newLeads,
    int? inTalkLeads,
    int? convertedLeads,
    int? notInterestedLeads,
    int? indiaLeads,
    int? usaLeads,
    int? leadsToday,
    int? leadsThisWeek,
    bool? isLoading,
    Failure? error,
    bool clearError = false,
  }) {
    return DashboardStats(
      totalLeads: totalLeads ?? this.totalLeads,
      newLeads: newLeads ?? this.newLeads,
      inTalkLeads: inTalkLeads ?? this.inTalkLeads,
      convertedLeads: convertedLeads ?? this.convertedLeads,
      notInterestedLeads: notInterestedLeads ?? this.notInterestedLeads,
      indiaLeads: indiaLeads ?? this.indiaLeads,
      usaLeads: usaLeads ?? this.usaLeads,
      leadsToday: leadsToday ?? this.leadsToday,
      leadsThisWeek: leadsThisWeek ?? this.leadsThisWeek,
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
          status: LeadStatus.inTalk,
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
      ]);

      state = DashboardStats(
        totalLeads: results[0],
        newLeads: results[1],
        inTalkLeads: results[2],
        convertedLeads: results[3],
        notInterestedLeads: results[4],
        indiaLeads: results[5],
        usaLeads: results[6],
        leadsToday: results[7],
        leadsThisWeek: results[8],
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

