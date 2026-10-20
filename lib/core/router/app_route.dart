/// Canonical destinations. A task marks a feature that is not built yet.
enum AppRoute {
  home('/home', 'Trang chủ'),
  map('/map', 'Bản đồ'),
  favorites('/favorites', 'Yêu thích'),
  profile('/profile', 'Cá nhân'),
  login('/login', 'Đăng nhập'),
  register('/register', 'Đăng ký', task: 'T11'),
  forgotPassword('/forgot-password', 'Quên mật khẩu', task: 'T12'),
  search('/search', 'Tìm kiếm'),
  filters('/search/filters', 'Bộ lọc và sắp xếp'),
  category('/categories/:categoryId', 'Kết quả danh mục'),
  restaurant('/restaurants/:restaurantId', 'Chi tiết quán'),
  reviews('/restaurants/:restaurantId/reviews', 'Tất cả đánh giá'),
  createReview(
    '/restaurants/:restaurantId/reviews/create',
    'Viết đánh giá',
    task: 'T13',
  ),
  editReview('/reviews/:reviewId/edit', 'Sửa đánh giá', task: 'T14'),
  gallery('/restaurants/:restaurantId/gallery', 'Thư viện ảnh'),
  wantToVisit('/want-to-visit', 'Muốn ghé thăm', task: 'T16'),
  editProfile('/profile/edit', 'Chỉnh sửa hồ sơ'),
  myReviews('/my-reviews', 'Đánh giá của tôi', task: 'T19'),
  settings('/settings', 'Cài đặt', task: 'T20'),
  notifications('/notifications', 'Thông báo', task: 'T23'),
  reviewer('/users/:userId', 'Hồ sơ người đánh giá', task: 'T24'),
  collections('/collections', 'Bộ sưu tập', task: 'T21'),
  createCollection('/collections/create', 'Tạo bộ sưu tập', task: 'T22'),
  editCollection(
    '/collections/:collectionId/edit',
    'Chỉnh sửa bộ sưu tập',
    task: 'T22',
  ),
  createReport('/reports/create', 'Báo cáo nội dung', task: 'T25'),
  adminReports('/admin/reports', 'Quản lý báo cáo', task: 'T26'),
  adminReport('/admin/reports/:reportId', 'Chi tiết báo cáo', task: 'T27'),
  designSystem('/design-system', 'UI Kit');

  const AppRoute(this.path, this.title, {this.task});
  final String path;
  final String title;
  final String? task;

  bool get isAdmin => path.startsWith('/admin/');
  bool get requiresAuth => {
    AppRoute.createReview,
    AppRoute.editReview,
    AppRoute.wantToVisit,
    AppRoute.editProfile,
    AppRoute.myReviews,
    AppRoute.notifications,
    AppRoute.collections,
    AppRoute.createCollection,
    AppRoute.editCollection,
    AppRoute.createReport,
  }.contains(this);

  String location({
    Map<String, String> parameters = const {},
    Map<String, dynamic>? query,
  }) {
    final resolved = path.replaceAllMapped(RegExp(r':(\w+)'), (match) {
      final value = parameters[match[1]];
      if (value == null || value.isEmpty) {
        throw ArgumentError('Missing route parameter: ${match[1]}');
      }
      return Uri.encodeComponent(value);
    });
    return Uri.parse(resolved).replace(queryParameters: query).toString();
  }
}

/// Only allow known internal destinations, never auth loops or admin URLs.
String? safeReturnTo(String? value) {
  if (value == null) return null;
  final uri = Uri.tryParse(value);
  if (uri == null || uri.hasScheme || uri.hasAuthority || uri.hasFragment) {
    return null;
  }
  String decodedPath;
  try {
    // Inspect the raw path before Uri normalizes away dot segments.
    decodedPath = Uri.decodeComponent(value.split('?').first);
  } on FormatException {
    return null;
  }
  if (!decodedPath.startsWith('/') ||
      decodedPath.contains('//') ||
      decodedPath.contains('\\') ||
      RegExp(r'[\x00-\x20\x7f]').hasMatch(decodedPath) ||
      decodedPath.split('/').any((part) => part == '.' || part == '..')) {
    return null;
  }
  for (final route in AppRoute.values) {
    if (route.isAdmin ||
        {
          AppRoute.login,
          AppRoute.register,
          AppRoute.forgotPassword,
        }.contains(route)) {
      continue;
    }
    final pattern = route.path.replaceAll(RegExp(r':\w+'), r'[^/]+');
    if (RegExp('^$pattern\$').hasMatch(decodedPath)) return uri.toString();
  }
  return null;
}
