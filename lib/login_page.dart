import 'dart:convert';
import 'package:flutter/material.dart';
import 'api.dart';
import 'home_pages.dart';
import 'notify.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final pass = TextEditingController();
  final name = TextEditingController();
  final otp = TextEditingController();
  int step = 0; // 0: đăng nhập, 1: nhập OTP, 2: đăng ký
  bool loading = false;

  void msg(String s) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));

  Future<void> login() async {
    if (email.text.trim().isEmpty || pass.text.isEmpty) {
      msg('Nhập email và mật khẩu');
      return;
    }
    setState(() => loading = true);
    try {
      final r = await Api.post(
          'Auth/login', {'email': email.text.trim(), 'password': pass.text});
      if (r.statusCode == 200) {
        final d = jsonDecode(r.body);
        if (d['otp'] != null) {
          Notify.show('Mã OTP đăng nhập',
              'Mã OTP của bạn: ${d['otp']} (hết hạn sau 5 phút)');
        }
        otp.clear();
        msg('OTP đã được gửi, kiểm tra thông báo / email');
        setState(() => step = 1);
      } else {
        msg(r.body.isNotEmpty ? r.body : 'Sai email hoặc mật khẩu');
      }
    } catch (e) {
      msg('Lỗi kết nối server, kiểm tra lại Conveyor');
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> verify() async {
    setState(() => loading = true);
    try {
      final r = await Api.post('Auth/verify-otp',
          {'email': email.text.trim(), 'otp': otp.text.trim()});
      if (r.statusCode == 200) {
        await Api.saveSession(jsonDecode(r.body));
        if (!mounted) return;
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const RoleRouter()));
        return;
      } else {
        msg(r.body.isNotEmpty ? r.body : 'Mã OTP không chính xác');
      }
    } catch (e) {
      msg('Lỗi kết nối server, kiểm tra lại Conveyor');
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> register() async {
    if (email.text.trim().isEmpty || pass.text.length < 6) {
      msg('Nhập email và mật khẩu từ 6 ký tự');
      return;
    }
    setState(() => loading = true);
    try {
      final r = await Api.post('Auth/register', {
        'email': email.text.trim(),
        'password': pass.text,
        'fullName': name.text.trim(),
      });
      if (r.statusCode == 200) {
        msg('Đăng ký thành công, hãy đăng nhập');
        setState(() => step = 0);
      } else {
        msg(r.body);
      }
    } catch (e) {
      msg('Lỗi kết nối server, kiểm tra lại Conveyor');
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final titles = ['Đăng nhập', 'Nhập mã OTP', 'Đăng ký'];
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
              colors: [Color(0xFF6C63FF), Color(0xFF3F8EFC)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.child_care,
                      size: 56, color: Color(0xFF6C63FF)),
                  const SizedBox(height: 8),
                  Text(titles[step],
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  if (step == 2)
                    TextField(
                        controller: name,
                        decoration: const InputDecoration(
                            labelText: 'Họ tên',
                            prefixIcon: Icon(Icons.person))),
                  if (step != 1) ...[
                    TextField(
                        controller: email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                            labelText: 'Email', prefixIcon: Icon(Icons.email))),
                    TextField(
                        controller: pass,
                        obscureText: true,
                        decoration: const InputDecoration(
                            labelText: 'Mật khẩu',
                            prefixIcon: Icon(Icons.lock))),
                  ],
                  if (step == 1) ...[
                    const Text(
                      'Mã OTP đã được gửi về thông báo điện thoại và email của bạn',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                        controller: otp,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            labelText: 'Mã OTP', prefixIcon: Icon(Icons.sms))),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: loading
                          ? null
                          : (step == 0 ? login : step == 1 ? verify : register),
                      child: loading
                          ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(titles[step]),
                    ),
                  ),
                  if (step == 1)
                    TextButton(
                        onPressed: () => setState(() => step = 0),
                        child: const Text('Quay lại đăng nhập')),
                  if (step != 1)
                    TextButton(
                        onPressed: () =>
                            setState(() => step = step == 0 ? 2 : 0),
                        child: Text(step == 0
                            ? 'Chưa có tài khoản? Đăng ký'
                            : 'Đã có tài khoản? Đăng nhập')),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}