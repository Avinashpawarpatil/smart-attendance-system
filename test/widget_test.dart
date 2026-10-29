import 'package:flutter_test/flutter_test.dart';
import 'package:smartattendance/services/attendance_service.dart';
import 'package:smartattendance/utils/app_strings.dart';

void main() {
  group('AttendanceService Unit Tests', () {
    test('Initial default values are correct', () {
      final service = AttendanceService();
      expect(service.userRole, 'Teacher');
      expect(service.selectedLanguage, 'English');
      expect(service.isDarkMode, false);
      expect(service.notificationsEnabled, true);
    });

    test('Role switching works correctly', () {
      final service = AttendanceService();
      service.setUserRole('Student');
      expect(service.userRole, 'Student');
      expect(service.isStudent, true);
      expect(service.isTeacher, false);

      service.setUserRole('Teacher');
      expect(service.userRole, 'Teacher');
      expect(service.isTeacher, true);
      expect(service.isStudent, false);
    });

    test('Language setting works correctly', () {
      final service = AttendanceService();
      service.setLanguage('Hindi');
      expect(service.selectedLanguage, 'Hindi');

      service.setLanguage('Marathi');
      expect(service.selectedLanguage, 'Marathi');

      service.setLanguage('English');
      expect(service.selectedLanguage, 'English');
    });

    test('AppStrings translations return correct values', () {
      expect(AppStrings.tr('app_title', 'English'), 'Smart Attendance');
      expect(AppStrings.tr('app_title', 'Marathi'), 'स्मार्ट हजेरी');
      expect(AppStrings.tr('app_title', 'Hindi'), 'स्मार्ट उपस्थिति');
    });
  });
}
