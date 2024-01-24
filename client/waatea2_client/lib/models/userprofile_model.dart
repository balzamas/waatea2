import 'package:waatea2_client/models/abonnement_model.dart';
import 'package:waatea2_client/models/classification_model.dart';
import 'package:waatea2_client/models/position_model.dart';

class UserProfileModel {
  final bool isPlaying;
  final int permission;
  final String comment;
  final String mobilePhone;

  final AbonnementModel? abonnement;
  final ClassificationModel? classification;
  final List<PositionModel>? positions; // Add positions field

  UserProfileModel(
      {required this.isPlaying,
      required this.permission,
      required this.abonnement,
      required this.comment,
      required this.mobilePhone,
      required this.classification,
      required this.positions});

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    final List<dynamic> positionsJson = json['positions'] ?? [];
    final List<PositionModel> positions = positionsJson
        .map((positionJson) => PositionModel.fromJson(positionJson))
        .toList();

    return UserProfileModel(
      isPlaying: json['is_playing'],
      permission: json['permission'],
      comment: json['comment'],
      mobilePhone: json['mobile_phone'],
      classification: json['classification'] != null
          ? ClassificationModel.fromJson(json['classification'])
          : null,
      abonnement: json['abonnement'] != null
          ? AbonnementModel.fromJson(json['abonnement'])
          : null,
      positions: positions,
    );
  }
}
