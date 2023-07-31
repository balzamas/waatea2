class SetAvailabilityModel {
  String games;
  final String date;
  int state;
  String avail_id;
  final int dayofyear;
  final String season;

  SetAvailabilityModel(
      {required this.games,
      required this.date,
      required this.state,
      required this.avail_id,
      required this.dayofyear,
      required this.season});
}
