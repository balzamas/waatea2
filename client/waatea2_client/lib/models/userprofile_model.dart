class UserProfileModel {
  final int level;
  final bool isPlaying;
  final int permission;
  final int abonnement;

  UserProfileModel(
      {required this.level,
      required this.isPlaying,
      required this.permission,
      required this.abonnement});

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
        level: json['level'],
        isPlaying: json['is_playing'],
        permission: json['permission'],
        abonnement: json['abonnement']);
  }
}
