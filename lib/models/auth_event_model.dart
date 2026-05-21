class AuthEventModel {
  final String event;
  final String? userId;
  final String? phone;
  final String environment;
  final Map<String, dynamic>? metadata;

  const AuthEventModel({
    required this.event,
    required this.environment,
    this.userId,
    this.phone,
    this.metadata,
  });
}
