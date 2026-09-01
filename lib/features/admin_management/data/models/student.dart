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
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    final user = json['userId'] as Map<String, dynamic>?;
    final parent = json['parentId'];
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
      address: json['address'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      status: json['status'] as String? ?? 'active',
    );
  }
}
