import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class CreditPage extends StatelessWidget {
  const CreditPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      appBar: AppBar(
        title: Text('ABOUT',
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w800, letterSpacing: 2.0)),
        backgroundColor: AppColors.bgDeep,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            // โลโก้แอป
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.neonGreen,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(Icons.analytics_rounded,
                  size: 50, color: Colors.black),
            ),
            const SizedBox(height: 20),
            Text('SME STRATEGY MAP',
                style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                    letterSpacing: 1.0)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.neonGreen),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text('Version 2.0.1 (Beta)',
                  style: GoogleFonts.inter(
                      color: AppColors.neonGreen,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                      letterSpacing: 1.5)),
            ),
            const SizedBox(height: 40),

            // Credit area
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(Icons.developer_board_rounded,
                      'ออกแบบและพัฒนาโดย', 'Chakrit'),
                  Padding(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      child: Divider(color: AppColors.border)),
                  _buildInfoRow(Icons.business_rounded, 'มหาวิทยาลัย',
                      'มหาวิทยาลัยเอเชียอาคเนย์ (SAU)'),
                  Padding(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      child: Divider(color: AppColors.border)),
                  _buildInfoRow(Icons.email_rounded, 'ช่องทางการติดต่อ',
                      's6752410026@sau.ac.th'),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Footer
            Text('© 2026 SAU.\nAll rights reserved.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    color: AppColors.textMuted, fontSize: 11, height: 1.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String detail) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: AppColors.neonGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(2)),
          child: Icon(icon, color: AppColors.neonGreen, size: 22),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: GoogleFonts.inter(
                      color: AppColors.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0)),
              const SizedBox(height: 4),
              Text(detail,
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.textPrimary)),
            ],
          ),
        ),
      ],
    );
  }
}
