import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// ชื่อ Class ต้องเป็น MapPage ตรงตามที่ main.dart เรียกครับ
class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('แผนที่ยุทธศาสตร์ SME'),
        backgroundColor: Colors.blue,
      ),
      body: const GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(13.5475, 100.2744), // พิกัดสมุทรสาคร
          zoom: 14,
        ),
      ),
    );
  }
}
