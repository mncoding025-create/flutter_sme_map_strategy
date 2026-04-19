import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';

// =======================================================
// Insights Page — Demographics + Compatibility Score
// คำนวณจากข้อมูลจริงใน Supabase
// =======================================================
class InsightsPage extends StatefulWidget {
  final String selectedIndustry;
  const InsightsPage({super.key, required this.selectedIndustry});

  @override
  State<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends State<InsightsPage> {
  final supabase = Supabase.instance.client;

  Future<Map<String, dynamic>> _fetchInsightsData() async {
    final List<dynamic> shops = await supabase.from('shops').select();

    int totalCustomers = 0;
    int totalPins = shops.length;
    int countCompetitor = 0;
    int countStore = 0;
    int countSupplier = 0;

    Map<String, int> ageData = {
      'ไม่ระบุ': 0,
      '15-25 ปี': 0,
      '26-40 ปี': 0,
      '41-60 ปี': 0,
      '60 ปีขึ้นไป': 0,
    };

    for (var shop in shops) {
      String type = (shop['type']?.toString() ?? '').trim();
      int qty = int.tryParse(shop['quantity']?.toString() ?? '0') ?? 0;
      String age = (shop['age_range']?.toString() ?? 'ไม่ระบุ').trim();

      if (type.contains('ลูกค้า')) {
        totalCustomers += qty;
        if (ageData.containsKey(age)) ageData[age] = ageData[age]! + qty;
      } else if (type.contains('คู่แข่ง')) {
        countCompetitor++;
      } else if (type.contains('หน้าร้านเรา')) {
        countStore++;
      } else if (type.contains('ซัพพลายเออร์')) {
        countSupplier++;
      }
    }

    // --- Compatibility Score Calculation ---
    // สูตร: ลูกค้า (40%) + กลุ่มอายุตรงเป้า (30%) + สัดส่วนคู่แข่ง (30%)
    double customerScore = (totalCustomers / 100.0).clamp(0, 1) * 40;

    // กลุ่มอายุหลัก (26-40 = target segment)
    int targetAgeCount = ageData['26-40 ปี'] ?? 0;
    double ageScore = totalCustomers > 0
        ? (targetAgeCount / totalCustomers) * 30
        : 0;

    // สัดส่วนคู่แข่งต่อร้านเรา (ยิ่งน้อยยิ่งดี)
    double competitorRatio = countStore > 0
        ? (countCompetitor / (countStore + countCompetitor))
        : (countCompetitor > 0 ? 1.0 : 0.0);
    double competitorScore = (1 - competitorRatio) * 30;

    int compatibilityScore =
        (customerScore + ageScore + competitorScore).round().clamp(0, 100);

    String fitStatus = 'NEEDS WORK';
    if (compatibilityScore >= 80) {
      fitStatus = 'EXCELLENT MATCH';
    } else if (compatibilityScore >= 60) {
      fitStatus = 'GOOD FIT';
    } else if (compatibilityScore >= 40) {
      fitStatus = 'MODERATE';
    }

    // Demographics percentages
    Map<String, double> agePercentages = {};
    for (var entry in ageData.entries) {
      agePercentages[entry.key] = totalCustomers > 0
          ? (entry.value / totalCustomers * 100)
          : 0;
    }

    return {
      'totalCustomers': totalCustomers,
      'totalPins': totalPins,
      'countCompetitor': countCompetitor,
      'countStore': countStore,
      'countSupplier': countSupplier,
      'ageData': ageData,
      'agePercentages': agePercentages,
      'compatibilityScore': compatibilityScore,
      'fitStatus': fitStatus,
    };
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<Map<String, dynamic>>(
        future: _fetchInsightsData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.neonGreen),
            );
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล',
                  style: GoogleFonts.inter(color: AppColors.textMuted)),
            );
          }

          final data = snapshot.data!;
          final agePercentages = data['agePercentages'] as Map<String, double>;
          final int score = data['compatibilityScore'] as int;
          final String fitStatus = data['fitStatus'] as String;

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
                        'SITE REPORT',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted,
                          letterSpacing: 3.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'LOCATION\nINSIGHTS',
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
                        'วิเคราะห์ข้อมูลเชิงพื้นที่จากฐานข้อมูลจริง',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.neonGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // --- KPI Stats Row ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      _buildMiniStat('CUSTOMERS', '${data['totalCustomers']}',
                          AppColors.customerGreen),
                      const SizedBox(width: 12),
                      _buildMiniStat(
                          'PINS', '${data['totalPins']}', AppColors.info),
                      const SizedBox(width: 12),
                      _buildMiniStat('COMPETITORS',
                          '${data['countCompetitor']}', AppColors.danger),
                      const SizedBox(width: 12),
                      _buildMiniStat(
                          'STORES', '${data['countStore']}', AppColors.storeBlue),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // --- Demographics Section ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.bgSurface,
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DEMOGRAPHICS BREAKDOWN',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.neonGreen,
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildDemographicRow(
                            'GEN Z (15-25)', agePercentages['15-25 ปี'] ?? 0,
                            'กลุ่มนักศึกษาและวัยเริ่มทำงาน'),
                        _buildDemographicRow(
                            'MILLENNIALS (26-40)',
                            agePercentages['26-40 ปี'] ?? 0,
                            'กลุ่มกำลังซื้อสูง — Target Segment'),
                        _buildDemographicRow(
                            'ESTABLISHED (41-60)',
                            agePercentages['41-60 ปี'] ?? 0,
                            'กลุ่มผู้บริหารและเจ้าของกิจการ'),
                        _buildDemographicRow(
                            'SENIOR (60+)', agePercentages['60 ปีขึ้นไป'] ?? 0,
                            'กลุ่มผู้สูงอายุ'),
                        _buildDemographicRow(
                            'UNKNOWN', agePercentages['ไม่ระบุ'] ?? 0,
                            'ไม่ระบุกลุ่มอายุ'),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // --- Compatibility Score ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 32),
                    decoration: BoxDecoration(
                      color: AppColors.neonGreen,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'OVERALL COMPATIBILITY',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.black.withOpacity(0.5),
                            letterSpacing: 3.0,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '$score%',
                          style: GoogleFonts.inter(
                            fontSize: 80,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'MARKET FIT STATUS',
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black.withOpacity(0.5),
                                  letterSpacing: 2.0,
                                ),
                              ),
                              Text(
                                fitStatus,
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // --- Score Breakdown ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.bgSurface,
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SCORE BREAKDOWN',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.neonGreen,
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildScoreRow('Customer Base (40%)',
                            '${((data['totalCustomers'] as int) / 100.0).clamp(0, 1).toStringAsFixed(0)}'),
                        _buildScoreRow('Target Age Match (30%)',
                            '${data['totalCustomers'] > 0 ? ((data['ageData']['26-40 ปี'] ?? 0) / data['totalCustomers'] * 100).toStringAsFixed(0) : 0}%'),
                        _buildScoreRow('Competition Index (30%)',
                            '${data['countStore'] > 0 ? ((1 - data['countCompetitor'] / (data['countStore'] + data['countCompetitor'])) * 100).toStringAsFixed(0) : 0}%'),
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

  Widget _buildMiniStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
                letterSpacing: 1.0,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDemographicRow(String label, double percentage, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${percentage.toStringAsFixed(0)}%',
                    style: GoogleFonts.inter(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Text(
                desc,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: AppColors.textMuted,
                ),
                textAlign: TextAlign.right,
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Progress bar
          Container(
            width: double.infinity,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.bgSurfaceHigh,
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (percentage / 100).clamp(0, 1),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.neonGreen,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Divider(color: AppColors.border, height: 1),
        ],
      ),
    );
  }

  Widget _buildScoreRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500)),
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
