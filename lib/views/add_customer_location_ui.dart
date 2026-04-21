import 'package:flutter/material.dart';
import '../models/customer_location.dart';
import '../services/supabase_service.dart';

class AddCustomerLocationUi extends StatefulWidget {
  const AddCustomerLocationUi({super.key});

  @override
  State<AddCustomerLocationUi> createState() => _AddCustomerLocationUiState();
}

class _AddCustomerLocationUiState extends State<AddCustomerLocationUi> {
  final SupabaseService _supabaseService = SupabaseService();

  // ตัวแปรสำหรับเลือกข้อมูล (Hardcode เบื้องต้นรอบๆ สมุทรสาครให้ก่อนค่ะ)
  String _selectedProvince = 'สมุทรสาคร';
  String _selectedDistrict = 'เมืองสมุทรสาคร';
  int _selectedFrequency = 3; // ระดับความสำคัญ 1-5

  final List<String> _provinces = [
    'สมุทรสาคร',
    'นครปฐม',
    'กรุงเทพฯ',
    'ราชบุรี'
  ];
  final List<String> _districts = [
    'เมืองสมุทรสาคร',
    'กระทุ่มแบน',
    'บ้านแพ้ว',
    'อ้อมน้อย',
    'สามพราน'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SME Map Strategy - เพิ่มย่านรวย'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('📍 ระบุพื้นที่ลูกค้า (Conversational Data)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            // เลือกจังหวัด
            DropdownButtonFormField<String>(
              initialValue: _selectedProvince,
              decoration: const InputDecoration(labelText: 'จังหวัด'),
              items: _provinces
                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
              onChanged: (val) => setState(() => _selectedProvince = val!),
            ),
            const SizedBox(height: 15),

            // เลือกอำเภอ/ย่าน
            DropdownButtonFormField<String>(
              initialValue: _selectedDistrict,
              decoration: const InputDecoration(labelText: 'อำเภอ/ย่าน'),
              items: _districts
                  .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                  .toList(),
              onChanged: (val) => setState(() => _selectedDistrict = val!),
            ),
            const SizedBox(height: 25),

            // ระดับความบ่อย (Frequency)
            const Text('ระดับความสำคัญ/ความถี่ (1-5):'),
            Slider(
              value: _selectedFrequency.toDouble(),
              min: 1,
              max: 5,
              divisions: 4,
              label: _selectedFrequency.toString(),
              onChanged: (val) =>
                  setState(() => _selectedFrequency = val.toInt()),
            ),

            const Spacer(),

            // ปุ่มบันทึก
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent),
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final nav = Navigator.of(context);
                  final newLoc = CustomerLocation(
                    province: _selectedProvince,
                    district: _selectedDistrict,
                    frequency: _selectedFrequency,
                    lastVisit: DateTime.now().toIso8601String(),
                    lat: 13.5475,
                    lng: 100.2744,
                  );

                  await _supabaseService.insertCustomerLocation(newLoc);

                  if (mounted) {
                    messenger.showSnackBar(
                      const SnackBar(content: Text('บันทึกพิกัดสำเร็จ!')),
                    );
                    nav.pop();
                  }
                },
                child: const Text('บันทึกเข้าแผนที่กลยุทธ์',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
