// lib/screens/parent_tasks_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

import 'parent_dashboard_screen.dart';

class ParentTasksScreen extends StatefulWidget {
  final String parentName;
  const ParentTasksScreen({super.key, required this.parentName});

  @override
  State<ParentTasksScreen> createState() => _ParentTasksScreenState();
}

class _ParentTasksScreenState extends State<ParentTasksScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _rewardCtrl = TextEditingController();
  String? _selectedChildId;
  bool _posting = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _rewardCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadChildren() async {
    // just to trigger UI to fetch from DB via FutureBuilder below
  }

  Future<void> _createTask() async {
    final title = _titleCtrl.text.trim();
    final desc = _descCtrl.text.trim();
    final reward = double.tryParse(_rewardCtrl.text.trim()) ?? 0.0;
    if (title.isEmpty || _selectedChildId == null || reward <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Заполните все поля')));
      return;
    }

    setState(() => _posting = true);
    final db = FirebaseDatabase.instance.ref();
    final parentKey = widget.parentName.replaceAll('.', '_');

    // check parent balance
    final parentSnap = await db.child('parents/$parentKey/balance').get();
    double parentBalance = 0.0;
    if (parentSnap.exists && parentSnap.value != null) {
      final p = parentSnap.value;
      if (p is num) parentBalance = p.toDouble();
      else if (p is String) parentBalance = double.tryParse(p) ?? 0.0;
    }
    if (parentBalance < reward) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Вознаграждение больше баланса родителя')));
      setState(() => _posting = false);
      return;
    }

    // create task under tasks/{parentKey}
    final taskRef = db.child('tasks/${parentKey}').push();
    await taskRef.set({
      'title': title,
      'desc': desc,
      'reward': reward,
      'childId': _selectedChildId,
      'createdAt': DateTime.now().toIso8601String(),
      'status': 'open',
    });

    // log
    final logRef = db.child('logs/$parentKey').push();
    await logRef.set({
      'type': 'task_created',
      'taskId': taskRef.key,
      'title': title,
      'amount': reward,
      'timestamp': DateTime.now().toIso8601String(),
    });

    setState(() {
      _posting = false;
      _titleCtrl.clear();
      _descCtrl.clear();
      _rewardCtrl.clear();
      _selectedChildId = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Задача создана')));
  }

  Future<void> _sendForApproval(String taskId, Map<String, dynamic> task) async {
    // mark request in task_requests and set status 'pending'
    final db = FirebaseDatabase.instance.ref();
    final parentKey = widget.parentName.replaceAll('.', '_');

    await db.child('tasks/$parentKey/$taskId/status').set('pending');
    await db.child('task_requests/$parentKey/$taskId').set({
      'task': task,
      'sentAt': DateTime.now().toIso8601String(),
    });

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Запрос на подтверждение отправлен')));
  }

  Future<void> _deleteTask(String taskId) async {
    final db = FirebaseDatabase.instance.ref();
    final parentKey = widget.parentName.replaceAll('.', '_');
    await db.child('tasks/$parentKey/$taskId').remove();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Задача удалена')));
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = ParentDashboardScreen(parentName: widget.parentName);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      body: SafeArea(
        child: Column(
          children: [
            dashboard.buildHeader(context),
            dashboard.buildNavBar(context, 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    // create form
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        children: [
                          TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Название задачи')),
                          const SizedBox(height: 8),
                          TextField(controller: _descCtrl, decoration: const InputDecoration(labelText: 'Описание')),
                          const SizedBox(height: 8),
                          FutureBuilder<DataSnapshot>(
                            future: FirebaseDatabase.instance.ref('parents_children/${widget.parentName.replaceAll('.', '_')}').get(),
                            builder: (context, snap) {
                              if (!snap.hasData || snap.data?.value == null) {
                                return const Text('Нет детей для назначения');
                              }
                              final raw = snap.data!.value as Map<Object?, Object?>;
                              final children = raw.map((k, v) => MapEntry(k.toString(), Map<String, dynamic>.from(v as Map)));
                              return DropdownButtonFormField<String>(
                                value: _selectedChildId,
                                items: children.entries.map((e) {
                                  return DropdownMenuItem(value: e.key, child: Text(e.value['childName'] ?? 'Без имени'));
                                }).toList(),
                                onChanged: (v) => setState(() => _selectedChildId = v),
                                decoration: const InputDecoration(labelText: 'Выберите ребёнка'),
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          TextField(controller: _rewardCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Вознаграждение (₽)')),
                          const SizedBox(height: 10),
                          Row(children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _posting ? null : _createTask,
                                child: _posting ? const CircularProgressIndicator(color: Colors.white) : const Text('Создать задачу'),
                              ),
                            ),
                          ]),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // tasks list
                    FutureBuilder<DataSnapshot>(
                      future: FirebaseDatabase.instance.ref('tasks/${widget.parentName.replaceAll('.', '_')}').get(),
                      builder: (context, snap) {
                        if (!snap.hasData || snap.data?.value == null) {
                          return const SizedBox();
                        }
                        final raw = snap.data!.value as Map<Object?, Object?>;
                        final entries = raw.entries.toList().reversed.toList();
                        return Column(
                          children: entries.map((e) {
                            final id = e.key.toString();
                            final task = Map<String, dynamic>.from(e.value as Map);
                            final title = task['title'] ?? '';
                            final desc = task['desc'] ?? '';
                            final reward = task['reward'] ?? 0;
                            final status = task['status'] ?? 'open';
                            return Card(
                              child: ListTile(
                                title: Text('$title — ₽${reward.toString()}'),
                                subtitle: Text('$desc\nСтатус: $status'),
                                isThreeLine: true,
                                trailing: PopupMenuButton(
                                  itemBuilder: (_) => [
                                    PopupMenuItem(value: 'send', child: const Text('Отправить на подтверждение')),
                                    PopupMenuItem(value: 'delete', child: const Text('Удалить')),
                                  ],
                                  onSelected: (v) async {
                                    if (v == 'send') await _sendForApproval(id, task);
                                    if (v == 'delete') await _deleteTask(id);
                                    setState(() {});
                                  },
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
