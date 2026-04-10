import 'package:flutter/material.dart';
import 'map_page.dart'; // ดึงโทนสี AppColors มาใช้

class CreditPage extends StatelessWidget {
  const CreditPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgGrey,
      appBar: AppBar(
        title: const Text('เกี่ยวกับระบบ',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.navyDeep,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            // โลโก้แอป
            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.grey.withOpacity(0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 10))
                  ]),
              child: const Icon(Icons.business_center_rounded,
                  size: 70, color: AppColors.navyDeep),
            ),
            const SizedBox(height: 25),
            const Text('SME Strategy Map',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppColors.navyDeep)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                  color: AppColors.azureLight,
                  borderRadius: BorderRadius.circular(20)),
              child: const Text('Version 2.0.1 (Beta)',
                  style: TextStyle(
                      color: AppColors.accentBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
            ),
            const SizedBox(height: 40),

            // การ์ดข้อมูลผู้พัฒนา
            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.grey.withOpacity(0.08),
                        blurRadius: 15,
                        offset: const Offset(0, 5))
                  ]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(Icons.developer_board_rounded,
                      'ออกแบบและพัฒนาโดย', 'Chakrit'),
                  const Padding(
                      padding: EdgeInsets.symmetric(vertical: 15),
                      child: Divider()),
                  _buildInfoRow(Icons.business_rounded, 'มหาวิทยาลัย',
                      'มหาวิทยาลัยเอเชียอาคเนย์ Southeast Asia University (SAU)'),
                  const Padding(
                      padding: EdgeInsets.symmetric(vertical: 15),
                      child: Divider()),

                  // 🌟 เพิ่มช่องทางติดต่อผ่าน Email ตรงนี้ครับ
                  _buildInfoRow(Icons.email_rounded, 'ช่องทางการติดต่อ',
                      's6752410026@sau.ac.th'),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Footer
            const Text('© 2026 SAU.\nAll rights reserved.',
                textAlign: TextAlign.center,
                style:
                    TextStyle(color: Colors.grey, fontSize: 12, height: 1.5)),
          ],
        ),
      ),
    );
  }

  // Widget สำหรับสร้างแถวข้อมูลให้ดูสะอาดตา
  Widget _buildInfoRow(IconData icon, String title, String detail) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: AppColors.azureLight.withOpacity(0.5),
              borderRadius: BorderRadius.circular(15)),
          child: Icon(icon, color: AppColors.accentBlue, size: 24),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              // ปรับขนาด font ลงนิดนึงเผื่อชื่อมหาลัยหรืออีเมลยาวเกินไป
              Text(detail,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.navyDeep)),
            ],
          ),
        ),
      ],
    );
  }
}
