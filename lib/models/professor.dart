class Professor {
  final String name;
  final String nameEn;
  final int professorId;
  final double reviewTotalWeight;

  Professor({
    required this.name,
    required this.nameEn,
    required this.professorId,
    required this.reviewTotalWeight,
  });

  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Professor && other.professorId == professorId);

  int get hashCode => professorId.hashCode;

  Professor.fromJson(Map<String, dynamic> json)
    : name = json['name'],
      nameEn = json['name_en'],
      professorId = json['professor_id'],
      reviewTotalWeight = json['review_total_weight'];

  /// Parses the v2 Basic professor shape (`id` and `name`).
  factory Professor.fromV2Json(Map<String, dynamic> json) {
    final id = _professorRequiredInt(json['id'], 'Professor.id');
    final name = _professorRequiredString(json['name'], 'Professor.name');
    return Professor(
      name: name,
      nameEn: _professorString(json['nameEn']) ?? name,
      professorId: id,
      reviewTotalWeight: _professorDouble(json['reviewTotalWeight']),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['name'] = this.name;
    data['name_en'] = this.nameEn;
    data['professor_id'] = this.professorId;
    data['review_total_weight'] = this.reviewTotalWeight;
    return data;
  }
}

String _professorRequiredString(Object? value, String field) {
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('$field must be a non-empty string');
  }
  return value;
}

int _professorRequiredInt(Object? value, String field) {
  if (value is! int || value <= 0) {
    throw FormatException('$field must be a positive integer');
  }
  return value;
}

String? _professorString(Object? value) {
  return value is String && value.trim().isNotEmpty ? value : null;
}

double _professorDouble(Object? value) => value is num ? value.toDouble() : 0;
