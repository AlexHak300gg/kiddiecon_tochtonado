import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChildHomeScreen extends StatelessWidget {
  final String childName;
  final int balance;
  final String goalName;
  final int goalTarget;
  final int goalProgress;

  const ChildHomeScreen({
    super.key,
    required this.childName,
    required this.balance,
    required this.goalName,
    required this.goalTarget,
    required this.goalProgress,
  });

  @override
  Widget build(BuildContext context) {
    double percent = goalTarget > 0 ? goalProgress / goalTarget : 0;

    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 👋 Приветствие
              Row(
                children: [
                  const CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, color: Colors.blue),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "Привет, $childName 👋",
                    style: GoogleFonts.nunito(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "Достигай своих целей!",
                style: GoogleFonts.nunito(color: Colors.black54),
              ),
              const SizedBox(height: 16),

              // 💳 Карточка школьная
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF42A5F5),
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.orangeAccent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.school, color: Colors.white, size: 36),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Моя школьная карта",
                              style: GoogleFonts.nunito(color: Colors.white70)),
                          Text(
                            childName,
                            style: GoogleFonts.nunito(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text("Баланс: $balance ₽",
                              style: GoogleFonts.nunito(color: Colors.white)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 🎯 Цель
              Text(
                "Мои цели",
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.pedal_bike, color: Colors.orange),
                        const SizedBox(width: 8),
                        Text(goalName,
                            style: GoogleFonts.nunito(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            )),
                        const Spacer(),
                        Text("Цель: $goalTarget ₽",
                            style: GoogleFonts.nunito(color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 120,
                          height: 120,
                          child: CircularProgressIndicator(
                            value: percent,
                            backgroundColor: Colors.grey[200],
                            color: Colors.orange,
                            strokeWidth: 8,
                          ),
                        ),
                        Text(
                          "${(percent * 100).toInt()}%",
                          style: GoogleFonts.nunito(
                              fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Накоплено: $goalProgress ₽",
                      style: GoogleFonts.nunito(),
                    ),
                    Text(
                      "Осталось: ${goalTarget - goalProgress} ₽",
                      style: GoogleFonts.nunito(color: Colors.grey),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 🧩 Активные задания
              Text(
                "Активные задания",
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _taskCard("Полить цветы", 50, true),
                  _taskCard("Помыть посуду", 100, false),
                ],
              ),
            ],
          ),
        ),
      ),

      // 🔽 Нижнее меню
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.task_alt), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: ''),
        ],
      ),
    );
  }

  Widget _taskCard(String title, int reward, bool done) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 4)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text("+$reward ₽",
              style: GoogleFonts.nunito(color: Colors.orangeAccent)),
          const SizedBox(height: 6),
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: done ? Colors.green[100] : Colors.yellow[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              done ? "Выполнено" : "Проверяется",
              style: GoogleFonts.nunito(
                color: done ? Colors.green[700] : Colors.orange[700],
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
