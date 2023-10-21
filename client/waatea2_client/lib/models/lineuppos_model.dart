import 'package:waatea2_client/models/game_model.dart';
import 'package:waatea2_client/models/user_model.dart';

class LineUpPosModel {
  String id; // You can use a unique identifier type here, like UUID
  UserModel? player; // Assuming you have a User model defined
  GameModel game; // Assuming you have a Game model defined
  int position;
  String remarks;

  LineUpPosModel({
    required this.id,
    required this.player,
    required this.game,
    required this.position,
    required this.remarks,
  });

  factory LineUpPosModel.fromJson(Map<String, dynamic> json) {
    return LineUpPosModel(
      id: json['id'],
      player:
          json['player'] != null ? UserModel.fromJson(json['player']) : null,
      game: GameModel.fromJson(json['game']),
      position: json['position'],
      remarks: json['remarks'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'player': player,
        'game': game,
        'position': position,
        'remarks': remarks
      };
}
