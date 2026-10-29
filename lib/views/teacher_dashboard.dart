import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartattendance/services/attendance_service.dart';
import 'package:smartattendance/models/course.dart';
import 'package:smartattendance/utils/app_strings.dart';
import 'qr_generator_screen.dart';
import 'manage_students_screen.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  Course? _selectedCourse;
  int _selectedValidityMinutes = 10;
  bool _isGenerating = false;

  Future<void> _handleGenerateQr(AttendanceService service) async {
    if (_selectedCourse == null || _isGenerating) return;

    setState(() {
      _isGenerating = true;
    });

    try {
      final newSession = await service.startNewSession(
        _selectedCourse!,
        expiryMinutes: _selectedValidityMinutes,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Live QR generated for ${_selectedCourse!.code} ($_selectedValidityMinutes Mins validity)'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => QrGeneratorScreen(session: newSession),
          ),
        );
      }
    } catch (e, st) {
      debugPrint('Error generating QR code: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notice generating QR code: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<AttendanceService>(context);
    final theme = Theme.of(context);
    final lang = service.selectedLanguage;

    Course? matchedCourse;
    if (service.courses.isNotEmpty) {
      if (_selectedCourse != null) {
        final matches = service.courses.where((c) => c.code == _selectedCourse!.code).toList();
        if (matches.isNotEmpty) {
          matchedCourse = matches.first;
        } else {
          matchedCourse = service.courses.first;
        }
      } else {
        matchedCourse = service.courses.first;
      }
    }

    _selectedCourse = matchedCourse;

    final activeSession = service.activeSession;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer.withAlpha(50),
            theme.colorScheme.surface,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Branded Teacher Console Header Banner Card
            Card(
              elevation: 0,
              color: theme.colorScheme.primaryContainer,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: theme.colorScheme.onPrimaryContainer.withAlpha(38),
                      child: Icon(Icons.school, size: 28, color: theme.colorScheme.onPrimaryContainer),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.tr('teacher_console', lang),
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppStrings.tr('teacher_console_sub', lang),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer.withAlpha(216),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Active Session Alert Card
            if (activeSession != null) ...[
              Card(
                color: activeSession.isExpired ? Colors.orange.shade50 : Colors.green.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: activeSession.isExpired ? Colors.orange.shade400 : Colors.green.shade400, width: 1.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Chip(
                            avatar: Icon(
                              activeSession.isExpired ? Icons.timer_off : Icons.circle,
                              color: activeSession.isExpired ? Colors.orange : Colors.green,
                              size: 14,
                            ),
                            label: Text(
                              activeSession.isExpired ? 'SESSION EXPIRED' : 'SESSION IN PROGRESS',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            backgroundColor: activeSession.isExpired ? Colors.orange.shade100 : Colors.green.shade100,
                          ),
                          Text(
                            '${service.getAttendeeCountForSession(activeSession.sessionCode)} Present',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: activeSession.isExpired ? Colors.orange.shade800 : Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${activeSession.courseCode} - ${activeSession.courseName}',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Session Code: ${activeSession.sessionCode}',
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.qr_code_2, size: 20),
                            label: const Text('Display Session QR'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => QrGeneratorScreen(session: activeSession),
                                ),
                              );
                            },
                          ),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.stop_circle_outlined, color: Colors.red, size: 20),
                            label: const Text('End Session', style: TextStyle(color: Colors.red)),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Close Session?'),
                                  content: const Text('Students will no longer be able to scan QR code for this session.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text('End Session'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await service.endActiveSession();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Session closed successfully.')),
                                  );
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Start New Session Card: Time Valid QR Code Generator
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.timer_outlined, color: Colors.indigo),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            AppStrings.tr('generate_qr', lang),
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Select a course and set QR code time validity. Students can scan it using their camera to mark attendance.',
                      style: TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                    const SizedBox(height: 16),
                    if (service.courses.isEmpty) ...[
                      const Text('No courses available. Please add courses first in Manage Courses.'),
                    ] else ...[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DropdownButtonFormField<Course>(
                            value: matchedCourse,
                            decoration: InputDecoration(
                              labelText: AppStrings.tr('select_course', lang),
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.book),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            isExpanded: true,
                            items: service.courses.map((course) {
                              return DropdownMenuItem<Course>(
                                value: course,
                                child: Text(
                                  '${course.code} - ${course.name}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (course) {
                              setState(() {
                                _selectedCourse = course;
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<int>(
                            initialValue: _selectedValidityMinutes,
                            decoration: InputDecoration(
                              labelText: AppStrings.tr('validity_time', lang),
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.timer_outlined),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            isExpanded: true,
                            items: const [
                              DropdownMenuItem(value: 2, child: Text('2 Minutes')),
                              DropdownMenuItem(value: 5, child: Text('5 Minutes')),
                              DropdownMenuItem(value: 10, child: Text('10 Minutes')),
                              DropdownMenuItem(value: 15, child: Text('15 Minutes')),
                              DropdownMenuItem(value: 30, child: Text('30 Minutes')),
                              DropdownMenuItem(value: 60, child: Text('1 Hour')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedValidityMinutes = val;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          icon: _isGenerating
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Icon(Icons.qr_code_2, size: 24),
                          label: _isGenerating
                              ? const Text(
                                  'Generating Live QR...',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                )
                              : FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    '${AppStrings.tr('generate_qr', lang)} ($_selectedValidityMinutes Mins)',
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                  ),
                                ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: (_selectedCourse == null || _isGenerating)
                              ? null
                              : () => _handleGenerateQr(service),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Teacher Student Management Card: Add Student Option & Added Students List
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${AppStrings.tr('students', lang)} (${service.students.length})',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Registered students in your institution',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.person_add, size: 18),
                          label: Text(AppStrings.tr('add_student', lang)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () => showAddStudentDialog(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    if (service.students.isEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: Text(
                            'No students added yet. Click "Add Student" above to register new students.',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ] else ...[
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: service.students.length > 5 ? 5 : service.students.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final st = service.students[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: theme.colorScheme.primaryContainer,
                              child: Text(
                                st.name.isNotEmpty ? st.name[0].toUpperCase() : 'S',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(
                              st.name,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              'ID: ${st.studentId} • ${st.department}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                              onPressed: () => showAddStudentDialog(context, student: st),
                            ),
                          );
                        },
                      ),
                      if (service.students.length > 5) ...[
                        const SizedBox(height: 10),
                        Center(
                          child: TextButton.icon(
                            icon: const Icon(Icons.format_list_bulleted),
                            label: Text('View All ${service.students.length} Students'),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const ManageStudentsScreen()),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              '${AppStrings.tr('courses', lang)} (${service.courses.length})',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: service.courses.length,
              itemBuilder: (context, index) {
                final course = service.courses[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        course.code.substring(0, course.code.length > 2 ? 2 : course.code.length),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(
                      '${course.code}: ${course.name}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      'Instructor: ${course.instructor}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.chevron_right),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
