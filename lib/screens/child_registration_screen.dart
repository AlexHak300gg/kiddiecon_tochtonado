import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import '../firebase_options.dart'; // убедись, что файл существует

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
  DatabaseReference? database;

  @override
  void initState() {
    super.initState();
    _initFirebase();
  }

  Future<void> _initFirebase() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      database = FirebaseDatabase.instance.ref();
    } catch (e) {
      debugPrint("Ошибка инициализации Firebase: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ошибка инициализации Firebase: $e")),
      );
    }
  }

  Future<void> _registerChild() async {
    if (database == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Firebase не инициализирован!')),
      );
      return;
    }

    if (_nameController.text.isEmpty ||
        _selectedAge == null ||
        _passwordController.text.length < 6 ||
        !_parentApproved ||
        _parentCodeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пожалуйста, заполни все поля корректно')),
      );
      return;
    }

    if (_parentCodeController.text != '1234') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Неверный код родителя')),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);

      await database!.child('children').push().set({
        'name': _nameController.text,
        'age': _selectedAge,
        'password': _passwordController.text,
        'parentCode': _parentCodeController.text,
        'parentApproved': _parentApproved,
        'createdAt': DateTime.now().toIso8601String(),
      });

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Аккаунт успешно создан! 🎉')),
      );

      Navigator.pop(context);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка регистрации: $e')),
      );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE6F3FB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(height: 10),
              Center(
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.grey,
                      child: Icon(Icons.star, color: Colors.white, size: 36),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Давай знакомиться!",
                      style: GoogleFonts.nunito(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
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
                  10,
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
                hint: "Введи уникальный код (например 1234)",
                controller: _parentCodeController,
              ),
              Row(
                children: [
                  Checkbox(
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
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _registerChild,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    "Создать аккаунт",
                    style: TextStyle(
                        fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
