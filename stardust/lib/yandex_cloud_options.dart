import 'package:flutter/foundation.dart';

/// Yandex Cloud configuration for the app.
class YandexCloudConfig {
  // Yandex Object Storage (S3 compatible)
  static const String accessKey = String.fromEnvironment(
    'YC_ACCESS_KEY',
    defaultValue: 'YCAJEc75X1Jlr5yLrgszHSMOO',
  );
  
  static const String secretKey = String.fromEnvironment(
    'YC_SECRET_KEY',
    defaultValue: 'YCPEEWRWAFaVAY247EdNrrWh2uG_OW4OkZrqczzs',
  );
  
  static const String bucket = String.fromEnvironment(
    'YC_BUCKET',
    defaultValue: 'daren',
  );
  
  static const String endpoint = String.fromEnvironment(
    'YC_ENDPOINT',
    defaultValue: 'https://storage.yandexcloud.net',
  );
  
  static const String region = String.fromEnvironment(
    'YC_REGION',
    defaultValue: 'ru-central1',
  );
  
  // Yandex Cloud Functions
  static const String functionUrl = String.fromEnvironment(
    'YC_FUNCTION_URL',
    defaultValue: 'https://functions.yandexcloud.net/d4eng2gb15591jsjabpf',
  );
  
  static const String functionToken = String.fromEnvironment(
    'YC_FUNCTION_TOKEN',
    defaultValue: 'mysecret-9a2fjs7891a',
  );
  
  // For Android, read from BuildConfig
  static String get androidAccessKey {
    try {
      // ignore: avoid_dynamic_calls
      return const String.fromEnvironment('YC_ACCESS_KEY');
    } catch (_) {
      return accessKey;
    }
  }
}
