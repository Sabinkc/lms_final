/// Shape confirmed by reading `studentRoutes.js`/`studentController.js`
/// directly. `class`/`section` are free-text Strings on the Student document
/// itself (`studentSchema.js`) — **not** `Class`/`Section` refs — so the
/// add/edit form submits the plain class/section *names* it reads from
/// `ClassRepository`/`SectionRepository`, never an id.
class Student {
  final String id;
  final String fullName;
  final String email;
  final String admissionNumber;
  final String rollNumber;
  final String className;
  final String section;
  final String? parentId;
  final String dob;
  final String address;
  final String phone;
  final String status;

  // Profile-only fields (Student Profile screen). All optional: most are
  // blank on real records, and older call sites/tests build a `Student`
  // without them. `null` means "not provided", never an empty string.
  final String? studentIdCode;
  final String? gender;
  final String? bloodGroup;
  final String? house;
  final String? academicYear;
  final String? previousSchool;
  final String? previousGrade;
  final String? secondSubject;
  final String? fatherName;
  final String? fatherMobile;
  final String? motherName;
  final String? motherMobile;
  final String? guardianName;
  final String? guardianRelationship;
  final String? guardianEmail;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? emergencyContactRelationship;

  /// Linked parent account (`parentId` populated as `{fullName, email}`).
  final String? parentName;
  final String? parentEmail;
  final String? admissionDate;
  final String? createdAt;

  const Student({
    required this.id,
    required this.fullName,
    required this.email,
    required this.admissionNumber,
    required this.rollNumber,
    required this.className,
    required this.section,
    required this.parentId,
    required this.dob,
    required this.address,
    required this.phone,
    required this.status,
    this.studentIdCode,
    this.gender,
    this.bloodGroup,
    this.house,
    this.academicYear,
    this.previousSchool,
    this.previousGrade,
    this.secondSubject,
    this.fatherName,
    this.fatherMobile,
    this.motherName,
    this.motherMobile,
    this.guardianName,
    this.guardianRelationship,
    this.guardianEmail,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.emergencyContactRelationship,
    this.parentName,
    this.parentEmail,
    this.admissionDate,
    this.createdAt,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    final user = json['userId'] as Map<String, dynamic>?;
    final parent = json['parentId'];
    final parentMap = parent is Map<String, dynamic> ? parent : null;
    final emergency = json['emergencyContact'] as Map<String, dynamic>?;
    String? text(Object? v) {
      final t = v?.toString().trim();
      return (t == null || t.isEmpty) ? null : t;
    }

    final fullAddress = text((json['currentAddress'] as Map<String, dynamic>?)?['fullAddress']) ??
        text((json['permanentAddress'] as Map<String, dynamic>?)?['fullAddress']);
    return Student(
      id: json['_id'] as String? ?? json['id'] as String,
      fullName: user?['fullName'] as String? ?? '',
      email: user?['email'] as String? ?? json['email'] as String? ?? '',
      admissionNumber: json['admissionNumber'] as String? ?? '',
      rollNumber: json['rollNumber'] as String? ?? '',
      className: json['class'] as String? ?? '',
      section: json['section'] as String? ?? '',
      parentId: parent is Map<String, dynamic> ? parent['_id'] as String? : parent as String?,
      dob: json['dob'] as String? ?? '',
      address: json['address'] as String? ?? fullAddress ?? '',
      phone: json['phone'] as String? ?? '',
      status: json['status'] as String? ?? 'active',
      studentIdCode: text(json['studentIdCode']),
      gender: text(json['gender']),
      bloodGroup: text(json['bloodGroup']),
      house: text(json['house']),
      academicYear: text(json['academicYear']),
      previousSchool: text(json['previousSchool']),
      previousGrade: text(json['previousGrade']),
      secondSubject: text(json['secondSubject']),
      fatherName: text(json['fatherName']),
      fatherMobile: text(json['fatherMobile']),
      motherName: text(json['motherName']),
      motherMobile: text(json['motherMobile']),
      guardianName: text(json['guardianName']),
      guardianRelationship: text(json['guardianRelationship']),
      guardianEmail: text(json['guardianEmail']),
      emergencyContactName: text(emergency?['name']),
      emergencyContactPhone: text(emergency?['phone']),
      emergencyContactRelationship: text(emergency?['relationship']),
      parentName: text(parentMap?['fullName']),
      parentEmail: text(parentMap?['email']),
      admissionDate: text(json['admissionDate']),
      createdAt: text(json['createdAt']),
    );
  }
}
