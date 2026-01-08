import 'package:otlplus/models/time.dart';

class Examtime extends Time {
  final String str;
  final String strEn;

  Examtime({
    required this.str,
    required this.strEn,
    required int day,
    required int begin,
    required int end,
  }) : super(day: day, begin: begin, end: end);

  @override
  List<Object> get props => super.props..addAll([str, strEn]);

  factory Examtime.fromJson(Map<String, dynamic> json) {
    return Examtime(
      str: json['str'],
      strEn: json['str_en'],
      day: json['day'],
      begin: json['begin'],
      end: json['end'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['str'] = this.str;
    data['str_en'] = this.strEn;
    data['day'] = this.day;
    data['begin'] = this.begin;
    data['end'] = this.end;
    return data;
  }
}
