import 'package:waatea2_client/models/user_model.dart';

class FitnessModel {
  final String pk;
  final UserModel player;
  final String date;
  final String season;
  final int points;
  final String note;

  FitnessModel(
      {required this.pk,
      required this.player,
      required this.date,
      required this.season,
      required this.note,
      required this.points});

  factory FitnessModel.fromJson(Map<String, dynamic> json) {
    return FitnessModel(
        pk: json['pk'],
        player: UserModel.fromJson(json['player']),
        date: json['date'],
        season: json['season'],
        note: json['note'],
        points: json['points']);
  }

  Map<String, dynamic> toJson() => {
        'pk': pk,
        'player': player,
        'date': date,
        'season': season,
        'note': note,
        'points': points
      };
}
