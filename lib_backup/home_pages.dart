import 'dart:convert';
import 'package:flutter/material.dart';
import 'api.dart';
import 'login_page.dart';
import 'devices_page.dart';
import 'settings_page.dart';
import 'location_pages.dart';
import 'call_page.dart';
import 'translation_page.dart';

Future<void> doLogout(BuildContext context) async {
  await Api.logout();
  if (!context.mounted) return;
  Navigator.pushReplacement(
      context, MaterialPageRoute(builder: (_) => const LoginPage()));
}

void go(BuildContext c, Widget w) =>
    Navigator.push(c, MaterialPageRoute(builder: (_) => w));

List<Widget> _actions(BuildContext c) => [
  IconButton(icon: const Icon(Icons.settings), onPressed: () => go(c, const SettingsPage())),
  IconButton(icon: const Icon(Icons.logout), onPressed: () => doLogout(c)),
];

class RoleRouter extends StatelessWidget {
  const RoleRouter({super.key});
  @override
  Widget build(BuildContext context) {
    final r = (Api.role ?? '').trim().toLowerCase();
    if (r == 'admin') return const AdminPage();
    if (r == 'child') return const ChildPage();
    return const ParentPage();
  }
}

Widget _tile(IconData i, String t, Color col, VoidCallback f) => Card(
  child: ListTile(
    leading: CircleAvatar(backgroundColor: col, child: Icon(i, color: Colors.white)),
    title: Text(t),
    trailing: const Icon(Icons.chevron_right),
    onTap: f,
  ),
);

// ---------- PARENT ----------
class ParentPage extends StatelessWidget {
  const ParentPage({super.key});

  Future<void> addChild(BuildContext context) async {
    final name = TextEditingController();
    final email = TextEditingController();
    final pass = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tạo tài khoản cho bé'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: name, decoration: const InputDecoration(labelText: 'Tên bé')),
          TextField(controller: email, decoration: const InputDecoration(labelText: 'Email')),
          TextField(controller: pass, obscureText: true, decoration: const InputDecoration(labelText: 'Mật khẩu')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Tạo')),
        ],
      ),
    );
    if (ok != true) return;
    final r = await Api.post('Auth/create-child',
        {'email': email.text.trim(), 'password': pass.text, 'fullName': name.text});
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(r.statusCode == 200 ? 'Đã tạo tài khoản cho bé' : r.body)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard phụ huynh'), actions: _actions(context)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Text('Xin chào ${Api.name ?? ''}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _tile(Icons.phone_android, 'Thiết bị & luật ứng dụng', Colors.indigo,
                () => go(context, const DevicesPage())),
        _tile(Icons.map, 'Vị trí của các bé', Colors.green,
                () => go(context, const ParentMapPage())),
        _tile(Icons.video_call, 'Gọi video', Colors.redAccent,
                () => go(context, const CallLobbyPage())),
        _tile(Icons.g_translate, 'Dịch & quét nội dung nhạy cảm', Colors.blue,
                () => go(context, const TranslationPage())),
        _tile(Icons.child_care, 'Tạo tài khoản cho bé', Colors.orange,
                () => addChild(context)),
      ]),
    );
  }
}

// ---------- ADMIN ----------
class AdminPage extends StatefulWidget {
  const AdminPage({super.key});
  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  List users = [];
  @override
  void initState() {
    super.initState();
    Api.get('Auth/admin-users').then((r) {
      if (r.statusCode == 200 && mounted) setState(() => users = jsonDecode(r.body));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trang quản trị'), actions: [
        IconButton(icon: const Icon(Icons.devices), onPressed: () => go(context, const DevicesPage())),
        ..._actions(context),
      ]),
      body: ListView.builder(
        itemCount: users.length,
        itemBuilder: (_, i) {
          final u = users[i];
          return ListTile(
            leading: CircleAvatar(child: Text('${u['id']}')),
            title: Text(u['fullName'] ?? u['email']),
            subtitle: Text(u['email']),
            trailing: Chip(label: Text(u['role'])),
          );
        },
      ),
    );
  }
}

// ---------- CHILD ----------
class ChildPage extends StatelessWidget {
  const ChildPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trang của bé'), actions: _actions(context)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Text('Xin chào ${Api.name ?? ''}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const ShareLocationCard(),
        _tile(Icons.video_call, 'Gọi video', Colors.redAccent,
                () => go(context, const CallLobbyPage())),
        _tile(Icons.g_translate, 'Dịch & quét nội dung', Colors.blue,
                () => go(context, const TranslationPage())),
      ]),
    );
  }
}