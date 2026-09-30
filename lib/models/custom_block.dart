class CustomBlockTime {
  const CustomBlockTime({
    required this.day,
    required this.begin,
    required this.end,
  });
  final int day;
  final int begin;
  final int end;
  bool get isValid =>
      day >= 0 && day <= 6 && begin >= 0 && begin < end && end <= 1440;
  bool overlaps(CustomBlockTime other) =>
      day == other.day && begin < other.end && other.begin < end;
  factory CustomBlockTime.fromJson(Map<String, dynamic> json) =>
      CustomBlockTime(
        day: json['day'] as int,
        begin: json['begin'] as int,
        end: json['end'] as int,
      );
  Map<String, dynamic> toJson() => {'day': day, 'begin': begin, 'end': end};
}

class CustomBlock {
  const CustomBlock({
    this.id = 0,
    required this.name,
    this.place = '',
    required this.day,
    required this.begin,
    required this.end,
    this.times = const [],
  });
  final int id;
  final String name;
  final String place;
  final int day;
  final int begin;
  final int end;
  final List<CustomBlockTime> times;
  List<CustomBlockTime> get occurrences => times.isEmpty
      ? [CustomBlockTime(day: day, begin: begin, end: end)]
      : times;
  bool get isValid =>
      name.trim().isNotEmpty &&
      occurrences.every((time) => time.isValid) &&
      !hasInternalOverlap;
  bool get hasInternalOverlap {
    final slots = occurrences;
    for (var i = 0; i < slots.length; i++) {
      for (var j = i + 1; j < slots.length; j++) {
        if (slots[i].overlaps(slots[j])) return true;
      }
    }
    return false;
  }

  bool overlaps(CustomBlock other) =>
      occurrences.any((time) => other.occurrences.any(time.overlaps));
  factory CustomBlock.fromJson(Map<String, dynamic> json) {
    final times = (json['times'] as List<dynamic>? ?? [])
        .map((time) => CustomBlockTime.fromJson(time as Map<String, dynamic>))
        .toList();
    final block = CustomBlock(
      id: json['id'] as int,
      name: json['block_name'] as String,
      place: json['place'] as String,
      day: json['day'] as int? ?? times.first.day,
      begin: json['begin'] as int? ?? times.first.begin,
      end: json['end'] as int? ?? times.first.end,
      times: List.unmodifiable(times),
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
    if (times.isNotEmpty) 'times': times.map((time) => time.toJson()).toList(),
  };
  Map<String, dynamic> toCreatePayload() => {
    'block_name': name.trim(),
    'place': place.trim(),
    'times': occurrences.map((time) => time.toJson()).toList(),
  };
}
