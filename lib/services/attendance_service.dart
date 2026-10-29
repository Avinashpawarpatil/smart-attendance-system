import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import '../models/student.dart';
import '../models/course.dart';
import '../models/attendance_session.dart';
import '../models/attendance_record.dart';
import '../utils/app_strings.dart';
import 'firebase_service.dart';

class AttendanceService extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final FirebaseService _fb = FirebaseService.instance;

  List<Student> _students = [];
  List<Course> _courses = [];
  List<AttendanceSession> _sessions = [];
  List<AttendanceRecord> _records = [];

  AttendanceSession? _activeSession;
  Student? _currentStudent;
  bool _isLoading = false;
  String _userRole = 'Teacher'; // 'Teacher' or 'Student'

  // Settings preferences
  String _selectedLanguage = 'English'; // 'English', 'Marathi', or 'Hindi'
  bool _isDarkMode = false;
  bool _notificationsEnabled = true;

  List<Student> get students => _students;
  List<Course> get courses => _courses;
  List<AttendanceSession> get sessions => _sessions;
  List<AttendanceRecord> get records => _records;

  AttendanceSession? get activeSession => _activeSession;
  Student? get currentStudent => _currentStudent;
  bool get isLoading => _isLoading;
  bool get isFirebaseConnected => _fb.isInitialized;

  String get userRole => _userRole;
  bool get isTeacher => _userRole == 'Teacher';
  bool get isStudent => _userRole == 'Student';

  String get selectedLanguage => _selectedLanguage;
  bool get isDarkMode => _isDarkMode;
  bool get notificationsEnabled => _notificationsEnabled;

  String tr(String key) => AppStrings.tr(key, _selectedLanguage);

  void setUserRole(String role) {
    _userRole = role;
    notifyListeners();
  }

  void setLanguage(String lang) {
    if (lang == 'English' || lang == 'Marathi' || lang == 'Hindi') {
      _selectedLanguage = lang;
      notifyListeners();
    }
  }

  void setDarkMode(bool enable) {
    _isDarkMode = enable;
    notifyListeners();
  }

  void setNotificationsEnabled(bool enable) {
    _notificationsEnabled = enable;
    notifyListeners();
  }

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _fb.init();
      await loadData();
    } catch (e, stack) {
      debugPrint('Error loading database data in AttendanceService: $e\n$stack');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadData() async {
    try {
      // 1. Always load local SQLite database records first for instant display
      _students = (await _db.getAllStudents())
          .where((s) => s.studentId.trim().isNotEmpty)
          .toList();
      _courses = (await _db.getAllCourses())
          .where((c) => c.code.trim().isNotEmpty)
          .toList();
      _sessions = await _db.getAllSessions();
      _records = await _db.getAllAttendanceRecords();

      if (_students.isNotEmpty && _currentStudent == null) {
        _currentStudent = _students.first;
      }

      notifyListeners();

      // 2. Sync with Cloud Firestore if Firebase is initialized
      if (!_fb.isInitialized) {
        await _fb.init();
      }

      if (_fb.isInitialized) {
        if (_fb.currentUser != null) {
          try {
            final profile = await _fb.getUserProfile(_fb.currentUser!.uid);
            if (profile != null && profile['role'] != null) {
              _userRole = profile['role'];
            }
          } catch (e) {
            debugPrint('Error getting user profile: $e');
          }
        }

        // Push local SQLite records to Cloud Firestore to guarantee cloud backup
        for (var st in _students) {
          if (st.studentId.trim().isNotEmpty) {
            try {
              await _fb.saveStudent(st);
            } catch (_) {}
          }
        }
        for (var c in _courses) {
          if (c.code.trim().isNotEmpty) {
            try {
              await _fb.saveCourse(c);
            } catch (_) {}
          }
        }

        // Pull remote Cloud Firestore records to local SQLite
        try {
          final fbStudents = await _fb.getStudents();
          for (var st in fbStudents) {
            if (st.studentId.trim().isNotEmpty) {
              await _db.insertStudent(st);
            }
          }
        } catch (e) {
          debugPrint('Error fetching Firebase students: $e');
        }

        try {
          final fbCourses = await _fb.getCourses();
          for (var c in fbCourses) {
            if (c.code.trim().isNotEmpty) {
              await _db.insertCourse(c);
            }
          }
        } catch (e) {
          debugPrint('Error fetching Firebase courses: $e');
        }

        try {
          final fbSessions = await _fb.getSessions();
          for (var s in fbSessions) {
            await _db.createSession(s);
          }
        } catch (e) {
          debugPrint('Error fetching Firebase sessions: $e');
        }

        try {
          final fbRecords = await _fb.getAttendanceRecords();
          for (var r in fbRecords) {
            await _db.markAttendance(r);
          }
        } catch (e) {
          debugPrint('Error fetching Firebase attendance records: $e');
        }

        // Re-read local SQLite database after merging Firebase entries
        _students = (await _db.getAllStudents())
            .where((s) => s.studentId.trim().isNotEmpty)
            .toList();
        _courses = (await _db.getAllCourses())
            .where((c) => c.code.trim().isNotEmpty)
            .toList();
        _sessions = await _db.getAllSessions();
        _records = await _db.getAllAttendanceRecords();
      }

      if (_students.isNotEmpty && _currentStudent == null) {
        _currentStudent = _students.first;
      }

      // Check if there is an active session
      final activeList = _sessions.where((s) => s.isActive && !s.isExpired).toList();
      if (activeList.isNotEmpty) {
        _activeSession = activeList.first;
      } else {
        _activeSession = null;
      }
    } catch (e, stack) {
      debugPrint('Error syncing database records: $e\n$stack');
    } finally {
      notifyListeners();
    }
  }

  void setCurrentStudent(Student student) {
    _currentStudent = student;
    notifyListeners();
  }

  // ==================== TEACHER / SESSION LOGIC ====================
  Future<AttendanceSession> startNewSession(Course course, {int expiryMinutes = 10}) async {
    final now = DateTime.now();
    final timestampStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
    final cleanCode = course.code.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    final sessionCode = '${cleanCode.isEmpty ? "SES" : cleanCode}-${now.millisecondsSinceEpoch.toString().substring(7)}';

    final expiresAt = expiryMinutes > 0
        ? DateFormat('yyyy-MM-dd HH:mm:ss').format(now.add(Duration(minutes: expiryMinutes)))
        : '';

    final session = AttendanceSession(
      sessionCode: sessionCode,
      courseCode: course.code,
      courseName: course.name,
      createdAt: timestampStr,
      expiresAt: expiresAt,
      expiryMinutes: expiryMinutes,
      isActive: true,
    );

    try {
      await _db.createSession(session);
      debugPrint('SQLite createSession success for $sessionCode');
    } catch (e) {
      debugPrint('SQLite createSession error: $e');
    }

    try {
      if (_fb.isInitialized) {
        await _fb.saveSession(session);
        debugPrint('Firebase saveSession success for $sessionCode');
      }
    } catch (e) {
      debugPrint('Firebase saveSession error: $e');
    }

    _activeSession = session;
    await loadData();
    return session;
  }

  Future<void> endActiveSession() async {
    if (_activeSession != null) {
      final updated = AttendanceSession(
        sessionCode: _activeSession!.sessionCode,
        courseCode: _activeSession!.courseCode,
        courseName: _activeSession!.courseName,
        createdAt: _activeSession!.createdAt,
        expiresAt: _activeSession!.expiresAt,
        expiryMinutes: _activeSession!.expiryMinutes,
        isActive: false,
      );
      await _db.closeSession(_activeSession!.sessionCode);
      await _fb.saveSession(updated);

      _activeSession = null;
      await loadData();
    }
  }

  // ==================== ATTENDANCE MARKING ====================
  Future<String> markAttendanceFromQr({
    required String qrPayload,
    required String studentId,
  }) async {
    final student = await _db.getStudentById(studentId);
    if (student == null) {
      return 'Error: Student ID ($studentId) not registered in system.';
    }

    final parsedPayload = AttendanceSession.parseQrPayload(qrPayload);
    String? sessionCode;
    String? courseCode;
    String? courseName;
    String? createdAt;
    String? expiresAt;
    int expiryMinutes = 10;

    if (parsedPayload != null) {
      sessionCode = parsedPayload['session_code'];
      courseCode = parsedPayload['course_code'];
      courseName = parsedPayload['course_name'];
      createdAt = parsedPayload['created_at'];
      expiresAt = parsedPayload['expires_at'];
      expiryMinutes = parsedPayload['expiry_minutes'] ?? 10;
    } else {
      sessionCode = qrPayload.trim();
    }

    if (sessionCode == null || sessionCode.isEmpty) {
      return 'Invalid QR Code Format. Please scan a valid Session QR.';
    }

    // Attempt to locate session locally
    var session = await _db.getSessionByCode(sessionCode);

    // If session not found locally, attempt to load from Firebase
    if (session == null && _fb.isInitialized) {
      final fbSessions = await _fb.getSessions();
      for (var s in fbSessions) {
        await _db.createSession(s);
      }
      session = await _db.getSessionByCode(sessionCode);
    }

    // Fallback: If payload contains course_code and session_code, create session record locally & remotely
    if (session == null && courseCode != null && courseCode.isNotEmpty) {
      session = AttendanceSession(
        sessionCode: sessionCode,
        courseCode: courseCode,
        courseName: courseName ?? courseCode,
        createdAt: createdAt ?? DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
        expiresAt: expiresAt ?? '',
        expiryMinutes: expiryMinutes,
        isActive: true,
      );
      await _db.createSession(session);
      await _fb.saveSession(session);
    }

    if (session == null) {
      return 'Error: Attendance session ($sessionCode) does not exist.';
    }

    if (!session.isActive) {
      return 'Error: This attendance session has already been closed by the teacher.';
    }

    if (session.isExpired) {
      return 'Error: QR Code Expired! The validity time for this session has ended.';
    }

    return await _processMarkAttendance(session: session, student: student);
  }

  Future<String> markAttendanceManual({
    required String sessionCode,
    required String studentId,
  }) async {
    final session = await _db.getSessionByCode(sessionCode.trim());
    if (session == null) {
      return 'Error: Invalid session code ($sessionCode).';
    }

    if (!session.isActive) {
      return 'Error: This attendance session is closed.';
    }

    if (session.isExpired) {
      return 'Error: Session Code Expired! Validity period ended.';
    }

    final student = await _db.getStudentById(studentId.trim());
    if (student == null) {
      return 'Error: Student ID ($studentId) not found.';
    }

    return await _processMarkAttendance(session: session, student: student);
  }

  Future<String> _processMarkAttendance({
    required AttendanceSession session,
    required Student student,
  }) async {
    final nowStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

    final record = AttendanceRecord(
      sessionCode: session.sessionCode,
      studentId: student.studentId,
      studentName: student.name,
      courseCode: session.courseCode,
      timestamp: nowStr,
      status: 'PRESENT',
    );

    final success = await _db.markAttendance(record);
    await _fb.saveAttendanceRecord(record);

    await loadData();

    if (success) {
      return 'SUCCESS: Attendance marked for ${student.name} in ${session.courseCode}!';
    } else {
      return 'Info: Attendance already marked for this session.';
    }
  }

  // ==================== MANAGEMENT METHODS ====================
  Future<void> addStudent(Student student) async {
    // 1. Immediately update in-memory list so UI reflects addition instantly
    final existingIndex = _students.indexWhere((s) => s.studentId == student.studentId);
    if (existingIndex >= 0) {
      _students[existingIndex] = student;
    } else {
      _students.add(student);
    }
    notifyListeners();

    // 2. Persist to local SQLite DB
    try {
      await _db.insertStudent(student);
      debugPrint('SQLite insertStudent success: ${student.studentId}');
    } catch (e) {
      debugPrint('SQLite insertStudent error: $e');
    }

    // 3. Persist to Cloud Firestore
    try {
      await _fb.saveStudent(student);
      debugPrint('Firebase saveStudent finished for: ${student.studentId}');
    } catch (e) {
      debugPrint('Firebase saveStudent error: $e');
    }

    // 4. Reload all data to ensure complete sync
    await loadData();
  }

  Future<void> updateStudent(Student student) async {
    final existingIndex = _students.indexWhere((s) => s.studentId == student.studentId || (student.id != null && s.id == student.id));
    if (existingIndex >= 0) {
      _students[existingIndex] = student;
      notifyListeners();
    }

    try {
      await _db.updateStudent(student);
    } catch (e) {
      debugPrint('SQLite updateStudent error: $e');
    }

    try {
      await _fb.saveStudent(student);
    } catch (e) {
      debugPrint('Firebase saveStudent error: $e');
    }

    await loadData();
  }

  Future<void> deleteStudent(Student student) async {
    _students.removeWhere((s) => s.studentId == student.studentId || (student.id != null && s.id == student.id));
    notifyListeners();

    try {
      await _db.deleteStudentById(student.studentId);
    } catch (e) {
      debugPrint('SQLite deleteStudent error: $e');
    }

    try {
      await _fb.deleteStudent(student.studentId);
    } catch (e) {
      debugPrint('Firebase deleteStudent error: $e');
    }

    await loadData();
  }

  Future<void> addCourse(Course course) async {
    final existingIndex = _courses.indexWhere((c) => c.code == course.code);
    if (existingIndex >= 0) {
      _courses[existingIndex] = course;
    } else {
      _courses.add(course);
    }
    notifyListeners();

    try {
      await _db.insertCourse(course);
    } catch (e) {
      debugPrint('SQLite insertCourse error: $e');
    }

    try {
      await _fb.saveCourse(course);
    } catch (e) {
      debugPrint('Firebase saveCourse error: $e');
    }

    await loadData();
  }

  Future<void> updateCourse(Course course) async {
    final existingIndex = _courses.indexWhere((c) => c.code == course.code || (course.id != null && c.id == course.id));
    if (existingIndex >= 0) {
      _courses[existingIndex] = course;
      notifyListeners();
    }

    try {
      await _db.updateCourse(course);
    } catch (e) {
      debugPrint('SQLite updateCourse error: $e');
    }

    try {
      await _fb.saveCourse(course);
    } catch (e) {
      debugPrint('Firebase saveCourse error: $e');
    }

    await loadData();
  }

  Future<void> deleteCourse(Course course) async {
    _courses.removeWhere((c) => c.code == course.code || (course.id != null && c.id == course.id));
    notifyListeners();

    try {
      await _db.deleteCourseByCode(course.code);
    } catch (e) {
      debugPrint('SQLite deleteCourse error: $e');
    }

    try {
      await _fb.deleteCourse(course.code);
    } catch (e) {
      debugPrint('Firebase deleteCourse error: $e');
    }

    await loadData();
  }

  // ==================== STATS & HELPER METRICS ====================
  int getAttendeeCountForSession(String sessionCode) {
    return _records.where((r) => r.sessionCode == sessionCode).length;
  }

  double getStudentAttendancePercentage(String studentId) {
    if (_sessions.isEmpty) return 0.0;
    final studentRecords = _records.where((r) => r.studentId == studentId).length;
    return (studentRecords / _sessions.length) * 100.0;
  }
}
