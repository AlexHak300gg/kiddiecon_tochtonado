import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChildTasksScreen extends StatefulWidget {
  final String childName;

  const ChildTasksScreen({super.key, required this.childName});

  @override
  State<ChildTasksScreen> createState() => _ChildTasksScreenState();
}

class _ChildTasksScreenState extends State<ChildTasksScreen> {
  // Заглушка: можно позже подключить Firebase
  final List<Map<String, dynamic>> _tasks = [
    {"title": "Помыть посуду", "reward": 100, "done": false},
    {"title": "Полить цветы", "reward": 50, "done": true},
    {"title": "Пропылесосить комнату", "reward": 120, "done": false},
    {"title": "Помочь с покупками", "reward": 80, "done": false},
    {"title": "Протереть пыль", "reward": 70, "done": true},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "Мои задания",
          style: GoogleFonts.nunito(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Привет, ${widget.childName}! 👋",
              style: GoogleFonts.nunito(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Выполняй задания и получай награды от родителей 💰",
              style: GoogleFonts.nunito(color: Colors.black54),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: ListView.builder(
                itemCount: _tasks.length,
                itemBuilder: (context, index) {
                  final task = _tasks[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          task["done"]
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color:
                          task["done"] ? Colors.green : Colors.grey.shade400,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(task["title"],
                                  style: GoogleFonts.nunito(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  )),
                              const SizedBox(height: 4),
                              Text(
                                "+${task["reward"]} ₽ награда",
                                style: GoogleFonts.nunito(
                                  color: Colors.orangeAccent,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: task["done"]
                              ? null
                              : () {
                            setState(() {
                              task["done"] = true;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    "Задание '${task["title"]}' отправлено на проверку!"),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: task["done"]
                                ? Colors.grey.shade300
                                : Colors.blueAccent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            task["done"] ? "На проверке" : "Сделано",
                            style: GoogleFonts.nunito(
                                fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
