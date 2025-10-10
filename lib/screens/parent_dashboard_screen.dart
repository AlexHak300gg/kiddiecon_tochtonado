// lib/screens/parent_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

import 'parent_tasks_screen.dart';
import 'parent_stats_screen.dart';
import 'fake_qr_scanner_screen.dart';

class ParentDashboardScreen extends StatelessWidget {
  final String parentName;
  const ParentDashboardScreen({super.key, required this.parentName});

  // header — требуется контекст, т.к. есть навигация на fake scanner
  Widget buildHeader(BuildContext context) {
    final parentKey = parentName.replaceAll('.', '_');
    final dbRef = FirebaseDatabase.instance.ref('parents/$parentKey/balance');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF6F6BF8),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 26,
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 30, color: Color(0xFF6F6BF8)),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Привет, $parentName!",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    "Родительская панель",
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Баланс — стрим на parents/{key}/balance
          StreamBuilder(
            stream: FirebaseDatabase.instance.ref('parents').onValue,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              }

              double balance = 0.0;
              if (snapshot.hasData && snapshot.data?.snapshot.value != null) {
                final parents = Map<String, dynamic>.from(
                  snapshot.data!.snapshot.value as Map,
                );
                for (final entry in parents.entries) {
                  final parent = Map<String, dynamic>.from(entry.value);
                  if ((parent['email'] ?? '').toString().toLowerCase() ==
                      parentName.toLowerCase()) {
                    final val = parent['balance'];
                    if (val is num) balance = val.toDouble();
                    else if (val is String) balance = double.tryParse(val) ?? 0.0;
                    break;
                  }
                }
              }

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF7E7AFB),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.account_balance_wallet,
                        color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Баланс на счёте",
                            style: TextStyle(color: Colors.white70),
                          ),
                          Text(
                            "₽${balance.toStringAsFixed(0)}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Nav bar — передаём parentName по навигации
  Widget buildNavBar(BuildContext context, int selectedIndex) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _navItem(context, Icons.home, "Главная", 0, selectedIndex),
          _navItem(context, Icons.list_alt, "Задачи", 1, selectedIndex),
          _navItem(context, Icons.bar_chart, "Статистика", 2, selectedIndex),
        ],
      ),
    );
  }

  Widget _navItem(
      BuildContext context, IconData icon, String label, int index, int selected) {
    final bool isActive = index == selected;
    return GestureDetector(
      onTap: () {
        if (index == selected) return;
        if (index == 1) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) => ParentTasksScreen(parentName: parentName)),
          );
        } else if (index == 2) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) => ParentStatsScreen(parentName: parentName)),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) => ParentDashboardScreen(parentName: parentName)),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF6F6BF8) : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: isActive ? Colors.white : Colors.black54, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.black54,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Children section (reads parents_children/{parentKey})
  Widget _buildChildrenSection() {
    final parentKey = parentName.replaceAll('.', '_');

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Мои дети",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          FutureBuilder<DataSnapshot>(
            future:
            FirebaseDatabase.instance.ref('parents_children/$parentKey').get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data?.value == null) {
                return const Text("Пока нет добавленных детей");
              }

              final raw = snapshot.data!.value as Map<Object?, Object?>;
              final childrenList = raw.entries.map((entry) {
                final key = entry.key.toString();
                final map = Map<String, dynamic>.from(entry.value as Map);
                final name = map['childName'] ?? 'Без имени';
                final goal = map['goal'] ?? 'Цель не установлена';
                final balance = '₽${map['balance'] ?? 0}';
                final progress = (map['progress'] ?? 0);
                return _childCard(key, name, goal, balance, progress, Colors.blue);
              }).toList();

              return SizedBox(height: 230, child: ListView(children: childrenList));
            },
          ),
        ],
      ),
    );
  }

  Widget _childCard(String childId, String name, String goal, String balance,
      int progress, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 6)],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundColor: Color(0xFFBBDEFB),
            child: Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(goal, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: progress / 100,
                  color: color,
                  backgroundColor: Colors.grey.shade200,
                ),
                Text("$progress% до цели",
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Text(balance,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
        ],
      ),
    );
  }

  // Quick actions: includes Перевести (transfer) и Пригласить
  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text("Быстрые действия", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Row(children: [
          _quickAction(Icons.add, "Новая задача", Colors.blue),
          _quickAction(Icons.compare_arrows, "Перевести", Colors.green, onTap: () => _showTransferDialog(context)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          _quickAction(Icons.check_circle_outline, "Проверить", Colors.purple),
          _quickAction(Icons.qr_code, "Пригласить", Colors.orange, onTap: () => _showInviteDialog(context)),
        ]),
      ]),
    );
  }

  Widget _quickAction(IconData icon, String label, Color color, {VoidCallback? onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.all(4),
          height: 90,
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
          ]),
        ),
      ),
    );
  }

  // Transfer dialog — безопасное чтение и запись
  void _showTransferDialog(BuildContext context) async {
    final db = FirebaseDatabase.instance.ref();
    final parentKey = parentName.replaceAll('.', '_');
    final snap = await db.child('parents_children/$parentKey').get();
    if (!snap.exists || snap.value == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Нет детей для перевода")));
      return;
    }

    // безопасно привести snapshot.value к Map<String, Map>
    final raw = snap.value as Map<Object?, Object?>;
    final children = raw.map((k, v) => MapEntry(k.toString(), Map<String, dynamic>.from(v as Map)));

    String? selectedChildId;
    double amount = 0.0;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: const Text("Перевод средств ребёнку"),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "Выберите ребёнка"),
                items: children.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value['childName'] ?? 'Без имени'))).toList(),
                onChanged: (v) => setState(() => selectedChildId = v),
              ),
              TextField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Сумма перевода (₽)"),
                onChanged: (v) => amount = double.tryParse(v) ?? 0.0,
              ),
            ]),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Отмена")),
              ElevatedButton(
                onPressed: () async {
                  if (selectedChildId == null || amount <= 0) return;

                  final parentRef = db.child('parents/${parentKey}/balance');
                  final parentSnap = await parentRef.get();
                  double parentBalance = 0.0;
                  if (parentSnap.exists && parentSnap.value != null) {
                    final val = parentSnap.value;
                    if (val is num) parentBalance = val.toDouble();
                    else if (val is String) parentBalance = double.tryParse(val) ?? 0.0;
                  }

                  if (parentBalance < amount) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Недостаточно средств")));
                    return;
                  }

                  // update parent balance and child's balance (atomicity not guaranteed by this code; for real app use transactions)
                  await parentRef.set(parentBalance - amount);

                  final childBalanceRef = db.child('parents_children/$parentKey/$selectedChildId/balance');
                  final childSnap = await childBalanceRef.get();
                  double childBalance = 0.0;
                  if (childSnap.exists && childSnap.value != null) {
                    final val = childSnap.value;
                    if (val is num) childBalance = val.toDouble();
                    else if (val is String) childBalance = double.tryParse(val) ?? 0.0;
                  }
                  await childBalanceRef.set(childBalance + amount);

                  // логирование операции в /transactions/{parentKey}/push()
                  final txRef = db.child('transactions/$parentKey').push();
                  await txRef.set({
                    'type': 'transfer',
                    'amount': amount,
                    'toChildId': selectedChildId,
                    'toChildName': children[selectedChildId]?['childName'] ?? '',
                    'timestamp': DateTime.now().toIso8601String(),
                  });

                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Перевод выполнен")));
                  Navigator.pop(context);
                },
                child: const Text("Перевести"),
              ),
            ],
          );
        });
      },
    );
  }

  // Invite dialog
  void _showInviteDialog(BuildContext context) async {
    final db = FirebaseDatabase.instance.ref();
    final code = (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString();
    final parentKey = parentName.replaceAll('.', '_');

    final codeRef = db.child('invites/$code');
    await codeRef.set({
      'parentKey': parentKey,
      'parentName': parentName,
      'createdAt': DateTime.now().toIso8601String(),
      'expiresAt': DateTime.now().add(const Duration(minutes: 2)).toIso8601String(),
    });
    Future.delayed(const Duration(minutes: 2), () => codeRef.remove());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Пригласить ребёнка"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.qr_code, size: 80, color: Color(0xFF6F6BF8)),
            const SizedBox(height: 10),
            const Text("Код для ребёнка (действует 2 мин):"),
            const SizedBox(height: 10),
            Text(code, style: const TextStyle(fontSize: 24, color: Color(0xFF6F6BF8), fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Закрыть"))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(children: [
            buildHeader(context),
            buildNavBar(context, 0),
            _buildChildrenSection(),
            _buildQuickActions(context),
            const SizedBox(height: 20),
          ]),
        ),
      ),
    );
  }
}
