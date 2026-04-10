import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

// =======================================================
// 🗺️ หน้า 1: แผนที่หลัก (MapPage)
// =======================================================
class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final supabase = Supabase.instance.client;
  GoogleMapController? _mapController;

  final Set<Marker> _markers = {};
  List<dynamic> _allShops = [];

  bool _isDarkMode = true;

  // 🌟 ระบบ Dynamic Zoom
  double _currentZoom = 15.0;
  double _lastDrawnZoom = 15.0;

  final Map<String, bool> _filters = {
    'ลูกค้า': true,
    'หน้าร้านเรา': true,
    'คู่แข่ง': true,
    'ซัพพลายเออร์': true,
  };

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

  @override
  void initState() {
    super.initState();
    _fetchShops();
  }

  // 🌟 ฟังก์ชันวาดหมุดไอคอน (เวอร์ชันย่อส่วนให้เล็กลง มินิมอลขึ้น)
  Future<BitmapDescriptor> _createScaledIconMarker(
      IconData iconData, Color bgColor, double zoom) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);

    // คำนวณตัวคูณ (Scale)
    double scale = (zoom / 15.0).clamp(0.4, 1.4);

    // 🌟 ลดขนาดพื้นฐานลงทั้งหมด
    double iconFontSize = 22.0 * scale; // ลดจาก 35 เหลือ 22
    double padding = 6.0 * scale; // ลดจาก 10 เหลือ 6

    // วาดไอคอน
    TextPainter iconPainter = TextPainter(textDirection: TextDirection.ltr);
    iconPainter.text = TextSpan(
        text: String.fromCharCode(iconData.codePoint),
        style: TextStyle(
            fontSize: iconFontSize,
            fontFamily: iconData.fontFamily,
            package: iconData.fontPackage,
            color: Colors.white));
    iconPainter.layout();

    final double size = iconPainter.width + (padding * 2);
    final double pointerHeight = 10.0 * scale; // ลดปลายแหลมจาก 15 เหลือ 10
    final double totalHeight = size + pointerHeight;

    // วาดพื้นหลังวงกลม
    final Paint paint = Paint()..color = bgColor;
    final RRect rrect =
        RRect.fromLTRBR(0, 0, size, size, Radius.circular(size / 2));
    canvas.drawRRect(rrect, paint);

    // วาดขอบขาว (บางลง)
    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 * scale; // ลดจาก 3 เหลือ 2
    canvas.drawRRect(rrect, borderPaint);

    // แปะไอคอนลงไป
    iconPainter.paint(canvas, Offset(padding, padding));

    // วาดสามเหลี่ยมชี้พิกัด
    final Path trianglePath = Path()
      ..moveTo(size / 2 - (5 * scale), size) // ฐานสามเหลี่ยมแคบลง
      ..lineTo(size / 2 + (5 * scale), size)
      ..lineTo(size / 2, totalHeight)
      ..close();
    canvas.drawPath(trianglePath, paint);
    canvas.drawPath(trianglePath, borderPaint);

    final ui.Image img = await pictureRecorder
        .endRecording()
        .toImage(size.toInt() + 2, totalHeight.toInt() + 2);
    final ByteData? data = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }

  Future<void> _fetchShops() async {
    try {
      final List<dynamic> shops = await supabase.from('shops').select();
      _allShops = shops;
      await _applyFilter();
    } catch (e) {
      debugPrint('Error Loading Markers: $e');
    }
  }

  Future<void> _applyFilter() async {
    Set<Marker> newMarkers = {};

    for (var shop in _allShops) {
      String type = (shop['type']?.toString() ?? 'ลูกค้า').trim();
      if (_filters[type] == true) {
        String shopId = shop['id'].toString();
        double? lat = double.tryParse(shop['latitude'].toString());
        double? lng = double.tryParse(shop['longitude'].toString());
        if (lat == null || lng == null) continue;

        String shopName = shop['description']?.toString() ?? type;
        if (shopName.isEmpty) shopName = type;

        IconData mIcon = Icons.warning_rounded;
        Color mColor = Colors.red.shade700;
        if (type.contains('หน้าร้านเรา')) {
          mIcon = Icons.storefront;
          mColor = Colors.blue.shade700;
        } else if (type.contains('ลูกค้า')) {
          mIcon = Icons.person;
          mColor = Colors.green.shade700;
        } else if (type.contains('ซัพพลายเออร์')) {
          mIcon = Icons.inventory_2;
          mColor = Colors.orange.shade700;
        }

        BitmapDescriptor markerIcon =
            await _createScaledIconMarker(mIcon, mColor, _currentZoom);

        newMarkers.add(Marker(
          markerId:
              MarkerId('${shopId}_zoom_${_currentZoom.toStringAsFixed(1)}'),
          position: LatLng(lat, lng),
          icon: markerIcon,
          infoWindow: InfoWindow(
            title: shopName,
            snippet: 'แตะที่นี่เพื่อดูรายละเอียด/นำทาง',
            onTap: () => _showEditDialog(shop),
          ),
        ));
      }
    }

    setState(() {
      _markers.clear();
      _markers.addAll(newMarkers);
    });
  }

  Future<void> _launchGoogleMaps(double lat, double lng) async {
    final Uri url = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    if (await canLaunchUrl(url))
      await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  void _showAddDialog(LatLng position) {
    final TextEditingController descController = TextEditingController();
    final TextEditingController qtyController =
        TextEditingController(text: '0');
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
                        setDialogState(() => localSelectedType = val!)),
                const SizedBox(height: 16),
                if (localSelectedType == 'ลูกค้า') ...[
                  DropdownButtonFormField<String>(
                      value: localSelectedAge,
                      decoration: const InputDecoration(
                          labelText: 'กลุ่มอายุหลัก',
                          border: OutlineInputBorder()),
                      items: _ageRanges
                          .map(
                              (a) => DropdownMenuItem(value: a, child: Text(a)))
                          .toList(),
                      onChanged: (val) =>
                          setDialogState(() => localSelectedAge = val!)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(4)),
                    child: Column(
                      children: [
                        const Text('จำนวนลูกค้า (คน)',
                            style:
                                TextStyle(color: Colors.black54, fontSize: 12)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                                icon: const Icon(Icons.remove_circle,
                                    color: Colors.redAccent, size: 36),
                                onPressed: () {
                                  int c = int.tryParse(qtyController.text) ?? 0;
                                  if (c > 0)
                                    qtyController.text = (c - 1).toString();
                                }),
                            SizedBox(
                                width: 80,
                                child: TextField(
                                    controller: qtyController,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly
                                    ],
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold),
                                    decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(
                                            vertical: 8)))),
                            IconButton(
                                icon: const Icon(Icons.add_circle,
                                    color: Colors.green, size: 36),
                                onPressed: () {
                                  int c = int.tryParse(qtyController.text) ?? 0;
                                  qtyController.text = (c + 1).toString();
                                }),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                TextField(
                    controller: descController,
                    decoration: const InputDecoration(
                        labelText: 'หมายเหตุ/ชื่อร้าน',
                        border: OutlineInputBorder()),
                    maxLines: 2),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('ยกเลิก')),
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white),
                onPressed: () async {
                  String finalQty =
                      qtyController.text.isEmpty ? '0' : qtyController.text;
                  await _saveData(position, descController.text,
                      localSelectedType, localSelectedAge, finalQty);
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('บันทึก')),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(dynamic shop) {
    final TextEditingController descController =
        TextEditingController(text: shop['description']?.toString() ?? '');
    final TextEditingController qtyController =
        TextEditingController(text: shop['quantity']?.toString() ?? '0');
    String rawType = (shop['type']?.toString() ?? 'ลูกค้า').trim();
    String localSelectedType = _types.contains(rawType) ? rawType : 'ลูกค้า';
    String rawAge = (shop['age_range']?.toString() ?? '26-40 ปี').trim();
    String localSelectedAge = _ageRanges.contains(rawAge) ? rawAge : '26-40 ปี';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('✏️ จัดการข้อมูล', style: TextStyle(fontSize: 20)),
              IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    bool? c = await _showConfirmDeleteDialog();
                    if (c == true) {
                      await _deleteData(shop['id']);
                      if (context.mounted) Navigator.pop(context);
                    }
                  })
            ],
          ),
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
                        setDialogState(() => localSelectedType = val!)),
                const SizedBox(height: 16),
                if (localSelectedType == 'ลูกค้า') ...[
                  DropdownButtonFormField<String>(
                      value: localSelectedAge,
                      decoration: const InputDecoration(
                          labelText: 'กลุ่มอายุหลัก',
                          border: OutlineInputBorder()),
                      items: _ageRanges
                          .map(
                              (a) => DropdownMenuItem(value: a, child: Text(a)))
                          .toList(),
                      onChanged: (val) =>
                          setDialogState(() => localSelectedAge = val!)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(4)),
                    child: Column(
                      children: [
                        const Text('จำนวนลูกค้า (คน)',
                            style:
                                TextStyle(color: Colors.black54, fontSize: 12)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                                icon: const Icon(Icons.remove_circle,
                                    color: Colors.redAccent, size: 36),
                                onPressed: () {
                                  int c = int.tryParse(qtyController.text) ?? 0;
                                  if (c > 0)
                                    qtyController.text = (c - 1).toString();
                                }),
                            SizedBox(
                                width: 80,
                                child: TextField(
                                    controller: qtyController,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly
                                    ],
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold),
                                    decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(
                                            vertical: 8)))),
                            IconButton(
                                icon: const Icon(Icons.add_circle,
                                    color: Colors.green, size: 36),
                                onPressed: () {
                                  int c = int.tryParse(qtyController.text) ?? 0;
                                  qtyController.text = (c + 1).toString();
                                }),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                TextField(
                    controller: descController,
                    decoration: const InputDecoration(
                        labelText: 'หมายเหตุ/ชื่อร้าน',
                        border: OutlineInputBorder()),
                    maxLines: 2),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12)),
                    icon: const Icon(Icons.directions),
                    label: const Text('นำทางไปที่นี่',
                        style: TextStyle(fontSize: 16)),
                    onPressed: () {
                      double? lat =
                          double.tryParse(shop['latitude'].toString());
                      double? lng =
                          double.tryParse(shop['longitude'].toString());
                      if (lat != null && lng != null)
                        _launchGoogleMaps(lat, lng);
                    },
                  ),
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
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white),
                onPressed: () async {
                  String finalQty =
                      qtyController.text.isEmpty ? '0' : qtyController.text;
                  await _updateData(shop['id'], descController.text,
                      localSelectedType, localSelectedAge, finalQty);
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('อัปเดตข้อมูล')),
          ],
        ),
      ),
    );
  }

  Future<bool?> _showConfirmDeleteDialog() {
    return showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text('ยืนยันการลบ'),
                content: const Text('คุณแน่ใจหรือไม่ว่าต้องการลบพิกัดนี้?'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('ยกเลิก')),
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('ลบเลย'))
                ]));
  }

  Future<void> _saveData(
      LatLng pos, String desc, String type, String age, String qty) async {
    try {
      await supabase.from('shops').insert({
        'description': desc,
        'type': type,
        'age_range': type == 'ลูกค้า' ? age : null,
        'quantity': qty,
        'latitude': pos.latitude,
        'longitude': pos.longitude
      });
      _fetchShops();
    } catch (e) {
      debugPrint('Save Error: $e');
    }
  }

  Future<void> _updateData(
      dynamic id, String desc, String type, String age, String qty) async {
    try {
      await supabase.from('shops').update({
        'description': desc,
        'type': type,
        'age_range': type == 'ลูกค้า' ? age : null,
        'quantity': qty
      }).eq('id', id);
      _fetchShops();
    } catch (e) {
      debugPrint('Update Error: $e');
    }
  }

  Future<void> _deleteData(dynamic id) async {
    try {
      await supabase.from('shops').delete().eq('id', id);
      _fetchShops();
    } catch (e) {
      debugPrint('Delete Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SME Strategy Analytics'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
              icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  size: 26),
              tooltip: 'สลับโหมดแผนที่',
              onPressed: () {
                setState(() {
                  _isDarkMode = !_isDarkMode;
                });
              }),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchShops),
          IconButton(
              icon: const Icon(Icons.bar_chart, size: 28),
              tooltip: 'สรุปภาพรวม',
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const DashboardPage()))),
          const SizedBox(width: 8),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
                decoration: BoxDecoration(color: Colors.blue.shade800),
                child: const Center(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                      Icon(Icons.filter_list, color: Colors.white, size: 40),
                      SizedBox(height: 10),
                      Text('ตัวกรองพิกัด',
                          style: TextStyle(color: Colors.white, fontSize: 20))
                    ]))),
            Expanded(
                child: ListView(
                    children: _filters.keys.map((String key) {
              return CheckboxListTile(
                  title: Text(key),
                  value: _filters[key],
                  activeColor: Colors.blue,
                  onChanged: (bool? value) {
                    setState(() {
                      _filters[key] = value!;
                      _applyFilter();
                    });
                  });
            }).toList())),
            const Divider(),
            Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('กำลังแสดงพิกัด: ${_markers.length} จุด',
                    style: const TextStyle(color: Colors.grey)))
          ],
        ),
      ),
      body: GoogleMap(
        initialCameraPosition:
            const CameraPosition(target: LatLng(13.5475, 100.2744), zoom: 15.0),
        markers: _markers,
        style: _isDarkMode ? _darkMapStyle : null,
        onCameraMove: (CameraPosition position) {
          _currentZoom = position.zoom;
        },
        onCameraIdle: () {
          if ((_currentZoom - _lastDrawnZoom).abs() > 0.5) {
            _lastDrawnZoom = _currentZoom;
            _applyFilter();
          }
        },
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

// โค้ดโหมดมืด JSON
const String _darkMapStyle =
    '''[{"elementType": "geometry","stylers": [{"color": "#212121"}]},{"elementType": "labels.icon","stylers": [{"visibility": "off"}]},{"elementType": "labels.text.fill","stylers": [{"color": "#757575"}]},{"elementType": "labels.text.stroke","stylers": [{"color": "#212121"}]},{"featureType": "administrative","elementType": "geometry","stylers": [{"color": "#757575"}]},{"featureType": "administrative.country","elementType": "labels.text.fill","stylers": [{"color": "#9e9e9e"}]},{"featureType": "administrative.locality","elementType": "labels.text.fill","stylers": [{"color": "#bdbdbd"}]},{"featureType": "poi","elementType": "labels.text.fill","stylers": [{"color": "#757575"}]},{"featureType": "park","elementType": "geometry","stylers": [{"color": "#181818"}]},{"featureType": "park","elementType": "labels.text.fill","stylers": [{"color": "#616161"}]},{"featureType": "park","elementType": "labels.text.stroke","stylers": [{"color": "#1b1b1b"}]},{"featureType": "road","elementType": "geometry.fill","stylers": [{"color": "#2c2c2c"}]},{"featureType": "road","elementType": "labels.text.fill","stylers": [{"color": "#8a8a8a"}]},{"featureType": "road.arterial","elementType": "geometry","stylers": [{"color": "#373737"}]},{"featureType": "road.highway","elementType": "geometry","stylers": [{"color": "#3c3c3c"}]},{"featureType": "road.highway.controlled_access","elementType": "geometry","stylers": [{"color": "#4e4e4e"}]},{"featureType": "road.local","elementType": "labels.text.fill","stylers": [{"color": "#616161"}]},{"featureType": "transit","elementType": "labels.text.fill","stylers": [{"color": "#757575"}]},{"featureType": "water","elementType": "geometry","stylers": [{"color": "#000000"}]},{"featureType": "water","elementType": "labels.text.fill","stylers": [{"color": "#3d3d3d"}]}]''';

// =======================================================
// 📊 หน้า 2: แดชบอร์ดสรุปข้อมูล
// =======================================================
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final supabase = Supabase.instance.client;
  Future<List<dynamic>> _fetchDashboardData() async {
    return await supabase.from('shops').select() as List<dynamic>;
  }

  Widget _buildSummaryCard(
      String title, String value, IconData icon, Color color) {
    return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
            padding: const EdgeInsets.all(16.0),
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 8),
              Text(value,
                  style: TextStyle(
                      fontSize: 28, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 4),
              Text(title,
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                  textAlign: TextAlign.center)
            ])));
  }

  Widget _buildSimpleBar(String label, int value, double percentage) {
    final chartBlue = Colors.blue.shade900;
    return Column(mainAxisAlignment: MainAxisAlignment.end, children: [
      Text('$value',
          style: TextStyle(
              fontWeight: FontWeight.bold, color: chartBlue, fontSize: 13)),
      const SizedBox(height: 6),
      Container(
          width: 35,
          height: 180 * percentage,
          decoration: BoxDecoration(
              color: chartBlue, borderRadius: BorderRadius.circular(6))),
      const SizedBox(height: 8),
      SizedBox(
          width: 55,
          child: Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: Colors.black87),
              maxLines: 2))
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('📊 สรุปภาพรวมยุทธศาสตร์'),
          backgroundColor: Colors.blue.shade800,
          foregroundColor: Colors.white),
      backgroundColor: Colors.grey.shade100,
      body: FutureBuilder<List<dynamic>>(
        future: _fetchDashboardData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError || !snapshot.hasData)
            return const Center(child: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล'));
          final shops = snapshot.data!;
          int totalPins = shops.length,
              totalCustomers = 0,
              countCompetitor = 0,
              countStore = 0;
          Map<String, int> ageData = {
            'ไม่ระบุ': 0,
            '15-25 ปี': 0,
            '26-40 ปี': 0,
            '41-60 ปี': 0,
            '60 ปีขึ้นไป': 0
          };
          for (var shop in shops) {
            String type = (shop['type']?.toString() ?? '').trim();
            int qty = int.tryParse(shop['quantity']?.toString() ?? '0') ?? 0;
            String age = (shop['age_range']?.toString() ?? 'ไม่ระบุ').trim();
            if (type.contains('ลูกค้า')) {
              totalCustomers += qty;
              if (ageData.containsKey(age)) ageData[age] = ageData[age]! + qty;
            } else if (type.contains('คู่แข่ง'))
              countCompetitor++;
            else if (type.contains('หน้าร้านเรา')) countStore++;
          }
          int maxAgeValue =
              ageData.values.reduce((curr, next) => curr > next ? curr : next);
          if (maxAgeValue == 0) maxAgeValue = 1;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('ดัชนีชี้วัดหลัก (KPIs)',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87)),
              const SizedBox(height: 12),
              GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildSummaryCard('ลูกค้ารวมทั้งหมด', '$totalCustomers',
                        Icons.groups, Colors.green),
                    _buildSummaryCard('จำนวนพิกัดที่ปัก', '$totalPins',
                        Icons.place, Colors.blue),
                    _buildSummaryCard('ร้านคู่แข่งรอบๆ', '$countCompetitor',
                        Icons.warning_rounded, Colors.red),
                    _buildSummaryCard('สาขาหน้าร้านเรา', '$countStore',
                        Icons.storefront, Colors.lightBlue)
                  ]),
              const SizedBox(height: 32),
              const Text('สัดส่วนกลุ่มอายุลูกค้า',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87)),
              const SizedBox(height: 12),
              Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: SizedBox(
                          height: 250,
                          child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: ageData.entries.map((entry) {
                                    double percentage =
                                        entry.value / maxAgeValue;
                                    return Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10.0),
                                        child: _buildSimpleBar(entry.key,
                                            entry.value, percentage));
                                  }).toList()))))),
              const SizedBox(height: 20),
            ]),
          );
        },
      ),
    );
  }
}
