class CustomBlock {
  const CustomBlock({
    this.id = 0,
    required this.name,
    this.place = '',
    required this.day,
    required this.begin,
    required this.end,
  });

  final int id;
  final String name;
  final String place;
  final int day;
  final int begin;
  final int end;

  bool get isValid =>
      name.trim().isNotEmpty &&
      day >= 0 &&
      day <= 6 &&
      begin >= 0 &&
      begin < end &&
      end <= 1440;

  bool overlaps(CustomBlock other) =>
      day == other.day && begin < other.end && other.begin < end;

  factory CustomBlock.fromJson(Map<String, dynamic> json) {
    final block = CustomBlock(
      id: json['id'] as int,
      name: json['block_name'] as String,
      place: json['place'] as String,
      day: json['day'] as int,
      begin: json['begin'] as int,
      end: json['end'] as int,
    );
    if (block.id <= 0 || !block.isValid)
      throw const FormatException('Invalid custom block');
    return block;
  }

  Map<String, dynamic> toJson() => {'id': id, ...toPayload()};
  Map<String, dynamic> toPayload() => {
    'block_name': name.trim(),
    'place': place.trim(),
    'day': day,
    'begin': begin,
    'end': end,
  };
}
