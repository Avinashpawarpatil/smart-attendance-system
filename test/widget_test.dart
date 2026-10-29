import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:smartattendance/main.dart';
import 'package:smartattendance/services/attendance_service.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('Smart Attendance System Smoke Test', (WidgetTester tester) async {
    final attendanceService = AttendanceService();
    await attendanceService.init();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: attendanceService,
        child: const SmartAttendanceApp(),
      ),
    );

    expect(find.text('Smart Attendance'), findsOneWidget);
  });
}
