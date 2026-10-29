import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../services/attendance_service.dart';
import '../services/firebase_service.dart';
import '../widgets/responsive_layout.dart';
import 'home_screen.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _selectedDepartment = 'Computer Science';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String _selectedRole = 'Student'; // 'Student' or 'Teacher'

  final List<String> _departments = const [
    'Computer Science',
    'Software Engineering',
    'Information Technology',
    'Data Science',
    'Cyber Security',
    'Electrical Engineering',
    'Business Administration',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _studentIdController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateAccount() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final fb = FirebaseService.instance;

      final credential = await fb.signUpWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
        name: _nameController.text,
        role: _selectedRole,
        studentId: _studentIdController.text,
        department: _selectedDepartment,
      );

      if (credential?.user != null && mounted) {
        final service = Provider.of<AttendanceService>(context, listen: false);
        service.setUserRole(_selectedRole);
        await service.loadData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account created successfully! Welcome.'),
              backgroundColor: Colors.green,
            ),
          );

          // Direct navigation to HomeScreen after authorized credentials creation
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'Registration failed.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final formContent = Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Text(
                  'Create New Account',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 48), // Balance back button
            ],
          ),
          const SizedBox(height: 16),

          // Role Selection Dropdown Menu
          DropdownButtonFormField<String>(
            initialValue: _selectedRole,
            decoration: const InputDecoration(
              labelText: 'Select Role / Account Type',
              prefixIcon: Icon(Icons.person_pin_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
            ),
            items: const [
              DropdownMenuItem<String>(
                value: 'Student',
                child: Row(
                  children: [
                    Icon(Icons.person, color: Colors.teal),
                    SizedBox(width: 10),
                    Text('Student'),
                  ],
                ),
              ),
              DropdownMenuItem<String>(
                value: 'Teacher',
                child: Row(
                  children: [
                    Icon(Icons.school, color: Colors.indigo),
                    SizedBox(width: 10),
                    Text('Teacher / Admin'),
                  ],
                ),
              ),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedRole = val;
                });
              }
            },
          ),
          const SizedBox(height: 20),

          // Full Name
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              hintText: 'e.g. Alice Johnson',
              prefixIcon: Icon(Icons.person_outline),
              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
            ),
            validator: (val) => val == null || val.trim().isEmpty ? 'Please enter your full name.' : null,
          ),
          const SizedBox(height: 14),

          // Student ID / Staff ID
          TextFormField(
            controller: _studentIdController,
            decoration: InputDecoration(
              labelText: _selectedRole == 'Student' ? 'Student ID Code' : 'Staff / Employee ID',
              hintText: _selectedRole == 'Student' ? 'e.g. STU1005' : 'e.g. TCH2001',
              prefixIcon: const Icon(Icons.badge_outlined),
              border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
            ),
            validator: (val) {
              if (_selectedRole == 'Student' && (val == null || val.trim().isEmpty)) {
                return 'Student ID is required for student accounts.';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),

          // Department Dropdown Select Menu
          DropdownButtonFormField<String>(
            initialValue: _selectedDepartment,
            decoration: const InputDecoration(
              labelText: 'Select Department / Faculty',
              prefixIcon: Icon(Icons.business_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
            ),
            items: _departments.map((dept) {
              return DropdownMenuItem<String>(
                value: dept,
                child: Text(dept),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedDepartment = val;
                });
              }
            },
          ),
          const SizedBox(height: 14),

          // Email
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email Address',
              prefixIcon: Icon(Icons.email_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Please enter your email.';
              if (!val.contains('@')) return 'Enter a valid email address.';
              return null;
            },
          ),
          const SizedBox(height: 14),

          // Password
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
            ),
            validator: (val) {
              if (val == null || val.isEmpty) return 'Please enter a password.';
              if (val.length < 6) return 'Password must be at least 6 characters.';
              return null;
            },
          ),
          const SizedBox(height: 14),

          // Confirm Password
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
              ),
              border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
            ),
            validator: (val) {
              if (val == null || val.isEmpty) return 'Please confirm your password.';
              if (val != _passwordController.text) return 'Passwords do not match.';
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Submit Button
          SizedBox(
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
              onPressed: _isLoading ? null : _handleCreateAccount,
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      'Register as $_selectedRole',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ResponsiveLayout.isDesktop(context) || ResponsiveLayout.isTablet(context)
                ? SizedBox(
                    width: 520,
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: formContent,
                      ),
                    ),
                  )
                : formContent,
          ),
        ),
      ),
    );
  }
}
