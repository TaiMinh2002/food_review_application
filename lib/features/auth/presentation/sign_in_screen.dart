import 'package:flutter/material.dart';

import '../../../shared/widgets/app_message.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng nhập')),
      body: const AppMessage(
        message: 'Firebase Authentication chưa được cấu hình. Bạn vẫn có thể khám phá và lưu quán trong bản demo.',
      ),
    );
  }
}
