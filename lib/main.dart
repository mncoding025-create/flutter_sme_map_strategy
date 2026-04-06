import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // ตัวอ่านไฟล์ .env
import 'views/map_page.dart'; // เช็ค Path ให้ตรงกับโฟลเดอร์ของคุณ

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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[900]!, Colors.blue[600]!],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.analytics_outlined,
                size: 100, color: Colors.white),
            const SizedBox(height: 24),
            const Text(
              'SME Strategy Map',
              style: TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const Text(
              'วิเคราะห์พิกัดการตลาดและกลุ่มเป้าหมาย',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 60),

            // --- ปุ่มเข้าใช้งานแบบ Guest (ทางลัดเข้าหน้าแผนที่) ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const MapPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blue[900],
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                  elevation: 5,
                ),
                child: const Text(
                  'เข้าใช้งานแบบ Guest (ทดสอบระบบ)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 20),
            const Text(
              'ระบบเชื่อมต่อกับ Supabase Database เรียบร้อยแล้ว',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
