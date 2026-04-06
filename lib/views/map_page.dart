import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:ui' as ui; // <--- เพิ่มตัวนี้สำหรับวาดรูป
import 'dart:typed_data'; // <--- เพิ่มตัวนี้สำหรับจัดการไฟล์ภาพ

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final supabase = Supabase.instance.client;
  // ignore: unused_field
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};

  final List<String> _types = [
    'ลูกค้า',
    'หน้าร้านเรา',
    'คู่แข่ง',
    'ซัพพลายเออร์'
  ];
  final List<String> _ageRanges = [
    'ไม่ระบุ',
    '15-25 ปี',
    '26-40 ปี',
    '41-60 ปี',
    '60 ปีขึ้นไป'
  ];

  // ตัวแปรเก็บรูปหมุดที่เราวาดเอง
  BitmapDescriptor? _iconCustomer;
  BitmapDescriptor? _iconStore;
  BitmapDescriptor? _iconSupplier;
  BitmapDescriptor? _iconCompetitor;

  @override
  void initState() {
    super.initState();
    // สร้างหมุดสีต่างๆ ให้เสร็จก่อน แล้วค่อยไปดึงข้อมูลจาก Database
    _initCustomMarkers().then((_) => _fetchShops());
  }

  // --- ฟังก์ชันวาดหมุดทรงกลม (แก้ปัญหา Web ไม่ยอมเปลี่ยนสี) ---
  Future<BitmapDescriptor> _createCustomMarker(Color color) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);

    // วาดขอบวงกลมสีขาว
    final Paint borderPaint = Paint()..color = Colors.white;
    canvas.drawCircle(const Offset(24, 24), 24, borderPaint);

    // วาดวงกลมสีหลักด้านใน
    final Paint fillPaint = Paint()..color = color;
    canvas.drawCircle(const Offset(24, 24), 18, fillPaint);

    final ui.Image img = await pictureRecorder.endRecording().toImage(48, 48);
    final ByteData? data = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }

  // เตรียมสีหมุดเอาไว้
  Future<void> _initCustomMarkers() async {
    _iconStore = await _createCustomMarker(Colors.blue); // 🔵 หน้าร้านเรา
    _iconCustomer = await _createCustomMarker(Colors.green); // 🟢 ลูกค้า
    _iconSupplier = await _createCustomMarker(Colors.orange); // 🟠 ซัพพลายเออร์
    _iconCompetitor = await _createCustomMarker(Colors.red); // 🔴 คู่แข่ง
    setState(() {}); // รีเฟรชหน้าจอ
  }

  // --- ฟังก์ชันดึงข้อมูล ---
  Future<void> _fetchShops() async {
    try {
      final List<dynamic> shops = await supabase.from('shops').select();

      setState(() {
        _markers.clear();
        for (var shop in shops) {
          double? lat = double.tryParse(shop['latitude'].toString());
          double? lng = double.tryParse(shop['longitude'].toString());
          if (lat == null || lng == null) continue;

          String type = (shop['type']?.toString() ?? 'ลูกค้า').trim();

          // 🎨 เลือกรูกหมุดที่เราวาดไว้
          BitmapDescriptor markerIcon =
              _iconCompetitor ?? BitmapDescriptor.defaultMarker;

          if (type.contains('หน้าร้านเรา')) {
            markerIcon = _iconStore ?? BitmapDescriptor.defaultMarker;
          } else if (type.contains('ลูกค้า')) {
            markerIcon = _iconCustomer ?? BitmapDescriptor.defaultMarker;
          } else if (type.contains('ซัพพลายเออร์')) {
            markerIcon = _iconSupplier ?? BitmapDescriptor.defaultMarker;
          }

          _markers.add(
            Marker(
              markerId: MarkerId(shop['id'].toString()),
              position: LatLng(lat, lng),
              infoWindow: InfoWindow(
                title: '[$type] ${shop['description'] ?? ""}',
                snippet:
                    'อายุ: ${shop['age_range'] ?? "-"} | จำนวน: ${shop['quantity'] ?? "0"}',
              ),
              icon: markerIcon, // ใช้หมุดที่เราวาดเอง!
            ),
          );
        }
      });
    } catch (e) {
      debugPrint('Error Loading Markers: $e');
    }
  }

  // --- หน้าต่าง Pop-up บันทึก ---
  void _showAddDialog(LatLng position) {
    final TextEditingController descController = TextEditingController();
    final TextEditingController qtyController = TextEditingController();
    String localSelectedType = 'ลูกค้า';
    String localSelectedAge = '26-40 ปี';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('📊 บันทึกข้อมูลการตลาด'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: localSelectedType,
                  decoration: const InputDecoration(
                      labelText: 'ประเภท', border: OutlineInputBorder()),
                  items: _types
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (val) =>
                      setDialogState(() => localSelectedType = val!),
                ),
                const SizedBox(height: 16),
                if (localSelectedType == 'ลูกค้า') ...[
                  DropdownButtonFormField<String>(
                    value: localSelectedAge,
                    decoration: const InputDecoration(
                        labelText: 'กลุ่มอายุหลัก',
                        border: OutlineInputBorder()),
                    items: _ageRanges
                        .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                        .toList(),
                    onChanged: (val) =>
                        setDialogState(() => localSelectedAge = val!),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: qtyController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'จำนวน (คน)',
                        prefixIcon: Icon(Icons.people),
                        border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                      labelText: 'หมายเหตุ/ชื่อร้าน',
                      border: OutlineInputBorder()),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('ยกเลิก')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, foregroundColor: Colors.white),
              onPressed: () async {
                await _saveData(position, descController.text,
                    localSelectedType, localSelectedAge, qtyController.text);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('บันทึก'),
            ),
          ],
        ),
      ),
    );
  }

  // --- ฟังก์ชันบันทึกลง Supabase ---
  Future<void> _saveData(
      LatLng pos, String desc, String type, String age, String qty) async {
    try {
      await supabase.from('shops').insert({
        'description': desc,
        'type': type,
        'age_range': type == 'ลูกค้า' ? age : null,
        'quantity': qty,
        'latitude': pos.latitude,
        'longitude': pos.longitude,
      });
      _fetchShops();
    } catch (e) {
      debugPrint('Save Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SME Strategy Analytics'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchShops),
        ],
      ),
      body: GoogleMap(
        initialCameraPosition:
            const CameraPosition(target: LatLng(13.5475, 100.2744), zoom: 15),
        markers: _markers,
        onMapCreated: (controller) {
          _mapController = controller;
        },
        onLongPress: _showAddDialog,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
      ),
    );
  }
}
