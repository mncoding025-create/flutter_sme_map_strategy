import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

// =======================================================
// Wizard Page — เลือกประเภทธุรกิจ (Step 01)
// =======================================================
class WizardPage extends StatelessWidget {
  final String selectedIndustry;
  final ValueChanged<String> onIndustrySelected;

  const WizardPage({
    super.key,
    required this.selectedIndustry,
    required this.onIndustrySelected,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header ---
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 30, 24, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.neonGreen,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: const Icon(
                          Icons.analytics_rounded,
                          color: Colors.black,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'SME STRATEGY MAP',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ],
                  ),
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.bgSurfaceHigh,
                    child: Icon(Icons.person, color: AppColors.textMuted, size: 20),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // --- Title Section ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'WIZARD JOURNEY 2026',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                      letterSpacing: 3.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'IDENTIFY\nINDUSTRY',
                    style: GoogleFonts.inter(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                      height: 1.0,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'ขั้นตอนที่ 01: ระบุประเภทธุรกิจของคุณ',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.neonGreen,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // --- Industry Cards ---
            ...industryTypes.asMap().entries.map((entry) {
              final int index = entry.key;
              final Map<String, dynamic> industry = entry.value;
              final bool isSelected = selectedIndustry == industry['id'];

              return _IndustryCard(
                index: index + 1,
                title: industry['title'] as String,
                titleTh: industry['titleTh'] as String,
                description: industry['desc'] as String,
                iconCode: industry['icon'] as int,
                isSelected: isSelected,
                onTap: () => onIndustrySelected(industry['id'] as String),
              );
            }),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// =======================================================
// Industry Selection Card (Brutalist Style)
// =======================================================
class _IndustryCard extends StatelessWidget {
  final int index;
  final String title;
  final String titleTh;
  final String description;
  final int iconCode;
  final bool isSelected;
  final VoidCallback onTap;

  const _IndustryCard({
    required this.index,
    required this.title,
    required this.titleTh,
    required this.description,
    required this.iconCode,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.bgSurfaceHigh : AppColors.bgSurface,
          border: Border.all(
            color: isSelected ? AppColors.neonGreen : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: index + icon
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '0$index',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.neonGreen
                        : AppColors.bgSurfaceHigh,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Icon(
                    IconData(iconCode, fontFamily: 'MaterialIcons'),
                    color: isSelected ? Colors.black : AppColors.textMuted,
                    size: 22,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Title
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              titleTh,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 12),

            // Description
            Text(
              description,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textMuted,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 16),

            // Active Selector Bar
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: isSelected ? AppColors.neonGreen : AppColors.border,
                    width: isSelected ? 2 : 1,
                  ),
                ),
              ),
              child: Text(
                isSelected ? 'SELECTED' : 'ACTIVE SELECTOR',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? AppColors.neonGreen : AppColors.textMuted,
                  letterSpacing: 3.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
