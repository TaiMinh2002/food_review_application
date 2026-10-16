# Auth data

Thêm FirebaseAuthRepository implement AuthRepository khi Firebase đã được cấu hình.
Map User SDK sang UserProfile; không để Firebase User đi vào domain/UI.
Map FirebaseAuthException sang AppException. Xử lý displayName/profile write thất bại
sau khi tạo tài khoản và theo dõi authStateChanges để routing phản ứng.
