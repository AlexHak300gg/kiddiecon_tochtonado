import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class FakeQrScannerScreen extends StatefulWidget {
  const FakeQrScannerScreen({super.key});

  @override
  State<FakeQrScannerScreen> createState() => _FakeQrScannerScreenState();
}

class _FakeQrScannerScreenState extends State<FakeQrScannerScreen> {
  CameraController? _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final backCamera = cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    _controller = CameraController(backCamera, ResolutionPreset.medium);
    await _controller!.initialize();
    setState(() => _isInitialized = true);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Сканер СБП", style: TextStyle(color: Colors.white)),
      ),
      body: _isInitialized
          ? Stack(
        children: [
          CameraPreview(_controller!),
          // затемнение вокруг зоны сканирования
          Container(
            color: Colors.black.withOpacity(0.4),
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  // 🔹 Анимация "сканирующей линии"
                  Positioned.fill(
                    child: AnimatedScannerLine(),
                  ),
                ],
              ),
            ),
          ),
        ],
      )
          : const Center(
        child: SpinKitFadingCircle(color: Colors.white, size: 50),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.purpleAccent,
        onPressed: () {
          Navigator.pop(context);
        },
        child: const Icon(Icons.close),
      ),
    );
  }
}

/// 🔹 Анимированная "линия" сканера
class AnimatedScannerLine extends StatefulWidget {
  const AnimatedScannerLine({super.key});

  @override
  State<AnimatedScannerLine> createState() => _AnimatedScannerLineState();
}

class _AnimatedScannerLineState extends State<AnimatedScannerLine>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: false);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Align(
          alignment: Alignment(0, (2 * _controller.value) - 1),
          child: Container(
            height: 3,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.greenAccent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      },
    );
  }
}
