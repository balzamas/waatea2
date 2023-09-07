import 'package:waatea2_client/models/abonnement_model.dart';
import 'package:waatea2_client/models/assessment_model.dart';
import 'package:waatea2_client/models/classification_model.dart';

class UserProfileModel {
  final bool isPlaying;
  final int permission;
  final String comment;
  final String mobilePhone;

  final AbonnementModel? abonnement;
  final AssessmentModel? assessment;
  final ClassificationModel? classification;

  UserProfileModel(
      {required this.assessment,
      required this.isPlaying,
      required this.permission,
      required this.abonnement,
      required this.comment,
      required this.mobilePhone,
      required this.classification});

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
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
      assessment: json['assessment'] != null
          ? AssessmentModel.fromJson(json['assessment'])
          : null,
    );
  }
}
