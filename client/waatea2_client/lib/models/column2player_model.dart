import 'package:uuid/uuid.dart';

class Column2PlayerModel {
  int playerid;
  int posid;
  String name;
  final Uuid fieldid;

  Column2PlayerModel(
      {required this.playerid,
      required this.posid,
      required this.name,
      required this.fieldid});
}
