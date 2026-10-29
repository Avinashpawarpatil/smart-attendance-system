import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../models/student.dart';
import '../services/attendance_service.dart';

class QrScannerScreen extends StatefulWidget {
  final Student? student;

  const QrScannerScreen({super.key, this.student});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> with WidgetsBindingObserver {
  late final MobileScannerController controller;
  bool _isProcessing = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!controller.value.isInitialized) return;

    switch (state) {
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        break;
      case AppLifecycleState.resumed:
        _retryCamera();
        break;
      case AppLifecycleState.inactive:
        controller.stop();
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller.dispose();
    super.dispose();
  }

  Future<void> _retryCamera() async {
    setState(() {
      _hasError = false;
    });
    try {
      await controller.start();
    } catch (_) {
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? rawValue = barcodes.first.rawValue;
    if (rawValue == null || rawValue.isEmpty) return;

    final service = Provider.of<AttendanceService>(context, listen: false);
    final activeStudent = widget.student ?? service.currentStudent;

    if (activeStudent == null) {
      if (_isProcessing) return;
      setState(() {
        _isProcessing = true;
      });

      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('No Student Selected'),
          content: const Text('Please select an active student profile before scanning.'),
          actions: [
            ElevatedButton(
              onPressed: () {
                final nav = Navigator.of(context);
                nav.pop(); // Close dialog
                Future.microtask(() {
                  if (mounted) nav.pop(); // Pop scanner screen
                });
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    final result = await service.markAttendanceFromQr(
      qrPayload: rawValue,
      studentId: activeStudent.studentId,
    );

    if (!mounted) return;

    final isSuccess = result.startsWith('SUCCESS');

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              color: isSuccess ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 10),
            Text(isSuccess ? 'Attendance Marked!' : 'Scan Status'),
          ],
        ),
        content: Text(result),
        actions: [
          ElevatedButton(
            onPressed: () {
              final nav = Navigator.of(context);
              nav.pop(); // Close result dialog
              Future.microtask(() {
                if (mounted) nav.pop(); // Return back to dashboard
              });
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _formatScannerError(MobileScannerException error) {
    switch (error.errorCode) {
      case MobileScannerErrorCode.permissionDenied:
        return 'Camera permission was denied.\nPlease allow camera permission in system settings or tap Retry.';
      case MobileScannerErrorCode.unsupported:
        return 'Camera is not supported on this device.';
      case MobileScannerErrorCode.controllerUninitialized:
        return 'Camera controller uninitialized. Tap Retry to start.';
      default:
        return error.errorDetails?.message ?? 'Camera unavailable. Tap Retry to start camera.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<AttendanceService>(context);
    final activeStudent = widget.student ?? service.currentStudent;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Class Session QR'),
        actions: [
          ValueListenableBuilder(
            valueListenable: controller,
            builder: (context, state, child) {
              if (!state.isInitialized) return const SizedBox.shrink();
              return Row(
                children: [
                  IconButton(
                    color: Colors.white,
                    icon: state.torchState == TorchState.on
                        ? const Icon(Icons.flash_on, color: Colors.yellow)
                        : const Icon(Icons.flash_off, color: Colors.grey),
                    onPressed: () => controller.toggleTorch(),
                  ),
                  IconButton(
                    color: Colors.white,
                    icon: const Icon(Icons.cameraswitch),
                    onPressed: () => controller.switchCamera(),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: _onDetect,
            errorBuilder: (context, error, child) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && !_hasError) {
                  setState(() {
                    _hasError = true;
                  });
                }
              });

              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.videocam_off, size: 64, color: Colors.amber),
                      const SizedBox(height: 16),
                      Text(
                        'Camera Unavailable',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _formatScannerError(error),
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _retryCamera,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry / Grant Permission'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Go Back'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          // Viewfinder overlay - only shown when camera works without error
          if (!_hasError) ...[
            Align(
              alignment: Alignment.center,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.green, width: 3),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  activeStudent != null
                      ? 'Student: ${activeStudent.name} (${activeStudent.studentId})\nAlign camera with Teacher QR code'
                      : 'Select active student profile before scanning',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
