class Goal {
  final String id;
  final String name;
  final int target; // целевая сумма в рублях
  int progress; // накоплено
  bool active;
  final DateTime createdAt;
  DateTime? completedAt;
  DateTime? deadline; // срок достижения цели (опционально)

  Goal({
    required this.id,
    required this.name,
    required this.target,
    this.progress = 0,
    this.active = true,
    DateTime? createdAt,
    this.completedAt,
    this.deadline,
  }) : createdAt = createdAt ?? DateTime.now();

  int get remaining => (target - progress).clamp(0, target);
  int get percent => target > 0 ? ((progress * 100) ~/ target).clamp(0, 100) : 0;
  bool get isCompleted => progress >= target;

  // Конвертация в JSON для Firebase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'target': target,
      'progress': progress,
      'active': active,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'deadline': deadline?.toIso8601String(),
    };
  }

  // Создание из Firebase JSON
  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      target: _toInt(json['target']),
      progress: _toInt(json['progress']),
      active: json['active'] == true,
      createdAt: _parseDateTime(json['createdAt']),
      completedAt: _parseDateTime(json['completedAt']),
      deadline: _parseDateTime(json['deadline']),
    );
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  static DateTime? _parseDateTime(dynamic v) {
    if (v == null) return null;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  Goal copyWith({
    String? id,
    String? name,
    int? target,
    int? progress,
    bool? active,
    DateTime? createdAt,
    DateTime? completedAt,
    DateTime? deadline,
  }) {
    return Goal(
      id: id ?? this.id,
      name: name ?? this.name,
      target: target ?? this.target,
      progress: progress ?? this.progress,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      deadline: deadline ?? this.deadline,
    );
  }
}
