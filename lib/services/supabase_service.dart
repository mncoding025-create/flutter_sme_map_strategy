import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/customer_location.dart';
import 'dart:math' as math;

class SupabaseService {
  final supabase = Supabase.instance.client;

  // ==========================================
  // ส่วนที่ 1: SME Map Strategy (ระบบแผนที่กลยุทธ์)
  // ==========================================

  // 1. ดึงข้อมูลพิกัดลูกค้าทั้งหมดจากตาราง customer_locations
  Future<List<CustomerLocation>> getCustomerLocations() async {
    try {
      final data = await supabase
          .from('customer_locations')
          .select('*')
          .order('last_visit', ascending: false);

      return data.map((item) => CustomerLocation.fromJson(item)).toList();
    } catch (e) {
      debugPrint('Error fetching locations: $e');
      return [];
    }
  }

  // 2. บันทึกข้อมูลพิกัดลูกค้าใหม่ลงใน Database
  Future<void> insertCustomerLocation(CustomerLocation customer) async {
    try {
      await supabase.from('customer_locations').insert(customer.toJson());
    } catch (e) {
      debugPrint('เกิดข้อผิดพลาดในการบันทึกพิกัด: $e');
      rethrow;
    }
  }

  // 3. ฟังก์ชันสำหรับฟีเจอร์ "เปรียบเทียบสาขา" (คำนวณจำนวนลูกค้าในรัศมี)
  // lat, lng = พิกัดจุดที่เล็งไว้, radiusKm = รัศมีที่ต้องการเช็ค (กิโลเมตร)
  Future<int> countCustomersInRadius(
      double lat, double lng, double radiusKm) async {
    final allLocations = await getCustomerLocations();
    int count = 0;

    for (var loc in allLocations) {
      if (loc.lat != null && loc.lng != null) {
        double distance = _calculateDistance(lat, lng, loc.lat!, loc.lng!);
        if (distance <= radiusKm) {
          // เราสามารถบวกน้ำหนักตามความถี่ (frequency) ของลูกค้าเข้าไปได้ด้วยนะคะ
          count++;
        }
      }
    }
    return count;
  }

  // สูตรคำนวณระยะทางระหว่างพิกัด 2 จุด (Haversine Formula)
  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295;
    var a = 0.5 -
        math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) *
            math.cos(lat2 * p) *
            (1 - math.cos((lon2 - lon1) * p)) /
            2;
    return 12742 * math.asin(math.sqrt(a));
  }

  // ==========================================
  // ส่วนที่ 2: Task Manager (ระบบเดิมของคุณชาคริต)
  // ==========================================

  // (ตรงนี้ใส่โค้ดจัดการ Task เดิมที่คุณชาคริตมีอยู่ได้เลยค่ะ
  // เช่น getTasks, insertTask, updateTask)

  Future<List<Map<String, dynamic>>> getTasks() async {
    try {
      final data = await supabase.from('tasks').select('*').order('created_at');
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('Error fetching tasks: $e');
      return [];
    }
  }
}
