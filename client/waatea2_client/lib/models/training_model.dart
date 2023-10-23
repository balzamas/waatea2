class TrainingModel {
  final String id;
  final int dayofyear;
  final String season;
  final String date;
  final String club;
  final String remarks;
  final String review;

  TrainingModel({
    required this.id,
    required this.dayofyear,
    required this.season,
    required this.date,
    required this.club,
    required this.remarks,
    required this.review,
  });

  factory TrainingModel.fromJson(Map<String, dynamic> json) {
    return TrainingModel(
      id: json['id'],
      dayofyear: json['dayofyear'],
      season: json['season'],
      date: json['date'],
      club: json['club'],
      remarks: json['remarks'],
      review: json['review'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'dayofyear': dayofyear,
        'season': season,
        'updated': date,
        'club': club
      };
}
