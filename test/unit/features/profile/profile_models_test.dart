import 'package:cloud_lms/features/auth/data/models/app_role.dart';
import 'package:cloud_lms/features/profile/data/models/my_profile.dart';
import 'package:cloud_lms/features/profile/data/models/school_info.dart';
import 'package:flutter_test/flutter_test.dart';

/// Shapes copied from the live server's responses (2026-10-07).
void main() {
  test('Admin: name/email/phone/photo on the document itself', () {
    final p = MyProfile.fromJson(AppRole.admin, {
      '_id': 'a1',
      'fullName': 'Sabin Test',
      'email': 'admin@x.com',
      'phone': null,
      'profileImage': '',
      'schoolId': {'_id': 's1', 'name': 'Cloud Test Academy'},
    });
    expect(p.id, 'a1');
    expect(p.fullName, 'Sabin Test');
    expect(p.email, 'admin@x.com');
    expect(p.phone, isNull);
    expect(p.photoUrl, isNull, reason: 'empty profileImage means no photo');
    expect(p.schoolName, 'Cloud Test Academy');
    expect(p.minPasswordLength, 8);
    expect(p.canChangePhoto, isTrue);
  });

  test('Teacher: name/email from the populated userId, work details rows', () {
    final p = MyProfile.fromJson(AppRole.teacher, {
      '_id': 't1',
      'userId': {'_id': 'u1', 'fullName': 'Ben Teacher', 'email': 'ben@x.com'},
      'schoolId': {'name': 'Cloud Test Academy'},
      'employeeId': 'T002',
      'department': 'Science',
      'qualification': null,
      'subjects': ['Physics', 'Maths'],
      'experience': 0,
      'joiningDate': '2026-09-04T06:00:00.000Z',
      'phone': '9800000000',
      'profileImage': 'https://img/x.jpg',
    });
    expect(p.fullName, 'Ben Teacher');
    expect(p.email, 'ben@x.com');
    expect(p.phone, '9800000000');
    expect(p.photoUrl, 'https://img/x.jpg');
    expect(p.minPasswordLength, 6);
    expect(p.details, [
      ('Employee ID', 'T002'),
      ('Department', 'Science'),
      ('Subjects', 'Physics, Maths'),
      ('Joined', '4 Sep 2026'),
    ], reason: 'empty qualification and 0 years experience are left out');
  });

  test('Student: class + section, parent name, date of birth', () {
    final p = MyProfile.fromJson(AppRole.student, {
      '_id': 'st1',
      'userId': {'fullName': 'Amy Student', 'email': 'amy@x.com'},
      'class': 'Class 10',
      'section': 'A',
      'rollNumber': null,
      'dob': '2012-05-20T00:00:00.000Z',
      'parentId': {'_id': 'p1', 'fullName': 'Ravi Parent'},
    });
    expect(p.fullName, 'Amy Student');
    expect(p.dob, DateTime.utc(2012, 5, 20));
    expect(p.details, [('Class', 'Class 10 – A'), ('Parent / Guardian', 'Ravi Parent')]);
  });

  test('Parent: children listed, occupation kept, no photo upload', () {
    final p = MyProfile.fromJson(AppRole.parent, {
      '_id': 'p1',
      'userId': {'fullName': 'Ravi Parent', 'email': 'ravi@x.com'},
      'occupation': 'Farmer',
      'students': [
        {
          'userId': {'fullName': 'Amy Student'},
        },
        {
          'userId': {'fullName': 'Bo Student'},
        },
      ],
    });
    expect(p.occupation, 'Farmer');
    expect(p.details, [('Children', 'Amy Student, Bo Student')]);
    expect(p.canChangePhoto, isFalse);
  });

  test('SchoolInfo: "N/A" placeholders and empty logo read as missing', () {
    final s = SchoolInfo.fromJson({
      '_id': 's1',
      'name': 'Cloud Test Academy',
      'address': 'N/A',
      'phone': 'N/A',
      'email': 'school@x.com',
      'logo': '',
      'slogan': '',
    });
    expect(s.name, 'Cloud Test Academy');
    expect(s.address, isNull);
    expect(s.phone, isNull);
    expect(s.email, 'school@x.com');
    expect(s.logoUrl, isNull);
    expect(s.slogan, isNull);
  });
}
