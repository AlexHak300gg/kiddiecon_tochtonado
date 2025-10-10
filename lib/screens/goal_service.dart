// lib/screens/goal_service.dart
import 'dart:async';
import 'dart:math';

/// Модель цели
class Goal {
  final String id;
  final String name;
  final int target; // целевая сумма в рублях
  int progress; // накоплено
  bool active;
  final DateTime createdAt;

  Goal({
    required this.id,
    required this.name,
    required this.target,
    this.progress = 0,
    this.active = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  int get remaining => (target - progress).clamp(0, target);
  int get percent => target > 0 ? ((progress * 100) ~/ target) : 0;
}

/// Сервис управления целями (singleton)
class GoalService {
  GoalService._private();
  static final GoalService instance = GoalService._private();

  final List<Goal> _goals = [];

  /// Возвращает активную цель или null
  Goal? get activeGoal {
    try {
      return _goals.firstWhere((g) => g.active);
    } catch (e) {
      return null;
    }
  }

  /// Копия списка целей для отображения истории
  List<Goal> get goals => List.unmodifiable(_goals);

  // Родительский код и таймер (TTL 2 минуты)
  String? _parentCode;
  DateTime? _expiry;
  Timer? _timer;

  /// Генерация 6-значного кода, действительного 2 минуты
  String generateParentCode() {
    final code = (100000 + Random().nextInt(900000)).toString();
    _parentCode = code;
    _expiry = DateTime.now().add(Duration(minutes: 2));
    _timer?.cancel();
    _timer = Timer(Duration(minutes: 2), () {
      _parentCode = null;
      _expiry = null;
    });
    return code;
  }

  /// Проверка кода родителя (валиден и не просрочен)
  bool validateParentCode(String code) {
    if (_parentCode == null || _expiry == null) return false;
    if (DateTime.now().isAfter(_expiry!)) return false;
    return code == _parentCode;
  }

  /// Создание цели.
  /// Возвращает созданную цель или null, если уже есть активная цель (и force == false).
  Goal? createGoal(String name, int target, {bool force = false}) {
    if (!force && activeGoal != null) return null;
    // деактивируем предыдущие цели
    for (var g in _goals) {
      g.active = false;
    }
    final goal = Goal(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      target: target,
    );
    _goals.insert(0, goal);
    return goal;
  }

  /// Пополнение цели amount руб.
  /// onInsufficient — опциональный callback, если нужно обрабатывать недостаток (внешне).
  /// Возвращает true если зачисление выполнено.
  bool deposit(Goal goal, int amount, {Function? onInsufficient}) {
    if (amount <= 0) {
      return false;
    }
    // Добавляем не больше, чем осталось до цели
    final toAdd = amount.clamp(0, goal.remaining);
    goal.progress += toAdd;
    if (goal.progress >= goal.target) {
      goal.progress = goal.target;
    }
    // Если внешнее управление балансом хочет знать о том, что сумма была больше,
    // можно вызывать onInsufficient (например, при попытке перевести сумму > remaining)
    if (onInsufficient != null && amount > toAdd) {
      onInsufficient();
    }
    return true;
  }

  /// Отказ от цели: накопления сгорают, цель деактивируется
  void abandonGoal(Goal goal) {
    goal.progress = 0;
    goal.active = false;
  }
}
