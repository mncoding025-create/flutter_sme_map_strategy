import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui' as ui;
import '../theme/app_theme.dart';

// =======================================================
// Map Page — Brutalist Dark Theme + Location Lock
// =======================================================
class MapPage extends StatefulWidget {
  final String selectedIndustry;
  const MapPage({super.key, required this.selectedIndustry});

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
  final String _locationName = 'SAMUT SAKHON';
  bool _showFilters = false;

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

  // --- สร้าง Marker Icon ---
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
      ..color = AppColors.neonGreen.withOpacity(0.6)
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

  // --- ตัวกรอง + สร้าง Markers ---
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
          mColor = AppColors.supplierOrange;
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
          backgroundColor: AppColors.bgSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: const BorderSide(color: AppColors.border),
          ),
          title: Row(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.neonGreen,
                borderRadius: BorderRadius.circular(2),
              ),
              child: const Icon(Icons.add_location_alt_rounded,
                  color: Colors.black, size: 20),
            ),
            const SizedBox(width: 10),
            Text('เพิ่มพิกัดยุทธศาสตร์',
                style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary))
          ]),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDropdown('ประเภทข้อมูล', localSelectedType, shopTypes,
                    (val) => setDialogState(() => localSelectedType = val!)),
                const SizedBox(height: 16),
                if (localSelectedType == 'ลูกค้า') ...[
                  _buildDropdown(
                      'กลุ่มอายุหลัก',
                      localSelectedAge,
                      ageRangeOptions,
                      (val) =>
                          setDialogState(() => localSelectedAge = val!)),
                  const SizedBox(height: 16),
                  _buildQuantityControl(qtyController),
                  const SizedBox(height: 16),
                ],
                _buildTextField(descController, 'ชื่อร้าน/รายละเอียด'),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('ยกเลิก',
                    style: GoogleFonts.inter(color: AppColors.textMuted))),
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.neonGreen,
                    foregroundColor: Colors.black),
                onPressed: () async {
                  String finalQty =
                      qtyController.text.isEmpty ? '0' : qtyController.text;
                  await _saveData(position, descController.text,
                      localSelectedType, localSelectedAge, finalQty);
                  if (context.mounted) Navigator.pop(context);
                },
                child: Text('บันทึกข้อมูล',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w800))),
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
          backgroundColor: AppColors.bgSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: const BorderSide(color: AppColors.border),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('จัดการข้อมูล',
                  style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary)),
              IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: AppColors.danger),
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
                _buildDropdown('ประเภทข้อมูล', localSelectedType, shopTypes,
                    (val) => setDialogState(() => localSelectedType = val!)),
                const SizedBox(height: 16),
                if (localSelectedType == 'ลูกค้า') ...[
                  _buildDropdown(
                      'กลุ่มอายุหลัก',
                      localSelectedAge,
                      ageRangeOptions,
                      (val) =>
                          setDialogState(() => localSelectedAge = val!)),
                  const SizedBox(height: 16),
                  _buildQuantityControl(qtyController),
                  const SizedBox(height: 16),
                ],
                _buildTextField(descController, 'ชื่อร้าน/รายละเอียด'),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.customerGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(2))),
                    icon: const Icon(Icons.directions),
                    label: Text('นำทางด้วยแผนที่',
                        style: GoogleFonts.inter(
                            fontSize: 14, fontWeight: FontWeight.w700)),
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
                child: Text('ยกเลิก',
                    style: GoogleFonts.inter(color: AppColors.textMuted))),
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.neonGreen,
                    foregroundColor: Colors.black),
                onPressed: () async {
                  String finalQty =
                      qtyController.text.isEmpty ? '0' : qtyController.text;
                  await _updateData(shop['id'], descController.text,
                      localSelectedType, localSelectedAge, finalQty);
                  if (context.mounted) Navigator.pop(context);
                },
                child: Text('อัปเดตข้อมูล',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w800))),
          ],
        ),
      ),
    );
  }

  // --- Shared Dialog Widgets ---
  Widget _buildDropdown(String label, String value, List<String> items,
      ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: AppColors.bgSurfaceHigh,
      style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(color: AppColors.textMuted),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(2),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(2),
          borderSide: const BorderSide(color: AppColors.neonGreen),
        ),
      ),
      items: items
          .map((t) => DropdownMenuItem(value: t, child: Text(t)))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      style: GoogleFonts.inter(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(color: AppColors.textMuted),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(2),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(2),
          borderSide: const BorderSide(color: AppColors.neonGreen),
        ),
      ),
      maxLines: 2,
    );
  }

  Widget _buildQuantityControl(TextEditingController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.bgSurfaceHigh,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Column(
        children: [
          Text('จำนวนลูกค้า (คน)',
              style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                  icon: const Icon(Icons.remove_circle,
                      color: AppColors.danger, size: 36),
                  onPressed: () {
                    int c = int.tryParse(controller.text) ?? 0;
                    if (c > 0) controller.text = (c - 1).toString();
                  }),
              SizedBox(
                  width: 80,
                  child: TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppColors.neonGreen),
                      decoration: const InputDecoration(
                          border: InputBorder.none, isDense: true))),
              IconButton(
                  icon: const Icon(Icons.add_circle,
                      color: AppColors.customerGreen, size: 36),
                  onPressed: () {
                    int c = int.tryParse(controller.text) ?? 0;
                    controller.text = (c + 1).toString();
                  }),
            ],
          ),
        ],
      ),
    );
  }

  // --- Database Operations ---
  Future<bool?> _showConfirmDeleteDialog() {
    return showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                backgroundColor: AppColors.bgSurface,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                    side: const BorderSide(color: AppColors.border)),
                title: Text('ยืนยันการลบ',
                    style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800)),
                content: Text(
                    'คุณแน่ใจหรือไม่ว่าต้องการลบพิกัดนี้? ข้อมูลจะไม่สามารถกู้คืนได้',
                    style: GoogleFonts.inter(color: AppColors.textSecondary)),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text('ยกเลิก',
                          style:
                              GoogleFonts.inter(color: AppColors.textMuted))),
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.danger,
                          foregroundColor: Colors.white),
                      onPressed: () => Navigator.pop(context, true),
                      child: Text('ลบทิ้ง',
                          style:
                              GoogleFonts.inter(fontWeight: FontWeight.w800)))
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
    return Stack(
      children: [
        // Google Map (Full screen)
        GoogleMap(
          initialCameraPosition:
              CameraPosition(target: _currentCenter, zoom: 15.0),
          markers: _markers,
          style: mapDarkStyle,
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
          myLocationButtonEnabled: false,
        ),

        // --- Top Header Overlay ---
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GEOSPATIAL ENGINE',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted,
                          letterSpacing: 3.0,
                        ),
                      ),
                      Text(
                        'MARKET MAP',
                        style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _buildMapAction(Icons.search, () {
                        // Search functionality
                      }),
                      const SizedBox(width: 8),
                      _buildMapAction(Icons.layers_outlined, () {
                        setState(() => _showFilters = !_showFilters);
                      }),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // --- Filter Panel ---
        if (_showFilters)
          Positioned(
            top: 100,
            right: 20,
            child: SafeArea(
              child: Container(
                width: 200,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.bgSurface.withOpacity(0.95),
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('LAYER FILTERS',
                        style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.neonGreen,
                            letterSpacing: 2.0)),
                    const SizedBox(height: 8),
                    ..._filters.keys.map((key) => _buildFilterTile(key)),
                  ],
                ),
              ),
            ),
          ),

        // --- Location Lock (Bottom Overlay) ---
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  AppColors.bgDeep.withOpacity(0.8),
                  AppColors.bgDeep,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LOCATION LOCK',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                    letterSpacing: 3.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _locationName,
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'COORDS: ${_currentCenter.latitude.toStringAsFixed(4)}° N, ${_currentCenter.longitude.toStringAsFixed(4)}° E',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.neonGreen,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(2)),
                        ),
                        icon: const Icon(Icons.my_location, size: 18),
                        label: Text('SYNC LOCATION',
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0)),
                        onPressed: _fetchShops,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.add_location_alt,
                            color: AppColors.neonGreen),
                        onPressed: () => _showAddDialog(_currentCenter),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMapAction(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.bgSurface.withOpacity(0.9),
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Icon(icon, color: AppColors.neonGreen, size: 22),
      ),
    );
  }

  Widget _buildFilterTile(String key) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _filters[key] = !_filters[key]!;
          _applyFilter();
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: _filters[key]! ? AppColors.neonGreen : Colors.transparent,
                border: Border.all(
                    color: _filters[key]!
                        ? AppColors.neonGreen
                        : AppColors.textMuted),
                borderRadius: BorderRadius.circular(2),
              ),
              child: _filters[key]!
                  ? const Icon(Icons.check, size: 12, color: Colors.black)
                  : null,
            ),
            const SizedBox(width: 10),
            Text(key,
                style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
