import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:smartattendance/services/attendance_service.dart';
import 'package:smartattendance/services/firebase_service.dart';
import 'package:smartattendance/views/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.macOS || defaultTargetPlatform == TargetPlatform.linux)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  try {
    await FirebaseService.instance.init();
  } catch (e) {
    debugPrint('Firebase main initialization notice: $e');
  }

  runApp(const SmartAttendanceApp());
}

class SmartAttendanceApp extends StatefulWidget {
  const SmartAttendanceApp({super.key});

  @override
  State<SmartAttendanceApp> createState() => _SmartAttendanceAppState();
}

class _SmartAttendanceAppState extends State<SmartAttendanceApp> {
  late final AttendanceService _attendanceService;

  @override
  void initState() {
    super.initState();
    _attendanceService = AttendanceService();
    _attendanceService.init();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AttendanceService>.value(
      value: _attendanceService,
      child: Consumer<AttendanceService>(
        builder: (context, service, child) {
          final isDark = service.isDarkMode;
          return MaterialApp(
            title: 'Smart Attendance System',
            debugShowCheckedModeBanner: false,
            themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF1E88E5),
                brightness: Brightness.light,
              ),
              appBarTheme: const AppBarTheme(
                centerTitle: false,
                elevation: 0,
              ),
              scaffoldBackgroundColor: const Color(0xFFF8F9FA),
              cardTheme: CardThemeData(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF1E88E5),
                brightness: Brightness.dark,
              ),
              cardTheme: CardThemeData(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            home: const AuthWrapper(),
          );
        },
      ),
    );
  }
}
