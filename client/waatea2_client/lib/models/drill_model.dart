class DrillModel {
  final String pk;
  final int minplayers;
  final String name;
  final String link;
  final String club;
  final String description;
  final String category;

  DrillModel(
      {required this.pk,
      required this.minplayers,
      required this.name,
      required this.link,
      required this.club,
      required this.description,
      required this.category});

  factory DrillModel.fromJson(Map<String, dynamic> json) {
    return DrillModel(
        pk: json['pk'],
        minplayers: json['minplayers'],
        name: json['name'],
        link: json['link'],
        club: json['club'],
        description: json['description'],
        category: json['category']);
  }
}
