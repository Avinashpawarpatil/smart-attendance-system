import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartattendance/services/attendance_service.dart';
import 'package:smartattendance/services/firebase_service.dart';
import 'package:smartattendance/utils/app_strings.dart';
import 'package:smartattendance/widgets/responsive_layout.dart';
import 'auth_wrapper.dart';
import 'teacher_dashboard.dart';
import 'student_dashboard.dart';
import 'attendance_reports_screen.dart';
import 'manage_students_screen.dart';
import 'manage_courses_screen.dart';
import 'qr_scanner_screen.dart';
import 'settings_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final service = Provider.of<AttendanceService>(context, listen: false);
        service.loadData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<AttendanceService>(context);
    final lang = service.selectedLanguage;

    final isTeacher = service.isTeacher;

    final pages = isTeacher
        ? [
            const RoleOverviewTab(),
            const TeacherDashboard(),
            const ManageStudentsScreen(),
            const AttendanceReportsScreen(),
          ]
        : [
            const RoleOverviewTab(),
            const StudentDashboard(),
            const AttendanceReportsScreen(),
          ];

    final destinations = isTeacher
        ? [
            NavigationDestination(
              icon: const Icon(Icons.dashboard_outlined),
              selectedIcon: const Icon(Icons.dashboard),
              label: AppStrings.tr('Home', lang),
            ),
            NavigationDestination(
              icon: const Icon(Icons.school_outlined),
              selectedIcon: const Icon(Icons.school),
              label: AppStrings.tr('teacher_mode', lang),
            ),
            NavigationDestination(
              icon: const Icon(Icons.people_outline),
              selectedIcon: const Icon(Icons.people),
              label: AppStrings.tr('students', lang),
            ),
            NavigationDestination(
              icon: const Icon(Icons.analytics_outlined),
              selectedIcon: const Icon(Icons.analytics),
              label: AppStrings.tr('reports', lang),
            ),
          ]
        : [
            NavigationDestination(
              icon: const Icon(Icons.dashboard_outlined),
              selectedIcon: const Icon(Icons.dashboard),
              label: AppStrings.tr('Home', lang),
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline),
              selectedIcon: const Icon(Icons.person),
              label: AppStrings.tr('student_mode', lang),
            ),
            NavigationDestination(
              icon: const Icon(Icons.analytics_outlined),
              selectedIcon: const Icon(Icons.analytics),
              label: AppStrings.tr('reports', lang),
            ),
          ];

    // Ensure _selectedIndex doesn't exceed pages bounds on role switch
    final safeIndex = _selectedIndex >= pages.length ? 0 : _selectedIndex;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.qr_code_scanner_rounded,
                size: 22,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isTeacher ? AppStrings.tr('app_title_teacher', lang) : AppStrings.tr('app_title_student', lang),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'My Profile',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          // IconButton(
          //   icon: const Icon(Icons.refresh),
          //   tooltip: 'Refresh Data',
          //   onPressed: () => service.loadData(),
          // ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'profile') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              } else if (value == 'students') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ManageStudentsScreen()),
                );
              } else if (value == 'courses') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ManageCoursesScreen()),
                );
              } else if (value == 'settings') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              } else if (value == 'logout') {
                final service = Provider.of<AttendanceService>(context, listen: false);
                await FirebaseService.instance.signOut();
                service.setUserRole('Teacher'); // Reset role state
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Logged out successfully.'),
                      backgroundColor: Colors.blue,
                    ),
                  );
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const AuthWrapper()),
                    (route) => false,
                  );
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person, size: 20, color: Colors.blue),
                    SizedBox(width: 10),
                    Text('My Profile'),
                  ],
                ),
              ),
              if (service.isTeacher)
                PopupMenuItem(
                  value: 'students',
                  child: Row(
                    children: [
                      const Icon(Icons.people, size: 20),
                      const SizedBox(width: 10),
                      Text(AppStrings.tr('manage_students', lang)),
                    ],
                  ),
                ),
              if (service.isTeacher)
                PopupMenuItem(
                  value: 'courses',
                  child: Row(
                    children: [
                      const Icon(Icons.book, size: 20),
                      const SizedBox(width: 10),
                      Text(AppStrings.tr('manage_courses', lang)),
                    ],
                  ),
                ),
              PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    const Icon(Icons.settings, size: 20, color: Colors.indigo),
                    const SizedBox(width: 10),
                    Text(AppStrings.tr('settings', lang)),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    const Icon(Icons.logout, size: 20, color: Colors.red),
                    const SizedBox(width: 10),
                    Text(AppStrings.tr('logout', lang), style: const TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: service.isLoading
          ? const Center(child: CircularProgressIndicator())
          : pages[safeIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: safeIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: destinations,
      ),
    );
  }
}

