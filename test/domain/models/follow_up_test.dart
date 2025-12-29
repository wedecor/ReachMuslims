import 'package:flutter_test/flutter_test.dart';
import '../../../lib/domain/models/follow_up.dart';

void main() {
  group('FollowUp', () {
    test('should create FollowUp with all fields', () {
      // Arrange
      final now = DateTime.now();
      const id = 'follow-up-123';
      const note = 'Test follow-up note';
      const createdBy = 'user-123';
      const createdByName = 'John Doe';

      // Act
      final followUp = FollowUp(
        id: id,
        note: note,
        createdBy: createdBy,
        createdByName: createdByName,
        createdAt: now,
      );

      // Assert
      expect(followUp.id, equals(id));
      expect(followUp.note, equals(note));
      expect(followUp.createdBy, equals(createdBy));
      expect(followUp.createdByName, equals(createdByName));
      expect(followUp.createdAt, equals(now));
    });

    test('should create FollowUp without createdByName', () {
      // Arrange
      final now = DateTime.now();
      const id = 'follow-up-123';
      const note = 'Test follow-up note';
      const createdBy = 'user-123';

      // Act
      final followUp = FollowUp(
        id: id,
        note: note,
        createdBy: createdBy,
        createdAt: now,
      );

      // Assert
      expect(followUp.id, equals(id));
      expect(followUp.note, equals(note));
      expect(followUp.createdBy, equals(createdBy));
      expect(followUp.createdByName, isNull);
      expect(followUp.createdAt, equals(now));
    });
  });
}

