class CurrentSeasonModel {
  final int pk;
  final String club;
  final String season;

  CurrentSeasonModel(
      {required this.pk, required this.club, required this.season});

  factory CurrentSeasonModel.fromJson(Map<String, dynamic> json) {
    return CurrentSeasonModel(
        pk: json['pk'], club: json['club'], season: json['season']);
  }

  Map<String, dynamic> toJson() => {'pk': pk, 'club': club, 'season': season};
}
