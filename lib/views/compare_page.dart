import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';

// =======================================================
// Compare Page — Site Benchmarking
// Option A: ข้อมูลจริงจาก Supabase (ลูกค้า, คู่แข่ง)
// Option B: เพิ่มข้อมูลเอง (rent, traffic)
// =======================================================
class ComparePage extends StatefulWidget {
  final String selectedIndustry;
  const ComparePage({super.key, required this.selectedIndustry});

  @override
  State<ComparePage> createState() => _ComparePageState();
}

class _ComparePageState extends State<ComparePage> {
  final supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> _fetchCompareData() async {
    final List<dynamic> shops = await supabase.from('shops').select();

    // --- Group shops by "หน้าร้านเรา" (Our Stores) ---
    List<Map<String, dynamic>> storeList = [];
    List<dynamic> stores = shops
        .where((s) => (s['type']?.toString() ?? '').contains('หน้าร้านเรา'))
        .toList();

    if (stores.isEmpty) {
      // ถ้ายังไม่มีสาขา → สร้าง default location
      storeList.add({
        'name': 'LOCATION 1',
        'description': 'ยังไม่มีสาขา — กรุณาเพิ่มหน้าร้านบนแผนที่',
        'lat': 13.5475,
        'lng': 100.2744,
        'customerCount': 0,
        'competitorCount': 0,
        'supplierCount': 0,
        'score': 0,
        'rent': '-',
        'traffic': 'N/A',
      });
      return storeList;
    }

    for (var store in stores) {
      double storeLat = double.tryParse(store['latitude'].toString()) ?? 0;
      double storeLng = double.tryParse(store['longitude'].toString()) ?? 0;
      String storeName =
          store['description']?.toString() ?? 'สาขา ${storeList.length + 1}';

      // นับ data points ในรัศมี 2 km
      int nearbyCustomers = 0;
      int nearbyCompetitors = 0;
      int nearbySuppliers = 0;

      for (var shop in shops) {
        if (shop['id'] == store['id']) continue;
        double lat = double.tryParse(shop['latitude'].toString()) ?? 0;
        double lng = double.tryParse(shop['longitude'].toString()) ?? 0;
        String type = (shop['type']?.toString() ?? '').trim();

        double distance = _calculateDistance(storeLat, storeLng, lat, lng);

        if (distance <= 2.0) {
          int qty = int.tryParse(shop['quantity']?.toString() ?? '0') ?? 0;
          if (type.contains('ลูกค้า')) {
            nearbyCustomers += qty > 0 ? qty : 1;
          } else if (type.contains('คู่แข่ง')) {
            nearbyCompetitors++;
          } else if (type.contains('ซัพพลายเออร์')) {
            nearbySuppliers++;
          }
        }
      }

      // Calculate score per store
      double cScore = (nearbyCustomers / 50.0).clamp(0, 1) * 40;
      double compScore = nearbyCompetitors == 0
          ? 30
          : ((1 - nearbyCompetitors / (nearbyCompetitors + 1)) * 30);
      double supScore = nearbySuppliers > 0 ? 15 : 0;
      int finalScore =
          (cScore + compScore + supScore + 15).round().clamp(0, 100);

      // Traffic estimation
      String trafficLevel = 'Low';
      if (nearbyCustomers > 50) {
        trafficLevel = 'High';
      } else if (nearbyCustomers > 20) {
        trafficLevel = 'Medium';
      }

      storeList.add({
        'name': storeName.toUpperCase(),
        'description': store['description'] ?? '',
        'lat': storeLat,
        'lng': storeLng,
        'customerCount': nearbyCustomers,
        'competitorCount': nearbyCompetitors,
        'supplierCount': nearbySuppliers,
        'score': finalScore,
        'rent': store['rent']?.toString() ?? '-',
        'traffic': trafficLevel,
      });
    }

    // Sort by score descending
    storeList.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));
    return storeList;
  }

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295;
    var a = 0.5 -
        math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) *
            math.cos(lat2 * p) *
            (1 - math.cos((lon2 - lon1) * p)) /
            2;
    return 12742 * math.asin(math.sqrt(a));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchCompareData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.neonGreen),
            );
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Text('เกิดข้อผิดพลาด',
                  style: GoogleFonts.inter(color: AppColors.textMuted)),
            );
          }

          final storeList = snapshot.data!;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Header ---
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SITE BENCHMARKING',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted,
                          letterSpacing: 3.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'COMPARE\nLOCATIONS',
                        style: GoogleFonts.inter(
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                          height: 1.0,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'เปรียบเทียบสถานที่จากข้อมูลจริง',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.neonGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // --- Compare Cards ---
                ...storeList.asMap().entries.map((entry) {
                  final storeData = entry.value;
                  return _CompareCard(
                    storeName: storeData['name'] as String,
                    score: storeData['score'] as int,
                    customerCount: storeData['customerCount'] as int,
                    competitorCount: storeData['competitorCount'] as int,
                    supplierCount: storeData['supplierCount'] as int,
                    rent: storeData['rent'] as String,
                    traffic: storeData['traffic'] as String,
                    isTopRanked: entry.key == 0 && storeList.length > 1,
                  );
                }),

                const SizedBox(height: 16),

                // --- Add Custom Location Button ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: GestureDetector(
                    onTap: () => _showAddCompareDialog(),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.bgSurface,
                        border: Border.all(
                            color: AppColors.border, style: BorderStyle.solid),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_circle_outline,
                              color: AppColors.neonGreen, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            'เพิ่มทำเลเปรียบเทียบ',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.neonGreen,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // --- Legend ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.bgSurface,
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'HOW SCORES WORK',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.neonGreen,
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildLegendRow(
                            'Customer Base', '40%', 'จำนวนลูกค้าในรัศมี 2 km'),
                        _buildLegendRow('Competition Index', '30%',
                            'ยิ่งมีคู่แข่งน้อย = Score สูง'),
                        _buildLegendRow(
                            'Supply Chain', '15%', 'มีซัพพลายเออร์ใกล้ = ดี'),
                        _buildLegendRow('Base Score', '15%', 'คะแนนพื้นฐาน'),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLegendRow(String label, String weight, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            padding: const EdgeInsets.symmetric(vertical: 2),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.neonGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Text(weight,
                style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.neonGreen)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                Text(desc,
                    style: GoogleFonts.inter(
                        fontSize: 10, color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Dialog: เพิ่มทำเลเปรียบเทียบ (Option B) ---
  void _showAddCompareDialog() {
    final descCtrl = TextEditingController();
    final latCtrl = TextEditingController();
    final lngCtrl = TextEditingController();
    final rentCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: AppColors.border),
        ),
        title: Text('เพิ่มทำเลเปรียบเทียบ',
            style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogTextField(descCtrl, 'ชื่อสถานที่', Icons.place),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                      child: _dialogTextField(latCtrl, 'Latitude', null,
                          inputType: TextInputType.number)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _dialogTextField(lngCtrl, 'Longitude', null,
                          inputType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 12),
              _dialogTextField(rentCtrl, 'ค่าเช่า (บาท/เดือน)', Icons.payments,
                  inputType: TextInputType.number),
              const SizedBox(height: 8),
              Text(
                'ระบบจะคำนวณ Score จากข้อมูลลูกค้าและคู่แข่งในรัศมี 2 km',
                style:
                    GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ยกเลิก',
                style: GoogleFonts.inter(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.neonGreen,
                foregroundColor: Colors.black),
            onPressed: () async {
              if (descCtrl.text.isEmpty) return;
              try {
                await supabase.from('shops').insert({
                  'description': descCtrl.text,
                  'type': 'หน้าร้านเรา',
                  'latitude': double.tryParse(latCtrl.text) ?? 13.5475,
                  'longitude': double.tryParse(lngCtrl.text) ?? 100.2744,
                  'quantity': '0',
                });
                if (context.mounted) {
                  Navigator.pop(context);
                  setState(() {}); // Refresh
                }
              } catch (e) {
                debugPrint('Error adding compare location: $e');
              }
            },
            child: Text('เพิ่มทำเล',
                style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Widget _dialogTextField(
      TextEditingController ctrl, String label, IconData? icon,
      {TextInputType? inputType}) {
    return TextField(
      controller: ctrl,
      keyboardType: inputType,
      style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12),
        prefixIcon: icon != null
            ? Icon(icon, color: AppColors.textMuted, size: 18)
            : null,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(2),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(2),
          borderSide: const BorderSide(color: AppColors.neonGreen),
        ),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }
}

// =======================================================
// Compare Card Widget (Brutalist Style)
// =======================================================
class _CompareCard extends StatelessWidget {
  final String storeName;
  final int score;
  final int customerCount;
  final int competitorCount;
  final int supplierCount;
  final String rent;
  final String traffic;
  final bool isTopRanked;

  const _CompareCard({
    required this.storeName,
    required this.score,
    required this.customerCount,
    required this.competitorCount,
    required this.supplierCount,
    required this.rent,
    required this.traffic,
    required this.isTopRanked,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        border: Border.all(
          color: isTopRanked ? AppColors.neonGreen : AppColors.border,
          width: isTopRanked ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Score badge + name
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Score
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isTopRanked
                        ? AppColors.neonGreen
                        : AppColors.bgSurfaceHigh,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    '$score',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: isTopRanked ? Colors.black : AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Name + desc
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        storeName,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isTopRanked) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.neonGreen.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Text(
                            '★ TOP RANKED',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: AppColors.neonGreen,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Stats row
          Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                _buildStatChip(
                    'CUSTOMERS', '$customerCount', AppColors.customerGreen),
                const SizedBox(width: 8),
                _buildStatChip(
                    'COMPETITORS', '$competitorCount', AppColors.danger),
                const SizedBox(width: 8),
                _buildStatChip('RENT', rent, AppColors.warning),
                const SizedBox(width: 8),
                _buildStatChip('TRAFFIC', traffic, AppColors.info),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: AppColors.bgSurfaceHigh,
          borderRadius: BorderRadius.circular(2),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 7,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
                letterSpacing: 1.0,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
