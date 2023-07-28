class UserModel {
  final String name;
  final String email;
  final int level;
  final String mobilephone;

  UserModel(
      {required this.name,
      required this.email,
      required this.level,
      required this.mobilephone});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      name: json['name'],
      email: json['email'],
      level: json['level'],
      mobilephone: json['mobile_phone'],
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'level': level,
        'mobilephone': mobilephone,
      };
}
