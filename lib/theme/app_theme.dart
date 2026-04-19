import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// =======================================================
// SME Strategy Map — Brutalist Dark Theme
// =======================================================

class AppColors {
  // Primary Accent (Neon Green)
  static const Color neonGreen = Color(0xFFD1FF26);
  static const Color neonGreenDim = Color(0xFF8FAF1A);

  // Backgrounds
  static const Color bgDeep = Color(0xFF0A0A0A);
  static const Color bgSurface = Color(0xFF141414);
  static const Color bgSurfaceHigh = Color(0xFF1A1A1A);
  static const Color bgCard = Color(0xFF1A1A1A);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF999999);
  static const Color textMuted = Color(0xFF666666);

  // Borders (Brutalist)
  static const Color border = Color(0xFF222222);
  static const Color borderLight = Color(0xFF333333);

  // Status Colors
  static const Color success = Color(0xFF66BB6A);
  static const Color warning = Color(0xFFFFAB40);
  static const Color danger = Color(0xFFEF5350);
  static const Color info = Color(0xFF42A5F5);

  // Pin/Marker Colors (เก็บไว้ใช้ต่อจาก original)
  static const Color compRed = Color(0xFFEF5350);
  static const Color storeBlue = Color(0xFF42A5F5);
  static const Color customerGreen = Color(0xFF66BB6A);
  static const Color supplierOrange = Color(0xFFFF9800);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bgDeep,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.neonGreen,
        onPrimary: Colors.black,
        surface: AppColors.bgSurface,
        onSurface: AppColors.textPrimary,
      ),
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.dark().textTheme,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bgDeep,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: 1.5,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.bgDeep,
        selectedItemColor: AppColors.neonGreen,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: AppColors.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(2),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.neonGreen,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(2),
          ),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
      ),
    );
  }
}

// =======================================================
// Google Maps Dark Style JSON
// =======================================================
const String mapDarkStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#212121"}]},
  {"elementType":"labels.icon","stylers":[{"visibility":"off"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#757575"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#212121"}]},
  {"featureType":"administrative","elementType":"geometry","stylers":[{"color":"#757575"}]},
  {"featureType":"administrative.country","elementType":"labels.text.fill","stylers":[{"color":"#9e9e9e"}]},
  {"featureType":"administrative.land_parcel","stylers":[{"visibility":"off"}]},
  {"featureType":"administrative.locality","elementType":"labels.text.fill","stylers":[{"color":"#bdbdbd"}]},
  {"featureType":"poi","elementType":"labels.text.fill","stylers":[{"color":"#757575"}]},
  {"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#181818"}]},
  {"featureType":"poi.park","elementType":"labels.text.fill","stylers":[{"color":"#616161"}]},
  {"featureType":"poi.park","elementType":"labels.text.stroke","stylers":[{"color":"#1b1b1b"}]},
  {"featureType":"road","elementType":"geometry.fill","stylers":[{"color":"#2c2c2c"}]},
  {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#8a8a8a"}]},
  {"featureType":"road.arterial","elementType":"geometry","stylers":[{"color":"#373737"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#3c3c3c"}]},
  {"featureType":"road.highway.controlled_access","elementType":"geometry","stylers":[{"color":"#4e4e4e"}]},
  {"featureType":"road.local","elementType":"labels.text.fill","stylers":[{"color":"#616161"}]},
  {"featureType":"transit","elementType":"labels.text.fill","stylers":[{"color":"#757575"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#000000"}]},
  {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#3d3d3d"}]}
]
''';

// =======================================================
// ข้อมูลคงที่ (ย้ายจาก map_page.dart เพื่อให้ทุกหน้าใช้ได้)
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

// Wizard industry types
const List<Map<String, dynamic>> industryTypes = [
  {
    'id': 'coffee_shop',
    'title': 'COFFEE SHOP',
    'titleTh': 'ร้านกาแฟ',
    'desc': 'วิเคราะห์ foot traffic, ชุมชนคนรุ่นใหม่, และพื้นที่ใกล้ออฟฟิศ',
    'icon': 0xe1a4, // Icons.coffee
  },
  {
    'id': 'retail',
    'title': 'RETAIL BOUTIQUE',
    'titleTh': 'ร้านค้าปลีก',
    'desc': 'วิเคราะห์กลุ่มรายได้สูง, ย่านหรู, และความสะดวกในการเดินทาง',
    'icon': 0xe59c, // Icons.storefront
  },
  {
    'id': 'services',
    'title': 'PROFESSIONAL SERVICES',
    'titleTh': 'ธุรกิจบริการ',
    'desc': 'วิเคราะห์ความใกล้ออฟฟิศ, การเข้าถึง, และที่จอดรถ',
    'icon': 0xe0af, // Icons.business_center
  },
  {
    'id': 'restaurant',
    'title': 'RESTAURANT',
    'titleTh': 'ร้านอาหาร',
    'desc': 'วิเคราะห์ความหนาแน่นประชากร, คู่แข่ง, และกลุ่มอายุ',
    'icon': 0xe56c, // Icons.restaurant
  },
];
