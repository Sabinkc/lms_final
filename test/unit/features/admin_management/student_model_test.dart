import 'package:cloud_lms/features/admin_management/data/models/student.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Student.fromJson reads profile fields and treats null/blank as not provided', () {
    // Trimmed from a real `GET /students` record.
    final student = Student.fromJson({
      '_id': 's1',
      'userId': {'_id': 'u1', 'fullName': 'Sam Student', 'email': 'sam@school.test'},
      'class': 'Class 10',
      'section': 'A',
      'admissionNumber': null,
      'rollNumber': null,
      'gender': 'male',
      'bloodGroup': 'B+',
      'house': '  ',
      'fatherName': 'Ram Student',
      'motherName': null,
      'emergencyContact': {'name': 'Hari', 'relationship': 'Uncle', 'phone': null},
      'parentId': {'_id': 'p1', 'fullName': 'Pat Parent', 'email': 'pat@school.test'},
      'address': null,
      'currentAddress': {'fullAddress': 'Kathmandu'},
      'admissionDate': '2026-09-30T18:19:32.622Z',
      'createdAt': '2026-09-04T18:35:34.136Z',
      'status': 'active',
    });

    expect(student.fullName, 'Sam Student');
    expect(student.admissionNumber, '');
    expect(student.gender, 'male');
    expect(student.bloodGroup, 'B+');
    expect(student.house, isNull);
    expect(student.fatherName, 'Ram Student');
    expect(student.motherName, isNull);
    expect(student.emergencyContactName, 'Hari');
    expect(student.emergencyContactPhone, isNull);
    expect(student.parentId, 'p1');
    expect(student.parentName, 'Pat Parent');
    expect(student.address, 'Kathmandu');
    expect(student.admissionDate, '2026-09-30T18:19:32.622Z');
  });
}
