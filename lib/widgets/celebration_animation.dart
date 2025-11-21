import 'dart:math';
import 'package:flutter/material.dart';

/// Виджет анимации конфетти для празднования достижения цели
class CelebrationAnimation extends StatefulWidget {
  final VoidCallback? onComplete;
  
  const CelebrationAnimation({super.key, this.onComplete});
  
  @override
  State<CelebrationAnimation> createState() => _CelebrationAnimationState();
}

class _CelebrationAnimationState extends State<CelebrationAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Confetti> _confettiPieces;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    
    _confettiPieces = List.generate(50, (index) => Confetti());
    
    _controller.forward().then((_) {
      widget.onComplete?.call();
    });
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
        return CustomPaint(
          painter: ConfettiPainter(
            progress: _controller.value,
            confettiPieces: _confettiPieces,
          ),
          child: Container(),
        );
      },
    );
  }
}

class Confetti {
  final double x;
  final double y;
  final Color color;
  final double size;
  final double speedX;
  final double speedY;
  final double rotation;
  
  Confetti()
      : x = Random().nextDouble(),
        y = -0.1,
        color = Color.fromRGBO(
          Random().nextInt(256),
          Random().nextInt(256),
          Random().nextInt(256),
          1,
        ),
        size = Random().nextDouble() * 10 + 5,
        speedX = Random().nextDouble() * 2 - 1,
        speedY = Random().nextDouble() * 2 + 1,
        rotation = Random().nextDouble() * 2 * pi;
}

class ConfettiPainter extends CustomPainter {
  final double progress;
  final List<Confetti> confettiPieces;
  
  ConfettiPainter({required this.progress, required this.confettiPieces});
  
  @override
  void paint(Canvas canvas, Size size) {
    for (var confetti in confettiPieces) {
      final x = confetti.x * size.width + confetti.speedX * progress * 100;
      final y = confetti.y * size.height + confetti.speedY * progress * size.height;
      
      if (y > size.height) continue;
      
      final paint = Paint()
        ..color = confetti.color
        ..style = PaintingStyle.fill;
      
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(confetti.rotation * progress * 4);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: confetti.size,
          height: confetti.size / 2,
        ),
        paint,
      );
      canvas.restore();
    }
  }
  
  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Показать диалог с анимацией достижения цели
Future<void> showCelebrationDialog(BuildContext context, String goalName) async {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            // Анимация конфетти
            const Positioned.fill(
              child: CelebrationAnimation(),
            ),
            // Центральное сообщение
            Center(
              child: Container(
                padding: const EdgeInsets.all(32),
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.emoji_events,
                      size: 80,
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '🎉 Поздравляем! 🎉',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Цель "$goalName" достигнута!',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Отлично!',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    },
  ).then((_) {
    // Задержка перед закрытием, чтобы анимация завершилась
    return Future.delayed(const Duration(milliseconds: 500));
  });
}
