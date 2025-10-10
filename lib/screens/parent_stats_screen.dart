import 'package:flutter/material.dart';
import 'parent_dashboard_screen.dart';

class ParentStatsScreen extends StatelessWidget {
  const ParentStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // создаём экземпляр без const — чтобы можно было вызывать методы .buildHeader()/.buildNavBar()
    final dashboard = ParentDashboardScreen(parentName: "Анна");

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      body: SafeArea(
        child: Column(
          children: [
            // Общая шапка и навигация
            dashboard.buildHeader(),
            dashboard.buildNavBar(context, 2),

            // Контент страницы статистики
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Статистика целей детей",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 12),
                    _goalProgress("Максим", "Велосипед", 70, Colors.blue),
                    const SizedBox(height: 10),
                    _goalProgress("София", "Кукла", 45, Colors.orange),
                    const SizedBox(height: 10),
                    _goalProgress("Илья", "Конструктор LEGO", 25, Colors.green),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Виджет прогресса: "Имя — цель: Название" (через тире)
  Widget _goalProgress(String name, String goal, int percent, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 4, offset: const Offset(0,2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$name — цель: $goal", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percent / 100,
              color: color,
              backgroundColor: Colors.grey.shade200,
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 8),
          Text("$percent% достигнуто", style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}
