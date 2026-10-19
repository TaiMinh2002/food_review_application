import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_review/features/auth/presentation/auth_providers.dart';
import 'package:food_review/features/profile/domain/user_profile.dart';

// Existing feature tests exercise their authenticated flows explicitly.
// Guest/loading/failure/session transitions are tested separately in auth tests.
final signedInSession = authSessionProvider.overrideWithValue(
  const AsyncData(UserProfile(id: 'test-user', displayName: 'Test User')),
);
final guestSession = authSessionProvider.overrideWithValue(
  const AsyncData(null),
);
