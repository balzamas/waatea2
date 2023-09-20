import 'package:waatea2_client/models/drill_model.dart';

class TrainingModel {
  final String pk;
  final int dayofyear;
  final String season;
  final String date;
  final String club;
  final String remarks;
  final String review;
  final List<DrillModel> drills;

  TrainingModel({
    required this.pk,
    required this.dayofyear,
    required this.season,
    required this.date,
    required this.club,
    required this.remarks,
    required this.review,
    required this.drills,
  });

  factory TrainingModel.fromJson(Map<String, dynamic> json) {
    final List<dynamic> drillsJson = json['drills'] ?? [];
    final List<DrillModel> drills =
        drillsJson.map((drillJson) => DrillModel.fromJson(drillJson)).toList();

    return TrainingModel(
      pk: json['pk'],
      dayofyear: json['dayofyear'],
      season: json['season'],
      date: json['date'],
      club: json['club'],
      remarks: json['remarks'],
      review: json['review'],
      drills: drills,
    );
  }

  Map<String, dynamic> toJson() => {
        'pk': pk,
        'dayofyear': dayofyear,
        'season': season,
        'updated': date,
        'club': club
      };
}
