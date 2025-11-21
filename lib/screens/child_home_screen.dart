import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/goal.dart';
import '../models/account.dart';
import '../models/operation.dart';
import '../services/goal_service.dart';
import '../services/account_service.dart';
import '../services/achievement_service.dart';
import '../widgets/celebration_animation.dart';
import 'dialogs.dart';
import 'goals_history_screen.dart';
import 'child_tasks_screen.dart';
import 'operation_history_screen.dart';
import 'achievements_screen.dart';
import 'setup_security_screen.dart';
import 'role_selection_screen.dart';

class ChildHomeScreen extends StatefulWidget {
  final String childId;
  final String parentKey;
  final String childName;

  const ChildHomeScreen({
    super.key,
    required this.childId,
    required this.parentKey,
    required this.childName,
  });

  @override
  State<ChildHomeScreen> createState() => _ChildHomeScreenState();
}

class _ChildHomeScreenState extends State<ChildHomeScreen> {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  late DatabaseReference _childRef;
  late GoalService _goalService;
  late AccountService _accountService;
  late AchievementService _achievementService;
  StreamSubscription<DatabaseEvent>? _sub;
  StreamSubscription<List<Goal>>? _goalsSub;

  int _balance = 0;
  Goal? _activeGoal;
  List<Map<String, dynamic>> _history = [];
  bool _loading = true;
  Goal? _lastCompletedGoal;
  
  // Account service related variables
  Account? _account;
  List<Operation> _operations = [];
  double _todayInterest = 0.0;

  @override
  void initState() {
    super.initState();
    _childRef = _db.child('parents_children/${widget.parentKey}/${widget.childId}');
    _goalService = GoalService(parentKey: widget.parentKey, childId: widget.childId);
    _accountService = AccountService(childId: widget.childId, parentKey: widget.parentKey);
    _achievementService = AchievementService();
    _subscribeToChild();
    _subscribeToGoals();
    _subscribeToAccount();
    _checkAndApplyMissedInterest();
  }

  void _subscribeToChild() {
    _sub?.cancel();
    _sub = _childRef.onValue.listen((event) {
      final val = event.snapshot.value;
      if (val == null) {
        setState(() {
          _balance = 0;
          _history = [];
          _loading = false;
        });
        return;
      }
      try {
        final map = Map<String, dynamic>.from(event.snapshot.value as Map);
        final histRaw = map['history'];
        List<Map<String, dynamic>> hist = [];
        if (histRaw is Map) {
          hist = (histRaw as Map).entries.map((e) {
            final item = Map<String, dynamic>.from(e.value as Map);
            item['id'] = e.key;
            return item;
          }).toList();
          hist.sort((a, b) {
            final ta = DateTime.tryParse(a['timestamp']?.toString() ?? '') ??
                DateTime.fromMillisecondsSinceEpoch(0);
            final tb = DateTime.tryParse(b['timestamp']?.toString() ?? '') ??
                DateTime.fromMillisecondsSinceEpoch(0);
            return tb.compareTo(ta);
          });
        }
        setState(() {
          _balance = _toInt(map['balance']);
          _history = hist;
          _loading = false;
        });
      } catch (e) {
        debugPrint('Parse child data error: $e');
        setState(() => _loading = false);
      }
    }, onError: (err) {
      debugPrint('Firebase listen error: $err');
      setState(() => _loading = false);
    });
  }

  void _subscribeToGoals() {
    _goalsSub?.cancel();
    _goalsSub = _goalService.goalsStream.listen((goals) {
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
      
      setState(() {
        _activeGoal = newActiveGoal;
      });
    });
  }

  void _subscribeToAccount() {
    _accountService.accountStream.listen((account) {
      setState(() {
        _account = account;
        _balance = account.balance.round();
      });
    });

    _accountService.operationsStream.listen((operations) {
      setState(() {
        _operations = operations;
        _calculateTodayInterest();
      });
    });
  }

