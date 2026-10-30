import 'package:flutter/material.dart';
import 'api.dart';
import 'login_page.dart';
import 'lock_page.dart';
import 'notify.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Notify.init();
  final logged = await Api.loadSession();
  runApp(MyApp(logged: logged));
}

class MyApp extends StatelessWidget {
  final bool logged;
  const MyApp({super.key, required this.logged});
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Color>(
      valueListenable: Api.seedColor,
      builder: (_, color, __) => ValueListenableBuilder<double>(
        valueListenable: Api.fontScale,
        builder: (_, scale, __) => MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Quản lý điện thoại trẻ em',
          theme: ThemeData(colorSchemeSeed: color, useMaterial3: true),
          builder: (c, child) => MediaQuery(
            data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: logged ? const LockPage() : const LoginPage(),
        ),
      ),
    );
  }
}
