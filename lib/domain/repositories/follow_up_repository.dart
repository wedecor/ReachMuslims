import '../models/follow_up.dart';

abstract class FollowUpRepository {
  /// Adds a follow-up note for the given [leadId].
  ///
  /// [note] is the full content that will be stored.
  /// [createdBy] is the UID of the user creating the follow-up.
  ///
  /// Optional metadata can be provided for analytics/audit:
  /// - [type]: e.g. "whatsapp"
  /// - [region]: e.g. "india" / "usa"
  /// - [messagePreview]: a short preview of the message (first 50 chars, etc.)
  Future<FollowUp> addFollowUp(
    String leadId,
    String note,
    String createdBy, {
    String? type,
    String? region,
    String? messagePreview,
  });

  Stream<List<FollowUp>> streamFollowUps(String leadId);
  Future<List<FollowUp>> getFollowUps(String leadId);
}

