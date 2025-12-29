import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/lead_repository.dart';
import '../../domain/models/lead.dart';
import '../../core/errors/failures.dart';
import '../../core/services/csv_export_service.dart';
import '../../core/services/file_download_service.dart';
import '../providers/auth_provider.dart';
import 'lead_list_provider.dart';

class LeadExportState {
  final bool isLoading;
  final Failure? error;
  final String? successMessage;

  const LeadExportState({
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  LeadExportState copyWith({
    bool? isLoading,
    Failure? error,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return LeadExportState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

class LeadExportNotifier extends StateNotifier<LeadExportState> {
  final LeadRepository _leadRepository;
  final Ref _ref;

  LeadExportNotifier(this._leadRepository, this._ref)
      : super(const LeadExportState());

  Future<bool> exportLeadsToCsv() async {
    try {
      final authState = _ref.read(authProvider);
      if (!authState.isAuthenticated || authState.user == null) {
        state = state.copyWith(
          error: const AuthFailure('User not authenticated'),
        );
        return false;
      }

      final user = authState.user!;
      if (!user.active) {
        state = state.copyWith(
          error: const AuthFailure('Inactive users cannot export leads'),
        );
        return false;
      }

      state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);

      // Fetch all non-deleted leads based on user role
      final isAdmin = user.isAdmin;
      final userId = user.uid;
      final region = isAdmin ? user.region : null;

      // Fetch all leads (no pagination limit for export)
      // Note: This may be slow for very large datasets, but acceptable for basic export
      List<Lead> allLeads = [];
      String? lastDocumentId;
      bool hasMore = true;

      while (hasMore) {
        final leads = await _leadRepository.getLeads(
          userId: userId,
          isAdmin: isAdmin,
          region: region,
          statuses: null,
          assignedTo: null,
          searchQuery: null,
          createdFrom: null,
          createdTo: null,
          limit: 1000, // Fetch in batches of 1000
          lastDocumentId: lastDocumentId,
        );

        allLeads.addAll(leads);

        if (leads.length < 1000) {
          hasMore = false;
        } else {
          lastDocumentId = leads.last.id;
        }
      }

      // Filter out deleted leads (in case any slipped through)
      allLeads = allLeads.where((lead) => !lead.isDeleted).toList();

      if (allLeads.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          error: const FirestoreFailure('No leads to export'),
        );
        return false;
      }

      // Generate CSV content
      final csvContent = CsvExportService.exportLeadsToCsv(allLeads);
      final filename = CsvExportService.generateFilename();

      // Download/share the file
      await FileDownloadService.downloadCsv(
        csvContent: csvContent,
        filename: filename,
      );

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Exported ${allLeads.length} leads successfully',
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e is Failure
            ? e
            : FirestoreFailure('Failed to export leads: ${e.toString()}'),
      );
      return false;
    }
  }
}

final leadExportProvider =
    StateNotifierProvider<LeadExportNotifier, LeadExportState>((ref) {
  final leadRepository = ref.watch(leadRepositoryProvider);
  return LeadExportNotifier(leadRepository, ref);
});

