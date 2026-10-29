import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/student.dart';
import '../models/course.dart';
import '../models/attendance_session.dart';
import '../models/attendance_record.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('smart_attendance.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onOpen: (db) async {
        try {
          await db.execute('ALTER TABLE sessions ADD COLUMN expires_at TEXT');
        } catch (_) {}
        try {
          await db.execute('ALTER TABLE sessions ADD COLUMN expiry_minutes INTEGER DEFAULT 10');
        } catch (_) {}
      },
    );
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';

    await db.execute('''
      CREATE TABLE students (
        id $idType,
        student_id $textType UNIQUE,
        name $textType,
        email $textType,
        department $textType
      )
    ''');

    await db.execute('''
      CREATE TABLE courses (
        id $idType,
        code $textType UNIQUE,
        name $textType,
        instructor $textType
      )
    ''');

    await db.execute('''
      CREATE TABLE sessions (
        id $idType,
        session_code $textType UNIQUE,
        course_code $textType,
        course_name $textType,
        created_at $textType,
        expires_at TEXT,
        expiry_minutes INTEGER DEFAULT 10,
        is_active $intType DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE attendance (
        id $idType,
        session_code $textType,
        student_id $textType,
        student_name $textType,
        course_code $textType,
        timestamp $textType,
        status $textType,
        UNIQUE(session_code, student_id)
      )
    ''');

    // Seed initial data for testing & quick start
    await _seedData(db);
  }

  Future<void> _seedData(Database db) async {
    // Initial Courses
    final courses = [
      {'code': 'CS101', 'name': 'Computer Science Basics', 'instructor': 'Dr. Alan Turing'},
      {'code': 'CS202', 'name': 'Data Structures & Algorithms', 'instructor': 'Prof. Grace Hopper'},
      {'code': 'SE301', 'name': 'Software Engineering Fundamentals', 'instructor': 'Dr. Margaret Hamilton'},
    ];
    for (var c in courses) {
      await db.insert('courses', c, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    // Initial Students
    final students = [
      {'student_id': 'STU1001', 'name': 'Alice Johnson', 'email': 'alice@example.com', 'department': 'Computer Science'},
      {'student_id': 'STU1002', 'name': 'Bob Smith', 'email': 'bob@example.com', 'department': 'Software Engineering'},
      {'student_id': 'STU1003', 'name': 'Charlie Davis', 'email': 'charlie@example.com', 'department': 'Computer Science'},
      {'student_id': 'STU1004', 'name': 'Diana Prince', 'email': 'diana@example.com', 'department': 'Information Technology'},
    ];
    for (var s in students) {
      await db.insert('students', s, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  // ==================== STUDENT CRUD ====================
  Future<int> insertStudent(Student student) async {
    final db = await instance.database;
    final existing = await getStudentById(student.studentId);
    if (existing != null) {
      return await db.update(
        'students',
        student.toMap(),
        where: 'student_id = ?',
        whereArgs: [student.studentId],
      );
    }
    return await db.insert('students', student.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Student>> getAllStudents() async {
    final db = await instance.database;
    final result = await db.query('students', orderBy: 'student_id ASC');
    return result.map((json) => Student.fromMap(json)).toList();
  }

  Future<Student?> getStudentById(String studentId) async {
    final db = await instance.database;
    final result = await db.query(
      'students',
      where: 'student_id = ?',
      whereArgs: [studentId],
    );
    if (result.isNotEmpty) {
      return Student.fromMap(result.first);
    }
    return null;
  }

  Future<int> updateStudent(Student student) async {
    final db = await instance.database;
    if (student.id != null) {
      return await db.update(
        'students',
        student.toMap(),
        where: 'id = ?',
        whereArgs: [student.id],
      );
    } else {
      return await db.update(
        'students',
        student.toMap(),
        where: 'student_id = ?',
        whereArgs: [student.studentId],
      );
    }
  }

  Future<int> deleteStudent(int id) async {
    final db = await instance.database;
    return await db.delete('students', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteStudentById(String studentId) async {
    final db = await instance.database;
    return await db.delete('students', where: 'student_id = ?', whereArgs: [studentId]);
  }

  // ==================== COURSE CRUD ====================
  Future<int> insertCourse(Course course) async {
    final db = await instance.database;
    final existing = await getCourseByCode(course.code);
    if (existing != null) {
      return await db.update(
        'courses',
        course.toMap(),
        where: 'code = ?',
        whereArgs: [course.code],
      );
    }
    return await db.insert('courses', course.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Course?> getCourseByCode(String code) async {
    final db = await instance.database;
    final result = await db.query(
      'courses',
      where: 'code = ?',
      whereArgs: [code],
    );
    if (result.isNotEmpty) {
      return Course.fromMap(result.first);
    }
    return null;
  }

  Future<List<Course>> getAllCourses() async {
    final db = await instance.database;
    final result = await db.query('courses', orderBy: 'code ASC');
    return result.map((json) => Course.fromMap(json)).toList();
  }

  Future<int> updateCourse(Course course) async {
    final db = await instance.database;
    if (course.id != null) {
      return await db.update(
        'courses',
        course.toMap(),
        where: 'id = ?',
        whereArgs: [course.id],
      );
    } else {
      return await db.update(
        'courses',
        course.toMap(),
        where: 'code = ?',
        whereArgs: [course.code],
      );
    }
  }

  Future<int> deleteCourse(int id) async {
    final db = await instance.database;
    return await db.delete('courses', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteCourseByCode(String code) async {
    final db = await instance.database;
    return await db.delete('courses', where: 'code = ?', whereArgs: [code]);
  }

  // ==================== SESSION OPERATIONS ====================
  Future<int> createSession(AttendanceSession session) async {
    final db = await instance.database;
    return await db.insert('sessions', session.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<AttendanceSession?> getSessionByCode(String sessionCode) async {
    final db = await instance.database;
    final result = await db.query(
      'sessions',
      where: 'session_code = ?',
      whereArgs: [sessionCode],
    );
    if (result.isNotEmpty) {
      return AttendanceSession.fromMap(result.first);
    }
    return null;
  }

  Future<List<AttendanceSession>> getAllSessions() async {
    final db = await instance.database;
    final result = await db.query('sessions', orderBy: 'id DESC');
    return result.map((json) => AttendanceSession.fromMap(json)).toList();
  }

  Future<int> closeSession(String sessionCode) async {
    final db = await instance.database;
    return await db.update(
      'sessions',
      {'is_active': 0},
      where: 'session_code = ?',
      whereArgs: [sessionCode],
    );
  }

  // ==================== ATTENDANCE RECORD OPERATIONS ====================
  Future<bool> markAttendance(AttendanceRecord record) async {
    final db = await instance.database;
    try {
      final id = await db.insert(
        'attendance',
        record.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return id > 0;
    } catch (_) {
      return false;
    }
  }

  Future<List<AttendanceRecord>> getAttendanceForSession(String sessionCode) async {
    final db = await instance.database;
    final result = await db.query(
      'attendance',
      where: 'session_code = ?',
      whereArgs: [sessionCode],
      orderBy: 'timestamp DESC',
    );
    return result.map((json) => AttendanceRecord.fromMap(json)).toList();
  }

  Future<List<AttendanceRecord>> getAttendanceForStudent(String studentId) async {
    final db = await instance.database;
    final result = await db.query(
      'attendance',
      where: 'student_id = ?',
      whereArgs: [studentId],
      orderBy: 'timestamp DESC',
    );
    return result.map((json) => AttendanceRecord.fromMap(json)).toList();
  }

  Future<List<AttendanceRecord>> getAllAttendanceRecords() async {
    final db = await instance.database;
    final result = await db.query('attendance', orderBy: 'timestamp DESC');
    return result.map((json) => AttendanceRecord.fromMap(json)).toList();
  }

  Future<void> clearAllData() async {
    final db = await instance.database;
    await db.delete('attendance');
    await db.delete('sessions');
  }
}
