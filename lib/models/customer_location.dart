class CustomerLocation {
  String? id;
  String? province; // จังหวัด
  String? district; // อำเภอ
  String? subDistrict; // ตำบล/ย่าน
  double? lat; // ละติจูดกลางของย่าน
  double? lng; // ลองจิจูดกลางของย่าน
  int? frequency; // ความถี่/ความสำคัญ (1-5)
  String? lastVisit; // วันที่บันทึกข้อมูลล่าสุด

  CustomerLocation({
    this.id,
    this.province,
    this.district,
    this.subDistrict,
    this.lat,
    this.lng,
    this.frequency,
    this.lastVisit,
  });

  // แปลงจาก JSON (ดึงจาก Supabase) มาเป็น Object ในแอป
  factory CustomerLocation.fromJson(Map<String, dynamic> json) {
    return CustomerLocation(
      id: json['id']?.toString(),
      province: json['province'],
      district: json['district'],
      subDistrict: json['sub_district'],
      lat: json['lat']?.toDouble(),
      lng: json['lng']?.toDouble(),
      frequency: json['frequency'],
      lastVisit: json['last_visit'],
    );
  }

  // แปลงจาก Object ในแอป กลับเป็น JSON (เพื่อส่งไปเก็บใน Supabase)
  Map<String, dynamic> toJson() {
    return {
      'province': province,
      'district': district,
      'sub_district': subDistrict,
      'lat': lat,
      'lng': lng,
      'frequency': frequency,
      'last_visit': lastVisit,
    };
  }
}
