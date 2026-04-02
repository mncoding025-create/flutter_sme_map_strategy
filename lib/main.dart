import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// ต้องมั่นใจว่ามีไฟล์ map_page.dart อยู่ในโฟลเดอร์ views นะครับ
import 'package:flutter_sme_map_strategy/views/login_page.dart';
import 'package:flutter_sme_map_strategy/views/map_page.dart';

Future<void> main() async {
  // 1. ตรวจสอบการเชื่อมต่อกับ Native Platform
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 2. โหลดไฟล์ .env (สำหรับ API Key ต่างๆ)
    await dotenv.load(fileName: ".env");
    print("✅ .env loaded successfully");

    // 3. เริ่มต้น Supabase
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL'] ?? '',
      anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
    print("✅ Supabase initialized");
  } catch (e) {
    print("❌ Error during initialization: $e");
  }

  runApp(const MyApp());
}

// ตัวแปรลัดสำหรับเรียกใช้ Supabase Client ทั่วทั้งแอป
final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SME Map Strategy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue, // ใช้สีฟ้าเป็นธีมหลัก
        brightness: Brightness.light,
      ),
      // ด่านแรก: เช็คว่า Login หรือยัง
      home: const AuthCheckPage(),
    );
  }
}

class AuthCheckPage extends StatefulWidget {
  const AuthCheckPage({super.key});

  @override
  State<AuthCheckPage> createState() => _AuthCheckPageState();
}

class _AuthCheckPageState extends State<AuthCheckPage> {
  @override
  void initState() {
    super.initState();
    // ติดตามสถานะการเข้าสู่ระบบ
    supabase.auth.onAuthStateChange.listen((data) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = supabase.auth.currentSession;

    if (session != null) {
      // --- ส่วนหน้าจอ Dashboard เมื่อ Login สำเร็จ ---
      return Scaffold(
        appBar: AppBar(
          title: const Text('SME Strategy Dashboard'),
          centerTitle: true,
          elevation: 2,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              onPressed: () async {
                await supabase.auth.signOut();
              },
            )
          ],
        ),
        body: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 100),
              const SizedBox(height: 24),
              Text(
                'ยินดีต้อนรับคุณ Chakrit',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'บัญชี: ${session.user.email}',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 40),

              // ปุ่มนำทางไปหน้าแผนที่ (หัวใจหลักของแอปเรา)
              SizedBox(
                width: 250,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // คำสั่งเปลี่ยนหน้าไปหน้าแผนที่
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MapPage()),
                    );
                  },
                  icon: const Icon(Icons.map_outlined),
                  label: const Text(
                    'เริ่มวางแผนบนแผนที่',
                    style: TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                  ),
                ),
              ),

              const SizedBox(height: 16),
              const Text(
                'เริ่มปักหมุดจุดยุทธศาสตร์ร้านค้าของคุณได้เลย',
                style: TextStyle(fontSize: 14, color: Colors.blueGrey),
              ),
            ],
          ),
        ),
      );
    } else {
      // --- ถ้ายังไม่ได้ Login ให้ไปหน้า Login ---
      return const LoginPage();
    }
  }
}
