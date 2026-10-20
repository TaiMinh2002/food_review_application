import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../../core/config/app_config.dart';
import '../../../core/errors/app_exception.dart';
import '../domain/profile_repository.dart';

class DeviceProfilePhotoRepository implements ProfilePhotoRepository {
  DeviceProfilePhotoRepository({required this.picker, required this.client});
  final ImagePicker picker;
  final http.Client client;

  @override
  Future<ProfilePhoto?> pickPhoto() async {
    try {
      final file = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (file == null) return null;
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty || bytes.length > 5 * 1024 * 1024) {
        throw const AppException('Vui lòng chọn ảnh không quá 5 MB.');
      }
      return ProfilePhoto(bytes: bytes, name: file.name);
    } on AppException {
      rethrow;
    } catch (_) {
      throw const AppException(
        'Không mở được thư viện ảnh. Kiểm tra quyền truy cập ảnh.',
      );
    }
  }

  @override
  Future<String> uploadPhoto(ProfilePhoto photo) async {
    if (AppConfig.cloudinaryCloudName.isEmpty ||
        AppConfig.cloudinaryUploadPreset.isEmpty) {
      throw const AppException(
        'Chưa cấu hình dịch vụ tải ảnh. Bạn có thể lưu tên hoặc thử tải ảnh sau.',
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
              http.MultipartFile.fromBytes(
                'file',
                photo.bytes,
                filename: photo.name,
              ),
            );
      final response = await http.Response.fromStream(
        await client.send(request).timeout(const Duration(seconds: 30)),
      ).timeout(const Duration(seconds: 30));
      final body = jsonDecode(response.body);
      final url = body is Map ? body['secure_url'] : null;
      if (response.statusCode != 200 ||
          url is! String ||
          Uri.tryParse(url)?.scheme != 'https' ||
          Uri.tryParse(url)?.host.isNotEmpty != true) {
        throw const AppException('Không tải được ảnh. Vui lòng thử lại.');
      }
      return url;
    } on AppException {
      rethrow;
    } catch (_) {
      throw const AppException('Không tải được ảnh. Kiểm tra mạng và thử lại.');
    }
  }
}
