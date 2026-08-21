class Department {
  final int id;
  final String name;
  final String nameEn;
  final String code;

  Department({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.code,
  });

  bool operator ==(Object other) =>
      identical(this, other) || (other is Department && other.id == id);

  int get hashCode => id.hashCode;

  Department.fromJson(Map<String, dynamic> json)
    : id = json['id'],
      name = json['name'],
      nameEn = json['name_en'],
      code = json['code'];

  /// Parses the v2 Basic department shape (`id`, `name`, and optional `code`).
  factory Department.fromV2Json(Map<String, dynamic> json) {
    final id = _departmentRequiredInt(json['id'], 'Department.id');
    final name = _departmentRequiredString(json['name'], 'Department.name');
    return Department(
      id: id,
      name: name,
      nameEn: _departmentString(json['nameEn']) ?? name,
      code: _departmentString(json['code']) ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['name_en'] = this.nameEn;
    data['code'] = this.code;
    return data;
  }
}

String _departmentRequiredString(Object? value, String field) {
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('$field must be a non-empty string');
  }
  return value;
}

int _departmentRequiredInt(Object? value, String field) {
  if (value is! int || value <= 0) {
    throw FormatException('$field must be a positive integer');
  }
  return value;
}

String? _departmentString(Object? value) {
  return value is String && value.trim().isNotEmpty ? value : null;
}
