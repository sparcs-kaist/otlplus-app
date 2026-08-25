import 'package:equatable/equatable.dart';

enum Weekday {
  monday(0),
  tuesday(1),
  wednesday(2),
  thursday(3),
  friday(4),
  saturday(5),
  sunday(6);

  const Weekday(this.code);

  final int code;

  static Weekday fromCode(int code) => values[code];
}

abstract class Time extends Equatable {
  final Weekday day;
  final int begin;
  final int end;

  Time({required Object day, required this.begin, required this.end})
    : day = day is Weekday ? day : Weekday.fromCode(day as int);

  @override
  List<Object> get props => [day, begin, end];
}
