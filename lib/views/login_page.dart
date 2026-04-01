import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  bool _isLoading = false;

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกอีเมลก่อนครับ')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // ส่ง Magic Link ไปที่ Email
      await Supabase.instance.client.auth.signInWithOtp(
        email: email,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ส่ง Magic Link เรียบร้อย! เช็คอีเมลของคุณเพื่อเข้าสู่ระบบนะ'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose(); // คืน Memory เมื่อไม่ใช้หน้าจอแล้ว
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SME Map Strategy'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView( // ป้องกันหน้าจอล้นเวลาเปิดคีย์บอร์ด
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, // แก้เป็นอันนี้แล้วครับ
              children: [
                const Icon(Icons.map_rounded, size: 100, color: Colors.blue),
                const SizedBox(height: 24),
                const Text(
                  'ยินดีต้อนรับ',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const Text(
                  'เข้าสู่ระบบเพื่อวางแผนกลยุทธ์ SME',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Email Address',
                    hintText: 'example@email.com',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading 
                      ? const SizedBox(
                          width: 20, 
                          height: 20, 
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        ) 
                      : const Text('ส่ง Magic Link', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'เราจะส่งลิงก์สำหรับเข้าสู่ระบบไปที่อีเมลของคุณ\nโดยไม่ต้องใช้รหัสผ่าน',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}