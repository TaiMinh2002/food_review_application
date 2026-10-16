class UserProfile {
  const UserProfile({
    required this.id,
    required this.displayName,
    this.photoUrl,
  });

  final String id;
  final String displayName;
  final String? photoUrl;
}
