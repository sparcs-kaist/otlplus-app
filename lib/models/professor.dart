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

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['name'] = this.name;
    data['name_en'] = this.nameEn;
    data['professor_id'] = this.professorId;
    data['review_total_weight'] = this.reviewTotalWeight;
    return data;
  }
}
