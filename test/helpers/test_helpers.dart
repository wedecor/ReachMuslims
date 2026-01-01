import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import '../../lib/domain/models/user.dart';
import '../../lib/data/models/user_model.dart';
import '../../lib/domain/models/lead.dart';
import '../../lib/data/models/lead_model.dart';
import '../../lib/data/models/follow_up_model.dart';
import '../../lib/domain/models/notification.dart';
import '../../lib/data/models/notification_model.dart';

class TestHelpers {
  static MockFirebaseAuth createMockAuth({
    String? uid,
    String? email,
    bool signedIn = false,
  }) {
    final auth = MockFirebaseAuth(
      signedIn: signedIn,
      mockUser: signedIn
          ? MockUser(
              uid: uid ?? 'test-uid-123',
              email: email ?? 'test@example.com',
            )
          : null,
    );
    return auth;
  }

  static FakeFirebaseFirestore createMockFirestore() {
    return FakeFirebaseFirestore();
  }

  static Future<void> addUserToFirestore(
    FakeFirebaseFirestore firestore,
    String uid,
    String name,
    String email,
    UserRole role,
    UserRegion region,
    bool active,
  ) async {
    await firestore.collection('users').doc(uid).set({
      'name': name,
      'email': email,
      'role': role.name,
      'region': region.name,
      'active': active,
    });
  }

  static UserModel createTestUser({
    String uid = 'test-uid-123',
    String name = 'Test User',
    String email = 'test@example.com',
    UserRole role = UserRole.admin,
    UserRegion region = UserRegion.india,
    bool active = true,
  }) {
    return UserModel(
      uid: uid,
      name: name,
      email: email,
      role: role,
      region: region,
      active: active,
    );
  }

  static LeadModel createTestLead({
    String id = 'test-lead-123',
    String name = 'Test Lead',
    String phone = '1234567890',
    String? location,
    UserRegion region = UserRegion.india,
    LeadStatus status = LeadStatus.newLead,
    String? assignedTo,
    String? assignedToName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final now = DateTime.now();
    return LeadModel(
      id: id,
      name: name,
      phone: phone,
      location: location,
      region: region,
      status: status,
      assignedTo: assignedTo,
      assignedToName: assignedToName,
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
    );
  }

  static FollowUpModel createTestFollowUp({
    String id = 'test-followup-123',
    String note = 'Test follow-up note',
    String createdBy = 'user-123',
    String? createdByName,
    DateTime? createdAt,
  }) {
    return FollowUpModel(
      id: id,
      note: note,
      createdBy: createdBy,
      createdByName: createdByName,
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  static NotificationModel createTestNotification({
    String id = 'test-notification-123',
    String userId = 'user-123',
    String leadId = 'lead-123',
    NotificationType type = NotificationType.leadAssigned,
    String title = 'Test Notification',
    String body = 'Test body',
    bool read = false,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id,
      userId: userId,
      leadId: leadId,
      type: type,
      title: title,
      body: body,
      read: read,
      createdAt: createdAt ?? DateTime.now(),
    );
  }
}

