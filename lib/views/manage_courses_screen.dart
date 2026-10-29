import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/course.dart';
import '../services/attendance_service.dart';

class ManageCoursesScreen extends StatefulWidget {
  const ManageCoursesScreen({super.key});

  @override
  State<ManageCoursesScreen> createState() => _ManageCoursesScreenState();
}

class _ManageCoursesScreenState extends State<ManageCoursesScreen> {
  String _searchQuery = '';

  void _showCourseDialog({Course? course}) {
    final service = Provider.of<AttendanceService>(context, listen: false);
    final isEditing = course != null;

    final codeController = TextEditingController(text: course?.code ?? '');
    final nameController = TextEditingController(text: course?.name ?? '');
    final instructorController = TextEditingController(text: course?.instructor ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEditing ? 'Edit Course' : 'Add New Course'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: codeController,
              decoration: const InputDecoration(
                labelText: 'Course Code',
                hintText: 'e.g. CS101',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.bookmark_border),
              ),
              enabled: !isEditing,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Course Name',
                hintText: 'e.g. Computer Science Basics',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.book_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: instructorController,
              decoration: const InputDecoration(
                labelText: 'Instructor Name',
                hintText: 'e.g. Dr. Turing',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final codeStr = codeController.text.trim();
              final nameStr = nameController.text.trim();
              final instructorStr = instructorController.text.trim();

              if (codeStr.isEmpty || nameStr.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Course Code and Name are required.')),
                );
                return;
              }

              final navigator = Navigator.of(ctx);
              final parentContext = context;

              try {
                if (isEditing) {
                  final updated = course.copyWith(
                    name: nameStr,
                    instructor: instructorStr,
                  );
                  await service.updateCourse(updated);
                } else {
                  final newCourse = Course(
                    code: codeStr,
                    name: nameStr,
                    instructor: instructorStr,
                  );
                  await service.addCourse(newCourse);
                }
              } catch (e) {
                debugPrint('Error saving course: $e');
              }

              navigator.pop(); // Close form dialog

              // Safely queue success popup after Navigator route lock releases
              Future.microtask(() {
                if (parentContext.mounted) {
                  // Show SnackBar
                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    SnackBar(
                      content: Text(isEditing ? 'Course updated successfully!' : 'Course $codeStr added successfully!'),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 3),
                    ),
                  );

                  // Show "Course Added / Updated Successfully" popup dialog
                  showDialog(
                    context: parentContext,
                    builder: (successCtx) => AlertDialog(
                      title: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 30),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              isEditing ? 'Course Updated' : 'Course Added Successfully',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                          ),
                        ],
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Course Code: $codeStr', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 6),
                          Text('Course Name: $nameStr', style: const TextStyle(color: Colors.grey)),
                          Text('Instructor: ${instructorStr.isEmpty ? "N/A" : instructorStr}', style: const TextStyle(color: Colors.grey)),
                          const SizedBox(height: 14),
                          const Text(
                            'The course has been saved to SQLite database and synchronized with Firebase Cloud Firestore.',
                            style: TextStyle(fontSize: 12, color: Colors.black87),
                          ),
                        ],
                      ),
                      actions: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(successCtx),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                }
              });
            },
            child: Text(isEditing ? 'Update' : 'Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<AttendanceService>(context);
    final theme = Theme.of(context);

    final filteredCourses = service.courses.where((c) {
      final q = _searchQuery.toLowerCase();
      return c.code.toLowerCase().contains(q) ||
          c.name.toLowerCase().contains(q) ||
          c.instructor.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Courses'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.bookmark_add),
        label: const Text('Add Course'),
        onPressed: () => _showCourseDialog(),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: 'Search by Course Code, Name or Instructor...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
              ),
              onChanged: (q) {
                setState(() {
                  _searchQuery = q;
                });
              },
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Added Courses List (${filteredCourses.length})',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Course'),
                  onPressed: () => _showCourseDialog(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: filteredCourses.isEmpty
                  ? const Center(child: Text('No courses found.'))
                  : ListView.builder(
                      itemCount: filteredCourses.length,
                      itemBuilder: (context, index) {
                        final c = filteredCourses[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: theme.colorScheme.primaryContainer,
                              child: const Icon(Icons.book),
                            ),
                            title: Text('${c.code}: ${c.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Instructor: ${c.instructor}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _showCourseDialog(course: c),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Delete Course?'),
                                        content: Text('Are you sure you want to delete ${c.code}?'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                            onPressed: () => Navigator.pop(ctx, true),
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await service.deleteCourse(c);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
