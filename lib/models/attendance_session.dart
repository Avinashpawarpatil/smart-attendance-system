import 'dart:convert';

class AttendanceSession {
  final int? id;
  final String sessionCode;
  final String courseCode;
  final String courseName;
  final String createdAt;
  final String expiresAt;
  final int expiryMinutes;
  final bool isActive;

  AttendanceSession({
    this.id,
    required this.sessionCode,
    required this.courseCode,
    required this.courseName,
    required this.createdAt,
    this.expiresAt = '',
    this.expiryMinutes = 10,
    this.isActive = true,
  });

  bool get isExpired {
    if (!isActive) return true;
    if (expiresAt.isEmpty) return false;
    try {
      final expiryDate = DateTime.parse(expiresAt);
      return DateTime.now().isAfter(expiryDate);
    } catch (_) {
      return false;
    }
  }

  int get remainingSeconds {
    if (expiresAt.isEmpty) return 0;
    try {
      final expiryDate = DateTime.parse(expiresAt);
      final diff = expiryDate.difference(DateTime.now()).inSeconds;
      return diff > 0 ? diff : 0;
    } catch (_) {
      return 0;
    }
  }

  /// Payload format encoded into the QR code
  String toQrPayload() {
    return jsonEncode({
      'type': 'ATTENDANCE_SESSION',
      'session_code': sessionCode,
      'course_code': courseCode,
      'course_name': courseName,
      'created_at': createdAt,
      'expires_at': expiresAt,
      'expiry_minutes': expiryMinutes,
    });
  }

  /// Parses payload scanned from QR code
  static Map<String, dynamic>? parseQrPayload(String payload) {
    try {
      final data = jsonDecode(payload);
      if (data is Map && data['type'] == 'ATTENDANCE_SESSION') {
        return {
          'session_code': data['session_code']?.toString() ?? '',
          'course_code': data['course_code']?.toString() ?? '',
          'course_name': data['course_name']?.toString() ?? '',
          'created_at': data['created_at']?.toString() ?? '',
          'expires_at': data['expires_at']?.toString() ?? '',
          'expiry_minutes': int.tryParse(data['expiry_minutes']?.toString() ?? '10') ?? 10,
        };
      }
    } catch (_) {}
    return null;
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'session_code': sessionCode,
      'course_code': courseCode,
      'course_name': courseName,
      'created_at': createdAt,
      'expires_at': expiresAt,
      'expiry_minutes': expiryMinutes,
      'is_active': isActive ? 1 : 0,
    };
  }

  factory AttendanceSession.fromMap(Map<String, dynamic> map) {
    return AttendanceSession(
      id: map['id'] as int?,
      sessionCode: map['session_code'] as String? ?? '',
      courseCode: map['course_code'] as String? ?? '',
      courseName: map['course_name'] as String? ?? '',
      createdAt: map['created_at'] as String? ?? '',
      expiresAt: map['expires_at'] as String? ?? '',
      expiryMinutes: map['expiry_minutes'] as int? ?? 10,
      isActive: (map['is_active'] as int? ?? 1) == 1,
    );
  }
}
