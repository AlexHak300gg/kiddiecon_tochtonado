class Achievement {
  final String? id;
  final String title;
  final String description;
  final String icon;
  final DateTime? unlockedAt;
  final bool isUnlocked;

  const Achievement({
    this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.unlockedAt,
    this.isUnlocked = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'icon': icon,
      'unlockedAt': unlockedAt?.toIso8601String(),
      'isUnlocked': isUnlocked,
    };
  }

  factory Achievement.fromMap(Map<String, dynamic> map, {String? id}) {
    return Achievement(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      icon: map['icon'] ?? '🏆',
      unlockedAt: _parseDateTime(map['unlockedAt']),
      isUnlocked: map['isUnlocked'] ?? false,
    );
  }

  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    String? icon,
    DateTime? unlockedAt,
    bool? isUnlocked,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      isUnlocked: isUnlocked ?? this.isUnlocked,
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // Predefined achievements
  static List<Achievement> get predefinedAchievements => [
    Achievement(
      id: 'first_task',
      title: 'Первая задача',
      description: 'Выполнил 1 задачу',
      icon: '🎯',
    ),
    Achievement(
      id: 'persistent_saver',
      title: 'Упорный копилка',
      description: 'Накопил 50% от текущей цели',
      icon: '💰',
    ),
    Achievement(
      id: 'goal_achieved',
      title: 'Цель достигнута!',
      description: 'Достиг 100% текущей цели',
      icon: '🏆',
    ),
    Achievement(
      id: 'week_active',
      title: 'Неделя активности',
      description: 'Выполнял задачи 7 дней подряд',
      icon: '📅',
    ),
    Achievement(
      id: 'balance_100',
      title: '100₽ на счету',
      description: 'Баланс достиг 100₽',
      icon: '💵',
    ),
    Achievement(
      id: 'five_tasks',
      title: '5 задач выполнено',
      description: 'Выполнил 5 задач всего',
      icon: '⭐',
    ),
  ];
}