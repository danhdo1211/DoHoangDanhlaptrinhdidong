import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'api.dart';
import 'home_pages.dart';
import 'login_page.dart';

class LockPage extends StatefulWidget {
  const LockPage({super.key});
  @override
  State<LockPage> createState() => _LockPageState();
}

class _LockPageState extends State<LockPage> {
  final auth = LocalAuthentication();
  String info = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unlock());
  }

  Future<void> toLogin() async {
    await Api.logout();
    if (!mounted) return;
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const LoginPage()));
  }

  Future<void> unlock() async {
    try {
      final supported = await auth.isDeviceSupported();
      if (!supported) {
        setState(() => info = 'Máy chưa bật khóa sinh trắc học');
        return;
      }
      final ok = await auth.authenticate(
        localizedReason: 'Xác thực vân tay / khuôn mặt để đăng nhập',
        options: const AuthenticationOptions(biometricOnly: false),
      );
      if (!ok) return;
      final r = await Api.post('Profile/refresh', {});
      if (r.statusCode == 200) {
        await Api.saveSession(jsonDecode(r.body));
        if (!mounted) return;
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const RoleRouter()));
      } else {
        await toLogin(); // token hỏng/hết hạn -> đăng nhập lại
      }
    } catch (e) {
      setState(() => info = 'Lỗi: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.fingerprint, size: 90),
          const SizedBox(height: 12),
          Text(info),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: unlock, child: const Text('Vân tay / Khuôn mặt')),
          TextButton(onPressed: toLogin, child: const Text('Dùng mật khẩu + OTP')),
        ]),
      ),
    );
  }
}