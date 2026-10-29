class Course {
  final int? id;
  final String code;
  final String name;
  final String instructor;

  Course({
    this.id,
    required this.code,
    required this.name,
    required this.instructor,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'code': code,
      'name': name,
      'instructor': instructor,
    };
  }

  factory Course.fromMap(Map<String, dynamic> map) {
    final codeVal = (map['code'] ?? map['course_code'] ?? '').toString().trim();
    final nameVal = (map['name'] ?? map['course_name'] ?? '').toString().trim();
    final instructorVal = (map['instructor'] ?? '').toString().trim();

    return Course(
      id: map['id'] is int ? map['id'] as int : null,
      code: codeVal,
      name: nameVal,
      instructor: instructorVal,
    );
  }

  Course copyWith({
    int? id,
    String? code,
    String? name,
    String? instructor,
  }) {
    return Course(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      instructor: instructor ?? this.instructor,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Course &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => code.hashCode;
}
