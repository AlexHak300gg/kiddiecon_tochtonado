// lib/screens/parent_stats_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

import 'parent_dashboard_screen.dart';

class ParentStatsScreen extends StatefulWidget {
  final String parentName;
  const ParentStatsScreen({super.key, required this.parentName});

  @override
  State<ParentStatsScreen> createState() => _ParentStatsScreenState();
}

class _ParentStatsScreenState extends State<ParentStatsScreen> {
  String selectedPeriod = "День";
  String? selectedChild;
  List<String> children = [];

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  void _loadChildren() async {
    final ref = FirebaseDatabase.instance.ref("children/${widget.parentName.replaceAll('.', '_')}");
    final snap = await ref.get();
    if (snap.exists && snap.value is Map) {
      final map = snap.value as Map;
      setState(() {
        children = map.keys.map((e) => e.toString()).toList();
        selectedChild = children.isNotEmpty ? children.first : null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = ParentDashboardScreen(parentName: widget.parentName);
    final parentKey = widget.parentName.replaceAll('.', '_');

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Заголовок + фильтр выбора ребёнка
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Статистика накоплений",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                        ),
                        if (children.isNotEmpty)
                          DropdownButton<String>(
                            value: selectedChild,
                            items: children
                                .map((name) => DropdownMenuItem(value: name, child: Text(name)))
                                .toList(),
                            onChanged: (value) => setState(() => selectedChild = value),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Периоды
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: ["День", "Неделя", "Месяц", "Квартал"].map((period) {
                        final isSelected = selectedPeriod == period;
                        return GestureDetector(
                          onTap: () => setState(() => selectedPeriod = period),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.black : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              period,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 20),

                    // График (заглушка)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(color: Colors.grey.shade200, blurRadius: 6, offset: const Offset(0, 2))
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("График накоплений",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 8),
                          Container(
                            height: 120,
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: Text("Динамика роста накоплений",
                                  style: TextStyle(color: Colors.grey)),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Прогресс целей
                    const Text("Прогресс по целям",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    _goalProgress("Новый телефон", 15000, 20000, Colors.blue),
                    const SizedBox(height: 10),
                    _goalProgress("Велосипед", 4500, 10000, Colors.orange),

                    const SizedBox(height: 24),

                    // Таблица действий
                    const Text("Таблица действий",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 10),
                    _logItem("Задача выполнена", "Уборка комнаты", "+500 ₽", "15.01.2025", Icons.check_circle),
                    _logItem("Пополнение", "От родителей", "+1,000 ₽", "14.01.2025", Icons.add_circle),
                    _logItem("Начисление процентов", "Ежемесячный бонус", "+150 ₽", "13.01.2025", Icons.percent),
                    _logItem("Задача выполнена", "Помощь по дому", "+300 ₽", "12.01.2025", Icons.check_circle),

                    const SizedBox(height: 20),

                    // Итоги
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Заработано", style: TextStyle(color: Colors.white70)),
                              SizedBox(height: 4),
                              Text("1,950 ₽",
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text("Накоплено", style: TextStyle(color: Colors.white70)),
                              SizedBox(height: 4),
                              Text("19,500 ₽",
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _goalProgress(String title, int progress, int total, Color color) {
    final percent = (progress / total).clamp(0, 1);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text("${(percent * 100).toInt()}%"),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            // value: percent,
            minHeight: 8,
            backgroundColor: Colors.grey.shade200,
            color: color,
            borderRadius: BorderRadius.circular(10),
          ),
          const SizedBox(height: 6),
          Text("$progress ₽ из $total ₽", style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _logItem(String title, String subtitle, String amount, String date, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Icon(icon, color: Colors.grey),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(subtitle, style: const TextStyle(color: Colors.grey)),
            ]),
          ]),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(amount, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(date, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ]),
        ],
      ),
    );
  }
}
