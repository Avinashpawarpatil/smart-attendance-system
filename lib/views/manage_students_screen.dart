import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/student.dart';
import '../services/attendance_service.dart';

const List<String> kDepartmentsList = [
  'Computer Science',
  'Software Engineering',
  'Information Technology',
  'Data Science',
  'Cyber Security',
  'Electrical Engineering',
  'Business Administration',
];

void showAddStudentDialog(BuildContext context, {Student? student}) {
  final service = Provider.of<AttendanceService>(context, listen: false);
  final isEditing = student != null;

  final idController = TextEditingController(text: student?.studentId ?? '');
  final nameController = TextEditingController(text: student?.name ?? '');
  final emailController = TextEditingController(text: student?.email ?? '');

  String selectedDept = student?.department ?? kDepartmentsList.first;
  if (!kDepartmentsList.contains(selectedDept)) {
    selectedDept = kDepartmentsList.first;
  }

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Text(isEditing ? 'Edit Student Profile' : 'Add New Student'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: idController,
                decoration: const InputDecoration(
                  labelText: 'Student ID Code',
                  hintText: 'e.g. STU1005',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                enabled: !isEditing,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 12),

              // Department Select Dropdown Menu
              DropdownButtonFormField<String>(
                initialValue: selectedDept,
                decoration: const InputDecoration(
                  labelText: 'Select Department',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business_outlined),
                ),
                items: kDepartmentsList.map((dept) {
                  return DropdownMenuItem<String>(
                    value: dept,
                    child: Text(dept),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setDialogState(() {
                      selectedDept = val;
                    });
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final idStr = idController.text.trim();
              final nameStr = nameController.text.trim();
              final emailStr = emailController.text.trim();

              if (idStr.isEmpty || nameStr.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Student ID and Name are required.')),
                );
                return;
              }

              final navigator = Navigator.of(ctx);
              final parentContext = context;

              try {
                if (isEditing) {
                  final updated = student.copyWith(
                    name: nameStr,
                    email: emailStr,
                    department: selectedDept,
                  );
                  await service.updateStudent(updated);
                } else {
                  final newSt = Student(
                    studentId: idStr,
                    name: nameStr,
                    email: emailStr,
                    department: selectedDept,
                  );
                  await service.addStudent(newSt);
                }
              } catch (e) {
                debugPrint('Error saving student: $e');
              }

              navigator.pop(); // Close form dialog

              // Safely queue success popup after Navigator route lock releases
              Future.microtask(() {
                if (parentContext.mounted) {
                  // Show SnackBar
                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    SnackBar(
                      content: Text(isEditing ? 'Student updated successfully!' : 'Student $nameStr added successfully!'),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 3),
                    ),
                  );

                  // Display "Student Added / Updated Successfully" popup dialog
                  showDialog(
                    context: parentContext,
                    builder: (successCtx) => AlertDialog(
                      title: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 30),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              isEditing ? 'Student Updated' : 'Student Added Successfully',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                          ),
                        ],
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Name: $nameStr', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 6),
                          Text('Student ID: $idStr', style: const TextStyle(color: Colors.grey)),
                          Text('Department: $selectedDept', style: const TextStyle(color: Colors.grey)),
                          Text('Email: ${emailStr.isEmpty ? "N/A" : emailStr}', style: const TextStyle(color: Colors.grey)),
                          const SizedBox(height: 14),
                          // const Text(
                          //   'The student profile is now saved.',
                          //   style: TextStyle(fontSize: 12, color: Colors.black87),
                          // ),
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
    ),
  );
}

class ManageStudentsScreen extends StatefulWidget {
  const ManageStudentsScreen({super.key});

  @override
  State<ManageStudentsScreen> createState() => _ManageStudentsScreenState();
}

class _ManageStudentsScreenState extends State<ManageStudentsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch() {
    setState(() {
      _searchQuery = _searchController.text.trim();
    });
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<AttendanceService>(context);
    final theme = Theme.of(context);

    final filteredStudents = service.students.where((st) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return st.name.toLowerCase().contains(q) ||
          st.studentId.toLowerCase().contains(q) ||
          st.department.toLowerCase().contains(q) ||
          st.email.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Students'),
      ),
      floatingActionButton: service.isTeacher
          ? FloatingActionButton.extended(
              icon: const Icon(Icons.person_add),
              label: const Text('Add Student'),
              onPressed: () => showAddStudentDialog(context),
            )
          : null,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Input Field with Interactive Search & Clear Buttons
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by Student Name, ID or Department...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: _clearSearch,
                            )
                          : null,
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    onChanged: (q) {
                      setState(() {
                        _searchQuery = q.trim();
                      });
                    },
                    onSubmitted: (_) => _performSearch(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.search, size: 20),
                  label: const Text('Search'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _performSearch,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Active Search Filter Chip Indicator
            if (_searchQuery.isNotEmpty) ...[
              Wrap(
                children: [
                  InputChip(
                    avatar: const Icon(Icons.filter_list, size: 16),
                    label: Text('Filter: "$_searchQuery" (${filteredStudents.length} matches)'),
                    onDeleted: _clearSearch,
                    deleteIcon: const Icon(Icons.cancel, size: 16),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Added Students List (${filteredStudents.length})',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (service.isTeacher)
                  TextButton.icon(
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add New'),
                    onPressed: () => showAddStudentDialog(context),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: filteredStudents.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.person_search, size: 48, color: Colors.grey),
                          const SizedBox(height: 12),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'No students match "$_searchQuery"'
                                : 'No students found.',
                            style: const TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          if (_searchQuery.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: _clearSearch,
                              child: const Text('Clear Search Filter'),
                            ),
                          ],
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredStudents.length,
                      itemBuilder: (context, index) {
                        final st = filteredStudents[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: theme.colorScheme.primaryContainer,
                              child: Text(
                                st.name.isNotEmpty ? st.name[0].toUpperCase() : 'S',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(st.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('ID: ${st.studentId} • ${st.department}\n${st.email}'),
                            isThreeLine: true,
                            trailing: service.isTeacher
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.blue),
                                        onPressed: () => showAddStudentDialog(context, student: st),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () async {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: const Text('Delete Student?'),
                                              content: Text('Are you sure you want to remove ${st.name}?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(ctx, false),
                                                  child: const Text('Cancel'),
                                                ),
                                                ElevatedButton(
                                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                                  onPressed: () => Navigator.pop(ctx, true),
                                                  child: const Text('Delete'),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (confirm == true) {
                                            await service.deleteStudent(st);
                                          }
                                        },
                                      ),
                                    ],
                                  )
                                : null,
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
