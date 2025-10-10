import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'parent_dashboard_screen.dart';

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

      final data = Map<String, dynamic>.from(snapshot.value as Map);
      bool match = false;
      String parentName = "Родитель";

      for (var entry in data.entries) {
        final parent = Map<String, dynamic>.from(entry.value);
        if (parent['email'] == email && parent['password'] == password) {
          match = true;
          parentName = parent['name'] ?? 'Родитель';
          break;
        }
      }

      if (match) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => ParentDashboardScreen(parentName: parentName)),
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
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Вход для родителей"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                hintText: "Email",
                prefixIcon: const Icon(Icons.email_outlined),
                filled: true,
                fillColor: Colors.white,
                border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: "Пароль",
                prefixIcon: const Icon(Icons.lock_outline),
                filled: true,
                fillColor: Colors.white,
                border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _loginParent,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Войти"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
