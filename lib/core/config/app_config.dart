import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Public client configuration loaded from .env before the app starts.
/// Never store server secrets in the bundled .env asset.
abstract final class AppConfig {
  static String _value(String key, {String fallback = ''}) {
    final value = dotenv.get(key, fallback: fallback).trim();
    return value.isEmpty ? fallback : value;
  }

  static String get environment => _value('APP_ENV', fallback: 'development');

  static String get cloudinaryCloudName => _value('CLOUDINARY_CLOUD_NAME');
  static String get cloudinaryUploadPreset =>
      _value('CLOUDINARY_UPLOAD_PRESET');

  static String get mapStyleUrl => _value(
    'MAP_STYLE_URL',
    fallback: 'https://tiles.openfreemap.org/styles/liberty',
  );

  static String get mapDarkStyleUrl => _value(
    'MAP_DARK_STYLE_URL',
    // Preserve road/label contrast in dark UI unless a custom style is provided.
    fallback: mapStyleUrl,
  );
}
