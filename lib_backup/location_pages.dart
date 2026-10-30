import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'api.dart';

// ================= BÉ: BẬT/TẮT CHIA SẺ VỊ TRÍ =================
class ShareLocationCard extends StatefulWidget {
  const ShareLocationCard({super.key});
  @override
  State<ShareLocationCard> createState() => _ShareLocationCardState();
}

class _ShareLocationCardState extends State<ShareLocationCard> {
  StreamSubscription<Position>? sub;
  bool sharing = false;
  String status = 'Chưa chia sẻ';

  Future<void> send(Position pos) async {
    try {
      final r = await Api.post('Location', {'lat': pos.latitude, 'lng': pos.longitude});
      if (!mounted) return;
      setState(() => status = r.statusCode == 200
          ? 'Đã gửi: ${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}'
          : 'Gửi lỗi ${r.statusCode}');
    } catch (e) {
      if (mounted) setState(() => status = 'Lỗi mạng: $e');
    }
  }

  Future<void> toggle() async {
    if (sharing) {
      await sub?.cancel();
      setState(() {
        sharing = false;
        status = 'Đã dừng chia sẻ';
      });
      return;
    }
    var p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) {
      p = await Geolocator.requestPermission();
    }
    if (p == LocationPermission.denied ||
        p == LocationPermission.deniedForever) {
      setState(() => status = 'Chưa cấp quyền vị trí');
      return;
    }
    final first = await Geolocator.getCurrentPosition();
    await send(first);
    sub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(distanceFilter: 5),
    ).listen(send);
    setState(() => sharing = true);
  }

  @override
  void dispose() {
    sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.all(16),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.location_on,
            size: 56, color: sharing ? Colors.green : Colors.grey),
        const SizedBox(height: 8),
        Text(status, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: toggle,
          icon: Icon(sharing ? Icons.stop : Icons.play_arrow),
          label: Text(sharing ? 'Dừng chia sẻ' : 'Chia sẻ vị trí'),
        ),
      ]),
    ),
  );
}

// ================= PHỤ HUYNH: BẢN ĐỒ VỊ TRÍ CÁC BÉ =================
class ParentMapPage extends StatefulWidget {
  const ParentMapPage({super.key});
  @override
  State<ParentMapPage> createState() => _ParentMapPageState();
}

class _ParentMapPageState extends State<ParentMapPage> {
  final map = MapController();
  List kids = [];
  Timer? timer;
  bool centered = false;

  @override
  void initState() {
    super.initState();
    load();
    timer = Timer.periodic(const Duration(seconds: 5), (_) => load());
  }

  Future<void> load() async {
    try {
      final r = await Api.get('Location/children');
      if (r.statusCode != 200 || !mounted) return;
      setState(() => kids = jsonDecode(r.body));
      final pts = kids.where((k) => k['lat'] != null).toList();
      if (!centered && pts.isNotEmpty) {
        map.move(LatLng(pts.first['lat'], pts.first['lng']), 16);
        centered = true;
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pts = kids.where((k) => k['lat'] != null).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Vị trí của các bé')),
      body: Stack(children: [
        FlutterMap(
          mapController: map,
          options: const MapOptions(
              initialCenter: LatLng(10.8231, 106.6297), initialZoom: 13),
          children: [
            TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.dohoangdanh'),
            MarkerLayer(
              markers: pts
                  .map((k) => Marker(
                point: LatLng(k['lat'], k['lng']),
                width: 110,
                height: 70,
                child: Column(children: [
                  const Icon(Icons.location_pin,
                      color: Colors.red, size: 40),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    color: Colors.white70,
                    child: Text('${k['fullName']}',
                        style: const TextStyle(fontSize: 12)),
                  ),
                ]),
              ))
                  .toList(),
            ),
          ],
        ),
        if (pts.isEmpty)
          const Positioned(
              top: 12,
              left: 0,
              right: 0,
              child: Center(
                  child: Card(
                      child: Padding(
                          padding: EdgeInsets.all(10),
                          child: Text('Chưa có vị trí của bé nào')))))
      ]),
    );
  }
}