import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme/app_theme.dart';
import 'views/main_shell.dart';
import 'views/login_page.dart';

void main() async {
  // 1. ตรวจสอบการเชื่อมต่อกับ Flutter Engine
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 2. โหลดค่าจากไฟล์ .env (ต้องทำก่อน Initialize Supabase)
    await dotenv.load(fileName: ".env");

    // 3. เริ่มต้นระบบ Supabase ด้วยค่าจาก .env
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL'] ?? '',
      anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
    );

    debugPrint("✅ Supabase Initialized Successfully");
  } catch (e) {
    debugPrint("❌ Error Initializing: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SME Strategy Map',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const SplashPage(),
    );
  }
}

// =======================================================
// Splash / Login Page — Brutalist Dark Style
// =======================================================
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.neonGreen,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.analytics_outlined,
                    size: 60,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 32),

                // Title
                Text(
                  'SME\nSTRATEGY\nMAP',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                    height: 1.0,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'วิเคราะห์พิกัดการตลาดและกลุ่มเป้าหมาย',
                  style: GoogleFonts.inter(
                    color: AppColors.textMuted,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.neonGreen),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    'VERSION 2.0 — BRUTALIST',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: AppColors.neonGreen,
                      letterSpacing: 2.0,
                    ),
                  ),
                ),
                const SizedBox(height: 60),

                // Guest Mode Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const MainShell()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.neonGreen,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(2)),
                      elevation: 0,
                    ),
                    child: Text(
                      'เข้าใช้งานแบบ Guest',
                      style: GoogleFonts.inter(
                          fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Login Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const LoginPage()),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(2)),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    child: Text(
                      'เข้าสู่ระบบด้วย Email',
                      style: GoogleFonts.inter(
                          fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),

                const SizedBox(height: 40),
                Text(
                  'SYSTEM STATUS: READY',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                    letterSpacing: 2.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
