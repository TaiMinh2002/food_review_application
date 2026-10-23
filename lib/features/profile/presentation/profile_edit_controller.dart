import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../../core/errors/app_exception.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/device_profile_photo_repository.dart';
import '../data/firebase_profile_repository.dart';
import '../domain/profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return Firebase.apps.isEmpty
      ? UnavailableProfileRepository()
      : FirebaseProfileRepository(
          FirebaseAuth.instance,
          firestore: FirebaseFirestore.instance,
        );
});

final profilePhotoRepositoryProvider = Provider<ProfilePhotoRepository>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return DeviceProfilePhotoRepository(picker: ImagePicker(), client: client);
});

final profileEditControllerProvider = NotifierProvider.autoDispose
    .family<ProfileEditController, AsyncValue<void>, String>(
      ProfileEditController.new,
    );

class ProfileEditController extends Notifier<AsyncValue<void>> {
  ProfileEditController(this.userId);
  final String userId;
  ProfilePhoto? _uploadedPhoto;
  String? _uploadedUrl;

  @override
  AsyncValue<void> build() => const AsyncData(null);

  bool get _sameUser {
    final session = ref.read(authSessionProvider);
    return !session.isLoading &&
        !session.hasError &&
        session.asData?.value?.id == userId;
  }

  Future<bool> save({
    required String displayName,
    required String? photoUrl,
    ProfilePhoto? newPhoto,
  }) async {
    if (state.isLoading) return false;
    final repository = ref.read(profileRepositoryProvider);
    final photos = ref.read(profilePhotoRepositoryProvider);
    state = const AsyncLoading();
    try {
      if (!_sameUser) throw const AppException('Phiên đăng nhập đã thay đổi.');
      final error = validateProfileName(displayName);
      if (error != null) throw AppException(error);
      var url = photoUrl;
      if (newPhoto != null) {
        if (!identical(_uploadedPhoto, newPhoto)) {
          _uploadedUrl = await photos.uploadPhoto(newPhoto);
          _uploadedPhoto = newPhoto;
        }
        url = _uploadedUrl;
      }
      if (!ref.mounted) return false;
      if (!_sameUser) throw const AppException('Phiên đăng nhập đã thay đổi.');
      await repository.updateIdentity(
        userId: userId,
        displayName: displayName.trim(),
        photoUrl: url,
      );
      if (!ref.mounted || !_sameUser) return false;
      state = const AsyncData(null);
      return true;
    } catch (error, stack) {
      if (ref.mounted) state = AsyncError(error, stack);
      return false;
    }
  }
}
