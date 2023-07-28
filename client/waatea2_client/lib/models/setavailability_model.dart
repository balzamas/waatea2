class SetAvailabilityModel {
  final String pk;
  final String home;
  final String away;
  final String date;
  int state;
  String avail_id;
  final int dayofyear;

  SetAvailabilityModel(
      {required this.pk,
      required this.home,
      required this.away,
      required this.date,
      required this.state,
      required this.avail_id,
      required this.dayofyear});

  factory SetAvailabilityModel.fromJson(Map<String, dynamic> json) {
    return SetAvailabilityModel(
        pk: json['pk'],
        home: json['home']['name'],
        away: json['away']['name'],
        date: json['date'],
        state: 0,
        avail_id: "",
        dayofyear: json['dayofyear']);
  }

  Map<String, dynamic> toJson() =>
      {'pk': pk, 'home': home, 'away': away, 'date': date};
}
