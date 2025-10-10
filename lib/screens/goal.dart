class Goal {
  final String id;
  final String name;
  final int target; // в рублях
  int progress; // накоплено
  final DateTime createdAt;
  bool active;

  Goal({
    required this.id,
    required this.name,
    required this.target,
    this.progress = 0,
    DateTime? createdAt,
    this.active = true,
  }) : createdAt = createdAt ?? DateTime.now();

  int get remaining => (target - progress).clamp(0, target);
  int get percent => target > 0 ? ((progress * 100) ~/ target) : 0;
}
