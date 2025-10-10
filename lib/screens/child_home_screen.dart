import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dialogs.dart';

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
  StreamSubscription<DatabaseEvent>? _sub;

  int _balance = 0;
  String _goalName = 'Пока не установлена';
  int _goalTarget = 0;
  int _goalProgress = 0;
  List<Map<String, dynamic>> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _childRef =
        _db.child('parents_children/${widget.parentKey}/${widget.childId}');
    _subscribeToChild();
  }

  void _subscribeToChild() {
    _sub?.cancel();
    _sub = _childRef.onValue.listen((event) {
      final val = event.snapshot.value;
      if (val == null) {
        setState(() {
          _balance = 0;
          _goalName = 'Пока не установлена';
          _goalTarget = 0;
          _goalProgress = 0;
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
          _goalName = (map['goal'] ?? 'Пока не установлена').toString();
          _goalTarget = _toInt(map['target']);
          _goalProgress = _toInt(map['progress']);
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

  int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  Future<void> _setGoal(String name, int target) async {
    await _childRef.update({
      'goal': name,
      'target': target,
      'progress': 0,
    });
    await _childRef.child('history').push().set({
      'action': 'Создание цели',
      'amount': 0,
      'note': name,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _addBalance(int amount) async {
    final newBal = _balance + amount;
    await _childRef.update({'balance': newBal});
    await _childRef.child('history').push().set({
      'action': 'Пополнение',
      'amount': amount,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _depositToGoal() async {
    if (_goalTarget <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Сначала установи цель')),
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
    final newProgress = _goalProgress + amount;
    await _childRef.update({'balance': newBalance, 'progress': newProgress});
    await _childRef.child('history').push().set({
      'action': 'Вклад в цель',
      'amount': amount,
      'note': _goalName,
      'timestamp': DateTime.now().toIso8601String(),
    });

    if (_goalTarget > 0 && newProgress >= _goalTarget) {
      await _childRef.child('history').push().set({
        'action': 'Цель достигнута',
        'amount': 0,
        'note': _goalName,
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  double get _progressPercent {
    if (_goalTarget == 0) return 0.0;
    return (_goalProgress / _goalTarget).clamp(0.0, 1.0);
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
    final percent = (_progressPercent * 100).toInt();
    return Container(
      padding: const EdgeInsets.all(18),
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
      child: Row(
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
                  color: Colors.orange,
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
                      'цель',
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        color: Colors.black54,
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
                  _goalName,
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Цель: ${_goalTarget}₽',
                  style: GoogleFonts.nunito(color: Colors.black54),
                ),
                const SizedBox(height: 6),
                Text(
                  'Накоплено: ${_goalProgress}₽',
                  style: GoogleFonts.nunito(
                    color: Colors.green,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),

                // 🔘 Кнопки
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        await showDialog(
                          context: context,
                          builder: (_) => CreateGoalDialog(
                            onCreated: (name, target) => _setGoal(name, target),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF42A5F5),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Изменить',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 6),

                    // ⚠️ Меньшая кнопка "Отказаться"
                    OutlinedButton(
                      onPressed: () async {
                        await _childRef.update({
                          'goal': 'Пока не установлена',
                          'target': 0,
                          'progress': 0,
                        });
                        await _childRef.child('history').push().set({
                          'action': 'Отказ от цели',
                          'amount': 0,
                          'timestamp': DateTime.now().toIso8601String(),
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent, width: 1),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 5),
                        textStyle: const TextStyle(fontSize: 12),
                        minimumSize: const Size(0, 25),
                      ),
                      child: const Text('Отказаться'),
                    ),
                  ],
                ),
              ],
            ),
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
                      onPressed: () {},
                      child: const Text('История'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildGoalCard(),
                const SizedBox(height: 18),
                Text('Активные задания',
                    style: GoogleFonts.nunito(
                        fontSize: 18, fontWeight: FontWeight.w800)),
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
                Text('История операций',
                    style: GoogleFonts.nunito(
                        fontSize: 18, fontWeight: FontWeight.w800)),
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
}
