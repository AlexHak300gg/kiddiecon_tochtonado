import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'parent_tasks_screen.dart';
import 'parent_stats_screen.dart';

class ParentDashboardScreen extends StatelessWidget {
  final String parentName;
  const ParentDashboardScreen({super.key, required this.parentName});

  // 🌟 Шапка родителя с Firebase-балансом
  Widget buildHeader() {
    final dbRef = FirebaseDatabase.instance.ref('parents/$parentName/balance');

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

          // 🔹 Баланс родителя — в реальном времени из Firebase
          StreamBuilder(
            stream: dbRef.onValue,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(color: Colors.white));
              }

              double balance = 0.0;
              if (snapshot.hasData && snapshot.data?.snapshot.value != null) {
                balance =
                    (snapshot.data!.snapshot.value as num?)?.toDouble() ?? 0.0;
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
                    const Icon(Icons.sync, color: Colors.white),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // 🌟 Навигация
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
      BuildContext context,
      IconData icon,
      String label,
      int index,
      int selected,
      ) {
    final bool isActive = index == selected;
    return GestureDetector(
      onTap: () {
        if (index == selected) return;
        if (index == 1) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const ParentTasksScreen()),
          );
        } else if (index == 2) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const ParentStatsScreen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ParentDashboardScreen(parentName: parentName),
            ),
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

  // 🌟 Секция детей
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
            future: FirebaseDatabase.instance
                .ref('parents_children/$parentKey')
                .get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data?.value == null) {
                return const Text("Пока нет добавленных детей");
              }

              final data = Map<String, dynamic>.from(snapshot.data!.value as Map);

              final children = data.values.map((childData) {
                final child = Map<String, dynamic>.from(childData);
                final name = child['childName'] ?? 'Без имени';
                final goal = 'Цель: велосипед'; // временная цель
                final balance = '₽${child['balance'] ?? '0'}';
                final progress = (child['progress'] ?? 35);

                return _childCard(name, goal, balance, progress, Colors.blueAccent);
              }).toList();

              return SizedBox(
                height: 230,
                child: ListView(children: children),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _childCard(
      String name,
      String goal,
      String balance,
      int progress,
      Color color,
      ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
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
                Text(
                  "$progress% до цели",
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          Text(
            balance,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  // 🌟 Быстрые действия + приглашение
  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Быстрые действия",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _quickAction(Icons.add, "Новая задача", Colors.blue),
              _quickAction(Icons.attach_money, "Пополнить", Colors.green),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _quickAction(Icons.check_circle_outline, "Проверить", Colors.purple),
              _quickAction(Icons.qr_code, "Пригласить", Colors.orange,
                  onTap: () => _showInviteDialog(context)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickAction(IconData icon, String label, Color color,
      {VoidCallback? onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.all(4),
          height: 90,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(label,
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  // 🟣 Приглашение ребёнка
  void _showInviteDialog(BuildContext context) async {
    final databaseRef = FirebaseDatabase.instance.ref();
    final String inviteCode =
    (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString();

    final codeRef = databaseRef.child('invites/$inviteCode');
    await codeRef.set({
      'parentName': parentName,
      'createdAt': DateTime.now().toIso8601String(),
      'expiresAt':
      DateTime.now().add(const Duration(minutes: 2)).toIso8601String(),
    });

    Future.delayed(const Duration(minutes: 2), () {
      codeRef.remove();
    });

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.qr_code_2, size: 60, color: Color(0xFF6F6BF8)),
                const SizedBox(height: 16),
                const Text(
                  "Пригласить ребёнка",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 10),
                Text(
                  "Передайте ребёнку этот код. Он действует 2 минуты:",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 12, horizontal: 24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6F6BF8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    inviteCode,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6F6BF8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.close, color: Colors.white),
                  label: const Text("Закрыть",
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              buildHeader(),
              buildNavBar(context, 0),
              _buildChildrenSection(),
              _buildQuickActions(context),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
