import 'dart:convert';
import 'package:flutter/material.dart';
import 'api.dart';
import 'login_page.dart';
import 'devices_page.dart';
import 'location_pages.dart';
import 'call_page.dart';
import 'translation_page.dart';

Future<void> doLogout(BuildContext context) async {
  await Api.logout();
  if (!context.mounted) return;
  Navigator.pushReplacement(
      context, MaterialPageRoute(builder: (_) => const LoginPage()));
}

class RoleRouter extends StatelessWidget {
  const RoleRouter({super.key});
  @override
  Widget build(BuildContext context) {
    switch (Api.role) {
      case 'Admin':
        return const AdminPage();
      case 'Child':
        return const ChildPage();
      default:
        return const ParentPage();
    }
  }
}

// ---------- PARENT / USER (Được thiết kế lại UI/UX chuẩn Câu 7) ----------
class ParentPage extends StatelessWidget {
  const ParentPage({super.key});

  Future<void> addChild(BuildContext context) async {
    final name = TextEditingController();
    final email = TextEditingController();
    final pass = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.child_care, color: Colors.orange, size: 28),
            SizedBox(width: 8),
            Text('Tạo tài khoản cho bé', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: name, decoration: InputDecoration(labelText: 'Tên bé', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
          const SizedBox(height: 12),
          TextField(controller: email, decoration: InputDecoration(labelText: 'Email', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
          const SizedBox(height: 12),
          TextField(controller: pass, obscureText: true, decoration: InputDecoration(labelText: 'Mật khẩu', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Tạo'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final r = await Api.post('Auth/create-child',
        {'email': email.text.trim(), 'password': pass.text, 'fullName': name.text});
    if (!context.mounted) return;
    String m = r.body;
    if (r.statusCode == 200) {
      m = 'Đã tạo bé, ID = ${jsonDecode(r.body)['id']} (dùng ID này khi thêm thiết bị)';
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text('Dashboard Phụ Huynh', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Đăng xuất',
            onPressed: () => doLogout(context),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Banner chào mừng trực quan
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3F51B5), Color(0xFF1A237E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.security, size: 32, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Xin chào,', style: TextStyle(color: Colors.white70, fontSize: 14)),
                      Text(
                        Api.name ?? 'Phụ huynh',
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      const Text('Hệ thống giám sát đang hoạt động', style: TextStyle(color: Colors.white60, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Quản lý & Giám sát', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 12),

          // Danh sách các chức năng được cách điệu thẻ Card hiện đại
          _tile(context, Icons.phone_android, 'Thiết bị & luật ứng dụng', Colors.indigo,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DevicesPage()))),
          _tile(context, Icons.map_rounded, 'Bản đồ vị trí các bé', Colors.green,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ParentMapPage()))),
          _tile(context, Icons.video_call_rounded, 'Gọi video nhóm', Colors.redAccent,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CallLobbyPage()))),
          _tile(context, Icons.document_scanner_rounded, 'Dịch văn bản & Quét OCR an toàn', Colors.purple,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TranslationPage()))),
          _tile(context, Icons.child_care_rounded, 'Tạo tài khoản cho bé', Colors.orange,
                  () => addChild(context)),
        ],
      ),
    );
  }
}

// Widget tile được nâng cấp UI bo góc và đổ bóng nhẹ sang trọng
Widget _tile(BuildContext c, IconData i, String t, Color col, VoidCallback f) => Container(
  margin: const EdgeInsets.only(bottom: 12),
  child: Card(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: col.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(i, color: col, size: 24),
      ),
      title: Text(t, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
      onTap: f,
    ),
  ),
);

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
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(title: const Text('Trang Quản Trị Hệ Thống', style: TextStyle(fontWeight: FontWeight.bold)), actions: [
        IconButton(
            icon: const Icon(Icons.devices_rounded),
            tooltip: 'Quản lý thiết bị',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const DevicesPage()))),
        IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Đăng xuất',
            onPressed: () => doLogout(context)),
      ]),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: users.length,
        itemBuilder: (_, i) {
          final u = users[i];
          return Card(
            elevation: 1,
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.indigo[100],
                child: Text('${u['id']}', style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
              ),
              title: Text(u['fullName'] ?? u['email'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(u['email']),
              trailing: Chip(
                backgroundColor: Colors.blue[55],
                label: Text(u['role'], style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------- CHILD (Được làm đẹp lại giao diện cho phía trẻ em) ----------
class ChildPage extends StatelessWidget {
  const ChildPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text('Thiết Bị Của Bé', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Đăng xuất',
            onPressed: () => doLogout(context),
          )
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.indigo.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.child_care_rounded, size: 70, color: Colors.indigo),
            ),
            const SizedBox(height: 16),
            Text('Xin chào, ${Api.name ?? 'Bé'}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text('Thiết bị đang được bảo vệ an toàn', style: TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 30),

            // Chia sẻ vị trí card
            const ShareLocationCard(),
            const SizedBox(height: 14),

            // Nút gọi video
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                icon: const Icon(Icons.video_call_rounded),
                label: const Text('Gọi video nhóm khẩn cấp', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const CallLobbyPage())),
              ),
            ),
            const SizedBox(height: 14),

            // Nút quét OCR an toàn
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                icon: const Icon(Icons.translate_rounded),
                label: const Text('Dịch văn bản & Quét OCR an toàn', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const TranslationPage())),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}