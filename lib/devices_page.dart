import 'dart:convert';
import 'package:flutter/material.dart';
import 'api.dart';
import 'rules_page.dart';

class DevicesPage extends StatefulWidget {
  const DevicesPage({super.key});
  @override
  State<DevicesPage> createState() => _DevicesPageState();
}

class _DevicesPageState extends State<DevicesPage> {
  List devices = [];
  bool loading = true;
  final search = TextEditingController();

  @override
  void initState() {
    super.initState();
    load();
  }

  void msg(String s) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));

  Future<void> load([String? q]) async {
    setState(() => loading = true);
    try {
      final path = (q == null || q.isEmpty) ? 'Devices' : 'Devices/search?name=$q';
      final r = await Api.get(path);
      if (r.statusCode == 200) devices = jsonDecode(r.body);
    } catch (e) {
      msg('Lỗi kết nối: $e');
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> form([Map? d]) async {
    final name = TextEditingController(text: d?['name'] ?? '');
    final model = TextEditingController(text: d?['model'] ?? '');
    final child = TextEditingController(text: '${d?['childId'] ?? ''}');
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(d == null ? 'Thêm thiết bị' : 'Sửa thiết bị'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: name, decoration: const InputDecoration(labelText: 'Tên thiết bị')),
          TextField(controller: model, decoration: const InputDecoration(labelText: 'Model')),
          TextField(controller: child, keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'ID tài khoản con')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Lưu')),
        ],
      ),
    );
    if (ok != true) return;
    final body = {
      'id': d?['id'] ?? 0,
      'name': name.text,
      'model': model.text,
      'childId': int.tryParse(child.text) ?? 0,
    };
    final r = d == null
        ? await Api.post('Devices', body)
        : await Api.put('Devices/${d['id']}', body);
    if (r.statusCode >= 400) msg('Lỗi: ${r.body}');
    load();
  }

  Future<void> remove(int id) async {
    final r = await Api.delete('Devices/$id');
    if (r.statusCode >= 400) msg('Lỗi xóa');
    load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thiết bị của bé')),
      floatingActionButton: FloatingActionButton(
          onPressed: () => form(), child: const Icon(Icons.add)),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: search,
            decoration: InputDecoration(
              hintText: 'Tìm theo tên...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: load,
          ),
        ),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : devices.isEmpty
              ? const Center(child: Text('Chưa có thiết bị'))
              : ListView.builder(
            itemCount: devices.length,
            itemBuilder: (_, i) {
              final d = devices[i];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.phone_android)),
                  title: Text(d['name'] ?? ''),
                  subtitle: Text('${d['model'] ?? ''} • Bé ID ${d['childId']}'),
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => RulesPage(deviceId: d['id'], deviceName: d['name'] ?? ''))),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(icon: const Icon(Icons.edit), onPressed: () => form(d)),
                    IconButton(icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => remove(d['id'])),
                  ]),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}