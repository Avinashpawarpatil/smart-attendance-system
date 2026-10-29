import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/attendance_session.dart';
import '../services/attendance_service.dart';

class QrGeneratorScreen extends StatefulWidget {
  final AttendanceSession session;

  const QrGeneratorScreen({super.key, required this.session});

  @override
  State<QrGeneratorScreen> createState() => _QrGeneratorScreenState();
}

class _QrGeneratorScreenState extends State<QrGeneratorScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(int totalSeconds) {
    if (totalSeconds <= 0) return '00:00';
    final mins = totalSeconds ~/ 60;
    final secs = totalSeconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<AttendanceService>(context);
    final theme = Theme.of(context);
    final attendeeCount = service.getAttendeeCountForSession(widget.session.sessionCode);
    final records = service.records.where((r) => r.sessionCode == widget.session.sessionCode).toList();

    final isExpired = widget.session.isExpired;
    final remainingSecs = widget.session.remainingSeconds;

    final screenWidth = MediaQuery.of(context).size.width;
    final qrSize = (screenWidth - 100.0).clamp(180.0, 260.0);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.session.courseCode} Live Session'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Copy Session Code',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: widget.session.sessionCode));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Session Code copied: ${widget.session.sessionCode}')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Live Status & Expiry Timer Badge
              if (isExpired) ...[
                Chip(
                  avatar: const Icon(Icons.timer_off, color: Colors.red),
                  label: const Text('QR CODE EXPIRED', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                  backgroundColor: Colors.red.shade50,
                ),
              ] else ...[
                Chip(
                  avatar: const Icon(Icons.timer, color: Colors.green),
                  label: Text(
                    'QR VALID • ${_formatDuration(remainingSecs)} REMAINING',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                  backgroundColor: Colors.green.shade50,
                ),
              ],
              const SizedBox(height: 16),

              Text(
                widget.session.courseName,
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Course: ${widget.session.courseCode}',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 20),

              // Responsive QR Code Render Container
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Opacity(
                        opacity: isExpired ? 0.3 : 1.0,
                        child: QrImageView(
                          data: widget.session.toQrPayload(),
                          version: QrVersions.auto,
                          size: qrSize,
                          backgroundColor: Colors.white,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: Colors.black,
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SelectableText(
                        'Code: ${widget.session.sessionCode}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.1),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isExpired
                            ? 'Session validity period ended. Please start a new session.'
                            : 'Scan via Student App Camera or enter code manually',
                        style: TextStyle(
                          fontSize: 12,
                          color: isExpired ? Colors.red : Colors.grey,
                          fontWeight: isExpired ? FontWeight.bold : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Live Counter Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.people, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'Live Attendance: $attendeeCount / ${service.students.length}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Attendees Live List
              if (records.isNotEmpty) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Checked-In Students (${records.length})',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: records.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final rec = records[index];
                      return ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.green,
                          child: Icon(Icons.check, color: Colors.white),
                        ),
                        title: Text(rec.studentName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('ID: ${rec.studentId} • ${rec.timestamp}'),
                        trailing: const Chip(
                          label: Text('PRESENT', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                          backgroundColor: Color(0xFFE8F5E9),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
