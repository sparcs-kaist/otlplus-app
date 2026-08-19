import 'package:otlplus/models/time.dart';

class CustomBlockTime extends Time {
  final String place;

  CustomBlockTime({
    required this.place,
    required int day,
    required int begin,
    required int end,
  }) : super(day: day, begin: begin, end: end);

  @override
  List<Object> get props => super.props..add(place);
}

class CustomBlock {
  final int id;
  final String blockName;
  final String place;
  final int day;
  final int begin;
  final int end;

  CustomBlock({
    required this.id,
    required this.blockName,
    required this.place,
    required this.day,
    required this.begin,
    required this.end,
  });

  bool operator ==(Object other) =>
      identical(this, other) || (other is CustomBlock && other.id == id);

  @override
  int get hashCode => id.hashCode;

  CustomBlockTime get time => CustomBlockTime(
        place: place,
        day: day,
        begin: begin,
        end: end,
      );

  factory CustomBlock.fromJson(Map<String, dynamic> json) {
    return CustomBlock(
      id: json['id'],
      blockName: json['block_name'] ?? '',
      place: json['place'] ?? '',
      day: json['day'],
      begin: json['begin'],
      end: json['end'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['id'] = this.id;
    data['block_name'] = this.blockName;
    data['place'] = this.place;
    data['day'] = this.day;
    data['begin'] = this.begin;
    data['end'] = this.end;
    return data;
  }
}
