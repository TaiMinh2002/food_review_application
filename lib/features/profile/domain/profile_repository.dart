import 'dart:typed_data';

abstract interface class ProfileRepository {
  Future<void> updateIdentity({
    required String userId,
    required String displayName,
    required String? photoUrl,
  });
}

class ProfilePhoto {
  const ProfilePhoto({required this.bytes, required this.name});
  final Uint8List bytes;
  final String name;
}

abstract interface class ProfilePhotoRepository {
  Future<ProfilePhoto?> pickPhoto();
  Future<String> uploadPhoto(ProfilePhoto photo);
}

String? validateProfileName(String? value) {
  final name = value?.trim() ?? '';
  if (name.isEmpty) return 'Vui lòng nhập tên hiển thị.';
  if (name.runes.length > 50) return 'Tên hiển thị tối đa 50 ký tự.';
  return null;
}
