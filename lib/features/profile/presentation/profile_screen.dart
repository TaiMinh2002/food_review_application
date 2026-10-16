import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hồ sơ')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const CircleAvatar(
            radius: 40,
            child: Icon(Icons.person_outline, size: 40),
          ),
          const SizedBox(height: 24),
          const Text('Chào bạn!', textAlign: TextAlign.center),
          const SizedBox(height: 12),
          const Text(
            'Hiện đang dùng bản demo. Đăng nhập và review cá nhân sẽ được bổ sung khi kết nối Firebase.',
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () => context.push('/sign-in'),
            child: const Text('Thông tin đăng nhập'),
          ),
        ],
      ),
    );
  }
}
