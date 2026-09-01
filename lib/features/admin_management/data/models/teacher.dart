/// Shape confirmed by reading `teacherRoutes.js`/`teacherController.js`
/// directly. `fullName`/`email` live on the linked `User` document, returned
/// nested under a populated `userId` (`{fullName, email, role}`) — never
/// flat on the Teacher document itself, so [fromJson] reaches into that
/// nested object rather than the top level.
class Teacher {
  final String id;
  final String fullName;
  final String email;
  final String employeeId;
  final String department;
  final String designation;
  final String qualification;
  final List<String> subjects;
  final int experience;
  final double salary;
  final String address;
  final String phone;
  final String bankAccountNumber;
  final String status;

  const Teacher({
    required this.id,
    required this.fullName,
    required this.email,
    required this.employeeId,
    required this.department,
    required this.designation,
    required this.qualification,
    required this.subjects,
    required this.experience,
    required this.salary,
    required this.address,
    required this.phone,
    required this.bankAccountNumber,
    required this.status,
  });

  factory Teacher.fromJson(Map<String, dynamic> json) {
    final user = json['userId'] as Map<String, dynamic>?;
    return Teacher(
      id: json['_id'] as String? ?? json['id'] as String,
      fullName: user?['fullName'] as String? ?? '',
      email: user?['email'] as String? ?? json['email'] as String? ?? '',
      employeeId: json['employeeId'] as String? ?? '',
      department: json['department'] as String? ?? '',
      designation: json['designation'] as String? ?? '',
      qualification: json['qualification'] as String? ?? '',
      subjects: (json['subjects'] as List?)?.map((s) => s as String).toList() ?? const [],
      experience: (json['experience'] as num?)?.toInt() ?? 0,
      salary: (json['salary'] as num?)?.toDouble() ?? 0,
      address: json['address'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      bankAccountNumber: json['bankAccountNumber'] as String? ?? '',
      status: json['status'] as String? ?? 'active',
    );
  }
}
