import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';

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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Срок действия кода истёк')),
          );
          await _db.child('invites/$code').remove();
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
    if (_foundParent == null || _nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите имя ребёнка')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final parentName = _foundParent!['parentName'];
      final parentCode = _codeController.text.trim();

      // 🟣 1. Добавляем ребёнка в общий список
      final newChildRef = _db.child('children').push();
      await newChildRef.set({
        'name': _nameController.text.trim(),
        'parentName': parentName,
        'parentCode': parentCode,
        'goal': 'Пока не установлена',
        'balance': 0,
        'createdAt': DateTime.now().toIso8601String(),
      });

      // 🟢 2. Добавляем в список родителя
      await _db
          .child('parents_children')
          .child(parentName)
          .push()
          .set({
        'childId': newChildRef.key,
        'childName': _nameController.text.trim(),
        'goal': 'Пока не установлена',
        'balance': 0,
        'progress': 0,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ребёнок успешно привязан к родителю $parentName!'),
        ),
      );

      // 🧹 Очистка полей
      setState(() {
        _foundParent = null;
        _codeController.clear();
        _nameController.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при добавлении: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Вход для ребёнка',
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // 🔹 Ввод кода приглашения
            TextField(
              controller: _codeController,
              decoration: InputDecoration(
                hintText: "Введите код приглашения от родителя",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _searchParent,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 60),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Найти родителя"),
            ),

            const SizedBox(height: 30),

            if (_foundParent != null) ...[
              Card(
                color: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
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
                      const SizedBox(height: 20),
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          hintText: "Введите ваше имя (ребёнка)",
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _connectToParent,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text("Присоединиться"),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
