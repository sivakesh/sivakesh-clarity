import 'auth_service.dart';
import 'dev_auth_service.dart';
import 'prod_auth_service.dart';
import '../config/app_environment.dart';

class AuthFactory {
  static bool get isDev => AppConfig.isDev;
  static bool get isProd => AppConfig.isProd;
  static AuthService? _instance;

  static AuthService create() {
    _instance ??= AppConfig.isDev ? DevAuthService() : ProdAuthService();
    return _instance!;
  }
}
