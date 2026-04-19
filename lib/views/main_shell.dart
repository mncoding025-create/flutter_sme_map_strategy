import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'wizard_page.dart';
import 'map_page.dart';
import 'insights_page.dart';
import 'compare_page.dart';

// =======================================================
// MainShell — Bottom Navigation (4 Tabs)
// =======================================================
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  String _selectedIndustry = 'coffee_shop';

  void _onIndustrySelected(String industryId) {
    setState(() {
      _selectedIndustry = industryId;
      _currentIndex = 1; // ไปหน้า Maps อัตโนมัติหลังเลือก
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      WizardPage(
        selectedIndustry: _selectedIndustry,
        onIndustrySelected: _onIndustrySelected,
      ),
      MapPage(selectedIndustry: _selectedIndustry),
      InsightsPage(selectedIndustry: _selectedIndustry),
      ComparePage(selectedIndustry: _selectedIndustry),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: AppColors.bgDeep,
          selectedItemColor: AppColors.neonGreen,
          unselectedItemColor: AppColors.textMuted,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedLabelStyle: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.0,
          ),
          unselectedLabelStyle: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_rounded),
              activeIcon: Icon(Icons.grid_view_rounded),
              label: 'WIZARD',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined),
              activeIcon: Icon(Icons.map),
              label: 'MAPS',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_rounded),
              activeIcon: Icon(Icons.bar_chart_rounded),
              label: 'INSIGHTS',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.compare_arrows_rounded),
              activeIcon: Icon(Icons.compare_arrows_rounded),
              label: 'COMPARE',
            ),
          ],
        ),
      ),
    );
  }
}
