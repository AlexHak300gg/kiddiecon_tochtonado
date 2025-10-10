import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'parent_dashboard_screen.dart';
import 'preim_screen.dart'; // ← импортируем экран преимуществ

class LoginScreenParrent extends StatefulWidget {
  const LoginScreenParrent({super.key});

  @override
  State<LoginScreenParrent> createState() => _LoginScreenParrentState();
}

class _LoginScreenParrentState extends State<LoginScreenParrent> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _db = FirebaseDatabase.instance.ref();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // 🔐 Авторизация родителя
  Future<void> _loginParent() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите email и пароль')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final snapshot = await _db.child('parents').get();

      if (!snapshot.exists || snapshot.value == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Пользователи не найдены')),
        );
        setState(() => _isLoading = false);
        return;
      }

      final raw = snapshot.value;
      if (raw is! Map) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Неверный формат данных')),
        );
        setState(() => _isLoading = false);
        return;
      }

      bool match = false;
      String parentName = "Родитель";

      for (final entry in raw.entries) {
        if (entry.value is Map) {
          final parent = Map<String, dynamic>.from(entry.value as Map);
          final pEmail = (parent['email'] ?? '').toString();
          final pPassword = (parent['password'] ?? '').toString();

          if (pEmail == email && pPassword == password) {
            match = true;
            parentName = parent['name'] ?? 'Родитель';
            break;
          }
        }
      }

      if (match) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ParentDashboardScreen(parentName: parentName),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Неверный email или пароль')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка входа: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 🎨 Декорация для полей ввода
  InputDecoration _inputDecoration(String hintText, {Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Colors.grey),
      filled: true,
      fillColor: const Color(0xFFF6F6F6),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      suffixIcon: suffixIcon,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // 🔙 Кнопка назад (возвращает на экран преимуществ)
            Positioned(
              top: 10,
              left: 10,
              child: GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PreimScreen(role: 'parent'),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF8A00), Color(0xFFFF3D00)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
                ),
              ),
            ),

            // 🧩 Основной контент
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 80),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFFFF8A00), Color(0xFFFF3D00)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Icon(Icons.person_add,
                        color: Colors.white, size: 40),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'С Возвращением!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2C2C2C),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Email
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _inputDecoration('Email адрес'),
                  ),
                  const SizedBox(height: 16),

                  // Password
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: _inputDecoration(
                      'Пароль',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: Colors.grey,
                        ),
                        onPressed: () => setState(() {
                          _obscurePassword = !_obscurePassword;
                        }),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // 🔘 Кнопка "Войти"
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _loginParent,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Ink(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFFF8A00), Color(0xFFFF3D00)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        child: Container(
                          alignment: Alignment.center,
                          child: _isLoading
                              ? const CircularProgressIndicator(
                              color: Colors.white)
                              : const Text(
                            'Войти',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
