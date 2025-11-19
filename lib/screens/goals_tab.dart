import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/goal.dart';
import '../services/goal_service.dart';
import '../widgets/celebration_animation.dart';
import 'dialogs.dart';
import 'goals_history_screen.dart';

class GoalsTab extends StatefulWidget {
  final String childId;
  final String parentKey;
  final int childBalance;
  final Function(int delta) onBalanceChanged;
  
  const GoalsTab({
    required this.childId,
    required this.parentKey,
    required this.childBalance,
    required this.onBalanceChanged,
    super.key,
  });

  @override
  State<GoalsTab> createState() => _GoalsTabState();
}

class _GoalsTabState extends State<GoalsTab> {
  late GoalService _goalService;
  Goal? _activeGoal;
  Goal? _lastCompletedGoal;

  @override
  void initState() {
    super.initState();
    _goalService = GoalService(
      parentKey: widget.parentKey,
      childId: widget.childId,
    );
    _subscribeToGoals();
  }

  void _subscribeToGoals() {
    _goalService.goalsStream.listen((goals) {
      final newActiveGoal = _goalService.activeGoal;
      
      // Проверяем, была ли только что завершена цель
      if (_activeGoal != null && 
          !_activeGoal!.isCompleted && 
          newActiveGoal != null && 
          newActiveGoal.isCompleted &&
          newActiveGoal.id == _activeGoal!.id) {
        _lastCompletedGoal = newActiveGoal;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _lastCompletedGoal != null) {
            showCelebrationDialog(context, _lastCompletedGoal!.name);
            _lastCompletedGoal = null;
          }
        });
      }
      
      if (mounted) {
        setState(() {
          _activeGoal = newActiveGoal;
        });
      }
    });
  }

  @override
  void dispose() {
    _goalService.dispose();
    super.dispose();
  }

  void _createGoal() async {
    try {
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (_) => const CreateGoalDialog(),
      );

      if (result != null && result['name'] != null && result['target'] != null) {
        final name = result['name'] as String;
        final target = result['target'] as int;
        final deadline = result['deadline'] as DateTime?;

        await _goalService.createGoal(
          name: name,
          target: target,
          deadline: deadline,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Цель "$name" создана! 🎯')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
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

    await _goalService.depositToGoal(g, amount);
    widget.onBalanceChanged(-amount);
  }

  void _abandon(Goal g) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Отказаться от цели?'),
        content: Text('Вы уверены, что хотите отказаться от цели "${g.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Отказаться', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _goalService.abandonGoal(g);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Цель отменена')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F6FF),
      appBar: AppBar(
        title: Text(
          'Мои цели',
          style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GoalsHistoryScreen(goalService: _goalService),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Goal>>(
        stream: _goalService.goalsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final active = _goalService.activeGoal;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Активная цель:',
                  style: GoogleFonts.nunito(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                if (active == null)
                  _buildEmptyState()
                else
                  _buildActiveGoal(active),
                const SizedBox(height: 24),
                if (active == null || active.isCompleted) ...[
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: _createGoal,
                      icon: const Icon(Icons.add),
                      label: const Text('Создать новую цель'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.flag_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Нет активной цели',
            style: GoogleFonts.nunito(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Создайте цель, чтобы начать копить',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 14,
              color: Colors.black38,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveGoal(Goal g) {
    final percent = g.target > 0 ? g.progress / g.target : 0.0;
    final dateFormat = DateFormat('dd.MM.yyyy');

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: g.isCompleted
              ? const LinearGradient(
                  colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                g.name,
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Цель: ${g.target} ₽',
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
              if (g.deadline != null) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: Colors.black54),
                    const SizedBox(width: 4),
                    Text(
                      'Срок: ${dateFormat.format(g.deadline!)}',
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: 160,
                height: 160,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: percent,
                      strokeWidth: 16,
                      color: g.isCompleted ? Colors.green : Colors.orange,
                      backgroundColor: Colors.grey.shade200,
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(percent * 100).toInt()}%',
                          style: GoogleFonts.nunito(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: g.isCompleted ? Colors.green : Colors.orange,
                          ),
                        ),
                        Text(
                          g.isCompleted ? 'Готово!' : 'цель',
                          style: GoogleFonts.nunito(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        '${g.progress} ₽',
                        style: GoogleFonts.nunito(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      Text(
                        'Накоплено',
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        '${g.remaining} ₽',
                        style: GoogleFonts.nunito(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      Text(
                        'Осталось',
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (!g.isCompleted)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _deposit(g),
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('Пополнить'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF42A5F5),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: () => _abandon(g),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent, width: 2),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Отказаться'),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
