import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../firebase_options.dart';
import 'child_home_screen.dart';
import 'qr_scanner_screen.dart';
import 'setup_security_screen.dart';

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

  Future<void> _scanQrCode() async {
    final code = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );

    if (code != null && code.isNotEmpty) {
      _parentCodeController.text = code.toUpperCase();
      await _checkParentCode();
    }
  }

  Future<void> _checkParentCode() async {
    final code = _parentCodeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите код родителя')),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);
      final snap = await _db!.child('inviteCodes/$code').get();

      if (!snap.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Код не найден или истёк'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _foundParent = null);
        return;
      }

      final data = Map<String, dynamic>.from(snap.value as Map);

      if (data['isUsed'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Этот код уже использован'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _foundParent = null);
        return;
      }

      final expiresAt = DateTime.parse(data['expiresAt']);
      if (DateTime.now().isAfter(expiresAt)) {
        await _db!.child('inviteCodes/$code').remove();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Срок действия кода истёк'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _foundParent = null);
        return;
      }

      final parentKey = data['parentKey'];
      final parentExists = await _db!.child('parents/$parentKey').get();
      if (!parentExists.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Родитель не найден'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _foundParent = null);
        return;
      }

      final childrenSnap = await _db!.child('parents_children/$parentKey').get();
      int childrenCount = 0;
      if (childrenSnap.exists && childrenSnap.value != null) {
        final children = childrenSnap.value as Map;
        childrenCount = children.length;
      }

      if (childrenCount >= 5) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('У родителя уже максимальное количество детей (5)'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _foundParent = null);
        return;
      }

      setState(() => _foundParent = data);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Родитель найден: ${data['parentName']}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showConfirmationDialog() async {
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

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Подтверждение привязки',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Вы собираетесь привязаться к родителю:',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF6F6BF8).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person, color: Color(0xFF6F6BF8)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _foundParent!['parentName'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'После привязки вы сможете получать деньги и выполнять задания.',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6F6BF8),
            ),
            child: const Text('Подтвердить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _registerChild();
    }
  }

  Future<void> _registerChild() async {
    setState(() => _isLoading = true);

    try {
      final parentName = _foundParent!['parentName'];
      final parentKey = _foundParent!['parentKey'];
      final code = _parentCodeController.text.trim().toUpperCase();
      final newChildRef = _db!.child('children').push();

      await newChildRef.set({
        'name': _nameController.text.trim(),
        'age': _selectedAge,
        'password': _passwordController.text.trim(),
        'parentName': parentName,
        'parentKey': parentKey,
        'createdAt': DateTime.now().toIso8601String(),
      });

      await _db!
          .child('parents_children/$parentKey/${newChildRef.key}')
          .set({
        'childId': newChildRef.key,
        'childName': _nameController.text.trim(),
        'goal': 'Цель не установлена',
        'target': 0,
        'balance': 0,
        'progress': 0,
      });

      await _db!.child('inviteCodes/$code').update({
        'isUsed': true,
        'usedBy': newChildRef.key,
        'usedAt': DateTime.now().toIso8601String(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Аккаунт ребёнка успешно создан! 🎉'),
          backgroundColor: Colors.green,
        ),
      );

      if (!mounted) return;

      // Сохраняем данные пользователя в SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userRole', 'child');
      await prefs.setString('childId', newChildRef.key!);
      await prefs.setString('childName', _nameController.text.trim());
      await prefs.setString('parentKey', parentKey);
      await prefs.setString('parentName', parentName);
      await prefs.setBool('firstLoginDone', true);

      // После успешной регистрации ребёнка, перенаправляем на SetupSecurityScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SetupSecurityScreen(
            userRole: 'child',
            isFirstTime: true,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка регистрации: $e'),
          backgroundColor: Colors.red,
        ),
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

  Widget _gradientButton({
    required String text,
    required VoidCallback onPressed,
    bool loading = false,
    Color? color,
    IconData? icon,
  }) {
    return GestureDetector(
      onTap: loading ? null : onPressed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: color == null
              ? const LinearGradient(
                  colors: [Color(0xFFFF6B00), Color(0xFFFF9A44)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: color,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: loading
              ? const CircularProgressIndicator(color: Colors.white)
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, color: Colors.white),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      text,
                      style: GoogleFonts.nunito(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
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
              Text(
                "Код родителя",
                style: GoogleFonts.nunito(
                    color: Colors.black87, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _parentCodeController,
                decoration: InputDecoration(
                  hintText: "Введи код или отсканируй QR",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.qr_code_scanner, color: Color(0xFFFF6B00)),
                    onPressed: _scanQrCode,
                    tooltip: 'Сканировать QR-код',
                  ),
                ),
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 16),
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
                icon: Icons.search,
              ),
              const SizedBox(height: 14),
              _gradientButton(
                text: "Создать аккаунт",
                onPressed: _showConfirmationDialog,
                loading: _isLoading,
                icon: Icons.check_circle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
