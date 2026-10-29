import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartattendance/services/attendance_service.dart';
import 'package:smartattendance/utils/app_strings.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _showLanguageDialog(BuildContext context, AttendanceService service) {
    const languages = ['English', 'Marathi', 'Hindi'];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.language, color: Colors.indigo),
            const SizedBox(width: 10),
            Text(AppStrings.tr('language', service.selectedLanguage)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: languages.map((lang) {
            final isSelected = service.selectedLanguage == lang;
            String displayLabel = lang;
            if (lang == 'Marathi') displayLabel = 'मराठी (Marathi)';
            if (lang == 'Hindi') displayLabel = 'हिंदी (Hindi)';

            return RadioListTile<String>(
              title: Text(
                displayLabel,
                style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
              ),
              value: lang,
              groupValue: service.selectedLanguage,
              onChanged: (val) {
                if (val != null) {
                  service.setLanguage(val);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Language changed to $val'),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context, AttendanceService service) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.qr_code_scanner, color: Colors.indigo, size: 28),
            SizedBox(width: 10),
            Text('Smart Attendance System'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version: 1.0.0+1', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 6),
            Text('Developer: Avinash Pawar', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
            SizedBox(height: 12),
            Text(
              'A modern, touchless QR code attendance tracking solution featuring dual SQLite & Firebase Cloud Firestore synchronization.',
              style: TextStyle(fontSize: 13, color: Colors.black87),
            ),
            SizedBox(height: 12),
            Text('© 2026 All Rights Reserved.', style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: Colors.indigo),
            SizedBox(width: 10),
            Text('Help & FAQs'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('👨‍🏫 Teacher Guide:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              SizedBox(height: 4),
              Text('1. Go to Teacher Portal.\n2. Select Course & validity duration.\n3. Tap "Generate Time Valid QR Code".\n4. Students can scan the live QR code to mark attendance.'),
              SizedBox(height: 14),
              Text('🎓 Student Guide:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              SizedBox(height: 4),
              Text('1. Go to Student Console or tap "Scan QR / Camera".\n2. Align your mobile camera with the Teacher\'s live session QR code.\n3. Attendance will be marked "PRESENT" instantly.'),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<AttendanceService>(context);
    final theme = Theme.of(context);
    final lang = service.selectedLanguage;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.tr('settings', lang)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('General Settings', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
            const SizedBox(height: 10),

            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFE8EAF6),
                      child: Icon(Icons.language, color: Colors.indigo),
                    ),
                    title: Text(AppStrings.tr('language', lang), style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      service.selectedLanguage == 'Marathi'
                          ? 'मराठी (Marathi)'
                          : service.selectedLanguage == 'Hindi'
                              ? 'हिंदी (Hindi)'
                              : 'English',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showLanguageDialog(context, service),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const CircleAvatar(
                      backgroundColor: Color(0xFFFFF3E0),
                      child: Icon(Icons.dark_mode_outlined, color: Colors.orange),
                    ),
                    title: Text(AppStrings.tr('dark_mode', lang), style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(service.isDarkMode ? 'Dark Theme Enabled' : 'Light Theme Enabled'),
                    value: service.isDarkMode,
                    onChanged: (val) {
                      service.setDarkMode(val);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(val ? 'Dark mode enabled' : 'Light mode enabled'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const CircleAvatar(
                      backgroundColor: Color(0xFFE8F5E9),
                      child: Icon(Icons.notifications_outlined, color: Colors.green),
                    ),
                    title: Text(AppStrings.tr('notifications', lang), style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(service.notificationsEnabled ? 'Attendance alerts enabled' : 'Notifications disabled'),
                    value: service.notificationsEnabled,
                    onChanged: (val) {
                      service.setNotificationsEnabled(val);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(val ? 'Notifications enabled' : 'Notifications disabled'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text('Data & Sync', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
            const SizedBox(height: 10),

            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE0F2F1),
                  child: Icon(Icons.sync, color: Colors.teal),
                ),
                title: Text(AppStrings.tr('sync_database', lang), style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(service.isFirebaseConnected ? 'Firebase Cloud Connected • SQLite Persistent' : 'Local SQLite Storage Mode'),
                trailing: ElevatedButton.icon(
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Sync'),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    await service.loadData();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Database and Cloud Firestore synchronized!'),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            Text('Support & Info', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
            const SizedBox(height: 10),

            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFE3F2FD),
                      child: Icon(Icons.info_outline, color: Colors.blue),
                    ),
                    title: Text(AppStrings.tr('about_app', lang), style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Version 1.0.0 • Avinash Pawar'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showAboutDialog(context, service),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFF3E5F5),
                      child: Icon(Icons.help_outline, color: Colors.purple),
                    ),
                    title: const Text('Help & User FAQs', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Guides for Teachers and Students'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showHelpDialog(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
