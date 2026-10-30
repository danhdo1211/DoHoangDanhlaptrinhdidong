import 'dart:convert';
import 'package:flutter/material.dart';
import 'api.dart';

class RulesPage extends StatefulWidget {
  final int deviceId;
  final String deviceName;
  const RulesPage({super.key, required this.deviceId, required this.deviceName});
  @override
  State<RulesPage> createState() => _RulesPageState();
}

class _RulesPageState extends State<RulesPage> {
  List rules = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);
    try {
      final r = await Api.get('AppRules?deviceId=${widget.deviceId}');
      if (r.statusCode == 200) rules = jsonDecode(r.body);
    } catch (_) {}
    if (mounted) setState(() => loading = false);
  }

  Future<void> form([Map? x]) async {
    final app = TextEditingController(text: x?['appName'] ?? '');
    final limit = TextEditingController(text: '${x?['dailyLimitMinutes'] ?? 60}');
    bool blocked = x?['isBlocked'] ?? false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(x == null ? 'Thêm luật' : 'Sửa luật'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: app, decoration: const InputDecoration(labelText: 'Tên ứng dụng (YouTube, TikTok...)')),
            TextField(controller: limit, keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Giới hạn/ngày (phút)')),
            SwitchListTile(
                title: const Text('Chặn hoàn toàn'),
                value: blocked,
                onChanged: (v) => setS(() => blocked = v)),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Lưu')),
          ],
        ),
      ),
    );
    if (ok != true) return;
    final body = {
      'id': x?['id'] ?? 0,
      'deviceId': widget.deviceId,
      'appName': app.text,
      'isBlocked': blocked,
      'dailyLimitMinutes': int.tryParse(limit.text) ?? 0,
    };
    if (x == null) {
      await Api.post('AppRules', body);
    } else {
      await Api.put('AppRules/${x['id']}', body);
    }
    load();
  }

  Future<void> remove(int id) async {
    await Api.delete('AppRules/$id');
    load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Luật: ${widget.deviceName}')),
      floatingActionButton: FloatingActionButton(
          onPressed: () => form(), child: const Icon(Icons.add)),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : rules.isEmpty
          ? const Center(child: Text('Chưa có luật nào'))
          : ListView.builder(
        itemCount: rules.length,
        itemBuilder: (_, i) {
          final x = rules[i];
          final blocked = x['isBlocked'] == true;
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              leading: Icon(blocked ? Icons.block : Icons.timer,
                  color: blocked ? Colors.red : Colors.green),
              title: Text(x['appName'] ?? ''),
              subtitle: Text(blocked
                  ? 'Đã chặn'
                  : 'Giới hạn ${x['dailyLimitMinutes']} phút/ngày'),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(icon: const Icon(Icons.edit), onPressed: () => form(x)),
                IconButton(icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => remove(x['id'])),
              ]),
            ),
          );
        },
      ),
    );
  }
}