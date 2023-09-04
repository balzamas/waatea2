import 'package:waatea2_client/models/classification_model.dart';

class UserProfileModel {
  final int level;
  final bool isPlaying;
  final int permission;
  final int abonnement;
  final String comment;
  final String mobilePhone;

  final ClassificationModel? classification;

  UserProfileModel(
      {required this.level,
      required this.isPlaying,
      required this.permission,
      required this.abonnement,
      required this.comment,
      required this.mobilePhone,
      required this.classification});

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      level: json['level'],
      isPlaying: json['is_playing'],
      permission: json['permission'],
      abonnement: json['abonnement'],
      comment: json['comment'],
      mobilePhone: json['mobile_phone'],
      classification: json['classification'] != null
          ? ClassificationModel.fromJson(json['classification'])
          : null,
    );
  }
}
