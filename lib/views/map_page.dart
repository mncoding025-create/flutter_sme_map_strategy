import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final supabase = Supabase.instance.client;
  GoogleMapController? _mapController;

  // เก็บหมุดที่จะแสดงบนแผนที่
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _fetchShops(); // โหลดข้อมูลหมุดทันทีที่เปิดหน้าแผนที่
  }

  // ดึงข้อมูลร้านค้าจากฐานข้อมูลมาทำเป็น Marker
  Future<void> _fetchShops() async {
    try {
      final data = await supabase.from('shops').select();
      final List<dynamic> shops = data as List<dynamic>;

      setState(() {
        _markers.clear();
        for (var shop in shops) {
          _markers.add(
            Marker(
              markerId: MarkerId(shop['id'].toString()),
              position: LatLng(shop['latitude'], shop['longitude']),
              infoWindow: InfoWindow(
                title: shop['name'],
                // ดึง description มาโชว์ ถ้าไม่มีให้แสดงข้อความว่างๆ
                snippet: shop['description'] ?? 'ไม่มีรายละเอียด',
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueRed), // สีของหมุด
            ),
          );
        }
      });
    } catch (e) {
      debugPrint('Error fetching shops: $e');
    }
  }

  // หน้าต่างเพิ่มข้อมูล (อัปเกรด 2 ช่อง: ชื่อร้าน และ รายละเอียด)
  void _showAddDialog(LatLng position) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📍 ปักหมุดร้านค้าใหม่'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'ชื่อร้าน หรือ ข้อมูลคู่แข่ง',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'รายละเอียด (เช่น ลูกค้า VIP, โน้ตเพิ่มเติม)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                // ส่งค่าพิกัด ชื่อ และรายละเอียด ไปบันทึก
                await _addShopWithDesc(
                    position, nameController.text, descController.text);
                if (context.mounted) Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('กรุณาใส่ชื่อร้านค้าด้วยครับ!')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('บันทึก', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // บันทึกข้อมูลลงฐานข้อมูล Supabase
  Future<void> _addShopWithDesc(
      LatLng position, String name, String description) async {
    try {
      await supabase.from('shops').insert({
        'name': name,
        'description': description,
        'latitude': position.latitude,
        'longitude': position.longitude,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('✅ บันทึกจุดยุทธศาสตร์สำเร็จ!'),
              backgroundColor: Colors.green),
        );
      }

      _fetchShops(); // รีโหลดแผนที่เพื่อให้หมุดใหม่เด้งขึ้นมาทันที
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('เกิดข้อผิดพลาดในการบันทึก: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SME Strategy Map'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: GoogleMap(
        // พิกัดเริ่มต้นที่สมุทรสาคร
        initialCameraPosition: const CameraPosition(
          target: LatLng(13.5475, 100.2744),
          zoom: 13,
        ),
        markers: _markers,
        onMapCreated: (controller) => _mapController = controller,
        // พอกดค้างที่แผนที่ ให้เรียกหน้าต่าง AddDialog
        onLongPress: _showAddDialog,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
      ),
    );
  }
}
