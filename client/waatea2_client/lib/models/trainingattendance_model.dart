class TrainingAttendanceModel {
  final String pk;
  final int dayofyear;
  final String season;
  final String date;
  final String club;
  final int attendanceCount;

  TrainingAttendanceModel(
      {required this.pk,
      required this.dayofyear,
      required this.season,
      required this.date,
      required this.club,
      required this.attendanceCount});

  factory TrainingAttendanceModel.fromJson(Map<String, dynamic> json) {
    return TrainingAttendanceModel(
        pk: json['pk'],
        dayofyear: json['dayofyear'],
        season: json['season'],
        date: json['date'],
        club: json['club'],
        attendanceCount: json['attendanceCount']);
  }
}
