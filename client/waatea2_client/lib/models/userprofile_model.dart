class UserProfileModel {
  final int level;
  final bool isPlaying;
  final int permission;
  // Add other profile fields as needed

  UserProfileModel(
      {required this.level, required this.isPlaying, required this.permission});

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
        level: json['level'],
        isPlaying: json['is_playing'],
        permission: json['permission']);
  }
}
