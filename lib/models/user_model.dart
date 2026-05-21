class UserModel {
  final String id;
  final String phone;
  final String name;
  final String? authUid;

  const UserModel({
    required this.id,
    required this.phone,
    required this.name,
    this.authUid,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'phone': phone,
    'name': name,
    'authUid': authUid,
  };

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] as String?) ?? '',
      phone: (json['phone'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      authUid: json['authUid'] as String?,
    );
  }
}
