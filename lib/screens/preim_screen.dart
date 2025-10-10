import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Импорты экранов
import 'role_selection_screen.dart';
import 'child_registration_screen.dart';
import 'login_screen_parrent.dart';
import 'register_screen_parrant.dart';
import 'children_search_screen.dart';

class PreimScreen extends StatefulWidget {
  final String role;
  const PreimScreen({super.key, required this.role});

  @override
  State<PreimScreen> createState() => _PreimScreenState();
}

class _PreimScreenState extends State<PreimScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  final List<Color> colors = const [
    Color(0xFF1976D2),
    Color(0xFF5365E5),
    Color(0xFF1976D2),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _resetRole() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userRole');
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
    );
  }

  Widget _buildAnimatedFeature({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF6514C), Color(0xFFFDB901)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.nunito(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _animatedButton({
    required String label,
    required VoidCallback onPressed,
    bool isGradient = false,
  }) {
    return StatefulBuilder(builder: (context, setInnerState) {
      bool isPressed = false;
      return GestureDetector(
        onTapDown: (_) => setInnerState(() => isPressed = true),
        onTapUp: (_) {
          Future.delayed(const Duration(milliseconds: 120),
                  () => setInnerState(() => isPressed = false));
          onPressed();
        },
        onTapCancel: () => setInnerState(() => isPressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          width: double.infinity,
          height: 55,
          transform: Matrix4.identity()
            ..scale(isPressed ? 0.97 : 1.0, isPressed ? 0.97 : 1.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: isGradient
                ? const LinearGradient(
              colors: [Color(0xFFF6514C), Color(0xFFFDB901)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
                : null,
            color: isGradient ? null : Colors.white.withOpacity(0.1),
            border: isGradient
                ? null
                : Border.all(color: Colors.white.withOpacity(0.5), width: 1.3),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.nunito(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) {
          final double t = _controller.value;
          return Stack(
            children: [
              // 🔹 Фон с градиентом
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: colors,
                  ),
                ),
              ),

              // 🔹 Анимация огненных шаров
              Positioned.fill(
                child: CustomPaint(painter: FireOrbPainter(progress: t)),
              ),

              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 60),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.15)),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFF6514C), Color(0xFFFDB901)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: const Icon(Icons.monetization_on,
                                  color: Colors.white, size: 48),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              "KiddieCoin",
                              style: GoogleFonts.nunito(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "Превратите накопление финансов\nв увлекательную игру для детей",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.nunito(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 15,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                      _buildAnimatedFeature(
                        icon: Icons.savings,
                        title: "Учись копить",
                        subtitle: "Ставь цели и копи на мечты",
                      ),
                      _buildAnimatedFeature(
                        icon: Icons.bar_chart,
                        title: "Отслеживай расходы",
                        subtitle: "Контролируй свой бюджет",
                      ),
                      _buildAnimatedFeature(
                        icon: Icons.emoji_events,
                        title: "Получай награды",
                        subtitle: "Зарабатывай баллы за достижения",
                      ),

                      const SizedBox(height: 24),
                      _animatedButton(
                        label: "Войти",
                        onPressed: () {
                          if (widget.role == 'parent') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const LoginScreenParrent()),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ChildrenSearchScreen(),
                              ),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 14),

                      // ✅ Исправленный переход на регистрацию родителя
                      _animatedButton(
                        label: "Создать аккаунт",
                        isGradient: true,
                        onPressed: () {
                          if (widget.role == 'child') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                  const ChildRegistrationScreen()),
                            );
                          } else {
                            Navigator.of(context).push(
                              PageRouteBuilder(
                                pageBuilder: (context, animation,
                                    secondaryAnimation) =>
                                    RegisterScreenParrent(),
                                transitionsBuilder: (context, animation,
                                    secondaryAnimation, child) {
                                  const begin = Offset(1.0, 0.0);
                                  const end = Offset.zero;
                                  const curve = Curves.easeInOut;
                                  final tween = Tween(
                                      begin: begin, end: end)
                                      .chain(CurveTween(curve: curve));
                                  return SlideTransition(
                                    position: animation.drive(tween),
                                    child: child,
                                  );
                                },
                                transitionDuration:
                                const Duration(milliseconds: 400),
                              ),
                            );
                          }
                        },
                      ),

                      const Spacer(),
                      TextButton(
                        onPressed: _resetRole,
                        child: Text(
                          "Сменить роль (${widget.role == 'parent' ? 'Родитель' : 'Ребёнок'})",
                          style: GoogleFonts.nunito(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 14,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// 🔸 Painter для мягких светящихся шаров
class FireOrbPainter extends CustomPainter {
  final double progress;
  FireOrbPainter({required this.progress});

  final List<_Orb> orbs = [
    _Orb(yOffset: 0.25, amplitude: 0.05, size: 22, speed: 0.5, phase: 0),
    _Orb(yOffset: 0.48, amplitude: 0.07, size: 25, speed: 0.6, phase: pi / 2),
    _Orb(yOffset: 0.68, amplitude: 0.06, size: 24, speed: 0.55, phase: pi),
    _Orb(yOffset: 0.84, amplitude: 0.04, size: 23, speed: 0.65, phase: 3 * pi / 2),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final orb in orbs) {
      final t = (progress * orb.speed + orb.phase / (2 * pi)) % 1.0;
      final x = size.width * (-0.2 + 1.4 * t);
      final y = size.height *
          (orb.yOffset + orb.amplitude * sin(2 * pi * t + orb.phase));

      final pulse = 1 + 0.1 * sin(4 * pi * t);

      final trail = Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFDB901).withOpacity(0.06),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: Offset(x, y), radius: 60));

      canvas.drawCircle(Offset(x, y), 60, trail);

      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFDB901),
            const Color(0xFFF6514C).withOpacity(0.4),
            Colors.transparent,
          ],
          stops: const [0.0, 0.4, 1.0],
        ).createShader(Rect.fromCircle(center: Offset(x, y), radius: orb.size * pulse))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawCircle(Offset(x, y), orb.size * pulse, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _Orb {
  final double yOffset;
  final double amplitude;
  final double size;
  final double speed;
  final double phase;

  _Orb({
    required this.yOffset,
    required this.amplitude,
    required this.size,
    required this.speed,
    required this.phase,
  });
}
