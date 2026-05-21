class UserSessionModel {
  final String id;
  final String userId;
  final String phone;
  final String? authUid;
  final bool isActive;
  final String platform;
  final String environment;

  const UserSessionModel({
    required this.id,
    required this.userId,
    required this.phone,
    required this.authUid,
    required this.isActive,
    required this.platform,
    required this.environment,
  });
}
