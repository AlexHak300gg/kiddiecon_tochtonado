import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'role_selection_screen.dart';
import 'registration_screen.dart';
import 'child_registration_screen.dart'; // ✅ для детей

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
    Color(0xFF01ADE4),
    Color(0xFF1976D2),
    Color(0xFF5365E5),
  ];

  @override
  void initState() {
    super.initState();
    _controller =
    AnimationController(vsync: this, duration: const Duration(seconds: 10))
      ..repeat(reverse: true);
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
      MaterialPageRoute(builder: (_) => RoleSelectionScreen()), // ❌ убрали const
    );
  }

  // 🔹 Компонент карточки
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

  // 🔹 Анимированная кнопка
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
          Future.delayed(
            const Duration(milliseconds: 120),
                () => setInnerState(() => isPressed = false),
          );
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
          final begin = Alignment(-1.2 + 2.4 * _controller.value, -1);
          final end = Alignment(1.2 - 2.4 * _controller.value, 1);

          return Container(
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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60),

                    // 🔸 Главная карточка
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border:
                        Border.all(color: Colors.white.withOpacity(0.15)),
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

                    // 🔹 Преимущества
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

                    // 🔸 Кнопки
                    _animatedButton(
                      label: "Войти",
                      onPressed: () {
                        // позже добавим вход
                      },
                    ),
                    const SizedBox(height: 14),
                    _animatedButton(
                      label: "Создать аккаунт",
                      isGradient: true,
                      onPressed: () {
                        if (widget.role == 'child') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ChildRegistrationScreen(),
                            ),
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RegistrationScreen(),
                            ),
                          );
                        }
                      },
                    ),

                    const Spacer(),

                    // 🔹 Сменить роль
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
          );
        },
      ),
    );
  }
}
