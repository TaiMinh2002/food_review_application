import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_review/core/config/app_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() => dotenv.loadFromString(envString: 'APP_ENV=test'));

  test('reads service configuration from the loaded environment', () {
    dotenv.loadFromString(
      envString: '''
APP_ENV=staging
CLOUDINARY_CLOUD_NAME=test-cloud
CLOUDINARY_UPLOAD_PRESET=test-preset
OSM_TILE_URL=https://example.com/{z}/{x}/{y}.png
OSM_USER_AGENT_PACKAGE_NAME=com.example.test
''',
    );
    expect(AppConfig.environment, 'staging');
    expect(AppConfig.cloudinaryCloudName, 'test-cloud');
    expect(AppConfig.cloudinaryUploadPreset, 'test-preset');
    expect(AppConfig.osmTileUrl, 'https://example.com/{z}/{x}/{y}.png');
    expect(AppConfig.osmUserAgentPackageName, 'com.example.test');
    dotenv.loadFromString(envString: 'APP_ENV=production');
    expect(AppConfig.environment, 'production');
    expect(AppConfig.cloudinaryCloudName, isEmpty);
  });

  test('missing or blank optional values retain safe defaults', () {
    dotenv.loadFromString(envString: 'APP_ENV=\nOSM_TILE_URL=');
    expect(AppConfig.environment, 'development');
    expect(AppConfig.cloudinaryCloudName, isEmpty);
    expect(AppConfig.cloudinaryUploadPreset, isEmpty);
    expect(
      AppConfig.osmTileUrl,
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    );
    expect(AppConfig.osmUserAgentPackageName, 'com.minhpt.foodreview');
  });

  test('configuration requires initialization before access', () {
    dotenv.clean();
    expect(() => AppConfig.environment, throwsA(isA<NotInitializedError>()));
  });

  test(
    'startup environment is bundled without backend credential fields',
    () async {
      await dotenv.load(fileName: '.env');
      expect(AppConfig.environment, isNotEmpty);
      final source = await rootBundle.loadString('.env');
      for (final key in [
        'CLOUDINARY_API_KEY',
        'CLOUDINARY_API_SECRET',
        'FIREBASE_SERVICE_ACCOUNT_PATH',
      ]) {
        expect(source, isNot(contains(key)));
      }
    },
  );
}
