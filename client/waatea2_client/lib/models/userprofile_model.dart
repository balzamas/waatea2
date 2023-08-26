class UserProfileModel {
  final int level;
  final bool isPlaying;
  final int permission;
  final int abonnement;
  final String comment;

  UserProfileModel(
      {required this.level,
      required this.isPlaying,
      required this.permission,
      required this.abonnement,
      required this.comment});

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
        level: json['level'],
        isPlaying: json['is_playing'],
        permission: json['permission'],
        abonnement: json['abonnement'],
        comment: json['comment']);
  }
}
