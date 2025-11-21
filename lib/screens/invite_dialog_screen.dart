import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:firebase_database/firebase_database.dart';

class InviteDialogScreen extends StatefulWidget {
  final String parentName;

  const InviteDialogScreen({super.key, required this.parentName});

  @override
  State<InviteDialogScreen> createState() => _InviteDialogScreenState();
}

class _InviteDialogScreenState extends State<InviteDialogScreen> {
  String? _inviteCode;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _generateInviteCode();
  }

  String _generateRandomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    return List.generate(8, (index) => chars[random.nextInt(chars.length)]).join();
  }

  Future<void> _generateInviteCode() async {
    final db = FirebaseDatabase.instance.ref();
    final parentKey = widget.parentName.replaceAll('.', '_');

    final childrenSnap = await db.child('parents_children/$parentKey').get();
    int childrenCount = 0;
    if (childrenSnap.exists && childrenSnap.value != null) {
      final children = childrenSnap.value as Map;
      childrenCount = children.length;
    }

    if (childrenCount >= 5) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Достигнут лимит: максимум 5 детей на родителя'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    String code = _generateRandomCode();
    final codeRef = db.child('inviteCodes/$code');
    final existingCodeSnap = await codeRef.get();

    while (existingCodeSnap.exists) {
      code = _generateRandomCode();
    }

    final parentSnap = await db.child('parents/$parentKey').get();
    String? parentId;
    if (parentSnap.exists && parentSnap.value != null) {
      final parentData = Map<String, dynamic>.from(parentSnap.value as Map);
      parentId = parentData['id'] ?? parentKey;
    }

    await codeRef.set({
      'parentId': parentId ?? parentKey,
      'parentKey': parentKey,
      'parentName': widget.parentName,
      'createdAt': DateTime.now().toIso8601String(),
      'expiresAt': DateTime.now().add(const Duration(hours: 24)).toIso8601String(),
      'isUsed': false,
    });

    Future.delayed(const Duration(hours: 24), () {
      codeRef.get().then((snap) {
        if (snap.exists) {
          final data = Map<String, dynamic>.from(snap.value as Map);
          if (data['isUsed'] != true) {
            codeRef.remove();
          }
        }
      });
    });

    setState(() {
      _inviteCode = code;
      _isLoading = false;
    });
  }

  void _copyToClipboard() {
    if (_inviteCode != null) {
      Clipboard.setData(ClipboardData(text: _inviteCode!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Код скопирован в буфер обмена'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6F6BF8),
        title: const Text(
          'Пригласить ребёнка',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    'QR-код для ребёнка',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6F6BF8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Действует 24 часа',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: QrImageView(
                      data: _inviteCode ?? '',
                      version: QrVersions.auto,
                      size: 250,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Divider(),
                  const SizedBox(height: 20),
                  const Text(
                    'Или введите код вручную:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6F6BF8).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF6F6BF8),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _inviteCode ?? '',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6F6BF8),
                            letterSpacing: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _copyToClipboard,
                      icon: const Icon(Icons.copy),
                      label: const Text(
                        'Скопировать код',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6F6BF8),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.orange),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Инструкция:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '1. Покажите QR-код ребёнку\n2. Ребёнок отсканирует его в приложении\n3. Или передайте код для ручного ввода',
                                style: TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
