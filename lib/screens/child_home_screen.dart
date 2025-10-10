import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'goal_service.dart';
import 'goals_tab.dart';
import 'dialogs.dart';

class ChildHomeScreen extends StatefulWidget {
  final String childName;
  final int balance;
  final String? goalName;
  final int? goalTarget;
  final int? goalProgress;

  const ChildHomeScreen({
    super.key,
    required this.childName,
    required this.balance,
    this.goalName,
    this.goalTarget,
    this.goalProgress,
  });

  @override
  State<ChildHomeScreen> createState() => _ChildHomeScreenState();
}

class _ChildHomeScreenState extends State<ChildHomeScreen> {
  final goalService = GoalService.instance;
  late int _balance;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _balance = widget.balance;

    if (goalService.activeGoal == null &&
        widget.goalName != null &&
        widget.goalTarget != null) {
      goalService.createGoal(widget.goalName!, widget.goalTarget!);
      if (widget.goalProgress != null) {
        final g = goalService.activeGoal;
        if (g != null) g.progress = widget.goalProgress!.clamp(0, g.target);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeGoal = goalService.activeGoal;
    final percent = (activeGoal != null && activeGoal.target > 0)
        ? (activeGoal.progress / activeGoal.target)
        : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: Colors.blue),
              ),
              const SizedBox(width: 10),
              Text("Привет, ${widget.childName} 👋",
                  style: GoogleFonts.nunito(
                      fontSize: 20, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 8),
            Text("Достигай своих целей!",
                style: GoogleFonts.nunito(color: Colors.black54)),
            const SizedBox(height: 16),

            Container(
              decoration: BoxDecoration(
                  color: const Color(0xFF42A5F5),
                  borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                      color: Colors.orangeAccent,
                      borderRadius: BorderRadius.circular(12)),
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
                        Text(widget.childName,
                            style: GoogleFonts.nunito(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                        Text("Баланс: $_balance ₽",
                            style: GoogleFonts.nunito(color: Colors.white)),
                      ]),
                ),
              ]),
            ),
            const SizedBox(height: 24),

            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text("Мои цели",
                  style: GoogleFonts.nunito(
                      fontWeight: FontWeight.bold, fontSize: 18)),
              TextButton(onPressed: _openGoalsTab, child: const Text("История")),
            ]),
            const SizedBox(height: 12),

            if (activeGoal != null)
              _buildGoalCard(activeGoal, percent)
            else
              _noGoalCard(),

            const SizedBox(height: 24),

            Text("Активные задания",
                style: GoogleFonts.nunito(
                    fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _taskCard("Полить цветы", 50, true),
              _taskCard("Помыть посуду", 100, false),
            ]),
          ]),
        ),
      ),
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
                    offset: const Offset(0, 8))
              ]),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child:
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _buildNavItem(Icons.home, 0),
            _buildNavItem(Icons.task_alt, 1),
            _buildNavItem(Icons.flag, 2),
            _buildNavItem(Icons.show_chart, 3),
          ]),
        ),
      ),
    );
  }

  Widget _buildGoalCard(Goal goal, double percent) {
    return Container(
      decoration:
      BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Row(children: [
          const Icon(Icons.pedal_bike, color: Colors.orange),
          const SizedBox(width: 8),
          Text(goal.name,
              style:
              GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.bold)),
          const Spacer(),
          Text("Цель: ${goal.target} ₽",
              style: GoogleFonts.nunito(color: Colors.grey)),
        ]),
        const SizedBox(height: 12),
        Stack(alignment: Alignment.center, children: [
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
          Text("${(percent * 100).toInt()}%",
              style: GoogleFonts.nunito(
                  fontWeight: FontWeight.bold, fontSize: 18)),
        ]),
        const SizedBox(height: 12),
        Text("Накоплено: ${goal.progress} ₽", style: GoogleFonts.nunito()),
        Text("Осталось: ${goal.remaining} ₽",
            style: GoogleFonts.nunito(color: Colors.grey)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: ElevatedButton(
                onPressed: () => _showDepositDialog(goal),
                child: const Text("Пополнить")),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            style:
            ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => _confirmAbandon(goal),
            child: const Text("Отказаться"),
          ),
        ]),
      ]),
    );
  }

  Widget _noGoalCard() {
    return Container(
      decoration:
      BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        Text("У вас нет активной цели.",
            style: GoogleFonts.nunito(fontSize: 16)),
        const SizedBox(height: 8),
        ElevatedButton.icon(
            onPressed: _showCreateGoalDialog,
            icon: const Icon(Icons.add),
            label: const Text("Создать цель")),
      ]),
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
          ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text("+$reward ₽",
            style: GoogleFonts.nunito(color: Colors.orangeAccent)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
              color: done ? Colors.green[100] : Colors.yellow[100],
              borderRadius: BorderRadius.circular(8)),
          child: Text(done ? "Выполнено" : "Проверяется",
              style: GoogleFonts.nunito(
                  color: done ? Colors.green[700] : Colors.orange[700],
                  fontSize: 12)),
        ),
      ]),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _currentIndex = index);
        if (index == 2) _openGoalsTab();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 50,
        height: 50,
        decoration: BoxDecoration(
            color: isSelected ? Colors.blueAccent : const Color(0xFFEDEDED),
            borderRadius: BorderRadius.circular(16)),
        child: Icon(icon, color: isSelected ? Colors.white : Colors.black54),
      ),
    );
  }

  void _openGoalsTab() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GoalsTab(
          childBalance: _balance,
          onBalanceChanged: (delta) {
            setState(() => _balance += delta);
          },
        ),
      ),
    );
  }

  void _showCreateGoalDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const CreateGoalDialog(),
    );

    if (result != null && result['name'] != null && result['target'] != null) {
      // Создаём новую цель через сервис
      final created = goalService.createGoal(result['name'], result['target']);
      if (created != null) {
        // Обновляем экран, чтобы отобразить новую цель
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Новая цель успешно создана!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('У вас уже есть активная цель')),
        );
      }
    }
  }


  void _showDepositDialog(Goal goal) async {
    final amountStr = await showDialog<String>(
        context: context,
        builder: (_) => DepositDialog(maxAmount: _balance));
    if (amountStr == null) return;
    final amount = int.tryParse(amountStr) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Введите корректную сумму")));
      return;
    }
    if (amount > _balance) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Недостаточно средств на балансе")));
      return;
    }
    goalService.deposit(goal, amount, onInsufficient: () {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Цель уже достигнута")));
    });
    setState(() {
      _balance -= amount;
    });
  }

  void _confirmAbandon(Goal goal) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Отказ от цели"),
        content: const Text("Все накопленные деньги сгорят. Продолжить?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Отмена")),
          TextButton(
              onPressed: () {
                goalService.abandonGoal(goal);
                Navigator.pop(context);
                _refresh();
              },
              child: const Text("Отказаться",
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  void _refresh() => setState(() {});
}
