class UserModel {
  final String id;
  final String phone;
  final String name;
  final String? authUid;
  final String role;

  const UserModel({
    required this.id,
    required this.phone,
    required this.name,
    this.authUid,
    required this.role,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'phone': phone,
    'name': name,
    'authUid': authUid,
    'role': role,
  };

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] as String?) ?? '',
      phone: (json['phone'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      authUid: json['authUid'] as String?,
      role: (json['role'] as String?) ?? 'user',
    );
  }
}
