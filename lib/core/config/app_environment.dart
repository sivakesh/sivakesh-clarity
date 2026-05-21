enum AppEnvironment { dev, prod }

class AppConfig {
  static const String _envValue = String.fromEnvironment(
    'ENV',
    defaultValue: 'dev',
  );

  static AppEnvironment get environment {
    switch (_envValue.toLowerCase()) {
      case 'prod':
        return AppEnvironment.prod;
      case 'dev':
      default:
        return AppEnvironment.dev;
    }
  }

  static bool get isDev => environment == AppEnvironment.dev;
  static bool get isProd => environment == AppEnvironment.prod;

  // Scalable configuration extension points.
  static String get apiBaseUrl {
    switch (environment) {
      case AppEnvironment.prod:
        return 'https://api.example.com';
      case AppEnvironment.dev:
        return 'https://dev-api.example.com';
    }
  }

  static bool get analyticsEnabled => isProd;
}
