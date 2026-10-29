import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartattendance/services/attendance_service.dart';
import 'package:smartattendance/services/firebase_service.dart';
import 'qr_scanner_screen.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final _manualCodeController = TextEditingController();

  @override
  void dispose() {
    _manualCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<AttendanceService>(context);
    final theme = Theme.of(context);
    final fbUser = FirebaseService.instance.currentUser;
    final verifiedStudent = service.currentStudent;

    final studentName = verifiedStudent?.name ?? fbUser?.displayName ?? 'Verified Student';
    final studentId = verifiedStudent?.studentId ?? 'STU-VERIFIED';
    final department = verifiedStudent?.department ?? 'Computer Science';

    final studentRecords = verifiedStudent != null
        ? service.records.where((r) => r.studentId == verifiedStudent.studentId).toList()
        : [];

    final attendancePercentage = verifiedStudent != null
        ? service.getStudentAttendancePercentage(verifiedStudent.studentId)
        : 0.0;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.camera_alt),
        label: Text(service.tr('scan_qr')),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => QrScannerScreen(student: verifiedStudent),
            ),
          );
        },
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 22,
                  child: Icon(Icons.person, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.tr('student_portal'),
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Text(
                        'Scan class QR code to record touchless attendance',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Verified Student Profile Card (Selection dropdown removed for security)
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        studentName.isNotEmpty ? studentName[0].toUpperCase() : 'S',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  studentName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.green.shade300),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.verified, size: 14, color: Colors.green),
                                    SizedBox(width: 4),
                                    Text('VERIFIED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('ID: $studentId • $department', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                          const SizedBox(height: 2),
                          const Text(
                            'Authenticated student profile. Attendance is locked to your account.',
                            style: TextStyle(fontSize: 11, color: Colors.teal, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Action Buttons: Camera Scanner & Manual Entry
            Card(
              color: theme.colorScheme.primaryContainer.withAlpha(128),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.camera_alt_outlined, size: 24),
                        label: Text(
                          service.tr('scan_qr'),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => QrScannerScreen(student: verifiedStudent),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Row(
                      children: [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text('OR ENTER SESSION CODE MANUALLY', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _manualCodeController,
                            decoration: const InputDecoration(
                              hintText: 'Enter Session Code (e.g. CS101-12345)',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: verifiedStudent == null
                              ? null
                              : () async {
                                  final code = _manualCodeController.text.trim();
                                  if (code.isEmpty) return;

                                  final result = await service.markAttendanceManual(
                                    sessionCode: code,
                                    studentId: verifiedStudent.studentId,
                                  );

                                  if (context.mounted) {
                                    _manualCodeController.clear();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(result),
                                        backgroundColor: result.startsWith('SUCCESS') ? Colors.green : Colors.red,
                                      ),
                                    );
                                  }
                                },
                          child: const Text('Submit'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Attendance Statistics & History
            if (verifiedStudent != null) ...[
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Personal Performance',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Chip(
                            label: Text(
                              '${attendancePercentage.toStringAsFixed(1)}% Attended',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo, fontSize: 12),
                            ),
                            backgroundColor: Colors.indigo.shade50,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      LinearProgressIndicator(
                        value: attendancePercentage / 100.0,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(10),
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          attendancePercentage >= 75 ? Colors.green : (attendancePercentage >= 50 ? Colors.orange : Colors.red),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Text(
                        'Attendance History (${studentRecords.length})',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),

                      if (studentRecords.isEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: Text(
                              'No attendance records found yet.',
                              style: TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                          ),
                        ),
                      ] else ...[
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: studentRecords.length,
                          separatorBuilder: (context, index) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final rec = studentRecords[index];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const CircleAvatar(
                                backgroundColor: Colors.green,
                                child: Icon(Icons.check, color: Colors.white, size: 20),
                              ),
                              title: Text(
                                'Course: ${rec.courseCode}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text('Session: ${rec.sessionCode}\nDate: ${rec.timestamp}'),
                              trailing: const Chip(
                                label: Text('PRESENT', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                                backgroundColor: Color(0xFFE8F5E9),
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 80), // Padding for floating action button
          ],
        ),
      ),
    );
  }
}
