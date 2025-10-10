import 'package:flutter/material.dart';
import 'parent_dashboard_screen.dart';
import 'parent_stats_screen.dart';

class ParentTasksScreen extends StatelessWidget {
  const ParentTasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final parentDashboard = ParentDashboardScreen(parentName: "Анна");

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      body: SafeArea(
        child: Column(
          children: [
            // 🔹 Шапка и навигация
            parentDashboard.buildHeader(),
            parentDashboard.buildNavBar(context, 1),

            // 🔹 Контент страницы задач
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Создать новую задачу",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    // Поля создания задачи
                    _buildTextField("Название задачи"),
                    const SizedBox(height: 12),
                    _buildDropdown(),
                    const SizedBox(height: 12),
                    _buildTextField("Вознаграждение (₽)"),
                    const SizedBox(height: 12),
                    _buildTextField("Дата завершения (опционально)"),
                    const SizedBox(height: 16),

                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text("Создать задачу"),
                    ),

                    const SizedBox(height: 30),
                    const Text(
                      "Список задач",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    // Пример задач
                    _buildTaskCard("Убрать комнату", "На проверке", 100),
                    _buildTaskCard("Выучить таблицу умножения", "Не выполнена", 200),
                    _buildTaskCard("Помыть посуду", "Не выполнена", 75),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String hint) {
    return TextField(
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonFormField<String>(
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16),
        ),
        items: const [
          DropdownMenuItem(value: "Учёба", child: Text("Учёба")),
          DropdownMenuItem(value: "Дом", child: Text("Дом")),
          DropdownMenuItem(value: "Спорт", child: Text("Спорт")),
        ],
        onChanged: (value) {},
        hint: const Text("Выберите категорию"),
      ),
    );
  }

  Widget _buildTaskCard(String title, String status, int reward) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 4),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(status,
              style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("₽$reward",
                  style: const TextStyle(
                      color: Colors.green, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.check_circle, color: Colors.green),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
