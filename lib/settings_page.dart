import 'dart:convert';
import 'package:flutter/material.dart';
import 'api.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final name = TextEditingController();
  final phone = TextEditingController();
  final addr = TextEditingController();
  String email = '';
  final colors = [Colors.indigo, Colors.teal, Colors.pink, Colors.orange, Colors.green, Colors.blueGrey];

  void msg(String s) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));

  @override
  void initState() {
    super.initState();
    Api.get('Profile').then((r) {
      if (r.statusCode == 200 && mounted) {
        final d = jsonDecode(r.body);
        setState(() {
          email = d['email'] ?? '';
          name.text = d['fullName'] ?? '';
          phone.text = d['phone'] ?? '';
          addr.text = d['address'] ?? '';
        });
      }
    });
  }

  Future<void> saveProfile() async {
    final r = await Api.put('Profile',
        {'fullName': name.text, 'phone': phone.text, 'address': addr.text});
    if (r.statusCode == 200) {
      Api.name = name.text;
      msg('Đã cập nhật hồ sơ');
    } else {
      msg('Lỗi: ${r.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const Text('Cỡ chữ', style: TextStyle(fontWeight: FontWeight.bold)),
        ValueListenableBuilder<double>(
          valueListenable: Api.fontScale,
          builder: (_, v, __) => Slider(
            value: v, min: 0.8, max: 1.6, divisions: 8, label: v.toStringAsFixed(1),
            onChanged: (x) => Api.fontScale.value = x,
            onChangeEnd: (_) => Api.saveSettings(),
          ),
        ),
        const Text('Màu nền', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(spacing: 10, children: [
          for (final c in colors)
            GestureDetector(
              onTap: () {
                Api.seedColor.value = c;
                Api.saveSettings();
              },
              child: CircleAvatar(backgroundColor: c, radius: 20),
            ),
        ]),
        const Divider(height: 32),
        const Text('Hồ sơ cá nhân', style: TextStyle(fontWeight: FontWeight.bold)),
        Text(email),
        TextField(controller: name, decoration: const InputDecoration(labelText: 'Họ tên')),
        TextField(controller: phone, decoration: const InputDecoration(labelText: 'Số điện thoại')),
        TextField(controller: addr, decoration: const InputDecoration(labelText: 'Địa chỉ')),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: saveProfile, child: const Text('Lưu hồ sơ')),
      ]),
    );
  }
}