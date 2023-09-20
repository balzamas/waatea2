class SetAvailabilityModel {
  String games;
  final String date;
  int state;
  String availId;
  final int dayofyear;
  final String season;

  SetAvailabilityModel(
      {required this.games,
      required this.date,
      required this.state,
      required this.availId,
      required this.dayofyear,
      required this.season});
}
