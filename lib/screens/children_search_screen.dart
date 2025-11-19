import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'child_home_screen.dart';
import 'qr_scanner_screen.dart';
import 'setup_security_screen.dart';

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

  Future<void> _scanQrCode() async {
    final code = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );

    if (code != null && code.isNotEmpty) {
      _codeController.text = code.toUpperCase();
      await _searchParent();
    }
  }

  Future<void> _searchParent() async {
    final code = _codeController.text.trim().toUpperCase();
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
      final snapshot = await _db.child('inviteCodes/$code').get();

      if (!snapshot.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Код не найден или истёк'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final data = Map<String, dynamic>.from(snapshot.value as Map);

      if (data['isUsed'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Этот код уже использован'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final expiresAt = DateTime.parse(data['expiresAt']);

      if (DateTime.now().isAfter(expiresAt)) {
        await _db.child('inviteCodes/$code').remove();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Срок действия кода истёк'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final parentKey = data['parentKey'];
      final parentExists = await _db.child('parents/$parentKey').get();
      if (!parentExists.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Родитель не найден'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final childrenSnap = await _db.child('parents_children/$parentKey').get();
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
          content: Text("Ошибка: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _showConfirmationDialog() async {
    if (_foundParent == null || _nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите имя ребёнка')),
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
      await _connectToParent();
    }
  }

  Future<void> _connectToParent() async {
    if (_isConnecting) return;

    setState(() {
      _loading = true;
      _isConnecting = true;
    });

    try {
      final parentName = _foundParent!['parentName'] ?? "Без имени";
      final parentKey = _foundParent!['parentKey'];
      final code = _codeController.text.trim().toUpperCase();

      final newChildRef = _db.child('children').push();
      await newChildRef.set({
        'name': _nameController.text.trim(),
        'parentName': parentName,
        'parentKey': parentKey,
        'goal': 'Пока не установлена',
        'balance': 0,
        'progress': 0,
        'target': 0,
        'createdAt': DateTime.now().toIso8601String(),
      });

      await _db
          .child('parents_children')
          .child(parentKey)
          .child(newChildRef.key!)
          .set({
        'childId': newChildRef.key,
        'childName': _nameController.text.trim(),
        'goal': 'Пока не установлена',
        'balance': 0,
        'progress': 0,
        'target': 0,
      });

      await _db.child('inviteCodes/$code').update({
        'isUsed': true,
        'usedBy': newChildRef.key,
        'usedAt': DateTime.now().toIso8601String(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ребёнок успешно подключён! 🎉'),
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

      // После успешного подключения ребёнка, перенаправляем на SetupSecurityScreen
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
          content: Text('Ошибка при добавлении: $e'),
          backgroundColor: Colors.red,
        ),
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
                  child: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
                ),
              ),
            ),

            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),

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

                    TextField(
                      controller: _codeController,
                      textAlign: TextAlign.center,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.qr_code_scanner, color: Color(0xFFFF6B00)),
                          onPressed: _scanQrCode,
                          tooltip: 'Сканировать QR-код',
                        ),
                        hintText: "Введите код приглашения от родителя",
                        hintStyle: GoogleFonts.nunito(color: Colors.black54, fontSize: 14),
                        filled: true,
                        fillColor: const Color(0xFFF6F8FB),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

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
                              onTap: _loading ? null : _showConfirmationDialog,
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
