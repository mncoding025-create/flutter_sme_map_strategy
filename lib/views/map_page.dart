import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'credit_page.dart';

// =======================================================
// สี
// =======================================================
class AppColors {
  static const Color navyDeep = Color(0xFF003366);
  static const Color azureLight = Color(0xFFE3F2FD);
  static const Color accentBlue = Color(0xFF1976D2);
  static const Color compRed = Color(0xFFEF5350);
  static const Color storeBlue = Color(0xFF42A5F5);
  static const Color customerGreen = Color(0xFF66BB6A);
  static const Color bgGrey = Color(0xFFF5F7FA);
}

// =======================================================
// ข้อมูลคงที่
// =======================================================
const List<String> shopTypes = [
  'ลูกค้า',
  'หน้าร้านเรา',
  'คู่แข่ง',
  'ซัพพลายเออร์'
];

const List<String> ageRangeOptions = [
  'ไม่ระบุ',
  '15-25 ปี',
  '26-40 ปี',
  '41-60 ปี',
  '60 ปีขึ้นไป'
];

// =======================================================
// แผนที่หลัก (MapPage)
// =======================================================
class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final supabase = Supabase.instance.client;

  final Set<Marker> _markers = {};
  List<dynamic> _allShops = [];

  double _currentZoom = 15.0;
  double _lastDrawnZoom = 15.0;
  LatLng _currentCenter = const LatLng(13.5475, 100.2744);

  final Map<String, bool> _filters = {
    'ลูกค้า': true,
    'หน้าร้านเรา': true,
    'คู่แข่ง': true,
    'ซัพพลายเออร์': true,
  };

  @override
  void initState() {
    super.initState();
    _fetchShops();
  }

  // --- ส่วนสร้างหมุดบนแผนที่ ---
  Future<BitmapDescriptor> _createScaledIconMarker(
      IconData iconData, Color bgColor, double zoom) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);

    double scale = (zoom / 15.0).clamp(0.5, 1.3);
    double padding = 7.0 * scale;

    TextPainter iconPainter = TextPainter(textDirection: TextDirection.ltr);
    iconPainter.text = TextSpan(
        text: String.fromCharCode(iconData.codePoint),
        style: TextStyle(
            fontSize: 24.0 * scale,
            fontFamily: iconData.fontFamily,
            package: iconData.fontPackage,
            color: Colors.white));
    iconPainter.layout();

    final double size = iconPainter.width + (padding * 2);
    final Paint paint = Paint()..color = bgColor;
    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 * scale;

    canvas.drawCircle(Offset(size / 2, size / 2), size / 2, paint);
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2, borderPaint);
    iconPainter.paint(canvas, Offset(padding, padding));

    final ui.Image img = await pictureRecorder
        .endRecording()
        .toImage(size.toInt(), size.toInt());
    final ByteData? data = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }

  // --- ดึงข้อมูลจาก Supabase ---
  Future<void> _fetchShops() async {
    try {
      final List<dynamic> shops = await supabase.from('shops').select();
      _allShops = shops;
      await _applyFilter();
    } catch (e) {
      debugPrint('Error Loading Markers: $e');
    }
  }

  // --- จัดการตัวกรองและการแสดงผลหมุด ---
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

        IconData mIcon = Icons.place;
        Color mColor = AppColors.compRed;

        if (type.contains('หน้าร้านเรา')) {
          mIcon = Icons.storefront;
          mColor = AppColors.storeBlue;
        } else if (type.contains('ลูกค้า')) {
          mIcon = Icons.person;
          mColor = AppColors.customerGreen;
        } else if (type.contains('ซัพพลายเออร์')) {
          mIcon = Icons.inventory_2;
          mColor = Colors.orange.shade700;
        }

        BitmapDescriptor markerIcon =
            await _createScaledIconMarker(mIcon, mColor, _currentZoom);

        newMarkers.add(Marker(
          markerId: MarkerId('${shopId}_z_${_currentZoom.toStringAsFixed(1)}'),
          position: LatLng(lat, lng),
          icon: markerIcon,
          infoWindow: InfoWindow(
            title: shopName,
            snippet: 'แตะเพื่อจัดการข้อมูล',
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

  // --- เพิ่มข้อมูล ---
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
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          title: const Row(children: [
            Icon(Icons.add_location_alt_rounded, color: AppColors.accentBlue),
            SizedBox(width: 10),
            Text('เพิ่มพิกัดยุทธศาสตร์',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
          ]),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                    value: localSelectedType,
                    decoration: InputDecoration(
                        labelText: 'ประเภทข้อมูล',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15))),
                    items: shopTypes
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (val) =>
                        setDialogState(() => localSelectedType = val!)),
                const SizedBox(height: 16),
                if (localSelectedType == 'ลูกค้า') ...[
                  DropdownButtonFormField<String>(
                      value: localSelectedAge,
                      decoration: InputDecoration(
                          labelText: 'กลุ่มอายุหลัก',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15))),
                      items: ageRangeOptions
                          .map(
                              (a) => DropdownMenuItem(value: a, child: Text(a)))
                          .toList(),
                      onChanged: (val) =>
                          setDialogState(() => localSelectedAge = val!)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                        color: AppColors.bgGrey,
                        borderRadius: BorderRadius.circular(15)),
                    child: Column(
                      children: [
                        const Text('จำนวนลูกค้า (คน)',
                            style: TextStyle(
                                color: Colors.black54,
                                fontSize: 13,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                                icon: const Icon(Icons.remove_circle,
                                    color: AppColors.compRed, size: 36),
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
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold),
                                    decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        isDense: true))),
                            IconButton(
                                icon: const Icon(Icons.add_circle,
                                    color: AppColors.customerGreen, size: 36),
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
                    decoration: InputDecoration(
                        labelText: 'ชื่อร้าน/รายละเอียด',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15))),
                    maxLines: 2),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child:
                    const Text('ยกเลิก', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
                onPressed: () async {
                  String finalQty =
                      qtyController.text.isEmpty ? '0' : qtyController.text;
                  await _saveData(position, descController.text,
                      localSelectedType, localSelectedAge, finalQty);
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('บันทึกข้อมูล')),
          ],
        ),
      ),
    );
  }

  // --- แก้ไขข้อมูล ---
  void _showEditDialog(dynamic shop) {
    final TextEditingController descController =
        TextEditingController(text: shop['description']?.toString() ?? '');
    final TextEditingController qtyController =
        TextEditingController(text: shop['quantity']?.toString() ?? '0');
    String rawType = (shop['type']?.toString() ?? 'ลูกค้า').trim();
    String localSelectedType = shopTypes.contains(rawType) ? rawType : 'ลูกค้า';
    String rawAge = (shop['age_range']?.toString() ?? '26-40 ปี').trim();
    String localSelectedAge =
        ageRangeOptions.contains(rawAge) ? rawAge : '26-40 ปี';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('จัดการข้อมูล',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: AppColors.compRed),
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
                    decoration: InputDecoration(
                        labelText: 'ประเภทข้อมูล',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15))),
                    items: shopTypes
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (val) =>
                        setDialogState(() => localSelectedType = val!)),
                const SizedBox(height: 16),
                if (localSelectedType == 'ลูกค้า') ...[
                  DropdownButtonFormField<String>(
                      value: localSelectedAge,
                      decoration: InputDecoration(
                          labelText: 'กลุ่มอายุหลัก',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15))),
                      items: ageRangeOptions
                          .map(
                              (a) => DropdownMenuItem(value: a, child: Text(a)))
                          .toList(),
                      onChanged: (val) =>
                          setDialogState(() => localSelectedAge = val!)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                        color: AppColors.bgGrey,
                        borderRadius: BorderRadius.circular(15)),
                    child: Column(
                      children: [
                        const Text('จำนวนลูกค้า (คน)',
                            style: TextStyle(
                                color: Colors.black54,
                                fontSize: 13,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                                icon: const Icon(Icons.remove_circle,
                                    color: AppColors.compRed, size: 36),
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
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold),
                                    decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        isDense: true))),
                            IconButton(
                                icon: const Icon(Icons.add_circle,
                                    color: AppColors.customerGreen, size: 36),
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
                    decoration: InputDecoration(
                        labelText: 'ชื่อร้าน/รายละเอียด',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15))),
                    maxLines: 2),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.customerGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10))),
                    icon: const Icon(Icons.directions),
                    label: const Text('นำทางด้วยแผนที่',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
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
                child:
                    const Text('ยกเลิก', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
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

  // --- ระบบ Database ของ Supabase ---
  Future<bool?> _showConfirmDeleteDialog() {
    return showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                title: const Text('ยืนยันการลบ'),
                content: const Text(
                    'คุณแน่ใจหรือไม่ว่าต้องการลบพิกัดนี้? ข้อมูลจะไม่สามารถกู้คืนได้'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('ยกเลิก')),
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.compRed,
                          foregroundColor: Colors.white),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('ลบทิ้ง'))
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

  // --- UI Build ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('SME Strategy Map',
            style: TextStyle(
                fontWeight: FontWeight.w800, letterSpacing: 1.0, fontSize: 22)),
        elevation: 0,
        backgroundColor: AppColors.navyDeep.withOpacity(0.9),
        foregroundColor: Colors.white,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(25))),
        leading: Builder(
            builder: (context) => IconButton(
                icon: const Icon(Icons.menu_open_rounded, size: 28),
                onPressed: () => Scaffold.of(context).openDrawer())),
        actions: [
          IconButton(
              icon: const Icon(Icons.analytics_outlined, size: 28),
              tooltip: 'แดชบอร์ด',
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const DashboardPage()))),
          const SizedBox(width: 10),
        ],
      ),
      drawer: Drawer(
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.horizontal(right: Radius.circular(30))),
        child: Column(children: [
          DrawerHeader(
              decoration: const BoxDecoration(color: AppColors.navyDeep),
              child: Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                    Container(
                        padding: const EdgeInsets.all(15),
                        decoration: const BoxDecoration(
                            color: Colors.white, shape: BoxShape.circle),
                        child: const Icon(Icons.business_center_rounded,
                            size: 45, color: AppColors.navyDeep)),
                    const SizedBox(height: 12),
                    const Text('SME Strategy Analytics',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold))
                  ]))),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('ตัวกรองข้อมูลบนแผนที่',
                  style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.bold))),
          Expanded(
              child: ListView(
                  padding: const EdgeInsets.all(10),
                  children: _filters.keys
                      .map((key) => CheckboxListTile(
                          title: Text(key,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                          value: _filters[key],
                          activeColor: AppColors.accentBlue,
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15)),
                          onChanged: (val) {
                            setState(() {
                              _filters[key] = val!;
                              _applyFilter();
                            });
                          }))
                      .toList())),
          const Divider(),

          // credit_page.dart
          ListTile(
            leading: const Icon(Icons.info_outline_rounded,
                color: AppColors.accentBlue, size: 28),
            title: const Text('Info',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: AppColors.navyDeep)),
            trailing:
                const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            onTap: () {
              Navigator.pop(context); // ปิด Drawer
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const CreditPage()));
            },
          ),
          const SizedBox(height: 20)
        ]),
      ),

      // ปุ่มซ้ายล่าง
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.accentBlue,
        child: const Icon(Icons.sync, color: Colors.white, size: 30),
        onPressed: _fetchShops,
      ),

      body: GoogleMap(
        initialCameraPosition:
            CameraPosition(target: _currentCenter, zoom: 15.0),
        markers: _markers,
        onCameraMove: (CameraPosition position) {
          _currentZoom = position.zoom;
          _currentCenter = position.target;
        },
        onCameraIdle: () {
          if ((_currentZoom - _lastDrawnZoom).abs() > 0.5) {
            _lastDrawnZoom = _currentZoom;
            _applyFilter();
          }
        },
        onLongPress: _showAddDialog,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
      ),
    );
  }
}

