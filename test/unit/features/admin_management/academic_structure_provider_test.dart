import 'package:cloud_lms/core/error/app_exception.dart';
import 'package:cloud_lms/core/error/result.dart';
import 'package:cloud_lms/features/admin_management/data/models/academic_class.dart';
import 'package:cloud_lms/features/admin_management/data/models/class_section.dart';
import 'package:cloud_lms/features/admin_management/data/repositories/class_repository.dart';
import 'package:cloud_lms/features/admin_management/data/repositories/section_repository.dart';
import 'package:cloud_lms/features/admin_management/presentation/providers/academic_structure_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockClassRepository extends Mock implements ClassRepository {}

class _MockSectionRepository extends Mock implements SectionRepository {}

const _class1 = AcademicClass(id: 'c1', name: 'Class 10', description: 'Grade 10', status: 'active');
const _section1 = ClassSection(id: 's1', name: 'A', classId: 'c1', status: 'active', studentCount: 5);

void main() {
  late _MockClassRepository classRepository;
  late _MockSectionRepository sectionRepository;
  late AcademicStructureProvider provider;

  setUp(() {
    classRepository = _MockClassRepository();
    sectionRepository = _MockSectionRepository();
    provider = AcademicStructureProvider(classRepository, sectionRepository);
  });

  test('loadClasses(): success populates classes and sets status', () async {
    when(() => classRepository.getClasses()).thenAnswer((_) async => const Result.success([_class1]));

    await provider.loadClasses();

    expect(provider.classesStatus, LoadStatus.success);
    expect(provider.classes, [_class1]);
  });

  test('loadClasses(): failure sets error status and surfaces the error', () async {
    when(() => classRepository.getClasses()).thenAnswer((_) async => const Result.failure(NetworkException()));

    await provider.loadClasses();

    expect(provider.classesStatus, LoadStatus.error);
    expect(provider.classesError, isA<NetworkException>());
  });

  test('createClass(): success appends to the classes list and returns true', () async {
    when(() => classRepository.createClass(name: any(named: 'name'), description: any(named: 'description')))
        .thenAnswer((_) async => const Result.success(_class1));

    final succeeded = await provider.createClass(name: 'Class 10', description: 'Grade 10');

    expect(succeeded, isTrue);
    expect(provider.classes.map((c) => c.id), [_class1.id]);
    // A just-created class has no sections yet.
    expect(provider.classes.single.sectionCount, 0);
    expect(provider.isSavingClass, isFalse);
  });

  test('createClass(): failure returns false and exposes the action error without touching the list', () async {
    when(() => classRepository.createClass(name: any(named: 'name'), description: any(named: 'description')))
        .thenAnswer((_) async => const Result.failure(ValidationException('name is required')));

    final succeeded = await provider.createClass(name: '');

    expect(succeeded, isFalse);
    expect(provider.classes, isEmpty);
    expect(provider.classActionError, isA<ValidationException>());
  });

  test('updateClass(): success replaces the matching class in place', () async {
    when(() => classRepository.getClasses()).thenAnswer((_) async => const Result.success([_class1]));
    await provider.loadClasses();

    const renamed = AcademicClass(id: 'c1', name: 'Class 10A', description: 'Grade 10', status: 'active');
    when(() => classRepository.updateClass(
          id: any(named: 'id'),
          name: any(named: 'name'),
          description: any(named: 'description'),
          status: any(named: 'status'),
        )).thenAnswer((_) async => const Result.success(renamed));

    final succeeded = await provider.updateClass(id: 'c1', name: 'Class 10A');

    expect(succeeded, isTrue);
    expect(provider.classes.map((c) => (c.id, c.name)), [(renamed.id, renamed.name)]);
  });

  test('deleteClass(): success removes it from the classes list', () async {
    when(() => classRepository.getClasses()).thenAnswer((_) async => const Result.success([_class1]));
    await provider.loadClasses();

    when(() => classRepository.deleteClass('c1')).thenAnswer((_) async => const Result.success(null));

    final succeeded = await provider.deleteClass('c1');

    expect(succeeded, isTrue);
    expect(provider.classes, isEmpty);
  });

  test('deleteClass(): failure (e.g. sections still exist) leaves the list untouched', () async {
    when(() => classRepository.getClasses()).thenAnswer((_) async => const Result.success([_class1]));
    await provider.loadClasses();

    when(() => classRepository.deleteClass('c1'))
        .thenAnswer((_) async => const Result.failure(ServerException('sections still exist')));

    final succeeded = await provider.deleteClass('c1');

    expect(succeeded, isFalse);
    expect(provider.classes, [_class1]);
    expect(provider.classActionError, isA<ServerException>());
  });

  test('loadSections(): success populates sections for the given classId', () async {
    when(() => sectionRepository.getSections('c1')).thenAnswer((_) async => const Result.success([_section1]));

    await provider.loadSections('c1');

    expect(provider.sectionsStatus, LoadStatus.success);
    expect(provider.sections, [_section1]);
    expect(provider.selectedClassId, 'c1');
  });

  test('createSection(): success appends to the sections list', () async {
    when(() => sectionRepository.createSection(classId: any(named: 'classId'), name: any(named: 'name')))
        .thenAnswer((_) async => const Result.success(_section1));

    final succeeded = await provider.createSection(classId: 'c1', name: 'A');

    expect(succeeded, isTrue);
    expect(provider.sections, [_section1]);
  });

  test('deleteSection(): success removes it from the sections list', () async {
    when(() => sectionRepository.getSections('c1')).thenAnswer((_) async => const Result.success([_section1]));
    await provider.loadSections('c1');

    when(() => sectionRepository.deleteSection('s1')).thenAnswer((_) async => const Result.success(null));

    final succeeded = await provider.deleteSection('s1');

    expect(succeeded, isTrue);
    expect(provider.sections, isEmpty);
  });
}
