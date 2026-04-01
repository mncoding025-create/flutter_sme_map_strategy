import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_sme_map_strategy/views/login_page.dart';

Future<void> main() async {
  // 1. ตรวจสอบการเชื่อมต่อกับ Native Platform
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 2. โหลดไฟล์ .env
    await dotenv.load(fileName: ".env");
    print("✅ .env loaded successfully");

    // 3. เริ่มต้น Supabase
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL'] ?? '',
      anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
      // ตั้งค่า Auth สำหรับ Web ให้เสถียรขึ้น
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

// ตัวแปรลัดสำหรับเรียกใช้ Supabase Client
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
        colorSchemeSeed: Colors.blue,
      ),
      // เริ่มต้นที่หน้าเช็คสถานะ Login
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
    // ฟังการเปลี่ยนแปลงสถานะ Login (เช่น พอกด Magic Link ปุ๊บ ให้เปลี่ยนหน้าปั๊บ)
    supabase.auth.onAuthStateChange.listen((data) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // เช็ค Session ปัจจุบัน
    final session = supabase.auth.currentSession;

    if (session != null) {
      // --- หน้าจอหลังจาก Login สำเร็จ ---
      return Scaffold(
        appBar: AppBar(
          title: const Text('SME Dashboard'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'ออกจากระบบ',
              onPressed: () async {
                await supabase.auth.signOut();
              },
            )
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline,
                  color: Colors.green, size: 80),
              const SizedBox(height: 20),
              Text(
                'เข้าสู่ระบบสำเร็จ!',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text('คุณเข้าใช้งานด้วยอีเมล: ${session.user.email}'),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: นำทางไปหน้าแผนที่ (ที่เรากำลังจะสร้าง)
                },
                icon: const Icon(Icons.map),
                label: const Text('เริ่มวางแผนบนแผนที่'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // --- ถ้ายังไม่ Login ให้แสดงหน้า LoginPage ---
      return const LoginPage();
    }
  }
}
