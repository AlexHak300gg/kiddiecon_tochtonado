// lib/screens/child_registration_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import '../firebase_options.dart';
import 'child_home_screen.dart';

class ChildRegistrationScreen extends StatefulWidget {
  const ChildRegistrationScreen({super.key});

  @override
  State<ChildRegistrationScreen> createState() =>
      _ChildRegistrationScreenState();
}

class _ChildRegistrationScreenState extends State<ChildRegistrationScreen> {
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _parentCodeController = TextEditingController();
  String? _selectedAge;
  bool _parentApproved = false;
  bool _isLoading = false;
  DatabaseReference? _db;
  Map<String, dynamic>? _foundParent;

  @override
  void initState() {
    super.initState();
    _initFirebase();
  }

  Future<void> _initFirebase() async {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    _db = FirebaseDatabase.instance.ref();
  }

  /// 🔍 Проверка кода родителя из Firebase
  Future<void> _checkParentCode() async {
    final code = _parentCodeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите код родителя')),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);
      final snap = await _db!.child('invites/$code').get();

      if (!snap.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Код не найден или истёк')),
        );
        setState(() => _foundParent = null);
        return;
      }

      final data = Map<String, dynamic>.from(snap.value as Map);
      final expiresAt = DateTime.parse(data['expiresAt']);
      if (DateTime.now().isAfter(expiresAt)) {
        await _db!.child('invites/$code').remove();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Срок действия кода истёк')),
        );
        setState(() => _foundParent = null);
        return;
      }

      setState(() => _foundParent = data);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Родитель найден: ${data['parentName']}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 👶 Регистрация ребёнка с привязкой к родителю
  Future<void> _registerChild() async {
    if (_db == null) return;

    if (_nameController.text.isEmpty ||
        _passwordController.text.length < 6 ||
        _selectedAge == null ||
        !_parentApproved ||
        _parentCodeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пожалуйста, заполни все поля')),
      );
      return;
    }

    if (_foundParent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Проверь код родителя перед регистрацией')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final parentName = _foundParent!['parentName'];
      final parentKey = parentName.replaceAll('.', '_');
      final newChildRef = _db!.child('children').push();

      await newChildRef.set({
        'name': _nameController.text.trim(),
        'age': _selectedAge,
        'password': _passwordController.text.trim(),
        'parentName': parentName,
        'createdAt': DateTime.now().toIso8601String(),
      });

      await _db!
          .child('parents_children/$parentKey/${newChildRef.key}')
          .set({
        'childId': newChildRef.key,
        'childName': _nameController.text.trim(),
        'goal': 'Пока не установлена',
        'balance': 0,
        'progress': 0,
      });

      await _db!.child('invites/${_parentCodeController.text.trim()}').remove();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Аккаунт ребёнка успешно создан! 🎉')),
      );

      // ✅ После регистрации — переход в ChildHomeScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ChildHomeScreen(
            childName: _nameController.text.trim(),
            balance: 0,
            goalName: 'Пока не установлена',
            goalTarget: 0,
            goalProgress: 0,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка регистрации: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    bool obscure = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.nunito(
                color: Colors.black87, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  /// 🌈 Универсальная кнопка с градиентом
  Widget _gradientButton({
    required String text,
    required VoidCallback onPressed,
    bool loading = false,
  }) {
    return GestureDetector(
      onTap: loading ? null : onPressed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF6B00), Color(0xFFFF9A44)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: loading
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(
            text,
            style: GoogleFonts.nunito(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5FAFF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Color(0xFFFF6B00)),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(height: 10),
              Center(
                child: Column(
                  children: [
                    Container(
                      height: 90,
                      width: 90,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFFFF6B00), Color(0xFFFF9A44)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Icon(Icons.person_add,
                          color: Colors.white, size: 44),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      "Давай знакомиться!",
                      style: GoogleFonts.nunito(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              _buildTextField(
                label: "Как тебя зовут?",
                hint: "Введи своё имя",
                controller: _nameController,
              ),
              Text(
                "Сколько тебе лет?",
                style: GoogleFonts.nunito(
                    color: Colors.black87, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedAge,
                items: List.generate(
                  13,
                      (i) => DropdownMenuItem(
                    value: (6 + i).toString(),
                    child: Text("${6 + i} лет"),
                  ),
                ),
                onChanged: (value) => setState(() => _selectedAge = value),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: "Придумай пароль",
                hint: "Минимум 6 символов",
                controller: _passwordController,
                obscure: true,
              ),
              _buildTextField(
                label: "Код родителя",
                hint: "Введи код, который дал родитель",
                controller: _parentCodeController,
              ),
              Row(
                children: [
                  Checkbox(
                    activeColor: const Color(0xFFFF6B00),
                    value: _parentApproved,
                    onChanged: (val) =>
                        setState(() => _parentApproved = val ?? false),
                  ),
                  Expanded(
                    child: Text(
                      "Родители согласились на использование приложения.",
                      style: GoogleFonts.nunito(fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _gradientButton(
                text: "Проверить код родителя",
                onPressed: _checkParentCode,
                loading: _isLoading,
              ),
              const SizedBox(height: 14),
              _gradientButton(
                text: "Создать аккаунт",
                onPressed: _registerChild,
                loading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
