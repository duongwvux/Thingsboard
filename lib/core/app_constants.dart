class AppConstants {
  AppConstants._();

  // Thay bằng URL ThingsBoard của bạn
  static const String tbBaseUrl = 'https://eu.thingsboard.cloud';

  static const String relayServerUrl = 'http://192.168.1.4:5000';

  // Key lưu trong SecureStorage
  static const String keyJwtToken     = 'jwt_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUserId       = 'user_id';
}