class RoleOverviewTab extends StatelessWidget {
  const RoleOverviewTab({super.key});

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<AttendanceService>(context);
    final theme = Theme.of(context);
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final lang = service.selectedLanguage;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Welcome Card
          Card(
            elevation: 0,
            color: theme.colorScheme.primaryContainer,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.tr('touchless_title', lang),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          service.isTeacher
                              ? AppStrings.tr('touchless_sub_teacher', lang)
                              : AppStrings.tr('touchless_sub_student', lang),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer.withAlpha(204),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.qr_code_2_rounded,
                    size: 56,
                    color: theme.colorScheme.onPrimaryContainer.withAlpha(178),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          Text(
            AppStrings.tr('system_stats', lang),
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          // Stat Cards Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: isDesktop ? 4 : (ResponsiveLayout.isTablet(context) ? 2 : 2),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: isDesktop ? 1.4 : 1.25,
            children: [
              _StatCard(
                title: AppStrings.tr('courses', lang),
                value: '${service.courses.length}',
                icon: Icons.book_outlined,
                color: Colors.blue,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ManageCoursesScreen()),
                  );
                },
              ),
              _StatCard(
                title: AppStrings.tr('students', lang),
                value: '${service.students.length}',
                icon: Icons.people_outline,
                color: Colors.purple,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ManageStudentsScreen()),
                  );
                },
              ),
              _StatCard(
                title: AppStrings.tr('live_sessions', lang),
                value: '${service.sessions.where((s) => s.isActive).length}',
                icon: Icons.cell_tower_outlined,
                color: service.activeSession != null ? Colors.green : Colors.grey,
                onTap: () {
                  if (service.isTeacher) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TeacherDashboard()),
                    );
                  }
                },
              ),
              _StatCard(
                title: AppStrings.tr('attendance_logs', lang),
                value: '${service.records.length}',
                icon: Icons.assignment_turned_in_outlined,
                color: Colors.orange,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AttendanceReportsScreen()),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          Text(
            AppStrings.tr('quick_actions', lang),
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          if (service.isTeacher) ...[
            Row(
              children: [
                Expanded(
                  child: _QuickActionTile(
                    title: AppStrings.tr('teacher_portal', lang),
                    subtitle: 'Start session & generate live QR code',
                    icon: Icons.school,
                    color: Colors.indigo,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TeacherDashboard()),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickActionTile(
                    title: 'Student Directory',
                    subtitle: 'View registered students list',
                    icon: Icons.people_alt_outlined,
                    color: Colors.teal,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ManageStudentsScreen()),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _QuickActionTile(
                    title: AppStrings.tr('manage_students', lang),
                    subtitle: 'Add, update or remove student profiles',
                    icon: Icons.person_add_outlined,
                    color: Colors.deepOrange,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ManageStudentsScreen()),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickActionTile(
                    title: AppStrings.tr('manage_courses', lang),
                    subtitle: 'Add or update subject definitions',
                    icon: Icons.library_books_outlined,
                    color: Colors.brown,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ManageCoursesScreen()),
                      );
                    },
                  ),
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: _QuickActionTile(
                    title: AppStrings.tr('student_portal', lang),
                    subtitle: 'View student console & manual code entry',
                    icon: Icons.person,
                    color: Colors.teal,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const StudentDashboard()),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickActionTile(
                    title: AppStrings.tr('scan_qr', lang),
                    subtitle: 'Open camera scanner to mark attendance',
                    icon: Icons.camera_alt_outlined,
                    color: Colors.green,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QrScannerScreen(student: service.currentStudent),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _QuickActionTile(
                    title: AppStrings.tr('reports', lang),
                    subtitle: 'View personal attendance logs & percentage',
                    icon: Icons.analytics_outlined,
                    color: Colors.orange,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AttendanceReportsScreen()),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: color, size: 24),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withAlpha(76)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: color.withAlpha(38),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
