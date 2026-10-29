class AttendanceRecord {
  final int? id;
  final String sessionCode;
  final String studentId;
  final String studentName;
  final String courseCode;
  final String timestamp;
  final String status; // 'PRESENT', 'LATE', 'ABSENT'

  AttendanceRecord({
    this.id,
    required this.sessionCode,
    required this.studentId,
    required this.studentName,
    required this.courseCode,
    required this.timestamp,
    this.status = 'PRESENT',
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'session_code': sessionCode,
      'student_id': studentId,
      'student_name': studentName,
      'course_code': courseCode,
      'timestamp': timestamp,
      'status': status,
    };
  }

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    return AttendanceRecord(
      id: map['id'] as int?,
      sessionCode: map['session_code'] as String? ?? '',
      studentId: map['student_id'] as String? ?? '',
      studentName: map['student_name'] as String? ?? '',
      courseCode: map['course_code'] as String? ?? '',
      timestamp: map['timestamp'] as String? ?? '',
      status: map['status'] as String? ?? 'PRESENT',
    );
  }
}
