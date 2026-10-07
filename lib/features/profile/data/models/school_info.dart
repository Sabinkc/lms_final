/// The Admin's own school, from `GET /api/schools/me`. The backend stores
/// one image for a school — its [logoUrl] (also printed on student ID
/// cards); there is no cover/banner photo field.
class SchoolInfo {
  final String id;
  final String name;
  final String? address;
  final String? phone;
  final String? email;
  final String? slogan;
  final String? logoUrl;

  const SchoolInfo({
    required this.id,
    required this.name,
    this.address,
    this.phone,
    this.email,
    this.slogan,
    this.logoUrl,
  });

  factory SchoolInfo.fromJson(Map<String, dynamic> json) => SchoolInfo(
    id: json['_id'] as String? ?? '',
    name: _text(json['name']) ?? '',
    address: _text(json['address']),
    phone: _text(json['phone']),
    email: _text(json['email']),
    slogan: _text(json['slogan']),
    logoUrl: _text(json['logo']),
  );

  /// Self-signup schools are created with "N/A" placeholders — treat those
  /// as empty rather than showing "N/A" as if it were real data.
  static String? _text(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty || trimmed.toUpperCase() == 'N/A' ? null : trimmed;
  }
}
