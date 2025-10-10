import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'child_home_screen.dart';

class ChildrenSearchScreen extends StatefulWidget {
  const ChildrenSearchScreen({super.key});

  @override
  State<ChildrenSearchScreen> createState() => _ChildrenSearchScreenState();
}

class _ChildrenSearchScreenState extends State<ChildrenSearchScreen> {
  final _db = FirebaseDatabase.instance.ref();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();

  bool _loading = false;
  bool _isConnecting = false;
  Map<String, dynamic>? _foundParent;

  /// 🔍 Поиск родителя по коду
  Future<void> _searchParent() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Введите код приглашения")),
      );
      return;
    }

    setState(() {
      _loading = true;
      _foundParent = null;
    });

    try {
      final snapshot = await _db.child('invites/$code').get();

      if (!snapshot.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Код не найден или истёк')),
        );
      } else {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        final expiresAt = DateTime.parse(data['expiresAt']);

        if (DateTime.now().isAfter(expiresAt)) {
          await _db.child('invites/$code').remove();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Срок действия кода истёк')),
          );
        } else {
          setState(() {
            _foundParent = data;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ошибка: $e")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  /// 👶 Привязка ребёнка к родителю
  Future<void> _connectToParent() async {
    if (_isConnecting) return;
    if (_foundParent == null || _nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите имя ребёнка')),
      );
      return;
    }

    setState(() {
      _loading = true;
      _isConnecting = true;
    });

    try {
      final parentName = _foundParent!['parentName'] ?? "Без имени";
      final parentCode = _codeController.text.trim();

      String sanitizeKey(String key) {
        return key.replaceAll(RegExp(r'[.#$\[\]]'), '_');
      }

      final safeParentKey = sanitizeKey(parentName);

      final newChildRef = _db.child('children').push();
      await newChildRef.set({
        'name': _nameController.text.trim(),
        'parentName': parentName,
        'parentCode': parentCode,
        'goal': 'Пока не установлена',
        'balance': 0,
        'createdAt': DateTime.now().toIso8601String(),
      });

      await _db
          .child('parents_children')
          .child(safeParentKey)
          .child(newChildRef.key!)
          .set({
        'childId': newChildRef.key,
        'childName': _nameController.text.trim(),
        'goal': 'Пока не установлена',
        'balance': 0,
        'progress': 0,
      });

      await _db.child('invites/$parentCode').remove();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ChildHomeScreen(
            childName: _nameController.text.trim(),
            balance: 2450,
            goalName: 'Велосипед',
            goalTarget: 15000,
            goalProgress: 6750,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при добавлении: $e')),
      );
    } finally {
      setState(() {
        _loading = false;
        _isConnecting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // 🔙 Кнопка "Назад" (в левом верхнем углу)
            Positioned(
              top: 10,
              left: 10,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6B00), Color(0xFFFF9A44)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.arrow_back,
                      color: Colors.white, size: 22),
                ),
              ),
            ),

            // 🧩 Основное содержимое
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    // 🟠 Иконка
                    Container(
                      height: 80,
                      width: 80,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFFFF6B00), Color(0xFFFF9A44)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Icon(Icons.person_add_alt_1,
                          size: 40, color: Colors.white),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      "С Возвращением!",
                      style: GoogleFonts.nunito(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Поле ввода кода
                    TextField(
                      controller: _codeController,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        prefixIcon:
                        const Icon(Icons.person_outline, color: Colors.grey),
                        hintText: "Введите код приглашения от родителя",
                        hintStyle:
                        GoogleFonts.nunito(color: Colors.black54, fontSize: 14),
                        filled: true,
                        fillColor: const Color(0xFFF6F8FB),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Кнопка “Найти родителя”
                    GestureDetector(
                      onTap: _loading ? null : _searchParent,
                      child: Container(
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF6B00), Color(0xFFFF9A44)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: _loading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(
                            "Найти родителя",
                            style: GoogleFonts.nunito(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    if (_foundParent != null) ...[
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.family_restroom,
                                color: Colors.blueAccent, size: 50),
                            const SizedBox(height: 8),
                            Text(
                              "Родитель найден!",
                              style: GoogleFonts.nunito(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Имя родителя: ${_foundParent!['parentName']}",
                              style: GoogleFonts.nunito(
                                color: Colors.grey[700],
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _nameController,
                              textAlign: TextAlign.center,
                              decoration: InputDecoration(
                                hintText: "Введите ваше имя (ребёнка)",
                                filled: true,
                                fillColor: const Color(0xFFF6F8FB),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            GestureDetector(
                              onTap: _loading ? null : _connectToParent,
                              child: Container(
                                width: double.infinity,
                                height: 50,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFFF6B00), Color(0xFFFF9A44)],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    "Присоединиться",
                                    style: GoogleFonts.nunito(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
