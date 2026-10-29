import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/attendance_service.dart';

class AttendanceReportsScreen extends StatefulWidget {
  const AttendanceReportsScreen({super.key});

  @override
  State<AttendanceReportsScreen> createState() => _AttendanceReportsScreenState();
}

class _AttendanceReportsScreenState extends State<AttendanceReportsScreen> {
  String _selectedCourseCode = 'ALL';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<AttendanceService>(context);
    final theme = Theme.of(context);

    // Course codes for dropdown filter
    final courseCodes = ['ALL', ...service.courses.map((c) => c.code)];

    final filteredRecords = service.records.where((rec) {
      final matchesCourse = _selectedCourseCode == 'ALL' || rec.courseCode == _selectedCourseCode;
      final q = _searchQuery.toLowerCase();
      final matchesSearch = rec.studentName.toLowerCase().contains(q) ||
          rec.studentId.toLowerCase().contains(q) ||
          rec.sessionCode.toLowerCase().contains(q);
      return matchesCourse && matchesSearch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Reports & Logs'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Analytics Summary Bar
            Row(
              children: [
                Expanded(
                  child: Card(
                    color: theme.colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Text(
                            '${service.records.length}',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const Text('Total Records', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Card(
                    color: Colors.green.shade100,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Text(
                            '${service.sessions.length}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const Text('Total Sessions', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Card(
                    color: Colors.orange.shade100,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Text(
                            '${service.students.length}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepOrange,
                            ),
                          ),
                          const Text('Enrolled Students', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Search & Filter Row
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search by Student Name or ID...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onChanged: (q) {
                      setState(() {
                        _searchQuery = q;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedCourseCode,
                    decoration: const InputDecoration(
                      labelText: 'Course Filter',
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    items: courseCodes.map((code) {
                      return DropdownMenuItem<String>(
                        value: code,
                        child: Text(code),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedCourseCode = val;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Text(
              'Filtered Log Results (${filteredRecords.length})',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Log Table List
            Expanded(
              child: filteredRecords.isEmpty
                  ? const Center(child: Text('No attendance records match your filters.'))
                  : ListView.builder(
                      itemCount: filteredRecords.length,
                      itemBuilder: (context, index) {
                        final rec = filteredRecords[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Colors.green,
                              child: Icon(Icons.check, color: Colors.white, size: 20),
                            ),
                            title: Text(
                              '${rec.studentName} (${rec.studentId})',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              'Course: ${rec.courseCode} • Session: ${rec.sessionCode}\nTimestamp: ${rec.timestamp}',
                            ),
                            isThreeLine: true,
                            trailing: const Chip(
                              label: Text('PRESENT', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                              backgroundColor: Color(0xFFE8F5E9),
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