// =======================================================
// DashboardPage
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

  Widget _buildSectionTitle(String title) {
    return Row(children: [
      Container(
          width: 6,
          height: 24,
          decoration: BoxDecoration(
              color: AppColors.accentBlue,
              borderRadius: BorderRadius.circular(10))),
      const SizedBox(width: 12),
      Text(title,
          style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.navyDeep)),
    ]);
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
                color: Colors.grey.withOpacity(0.08),
                blurRadius: 15,
                offset: const Offset(0, 5))
          ]),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(icon, color: color, size: 28)),
              Text(value,
                  style: TextStyle(
                      fontSize: 32, fontWeight: FontWeight.bold, color: color)),
            ]),
            const SizedBox(height: 15),
            Text(label,
                style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 13,
                    fontWeight: FontWeight.w500),
                maxLines: 2),
          ]),
    );
  }

  Widget _buildSimpleBar(String label, int value, double percentage) {
    return Column(mainAxisAlignment: MainAxisAlignment.end, children: [
      Text('$value',
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.navyDeep,
              fontSize: 14)),
      const SizedBox(height: 6),
      Container(
          width: 35,
          height: 180 * percentage,
          decoration: BoxDecoration(
              color: AppColors.accentBlue,
              borderRadius: BorderRadius.circular(8))),
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
      backgroundColor: AppColors.bgGrey,
      appBar: AppBar(
          title: const Text('ศูนย์รวมข้อมูลยุทธศาสตร์',
              style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: AppColors.navyDeep,
          foregroundColor: Colors.white,
          elevation: 0),
      body: FutureBuilder<List<dynamic>>(
        future: _fetchDashboardData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(
                child: CircularProgressIndicator(color: AppColors.navyDeep));
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
            padding: const EdgeInsets.all(20.0),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _buildSectionTitle('ดัชนีชี้วัดหลัก (KPIs)'),
              const SizedBox(height: 15),
              GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildStatCard('ลูกค้ารวม (คน)', '$totalCustomers',
                        Icons.groups_rounded, AppColors.customerGreen),
                    _buildStatCard('พิกัดทั้งหมด', '$totalPins',
                        Icons.map_rounded, AppColors.accentBlue),
                    _buildStatCard('ร้านคู่แข่ง', '$countCompetitor',
                        Icons.dangerous_rounded, AppColors.compRed),
                    _buildStatCard('สาขาของเรา', '$countStore',
                        Icons.storefront_rounded, AppColors.storeBlue)
                  ]),
              const SizedBox(height: 30),
              _buildSectionTitle('สัดส่วนกลุ่มอายุลูกค้าเป้าหมาย'),
              const SizedBox(height: 15),
              Container(
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.grey.withOpacity(0.08),
                            blurRadius: 15,
                            offset: const Offset(0, 5))
                      ]),
                  padding: const EdgeInsets.all(20.0),
                  child: SizedBox(
                      height: 250,
                      child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: ageData.entries.map((entry) {
                                double percentage = entry.value / maxAgeValue;
                                return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10.0),
                                    child: _buildSimpleBar(
                                        entry.key, entry.value, percentage));
                              }).toList())))),
              const SizedBox(height: 20),
            ]),
          );
        },
      ),
    );
  }
}
