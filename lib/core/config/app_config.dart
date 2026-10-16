/// Public client configuration. Never store server secrets here.
abstract final class AppConfig {
  static const environment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );

  static const cloudinaryCloudName = String.fromEnvironment(
    'CLOUDINARY_CLOUD_NAME',
  );
  static const cloudinaryUploadPreset = String.fromEnvironment(
    'CLOUDINARY_UPLOAD_PRESET',
  );

  static const osmTileUrl = String.fromEnvironment(
    'OSM_TILE_URL',
    defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  );

  static const osmUserAgentPackageName = String.fromEnvironment(
    'OSM_USER_AGENT_PACKAGE_NAME',
    defaultValue: 'com.minhpt.foodreview',
  );
}
