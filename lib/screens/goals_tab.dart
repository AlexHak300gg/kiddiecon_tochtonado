import 'package:flutter/material.dart';
import 'goal_service.dart';
import 'dialogs.dart';

class GoalsTab extends StatefulWidget {
  final int childBalance;
  final Function(int delta) onBalanceChanged;
  const GoalsTab({required this.childBalance, required this.onBalanceChanged, super.key});

  @override
  State<GoalsTab> createState() => _GoalsTabState();
}

class _GoalsTabState extends State<GoalsTab> {
  final service = GoalService.instance;

  void _createGoal() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const CreateGoalDialog(),
    );

    if (result != null && result['name'] != null && result['target'] != null) {
      final name = result['name'] as String;
      final target = result['target'] as int;
      service.createGoal(name, target);
      setState(() {});
    }
  }

  void _deposit(Goal g) async {
    final amountStr = await showDialog<String>(
      context: context,
      builder: (_) => DepositDialog(maxAmount: widget.childBalance),
    );
    if (amountStr == null) return;
    final amount = int.tryParse(amountStr) ?? 0;
    if (amount <= 0) return;
    if (amount > widget.childBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Недостаточно средств')),
      );
      return;
    }

    service.deposit(g, amount);
    widget.onBalanceChanged(-amount);
    setState(() {});
  }

  void _abandon(Goal g) {
    service.abandonGoal(g);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final active = service.activeGoal;
    final history = service.goals.where((g) => !g.active).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Мои цели')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Активная цель:', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          if (active == null)
            const Text('Нет активной цели')
          else
            _buildActiveGoal(active),
          const SizedBox(height: 20),
          Text('История целей:', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (history.isEmpty)
            const Text('История пуста')
          else
            ...history.map((g) => ListTile(
              title: Text(g.name),
              subtitle: Text('Цель: ${g.target} ₽, накоплено: ${g.progress} ₽'),
              trailing: Text('${g.percent}%'),
            )),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: _createGoal,
            icon: const Icon(Icons.add),
            label: const Text('Создать новую цель'),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveGoal(Goal g) {
    final percent = g.target > 0 ? g.progress / g.target : 0.0;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(g.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            Text('Цель: ${g.target} ₽'),
            const SizedBox(height: 8),
            SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: percent,
                    strokeWidth: 10,
                    color: Colors.orange,
                    backgroundColor: Colors.grey.shade300,
                  ),
                  Text('${(percent * 100).toInt()}%',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text('Накоплено: ${g.progress} ₽'),
            Text('Осталось: ${g.remaining} ₽'),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(onPressed: () => _deposit(g), child: const Text('Пополнить')),
                const SizedBox(width: 8),
                ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                    onPressed: () => _abandon(g),
                    child: const Text('Отказаться')),
              ],
            )
          ],
        ),
      ),
    );
  }
}
