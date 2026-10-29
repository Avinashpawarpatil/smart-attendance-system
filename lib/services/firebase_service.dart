import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../firebase_options.dart';
import '../models/student.dart';
import '../models/course.dart';
import '../models/attendance_session.dart';
import '../models/attendance_record.dart';

class FirebaseService {
  static final FirebaseService instance = FirebaseService._init();
  FirebaseFirestore? _firestore;
  FirebaseAuth? _auth;
  bool _isInitialized = false;

  FirebaseService._init();

  bool get isInitialized => _isInitialized;
  FirebaseAuth? get auth => _auth;
  User? get currentUser => _auth?.currentUser;
  Stream<User?> get authStateChanges =>
      _auth != null ? _auth!.authStateChanges() : const Stream.empty();

  /// Initializes Firebase Core, Auth, and Cloud Firestore
  Future<void> init() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      _firestore = FirebaseFirestore.instance;
      _auth = FirebaseAuth.instance;

      try {
        _firestore!.settings = const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        );
      } catch (e) {
        debugPrint('Firestore settings notice: $e');
      }

      _isInitialized = true;
      debugPrint('Firebase Firestore & Auth initialized successfully.');
    } catch (e, st) {
      debugPrint('Firebase initialization error: $e\n$st');
      if (_firestore != null) {
        _isInitialized = true;
      }
    }
  }

  // ==================== FIREBASE AUTHENTICATION ====================
  Future<UserCredential?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required String role, // 'Student' or 'Teacher'
    required String studentId,
    required String department,
  }) async {
    if (!_isInitialized) await init();
    if (_auth == null) {
      throw Exception('Firebase Auth is not initialized.');
    }

    final credential = await _auth!.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    if (credential.user != null) {
      final uid = credential.user!.uid;
      final userData = {
        'uid': uid,
        'name': name.trim(),
        'email': email.trim(),
        'role': role,
        'student_id': studentId.trim(),
        'department': department.trim(),
        'created_at': DateTime.now().toIso8601String(),
      };

      // Save to Firebase Firestore 'users' collection
      await _firestore?.collection('users').doc(uid).set(userData, SetOptions(merge: true));

      // If registered as a Student, automatically create student entry in Firestore
      if (role == 'Student' || studentId.isNotEmpty) {
        final student = Student(
          studentId: studentId.isEmpty ? 'STU-${uid.substring(0, 6).toUpperCase()}' : studentId,
          name: name,
          email: email,
          department: department.isEmpty ? 'General' : department,
        );
        await saveStudent(student);
      }
    }

    return credential;
  }

  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    if (!_isInitialized) await init();
    if (_auth == null) {
      throw Exception('Firebase Auth is not initialized.');
    }

    return await _auth!.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signOut() async {
    await _auth?.signOut();
  }

  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    if (!_isInitialized) await init();
    if (_firestore == null) return null;
    try {
      final doc = await _firestore!.collection('users').doc(uid).get();
      return doc.data();
    } catch (e) {
      debugPrint('Firestore getUserProfile error: $e');
      return null;
    }
  }

  // ==================== STUDENTS FIRESTORE OPERATIONS ====================
  Future<void> saveStudent(Student student) async {
    if (!_isInitialized) await init();
    if (_firestore == null) {
      debugPrint('Firestore instance null in saveStudent');
      return;
    }
    try {
      final docId = student.studentId.trim().isEmpty
          ? 'STU-${DateTime.now().millisecondsSinceEpoch}'
          : student.studentId.trim().replaceAll('/', '_');

      final data = {
        'student_id': student.studentId.trim(),
        'name': student.name.trim(),
        'email': student.email.trim(),
        'department': student.department.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _firestore!
          .collection('students')
          .doc(docId)
          .set(data, SetOptions(merge: true));

      debugPrint('Firestore saveStudent SUCCESS for $docId: $data');
    } catch (e, st) {
      debugPrint('Firestore saveStudent error: $e\n$st');
    }
  }

  Future<List<Student>> getStudents() async {
    if (!_isInitialized) await init();
    if (_firestore == null) return [];
    try {
      final snapshot = await _firestore!.collection('students').get();
      return snapshot.docs.map((doc) => Student.fromMap(doc.data())).toList();
    } catch (e) {
      debugPrint('Firestore getStudents error: $e');
      return [];
    }
  }

  Future<void> deleteStudent(String studentId) async {
    if (!_isInitialized) await init();
    if (_firestore == null) return;
    try {
      final docId = studentId.trim().replaceAll('/', '_');
      await _firestore!.collection('students').doc(docId).delete();
      debugPrint('Firestore deleteStudent SUCCESS for docId: $docId');
    } catch (e) {
      debugPrint('Firestore deleteStudent error: $e');
    }
  }

  // ==================== COURSES FIRESTORE OPERATIONS ====================
  Future<void> saveCourse(Course course) async {
    if (!_isInitialized) await init();
    if (_firestore == null) return;
    try {
      final docId = course.code.trim().replaceAll('/', '_');
      final data = {
        'code': course.code.trim(),
        'name': course.name.trim(),
        'instructor': course.instructor.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _firestore!
          .collection('courses')
          .doc(docId)
          .set(data, SetOptions(merge: true));

      debugPrint('Firestore saveCourse SUCCESS for docId: $docId');
    } catch (e, st) {
      debugPrint('Firestore saveCourse error: $e\n$st');
    }
  }

  Future<List<Course>> getCourses() async {
    if (!_isInitialized) await init();
    if (_firestore == null) return [];
    try {
      final snapshot = await _firestore!.collection('courses').get();
      return snapshot.docs.map((doc) => Course.fromMap(doc.data())).toList();
    } catch (e) {
      debugPrint('Firestore getCourses error: $e');
      return [];
    }
  }

  Future<void> deleteCourse(String courseCode) async {
    if (!_isInitialized) await init();
    if (_firestore == null) return;
    try {
      final docId = courseCode.trim().replaceAll('/', '_');
      await _firestore!.collection('courses').doc(docId).delete();
      debugPrint('Firestore deleteCourse SUCCESS for docId: $docId');
    } catch (e) {
      debugPrint('Firestore deleteCourse error: $e');
    }
  }

  // ==================== SESSIONS FIRESTORE OPERATIONS ====================
  Future<void> saveSession(AttendanceSession session) async {
    if (!_isInitialized) await init();
    if (_firestore == null) return;
    try {
      final docId = session.sessionCode.trim().replaceAll('/', '_');
      await _firestore!
          .collection('sessions')
          .doc(docId)
          .set(session.toMap(), SetOptions(merge: true));
      debugPrint('Firestore saveSession SUCCESS for docId: $docId');
    } catch (e) {
      debugPrint('Firestore saveSession error: $e');
    }
  }

  Future<List<AttendanceSession>> getSessions() async {
    if (!_isInitialized) await init();
    if (_firestore == null) return [];
    try {
      final snapshot =
          await _firestore!.collection('sessions').orderBy('created_at', descending: true).get();
      return snapshot.docs.map((doc) => AttendanceSession.fromMap(doc.data())).toList();
    } catch (e) {
      debugPrint('Firestore getSessions error: $e');
      return [];
    }
  }

  // ==================== ATTENDANCE RECORDS FIRESTORE OPERATIONS ====================
  Future<void> saveAttendanceRecord(AttendanceRecord record) async {
    if (!_isInitialized) await init();
    if (_firestore == null) return;
    try {
      final docId = '${record.sessionCode}_${record.studentId}'.replaceAll('/', '_');
      await _firestore!
          .collection('attendance')
          .doc(docId)
          .set(record.toMap(), SetOptions(merge: true));
      debugPrint('Firestore saveAttendanceRecord SUCCESS for docId: $docId');
    } catch (e) {
      debugPrint('Firestore saveAttendanceRecord error: $e');
    }
  }

  Future<List<AttendanceRecord>> getAttendanceRecords() async {
    if (!_isInitialized) await init();
    if (_firestore == null) return [];
    try {
      final snapshot =
          await _firestore!.collection('attendance').orderBy('timestamp', descending: true).get();
      return snapshot.docs.map((doc) => AttendanceRecord.fromMap(doc.data())).toList();
    } catch (e) {
      debugPrint('Firestore getAttendanceRecords error: $e');
      return [];
    }
  }
}
