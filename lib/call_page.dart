import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';

import 'api.dart';

// ================= NHẬP TÊN PHÒNG =================
class CallLobbyPage extends StatefulWidget {
  const CallLobbyPage({super.key});
  @override
  State<CallLobbyPage> createState() => _CallLobbyPageState();
}

class _CallLobbyPageState extends State<CallLobbyPage> {
  final room = TextEditingController(text: 'gia-dinh');

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF4F6F9),
    appBar: AppBar(title: const Text('Gọi Video Khẩn Cấp', style: TextStyle(fontWeight: FontWeight.bold))),
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.video_call_rounded, size: 80, color: Colors.redAccent),
              ),
              const SizedBox(height: 20),
              const Text(
                'Phòng Gọi Trực Tuyến',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Nhập tên phòng để kết nối hình ảnh và âm thanh',
                style: TextStyle(color: Colors.grey, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: room,
                decoration: InputDecoration(
                  labelText: 'Tên phòng (ví dụ: gia-dinh)',
                  prefixIcon: const Icon(Icons.meeting_room_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),
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
                  icon: const Icon(Icons.call_rounded),
                  label: const Text('Vào Phòng Ngay', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    final n = room.text.trim();
                    if (n.isEmpty) return;
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => CallPage(roomName: n)));
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

// ================= PHÒNG GỌI =================
class CallPage extends StatefulWidget {
  final String roomName;
  const CallPage({super.key, required this.roomName});
  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  final Room room = Room();
  bool connecting = true;
  String? error;
  bool micOn = true;
  bool camOn = true;

  @override
  void initState() {
    super.initState();
    room.addListener(_onChange);
    connect();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  Future<void> connect() async {
    try {
      // Gọi đúng endpoint API lấy token LiveKit từ Backend C#
      final r = await Api.get(
          'VideoCall/token?room=${Uri.encodeComponent(widget.roomName)}');

      if (r.statusCode != 200) {
        throw Exception('Lỗi Server (${r.statusCode}): ${r.body}');
      }

      final d = jsonDecode(r.body);
      final wsUrl = d['wsUrl'];
      final token = d['token'];

      if (wsUrl == null || token == null) {
        throw Exception('Phản hồi thiếu wsUrl hoặc token từ server!');
      }

      await room.connect(wsUrl, token);
      await room.localParticipant?.setCameraEnabled(true);
      await room.localParticipant?.setMicrophoneEnabled(true);

      if (mounted) setState(() => connecting = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          connecting = false;
          error = e.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    room.removeListener(_onChange);
    room.disconnect();
    room.dispose();
    super.dispose();
  }

  VideoTrack? videoOf(Participant p) {
    for (final pub in p.videoTrackPublications) {
      final t = pub.track;
      if (!pub.muted && t is VideoTrack) return t;
    }
    return null;
  }

  Widget tile(Participant p) {
    final v = videoOf(p);
    final label = p.name.isNotEmpty ? p.name : p.identity;
    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
          color: Colors.black87, borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Stack(fit: StackFit.expand, children: [
        v != null
            ? VideoTrackRenderer(v)
            : const Center(
            child: Icon(Icons.person, color: Colors.white54, size: 64)),
        Positioned(
          left: 8,
          bottom: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(label,
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final all = <Participant>[
      if (room.localParticipant != null) room.localParticipant!,
      ...room.remoteParticipants.values,
    ];

    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      appBar: AppBar(
        title: Text('Phòng: ${widget.roomName} (${all.length})'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: connecting
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : error != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'Không thể kết nối phòng gọi:\n$error',
            style: const TextStyle(color: Colors.redAccent, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
      )
          : GridView.count(
        padding: const EdgeInsets.all(8),
        crossAxisCount: all.length <= 1 ? 1 : 2,
        children: all.map(tile).toList(),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.black,
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          IconButton(
            color: Colors.white,
            icon: Icon(micOn ? Icons.mic : Icons.mic_off, color: micOn ? Colors.white : Colors.red),
            onPressed: () async {
              micOn = !micOn;
              await room.localParticipant?.setMicrophoneEnabled(micOn);
              setState(() {});
            },
          ),
          IconButton(
            color: Colors.white,
            icon: Icon(camOn ? Icons.videocam : Icons.videocam_off, color: camOn ? Colors.white : Colors.red),
            onPressed: () async {
              camOn = !camOn;
              await room.localParticipant?.setCameraEnabled(camOn);
              setState(() {});
            },
          ),
          IconButton(
            icon: const Icon(Icons.call_end, color: Colors.red, size: 28),
            onPressed: () => Navigator.pop(context),
          ),
        ]),
      ),
    );
  }
}