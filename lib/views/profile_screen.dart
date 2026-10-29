import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartattendance/services/attendance_service.dart';
import 'package:smartattendance/services/firebase_service.dart';
import 'package:smartattendance/views/auth_wrapper.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<AttendanceService>(context);
    final theme = Theme.of(context);
    final fbUser = FirebaseService.instance.currentUser;
    final currentStudent = service.currentStudent;

    final isTeacher = service.isTeacher;
    final displayName = isTeacher
        ? (fbUser?.displayName ?? 'Teacher Account')
        : (currentStudent?.name ?? fbUser?.displayName ?? 'Student Account');

    final email = fbUser?.email ?? currentStudent?.email ?? 'user@school.edu';
    final idCode = isTeacher ? (fbUser?.uid.substring(0, 8).toUpperCase() ?? 'TCH-101') : (currentStudent?.studentId ?? 'STU-101');
    final department = currentStudent?.department ?? 'Academic Department';

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 10),
            // Avatar Header Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      displayName,
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Chip(
                      avatar: const Icon(Icons.verified, size: 16, color: Colors.green),
                      label: Text(
                        isTeacher ? 'VERIFIED TEACHER' : 'VERIFIED STUDENT',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.green),
                      ),
                      backgroundColor: Colors.green.shade50,
                      side: BorderSide(color: Colors.green.shade300),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Profile Details Card
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFE8EAF6),
                      child: Icon(Icons.email, color: Colors.indigo),
                    ),
                    title: const Text('Email Address', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    subtitle: Text(email, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFE8F5E9),
                      child: Icon(Icons.badge, color: Colors.green),
                    ),
                    title: Text(isTeacher ? 'Teacher ID' : 'Student ID', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    subtitle: Text(idCode, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFFFF3E0),
                      child: Icon(Icons.business, color: Colors.orange),
                    ),
                    title: const Text('Department', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    subtitle: Text(department, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFE0F2F1),
                      child: Icon(Icons.security, color: Colors.teal),
                    ),
                    title: const Text('Account Status', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    subtitle: const Text('Authenticated & Secured via Firebase Auth', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.teal)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Logout Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.logout, size: 20),
                label: const Text('Sign Out / Logout', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Sign Out?'),
                      content: const Text('Are you sure you want to sign out of your account?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Sign Out'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await FirebaseService.instance.signOut();
                    service.setUserRole('Teacher');
                    if (context.mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const AuthWrapper()),
                        (route) => false,
                      );
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
