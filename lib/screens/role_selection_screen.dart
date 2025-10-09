import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled12/screens/register_screen_parrant.dart';
import 'register_screen_parrant.dart'; // 👈 добавлено
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

  final List<Color> colors = [
    const Color(0xFF1E3A8A),
    const Color(0xFFF6514C),
    const Color(0xFFFDB901),
  ];

  final List<double> stops = [0.0, 0.5, 1.0];

  @override
  void initState() {
    super.initState();
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat(reverse: true);

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
      lowerBound: 0.6,
      upperBound: 1.0,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _gradientController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _selectRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userRole', role);

    // ✅ Изменено: если выбрал "Родитель" → переход на экран регистрации
    if (role == 'parent') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const RegisterScreenParrant()),
      );
    } else {
      // если ребёнок — оставим поведение как было
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => PreimScreen(role: role)),
      );
    }
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
        animation: Listenable.merge([_gradientController, _glowController]),
        builder: (_, __) {
          double t = _gradientController.value;
          Alignment begin = Alignment(0.0, 1.0 - 2 * t);
          Alignment end = Alignment(0.0, -1.0 - 2 * t);

          return Container(
            width: size.width,
            height: size.height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: begin,
                end: end,
                colors: colors,
                stops: stops,
                tileMode: TileMode.mirror,
              ),
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(left: 30.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "KiddieCoin",
                          style: GoogleFonts.nunito(
                            fontSize: 56,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        AnimatedBuilder(
                          animation: _glowController,
                          builder: (context, child) => Transform.scale(
                            scale: 1 + 0.1 * _glowController.value,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.amber
                                        .withOpacity(0.6 * _glowController.value),
                                    blurRadius: 20,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.star_rounded,
                                color: Colors.amber,
                                size: 65,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.only(left: 30.0),
                    child: Text(
                      "Монетка за монеткой —\nк большой цели!",
                      style: GoogleFonts.nunito(
                        fontSize: 18,
                        color: Colors.white,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Center(
                    child: Text(
                      "Выберите свою роль для продолжения",
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: _animatedButton(
                            label: "Родитель",
                            icon: Icons.person,
                            onTap: () => _selectRole('parent'),
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF1E3A8A),
                                Color(0xFF3B82F6),
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
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
                              colors: [
                                Color(0xFFF6514C),
                                Color(0xFFFDB901),
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
