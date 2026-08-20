enum Season {
  spring(1, 'semester.spring'),
  summer(2, 'semester.summer'),
  fall(3, 'semester.fall'),
  winter(4, 'semester.winter');

  const Season(this.code, this.labelKey);

  final int code;
  final String labelKey;

  static Season? fromCode(int code) {
    for (final season in values) {
      if (season.code == code) return season;
    }
    return null;
  }
}

enum ReviewTab { hallOfFame, latest }

enum TimetableViewMode { classes, exams, map }

enum TimetableAddResult { added, overlap, failed }

enum TimetableTabAction { copy, exportImage, exportIcal, delete }
