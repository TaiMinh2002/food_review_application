import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../../core/errors/app_exception.dart';

class CloudinaryReviewPhotoUploader {
  CloudinaryReviewPhotoUploader({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  Future<String> uploadPhoto({
    required Uint8List bytes,
    required String filename,
  }) async {
    if (AppConfig.cloudinaryCloudName.isEmpty ||
        AppConfig.cloudinaryUploadPreset.isEmpty) {
      throw const AppException(
        'Chưa cấu hình dịch vụ tải ảnh. Vui lòng kiểm tra lại cấu hình.',
      );
    }
    try {
      final request =
          http.MultipartRequest(
              'POST',
              Uri.https(
                'api.cloudinary.com',
                '/v1_1/${AppConfig.cloudinaryCloudName}/image/upload',
              ),
            )
            ..fields['upload_preset'] = AppConfig.cloudinaryUploadPreset
            ..files.add(
              http.MultipartFile.fromBytes('file', bytes, filename: filename),
            );
      final response = await http.Response.fromStream(
        await _client.send(request).timeout(const Duration(seconds: 30)),
      ).timeout(const Duration(seconds: 30));
      final body = jsonDecode(response.body);
      final url = body is Map ? body['secure_url'] : null;
      if (response.statusCode != 200 ||
          url is! String ||
          Uri.tryParse(url)?.scheme != 'https' ||
          Uri.tryParse(url)?.host.isNotEmpty != true) {
        throw const AppException(
          'Không tải được ảnh đánh giá. Vui lòng thử lại.',
        );
      }
      return url;
    } on AppException {
      rethrow;
    } catch (_) {
      throw const AppException(
        'Không tải được ảnh đánh giá. Kiểm tra mạng và thử lại.',
      );
    }
  }
}
