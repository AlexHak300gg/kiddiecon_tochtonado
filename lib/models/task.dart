enum TaskStatus {
  open('На выполнении'),
  pending('На проверке'),
  completed('Выполнено'),
  rejected('Отклонено');

  const TaskStatus(this.displayName);
  final String displayName;

  static TaskStatus fromString(String? status) {
    switch (status) {
      case 'open':
        return TaskStatus.open;
      case 'pending':
        return TaskStatus.pending;
      case 'completed':
        return TaskStatus.completed;
      case 'rejected':
        return TaskStatus.rejected;
      default:
        return TaskStatus.open;
    }
  }
}

class Task {
  final String id;
  final String title;
  final String description;
  final double reward;
  final String childId;
  final String parentKey;
  final TaskStatus status;
  final DateTime createdAt;
  final DateTime? submittedAt;
  final DateTime? completedAt;
  final String? rejectionReason;
  final List<String> photoUrls;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.reward,
    required this.childId,
    required this.parentKey,
    required this.status,
    required this.createdAt,
    this.submittedAt,
    this.completedAt,
    this.rejectionReason,
    this.photoUrls = const [],
  });

  bool get isActive => status == TaskStatus.open || status == TaskStatus.pending;
  bool get isCompleted => status == TaskStatus.completed;
  bool get isRejected => status == TaskStatus.rejected;
  bool get isPending => status == TaskStatus.pending;

  // Конвертация в JSON для Firebase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'reward': reward,
      'childId': childId,
      'parentKey': parentKey,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'submittedAt': submittedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'rejectionReason': rejectionReason,
      'photoUrls': photoUrls,
    };
  }

  // Создание из Firebase JSON
  factory Task.fromJson(Map<String, dynamic> json, {String? id}) {
    return Task(
      id: id ?? json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      reward: _toDouble(json['reward']),
      childId: json['childId']?.toString() ?? '',
      parentKey: json['parentKey']?.toString() ?? '',
      status: TaskStatus.fromString(json['status']?.toString()),
      createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now(),
      submittedAt: _parseDateTime(json['submittedAt']),
      completedAt: _parseDateTime(json['completedAt']),
      rejectionReason: json['rejectionReason']?.toString(),
      photoUrls: _parseStringList(json['photoUrls']),
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  static DateTime? _parseDateTime(dynamic v) {
    if (v == null) return null;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  static List<String> _parseStringList(dynamic v) {
    if (v == null) return <String>[];
    if (v is List) {
      return v.map((e) => e.toString()).toList();
    }
    return <String>[];
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    double? reward,
    String? childId,
    String? parentKey,
    TaskStatus? status,
    DateTime? createdAt,
    DateTime? submittedAt,
    DateTime? completedAt,
    String? rejectionReason,
    List<String>? photoUrls,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      reward: reward ?? this.reward,
      childId: childId ?? this.childId,
      parentKey: parentKey ?? this.parentKey,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      submittedAt: submittedAt ?? this.submittedAt,
      completedAt: completedAt ?? this.completedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      photoUrls: photoUrls ?? this.photoUrls,
    );
  }
}