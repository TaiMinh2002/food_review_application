# Auth data

T10 đã có FirebaseAuthRepository: signInWithEmailAndPassword/signOut,
authStateChanges → UserProfile và map lỗi thành AppException.
Provider lấy FirebaseAuth khi Firebase đã khởi tạo; không có Firebase thì nguồn unavailable
không giả đăng nhập thành công. Bật Email/Password ở Console và nghiệm thu tài khoản thật;
xem docs/LOGIN_AUTH_UI.md. T11 mới triển khai signUp/profile write retry, T12 reset password.
