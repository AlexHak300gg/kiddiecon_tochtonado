import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChildStatsScreen extends StatefulWidget {
  final String childName;
  final int balance;

  const ChildStatsScreen({
    super.key,
    required this.childName,
    required this.balance,
  });

  @override
  State<ChildStatsScreen> createState() => _ChildStatsScreenState();
}

class _ChildStatsScreenState extends State<ChildStatsScreen> {
  String selectedPeriod = "День";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Статистика",
          style: GoogleFonts.nunito(
              fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔘 Переключатели периода
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: ["День", "Неделя", "Месяц", "Квартал"].map((period) {
                  final isSelected = selectedPeriod == period;
                  return GestureDetector(
                    onTap: () => setState(() => selectedPeriod = period),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.black : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        period,
                        style: GoogleFonts.nunito(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // 📊 График накоплений (заглушка)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.grey.shade200,
                        blurRadius: 6,
                        offset: const Offset(0, 2))
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("График накоплений",
                        style: GoogleFonts.nunito(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 10),
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

              // 🎯 Прогресс по целям
              Text("Прогресс по целям",
                  style: GoogleFonts.nunito(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              _goalProgress("Новый телефон", 15000, 20000, Colors.blue),
              const SizedBox(height: 10),
              _goalProgress("Велосипед", 4500, 10000, Colors.orange),

              const SizedBox(height: 24),

              // 📋 Таблица действий
              Text("История действий",
                  style: GoogleFonts.nunito(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),
              _logItem("Задача выполнена", "Уборка комнаты", "+500 ₽",
                  "15.01.2025", Icons.check_circle),
              _logItem("Пополнение", "От родителей", "+1,000 ₽", "14.01.2025",
                  Icons.add_circle),
              _logItem("Начисление процентов", "Ежемесячный бонус", "+150 ₽",
                  "13.01.2025", Icons.percent),
              _logItem("Задача выполнена", "Помощь по дому", "+300 ₽",
                  "12.01.2025", Icons.check_circle),

              const SizedBox(height: 20),

              // 💰 Итоги
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Заработано",
                            style: GoogleFonts.nunito(color: Colors.white70)),
                        const SizedBox(height: 4),
                        Text("1,950 ₽",
                            style: GoogleFonts.nunito(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text("Накоплено",
                            style: GoogleFonts.nunito(color: Colors.white70)),
                        const SizedBox(height: 4),
                        Text("19,500 ₽",
                            style: GoogleFonts.nunito(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
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
        boxShadow: [
          BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 4,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(title,
                style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
            Text("${(percent * 100).toInt()}%"),
          ]),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            // value: percent,
            minHeight: 8,
            backgroundColor: Colors.grey.shade200,
            color: color,
            borderRadius: BorderRadius.circular(10),
          ),
          const SizedBox(height: 6),
          Text("$progress ₽ из $total ₽",
              style: GoogleFonts.nunito(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _logItem(
      String title, String subtitle, String amount, String date, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 4,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Icon(icon, color: Colors.grey),
            const SizedBox(width: 10),
            Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
                  Text(subtitle,
                      style: GoogleFonts.nunito(color: Colors.grey)),
                ]),
          ]),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(amount, style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
            Text(date,
                style: GoogleFonts.nunito(color: Colors.grey, fontSize: 12)),
          ]),
        ],
      ),
    );
  }
}
