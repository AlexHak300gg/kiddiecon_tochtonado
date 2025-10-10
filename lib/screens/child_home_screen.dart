import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'child_stats_screen.dart';
import 'child_tasks_screen.dart';

class ChildHomeScreen extends StatefulWidget {
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
  State<ChildHomeScreen> createState() => _ChildHomeScreenState();
}

class _ChildHomeScreenState extends State<ChildHomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    double percent =
    widget.goalTarget > 0 ? widget.goalProgress / widget.goalTarget : 0;

    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 👋 Greeting
              Row(
                children: [
                  const CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, color: Colors.blue),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "Привет, ${widget.childName} 👋",
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

              // 💳 Card
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
                      child: const Icon(Icons.school,
                          color: Colors.white, size: 36),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Моя школьная карта",
                              style: GoogleFonts.nunito(color: Colors.white70)),
                          Text(
                            widget.childName,
                            style: GoogleFonts.nunito(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text("Баланс: ${widget.balance} ₽",
                              style: GoogleFonts.nunito(color: Colors.white)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 🎯 Goals
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
                        Text(widget.goalName,
                            style: GoogleFonts.nunito(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            )),
                        const Spacer(),
                        Text("Цель: ${widget.goalTarget} ₽",
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
                      "Накоплено: ${widget.goalProgress} ₽",
                      style: GoogleFonts.nunito(),
                    ),
                    Text(
                      "Осталось: ${widget.goalTarget - widget.goalProgress} ₽",
                      style: GoogleFonts.nunito(color: Colors.grey),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 🧩 Active tasks
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

      // ⚪ Bottom navigation
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 20, left: 40, right: 40),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home, 0),
              _buildNavItem(Icons.task_alt, 1), // ✅ Tasks
              _buildNavItem(Icons.center_focus_strong, 2),
              _buildNavItem(Icons.show_chart, 3), // 📊 Stats
            ],
          ),
        ),
      ),
    );
  }

  // 🔘 Navigation item
  Widget _buildNavItem(IconData icon, int index) {
    final bool isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _currentIndex = index);

        // 👉 Navigation
        if (index == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChildTasksScreen(childName: widget.childName),
            ),
          );
        } else if (index == 3) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChildStatsScreen(
                childName: widget.childName,
                balance: widget.balance,
              ),
            ),
          );
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueAccent : const Color(0xFFEDEDED),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.white : Colors.black54,
          size: 26,
        ),
      ),
    );
  }

  // 🧩 Task card
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
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
