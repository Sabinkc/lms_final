import 'package:cloud_lms/core/error/result.dart';
import 'package:cloud_lms/core/realtime/realtime_service.dart';
import 'package:cloud_lms/core/storage/secure_storage_service.dart';
import 'package:cloud_lms/features/admin_management/data/models/student.dart';
import 'package:cloud_lms/features/chat/data/models/group_conversation.dart';
import 'package:cloud_lms/features/chat/data/repositories/chat_repository.dart';
import 'package:cloud_lms/features/chat/presentation/providers/chat_provider.dart';
import 'package:cloud_lms/features/chat/presentation/screens/manage_group_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockChatRepository extends Mock implements ChatRepository {}

class _MockRealtimeService extends Mock implements RealtimeService {}

class _MockSecureStorageService extends Mock implements SecureStorageService {}

const _group = GroupConversation(
  id: 'g1',
  name: 'Class 10 (Whole Class)',
  classId: 'c1',
  className: 'Class 10',
  sectionId: null,
  sectionName: null,
  teacherIds: ['t1'],
  memberIds: ['s1'],
  lastMessageAt: null,
  lastMessagePreview: '',
  status: 'active',
);

Student _student(String id, String name) => Student(
      id: id,
      fullName: name,
      email: '$id@school.test',
      admissionNumber: 'A-$id',
      rollNumber: '1',
      className: 'Class 10',
      section: 'A',
      parentId: null,
      dob: '',
      address: '',
      phone: '',
      status: 'active',
    );

/// The settings (gear) button in a group chat opened this dialog with a
/// `Spacer` in its action row; dialog actions are laid out by an
/// `OverflowBar`, which can't hold a flex child, so opening it threw and
/// broke the dialog on a phone.
void main() {
  testWidgets('Manage Group opens without a layout error on a phone', (tester) async {
    tester.view.physicalSize = const Size(412, 915) * 2.6;
    tester.view.devicePixelRatio = 2.6;
    addTearDown(tester.view.reset);

    final repository = _MockChatRepository();
    when(() => repository.getGroupById('g1'))
        .thenAnswer((_) async => Result.success((_group, [_student('s1', 'Sam Student')])));
    when(() => repository.previewRoster(classId: 'c1', sectionId: null))
        .thenAnswer((_) async => Result.success([_student('s1', 'Sam Student'), _student('s2', 'Amy Student')]));
    final provider = ChatProvider(repository, _MockRealtimeService(), _MockSecureStorageService());

    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => showManageGroupDialog(context, provider, _group),
            child: const Text('Open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Manage "Class 10 (Whole Class)"'), findsOneWidget);
    expect(find.text('Sam Student'), findsOneWidget);
    expect(find.text('Amy Student'), findsOneWidget);
    for (final label in ['Archive', 'Delete', 'Close']) {
      expect(find.widgetWithText(TextButton, label), findsOneWidget);
    }

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.widgetWithText(FilledButton, 'Add'), findsOneWidget);
  });
}
