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
MAP_STYLE_URL=https://example.com/style
MAP_DARK_STYLE_URL=https://example.com/dark
''',
    );
    expect(AppConfig.environment, 'staging');
    expect(AppConfig.cloudinaryCloudName, 'test-cloud');
    expect(AppConfig.cloudinaryUploadPreset, 'test-preset');
    expect(AppConfig.mapStyleUrl, 'https://example.com/style');
    expect(AppConfig.mapDarkStyleUrl, 'https://example.com/dark');
    dotenv.loadFromString(envString: 'APP_ENV=production');
    expect(AppConfig.environment, 'production');
    expect(AppConfig.cloudinaryCloudName, isEmpty);
    dotenv.loadFromString(
      envString: 'MAP_STYLE_URL=https://example.com/streets',
    );
    expect(AppConfig.mapDarkStyleUrl, 'https://example.com/streets');
  });

  test('missing or blank optional values retain safe defaults', () {
    dotenv.loadFromString(envString: 'APP_ENV=\nMAP_STYLE_URL=');
    expect(AppConfig.environment, 'development');
    expect(AppConfig.cloudinaryCloudName, isEmpty);
    expect(AppConfig.cloudinaryUploadPreset, isEmpty);
    expect(
      AppConfig.mapStyleUrl,
      'https://tiles.openfreemap.org/styles/liberty',
    );
    expect(
      AppConfig.mapDarkStyleUrl,
      'https://tiles.openfreemap.org/styles/liberty',
    );
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
