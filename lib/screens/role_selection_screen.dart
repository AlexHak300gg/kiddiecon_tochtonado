import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'preim_screen.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen>
    with TickerProviderStateMixin {
  late AnimationController _gradientController;
  late AnimationController _glowController;
  late AnimationController _flyInController;

  late Animation<Offset> _flyPath;
  late Animation<double> _scaleBounce;

  final List<Color> colors = [
    const Color(0xFF171D33), // глубокий синий
    const Color(0xFF5365E5), // голубой
    const Color(0xFFF6514C), // жёлтый
    const Color(0xFFFDB901), // оранжево-красный
  ];

  @override
  void initState() {
    super.initState();

    // 🌈 Градиент плавно «переливается»
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat(reverse: true);

    // 💫 Пульсация и лёгкое движение звезды
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
      lowerBound: 0.85,
      upperBound: 1.15,
    )..repeat(reverse: true);

    // ⭐ Анимация прилёта звезды
    _flyInController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    // 🚀 Дуга полёта (плавная, слегка выгнутая вверх)
    _flyPath = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: const Offset(-1.5, -1.4),
          end: const Offset(-0.4, -0.6),
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: const Offset(-0.4, -0.6),
          end: const Offset(0.0, 0.0),
        ).chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 60,
      ),
    ]).animate(_flyInController);

    // 🎯 Мягкий подпрыгивающий масштаб
    _scaleBounce = Tween<double>(begin: 0.4, end: 1.0)
        .animate(CurvedAnimation(parent: _flyInController, curve: Curves.easeOutBack));

    _flyInController.forward();
  }

  @override
  void dispose() {
    _gradientController.dispose();
    _glowController.dispose();
    _flyInController.dispose();
    super.dispose();
  }

  Future<void> _selectRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userRole', role);
    
    if (!mounted) return;
    
    // После выбора роли, перенаправляем на PreimScreen для регистрации/входа
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PreimScreen(role: role),
      ),
    );
  }

  Widget _animatedButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required Gradient gradient,
  }) {
    bool isPressed = false;
    return StatefulBuilder(
      builder: (context, setInnerState) {
        return GestureDetector(
          onTapDown: (_) => setInnerState(() => isPressed = true),
          onTapUp: (_) {
            Future.delayed(const Duration(milliseconds: 100),
                    () => setInnerState(() => isPressed = false));
            onTap();
          },
          onTapCancel: () => setInnerState(() => isPressed = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            transform: Matrix4.identity()
              ..scale(isPressed ? 0.95 : 1.0, isPressed ? 0.95 : 1.0),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: gradient,
              boxShadow: isPressed
                  ? []
                  : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  offset: const Offset(0, 4),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: AnimatedBuilder(
        animation:
        Listenable.merge([_gradientController, _glowController, _flyInController]),
        builder: (_, __) {
          // движение фона (параллакс)
          final t = _gradientController.value;
          final begin = Alignment(-1.0 + 2 * t, -1.0);
          final end = Alignment(1.0 - 2 * t, 1.0);

          // лёгкое покачивание звезды после посадки
          final dx = 4 * sin(_gradientController.value * 2 * pi);
          final dy = 2 * cos(_gradientController.value * 2 * pi);

          return Container(
            width: size.width,
            height: size.height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: begin,
                end: end,
                colors: colors,
                tileMode: TileMode.mirror,
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Spacer(),

                    // 🌟 Логотип и звезда
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "KiddieCoin",
                          style: GoogleFonts.nunito(
                            fontSize: 52,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 10),

                        // ⭐ Плавный прилёт и мягкий пульс
                        Transform.translate(
                          offset: Offset(
                            _flyPath.value.dx * size.width * 0.4 + dx,
                            _flyPath.value.dy * size.height * 0.4 + dy,
                          ),
                          child: Transform.scale(
                            scale: _scaleBounce.value * _glowController.value,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.amber.withOpacity(0.8),
                                    blurRadius: 25 + 8 * _glowController.value,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.star_rounded,
                                color: Colors.amber,
                                size: 60,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),
                    Text(
                      "Монетка за монеткой —\nк большой цели!",
                      style: GoogleFonts.nunito(
                        fontSize: 18,
                        color: Colors.white,
                        height: 1.4,
                      ),
                    ),

                    const Spacer(),

                    Center(
                      child: Text(
                        "Выберите свою роль для продолжения",
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.85),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 🔘 Кнопки выбора роли
                    Row(
                      children: [
                        Expanded(
                          child: _animatedButton(
                            label: "Родитель",
                            icon: Icons.person,
                            onTap: () => _selectRole('parent'),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF171D33), Color(0xFF5365E5)],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _animatedButton(
                            label: "Ребёнок",
                            icon: Icons.child_care,
                            onTap: () => _selectRole('child'),
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF6514C), Color(0xFFFDB901)],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
