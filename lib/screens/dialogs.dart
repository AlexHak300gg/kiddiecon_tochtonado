import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

/// 🎯 Диалог создания новой цели
class CreateGoalDialog extends StatefulWidget {
  final void Function(String goalName, int target, DateTime? deadline)? onCreated;

  const CreateGoalDialog({super.key, this.onCreated});

  @override
  State<CreateGoalDialog> createState() => _CreateGoalDialogState();
}

class _CreateGoalDialogState extends State<CreateGoalDialog> {
  final _goalController = TextEditingController();
  final _targetController = TextEditingController();
  DateTime? _selectedDeadline;
  bool _isSaving = false;

  Future<void> _selectDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      locale: const Locale('ru', 'RU'),
    );
    
    if (picked != null) {
      setState(() => _selectedDeadline = picked);
    }
  }

  Future<void> _saveGoal() async {
    final goalName = _goalController.text.trim();
    final targetText = _targetController.text.trim();

    if (goalName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите название цели')),
      );
      return;
    }

    if (targetText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите сумму цели')),
      );
      return;
    }

    final target = int.tryParse(targetText);
    if (target == null || target <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Сумма должна быть больше 0')),
      );
      return;
    }

    setState(() => _isSaving = true);

    // 🔥 передаём данные родителю
    if (widget.onCreated != null) {
      widget.onCreated!(goalName, target, _selectedDeadline);
    }

    Navigator.pop(context, {
      'name': goalName,
      'target': target,
      'deadline': _selectedDeadline,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Новая цель 🎯",
                style: GoogleFonts.nunito(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _goalController,
                decoration: InputDecoration(
                  labelText: "Название цели",
                  hintText: "Например: Велосипед",
                  filled: true,
                  fillColor: const Color(0xFFF6F8FB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _targetController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Сумма цели (₽)",
                  hintText: "Введите сумму",
                  filled: true,
                  fillColor: const Color(0xFFF6F8FB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _selectDeadline,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F8FB),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.black54),
                      const SizedBox(width: 12),
                      Text(
                        _selectedDeadline == null
                            ? 'Срок достижения (необязательно)'
                            : 'Срок: ${DateFormat('dd.MM.yyyy').format(_selectedDeadline!)}',
                        style: GoogleFonts.nunito(
                          color: _selectedDeadline == null ? Colors.black54 : Colors.black87,
                          fontSize: 14,
                        ),
                      ),
                      if (_selectedDeadline != null) ...[
                        const Spacer(),
                        GestureDetector(
                          onTap: () => setState(() => _selectedDeadline = null),
                          child: const Icon(Icons.close, size: 18, color: Colors.red),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _isSaving ? null : _saveGoal,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6B00), Color(0xFFFF9A44)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: _isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                      "Сохранить",
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 💰 Диалог внесения средств в цель
class DepositDialog extends StatefulWidget {
  final int maxAmount;

  const DepositDialog({super.key, required this.maxAmount});

  @override
  State<DepositDialog> createState() => _DepositDialogState();
}

class _DepositDialogState extends State<DepositDialog> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Внести в цель 💰",
              style: GoogleFonts.nunito(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Доступно: ${widget.maxAmount}₽",
              style: GoogleFonts.nunito(color: Colors.black54),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Сколько внести?",
                filled: true,
                fillColor: const Color(0xFFF6F8FB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                Navigator.pop(context, _controller.text.trim());
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B00), Color(0xFFFF9A44)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    "Подтвердить",
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
