// lib/screens/parent_stats_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

import 'parent_dashboard_screen.dart';

class ParentStatsScreen extends StatelessWidget {
  final String parentName;
  const ParentStatsScreen({super.key, required this.parentName});

  @override
  Widget build(BuildContext context) {
    final dashboard = ParentDashboardScreen(parentName: parentName);
    final parentKey = parentName.replaceAll('.', '_');

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      body: SafeArea(
        child: Column(
          children: [
            dashboard.buildHeader(context),
            dashboard.buildNavBar(context, 2),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text("Статистика целей детей", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 12),
                  // пока заглушки целей
                  _goalProgress("Максим", "Велосипед", 70, Colors.blue),
                  const SizedBox(height: 10),
                  _goalProgress("София", "Кукла", 45, Colors.orange),
                  const SizedBox(height: 20),
                  const Text("Операции (лог):", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),

                  // Лог операций: читаем /transactions/{parentKey} или /logs/{parentKey}
                  StreamBuilder(
                    stream: FirebaseDatabase.instance.ref('transactions/$parentKey').onValue,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data == null) {
                        return const Text("Операций пока нет");
                      }
                      final snap = snapshot.data!.snapshot;
                      if (snap.value == null) return const Text("Операций пока нет");
                      final raw = snap.value as Map<Object?, Object?>;
                      final list = raw.entries.toList().reversed.toList();

                      return Column(
                        children: list.map((e) {
                          final id = e.key.toString();
                          final map = Map<String, dynamic>.from(e.value as Map);
                          final type = map['type'] ?? 'unknown';
                          final amount = map['amount'] ?? '';
                          final toName = map['toChildName'] ?? '';
                          final date = map['timestamp'] ?? '';
                          return GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: Text('Операция: $type'),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Сумма: ₽$amount'),
                                      const SizedBox(height: 6),
                                      Text('Кому: $toName'),
                                      const SizedBox(height: 6),
                                      Text('Время: $date'),
                                    ],
                                  ),
                                  actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Закрыть'))],
                                ),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: [
                                BoxShadow(color: Colors.grey.shade200, blurRadius: 4, offset: const Offset(0, 2))
                              ]),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(type, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text(toName, style: const TextStyle(color: Colors.grey)),
                                  ]),
                                  Text('₽$amount', style: const TextStyle(color: Colors.grey)),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _goalProgress(String name, String goal, int percent, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [
        BoxShadow(color: Colors.grey.shade200, blurRadius: 4, offset: const Offset(0, 2))
      ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text("$name — цель: $goal", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: percent / 100, color: color, backgroundColor: Colors.grey.shade200, minHeight: 10)),
        const SizedBox(height: 8),
        Text("$percent% достигнуто", style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ]),
    );
  }
}
