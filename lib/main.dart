import 'package:flutter/material.dart';
import 'api.dart';
import 'login_page.dart';
import 'home_pages.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final logged = await Api.loadSession();
  runApp(MyApp(logged: logged));
}

class MyApp extends StatelessWidget {
  final bool logged;
  const MyApp({super.key, required this.logged});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Quản lý điện thoại trẻ em',
      theme: ThemeData(
          colorSchemeSeed: const Color(0xFF6C63FF), useMaterial3: true),
      home: logged ? const RoleRouter() : const LoginPage(),
    );
  }
}