# Auth data

T10/T11/T12 đã có FirebaseAuthRepository: signInWithEmailAndPassword,
createUserWithEmailAndPassword + displayName/signOut, authStateChanges → UserProfile
và map lỗi thành AppException.
Provider lấy FirebaseAuth khi Firebase đã khởi tạo; không có Firebase thì nguồn unavailable
không giả đăng nhập/đăng ký thành công. Bật Email/Password ở Console và nghiệm thu tài khoản thật;
xem docs/LOGIN_AUTH_UI.md, docs/REGISTER_AUTH_UI.md và docs/FORGOT_PASSWORD_UI.md. Reset password dùng `sendPasswordResetEmail`.
