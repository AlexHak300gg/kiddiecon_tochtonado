import 'package:flutter/material.dart';

/// Диалог создания цели. Возвращает Map {'name': String, 'target': int}
class CreateGoalDialog extends StatelessWidget {
  const CreateGoalDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final nameCtrl = TextEditingController();
    final targetCtrl = TextEditingController();

    return AlertDialog(
      title: const Text('Новая цель'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameCtrl,
            decoration: const InputDecoration(labelText: 'Название цели'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: targetCtrl,
            decoration: const InputDecoration(labelText: 'Сумма (₽)'),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        TextButton(
          onPressed: () {
            final name = nameCtrl.text.trim();
            final target = int.tryParse(targetCtrl.text.trim()) ?? 0;
            if (name.isEmpty || target <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Введите корректные данные')),
              );
              return;
            }
            Navigator.pop(context, {'name': name, 'target': target});
          },
          child: const Text('Создать'),
        ),
      ],
    );
  }
}

/// Диалог пополнения. Возвращает строку с суммой (например "100")
class DepositDialog extends StatelessWidget {
  final int maxAmount;
  const DepositDialog({required this.maxAmount, super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = TextEditingController();
    return AlertDialog(
      title: const Text('Пополнить цель'),
      content: TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: 'Сумма (макс. $maxAmount ₽)'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
        TextButton(onPressed: () => Navigator.pop(context, ctrl.text), child: const Text('OK')),
      ],
    );
  }
}