  void _calculateTodayInterest() {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    _todayInterest = _operations
        .where((op) => 
            op.type == OperationType.dailyInterest &&
            op.timestamp.isAfter(todayStart) &&
            op.timestamp.isBefore(todayEnd))
        .fold(0.0, (sum, op) => sum + op.amount);
  }

  Future<void> _checkAndApplyMissedInterest() async {
    try {
      await _accountService.applyDailyInterest();
    } catch (e) {
      debugPrint('Error applying missed interest: $e');
    }
  }

  int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  Future<void> _createGoal() async {
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

  Future<void> _addBalance(int amount) async {
    try {
      await _accountService.addOperation(
        OperationType.bonus,
        amount.toDouble(),
        'Пополнение баланса',
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Баланс пополнен на +$amount₽')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  Future<void> _depositToGoal() async {
    if (_activeGoal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Сначала создайте цель')),
      );
      return;
    }
    
    final amountStr = await showDialog<String>(
      context: context,
      builder: (_) => DepositDialog(maxAmount: _balance),
    );
    if (amountStr == null) return;
    
    final amount = int.tryParse(amountStr) ?? 0;
    if (amount <= 0) return;
    
    if (amount > _balance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Недостаточно средств')),
      );
      return;
    }
    
    final newBalance = _balance - amount;
    await _childRef.update({'balance': newBalance});
    
    await _goalService.depositToGoal(_activeGoal!, amount);
    
    await _childRef.child('history').push().set({
      'action': 'Вклад в цель',
      'amount': amount,
      'note': _activeGoal!.name,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _logout() async {
   final confirmed = await showDialog<bool>(
     context: context,
     builder: (context) => AlertDialog(
       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
       title: Text(
         'Выход',
         style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
       ),
       content: Text(
         'Вы уверены, что хотите выйти?',
         style: GoogleFonts.nunito(),
       ),
       actions: [
         TextButton(
           onPressed: () => Navigator.pop(context, false),
           child: const Text('Отмена'),
         ),
         ElevatedButton(
           onPressed: () => Navigator.pop(context, true),
           style: ElevatedButton.styleFrom(
             backgroundColor: Colors.red,
           ),
           child: const Text('Выход'),
         ),
       ],
     ),
   );

   if (confirmed == true && mounted) {
     final prefs = await SharedPreferences.getInstance();
     await prefs.remove('userRole');
     await prefs.remove('firstLoginDone');

     if (!mounted) return;
     Navigator.pushReplacement(
       context,
       MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
     );
   }
  }

  Future<void> _changePIN() async {
   Navigator.push(
     context,
     MaterialPageRoute(
       builder: (_) => SetupSecurityScreen(
         userRole: 'child',
         isFirstTime: false,
       ),
     ),
   );
  }

  @override
  void dispose() {
   _sub?.cancel();
   _goalsSub?.cancel();
   _goalService.dispose();
   super.dispose();
  }

  double get _progressPercent {
    if (_activeGoal == null || _activeGoal!.target == 0) return 0.0;
    return (_activeGoal!.progress / _activeGoal!.target).clamp(0.0, 1.0);
  }

  // ---------- UI ----------
  Widget _buildHeaderCard(BuildContext ctx) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4FC3F7), Color(0xFF42A5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 👤 Иконка профиля
          Container(
            width: 68,
            height: 68,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: const Icon(
              Icons.person,
              size: 40,
              color: Color(0xFF42A5F5),
            ),
          ),
          const SizedBox(width: 16),

          // 🧾 Имя и баланс
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Привет, ${widget.childName} 👋',
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Баланс',
                  style: GoogleFonts.nunito(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₽ $_balance',
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (_todayInterest > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Сегодня начислено: +${_todayInterest.toStringAsFixed(2)}₽',
                    style: GoogleFonts.nunito(
                      color: Colors.green.shade200,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // 💸 Кнопки
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SizedBox(
                width: 85,
                child: ElevatedButton(
                  onPressed: () => _addBalance(100),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF42A5F5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: const Text('+100',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 85,
                child: ElevatedButton(
                  onPressed: _depositToGoal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: const Text('Внести',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard() {
    if (_activeGoal == null) {
      return Container(
        padding: const EdgeInsets.all(24),
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
              size: 60,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 12),
            Text(
              'Нет активной цели',
              style: GoogleFonts.nunito(
                fontSize: 18,
                fontWeight: FontWeight.w600,
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
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _createGoal,
              icon: const Icon(Icons.add),
              label: const Text('Создать цель'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final goal = _activeGoal!;
    final percent = goal.percent;
    final dateFormat = DateFormat('dd.MM.yyyy');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: goal.isCompleted
            ? const LinearGradient(
                colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: goal.isCompleted ? null : Colors.white,
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 🎯 Увеличенный круг прогресса
              SizedBox(
                width: 140,
                height: 140,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: _progressPercent,
                      strokeWidth: 12,
                      backgroundColor: Colors.grey.shade200,
                      color: goal.isCompleted ? Colors.green : Colors.orange,
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$percent%',
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          goal.isCompleted ? 'готово!' : 'цель',
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            color: goal.isCompleted ? Colors.green : Colors.black54,
                            fontWeight: goal.isCompleted ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
              const SizedBox(width: 18),

              // 🧾 Информация о цели
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.name,
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${goal.progress}₽ из ${goal.target}₽',
                      style: GoogleFonts.nunito(
                        color: Colors.black54,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (!goal.isCompleted)
                      Text(
                        'Осталось: ${goal.remaining}₽',
                        style: GoogleFonts.nunito(
                          color: Colors.orange,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    if (goal.deadline != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 14, color: Colors.black54),
                          const SizedBox(width: 4),
                          Text(
                            'Срок: ${dateFormat.format(goal.deadline!)}',
                            style: GoogleFonts.nunito(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 🔘 Кнопки
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (goal.isCompleted) ...[
                ElevatedButton.icon(
                  onPressed: _createGoal,
                  icon: const Icon(Icons.add),
                  label: const Text('Новая цель'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ] else ...[
                ElevatedButton.icon(
                  onPressed: () => _depositToGoal(),
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Внести'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF42A5F5),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Отказаться от цели?'),
                        content: Text('Вы уверены, что хотите отказаться от цели "${goal.name}"?'),
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
                      await _goalService.abandonGoal(goal);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Цель отменена')),
                        );
                      }
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent, width: 1),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  child: const Text('Отказаться'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildTaskCard(String title, int reward, bool done, Color color) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.06), blurRadius: 6)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 8,
              height: 8,
              decoration:
              BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(title,
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
            ),
            if (done)
              const Icon(Icons.check_circle, color: Colors.green, size: 18),
          ]),
          const SizedBox(height: 8),
          Text('+$reward₽',
              style: GoogleFonts.nunito(
                  color: Colors.orange, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: done
                ? null
                : () async {
              final newBalance = _balance + reward;
              await _childRef.update({'balance': newBalance});
              await _childRef.child('history').push().set({
                'action': 'Награда: $title',
                'amount': reward,
                'timestamp': DateTime.now().toIso8601String(),
              });
              setState(() => _balance = newBalance);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content:
                    Text('Задание "$title" выполнено! +$reward₽ 🎉')),
              );
            },
            style:
            ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            child: Text(done ? 'Выполнено' : 'Завершить'),
          ),
        ],
      ),
    );
  }

  Widget _buildHistory() {
    if (_history.isEmpty) {
      return Center(
        child: Text('Здесь будут операции',
            style: GoogleFonts.nunito(color: Colors.black54)),
      );
    }
    return Column(
      children: _history.take(6).map((h) {
        final action = h['action'] ?? '';
        final amount = h['amount']?.toString() ?? '';
        final ts = h['timestamp'] ?? '';
        return ListTile(
          dense: true,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
          leading: CircleAvatar(
            radius: 18,
            backgroundColor: Colors.grey.shade200,
            child: const Icon(Icons.history, color: Colors.orange),
          ),
          title:
          Text(action, style: GoogleFonts.nunito(fontWeight: FontWeight.w600)),
          subtitle:
          Text(ts.toString(), style: GoogleFonts.nunito(fontSize: 11, color: Colors.black45)),
          trailing: Text('$amount₽',
              style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F6FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'change_pin') {
                _changePIN();
              } else if (value == 'logout') {
                _logout();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'change_pin',
                child: Row(
                  children: [
                    const Icon(Icons.lock, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      'Изменить PIN',
                      style: GoogleFonts.nunito(),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    const Icon(Icons.logout, color: Colors.red),
                    const SizedBox(width: 8),
                    Text(
                      'Выход',
                      style: GoogleFonts.nunito(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
          onRefresh: () async => _childRef.get(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderCard(context),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Мои цели',
                        style: GoogleFonts.nunito(
                            fontSize: 18, fontWeight: FontWeight.w800)),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GoalsHistoryScreen(
                              childId: widget.childId,
                              childName: widget.childName,
                            ),
                          ),
                        );
                      },
                      child: const Text('История'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildGoalCard(),
                const SizedBox(height: 18),
                
                // Achievements section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Достижения',
                        style: GoogleFonts.nunito(
                            fontSize: 18, fontWeight: FontWeight.w800)),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AchievementsScreen(
                              childId: widget.childId,
                              childName: widget.childName,
                            ),
                          ),
                        );
                      },
                      child: const Text('Все'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  height: 120,
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: _getAchievementsPreview(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      
                      final achievements = snapshot.data ?? [];
                      if (achievements.isEmpty) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Center(
                            child: Text(
                              'Начните выполнять задания, чтобы получить достижения!',
                              style: GoogleFonts.nunito(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }
                      
                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: achievements.length,
                        itemBuilder: (context, index) {
                          final achievement = achievements[index];
                          return Container(
                            width: 100,
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: achievement['isUnlocked'] 
                                    ? Colors.orange.withOpacity(0.3)
                                    : Colors.grey.shade200,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  achievement['icon'],
                                  style: TextStyle(
                                    fontSize: 32,
                                    color: achievement['isUnlocked'] 
                                        ? null 
                                        : Colors.grey[400],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  achievement['title'],
                                  style: GoogleFonts.nunito(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: achievement['isUnlocked'] 
                                        ? Colors.black87 
                                        : Colors.grey[500],
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Активные задания',
                        style: GoogleFonts.nunito(
                            fontSize: 18, fontWeight: FontWeight.w800)),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChildTasksScreen(
                              childName: widget.childName,
                              childId: widget.childId,
                            ),
                          ),
                        );
                      },
                      child: const Text('Все задания'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildTaskCard('Полить цветы', 50, false, Colors.green),
                      const SizedBox(width: 12),
                      _buildTaskCard('Помыть посуду', 100, false, Colors.orange),
                      const SizedBox(width: 12),
                      _buildTaskCard('Убрать комнату', 80, true, Colors.purple),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('История операций',
                        style: GoogleFonts.nunito(
                            fontSize: 18, fontWeight: FontWeight.w800)),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OperationHistoryScreen(
                              parentKey: widget.parentKey,
                              childrenData: [
                                {'id': widget.childId, 'name': widget.childName}
                              ],
                            ),
                          ),
                        );
                      },
                      child: const Text('Подробнее'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildHistory(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _getAchievementsPreview() async {
    try {
      final achievements = await _achievementService.getAchievements(widget.childId);
      return achievements.take(4).map((a) => {
        'id': a.id,
        'title': a.title,
        'icon': a.icon,
        'isUnlocked': a.isUnlocked,
      }).toList();
    } catch (e) {
      return [];
    }
  }
}
