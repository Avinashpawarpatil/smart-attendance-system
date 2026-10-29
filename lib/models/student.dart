class Student {
  final int? id;
  final String studentId;
  final String name;
  final String email;
  final String department;

  Student({
    this.id,
    required this.studentId,
    required this.name,
    required this.email,
    required this.department,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'student_id': studentId,
      'name': name,
      'email': email,
      'department': department,
    };
  }

  factory Student.fromMap(Map<String, dynamic> map) {
    final idVal = (map['student_id'] ?? map['studentId'] ?? map['uid'] ?? '').toString().trim();
    final nameVal = (map['name'] ?? map['full_name'] ?? '').toString().trim();
    final emailVal = (map['email'] ?? '').toString().trim();
    final deptVal = (map['department'] ?? 'Computer Science').toString().trim();

    return Student(
      id: map['id'] is int ? map['id'] as int : null,
      studentId: idVal,
      name: nameVal,
      email: emailVal,
      department: deptVal.isEmpty ? 'Computer Science' : deptVal,
    );
  }

  Student copyWith({
    int? id,
    String? studentId,
    String? name,
    String? email,
    String? department,
  }) {
    return Student(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      name: name ?? this.name,
      email: email ?? this.email,
      department: department ?? this.department,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Student &&
          runtimeType == other.runtimeType &&
          studentId == other.studentId;

  @override
  int get hashCode => studentId.hashCode;
}
