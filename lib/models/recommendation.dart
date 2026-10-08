import 'risk_level.dart';

class Recommendation {
  final String id;
  final RiskLevel priority;
  final String title;
  final String action;
  final String type; // 'blur', 'crop', 'scrub_exif', 'do_not_share', 'rotate'
  final bool isCompleted;

  const Recommendation({
    required this.id,
    required this.priority,
    required this.title,
    required this.action,
    required this.type,
    this.isCompleted = false,
  });

  Recommendation copyWith({
    String? id,
    RiskLevel? priority,
    String? title,
    String? action,
    String? type,
    bool? isCompleted,
  }) {
    return Recommendation(
      id: id ?? this.id,
      priority: priority ?? this.priority,
      title: title ?? this.title,
      action: action ?? this.action,
      type: type ?? this.type,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'priority': priority.name,
        'title': title,
        'action': action,
        'type': type,
        'isCompleted': isCompleted,
      };

  factory Recommendation.fromJson(Map<String, dynamic> json) {
    return Recommendation(
      id: json['id'] as String? ?? DateTime.now().microsecondsSinceEpoch.toString(),
      priority: RiskLevel.fromString(json['priority'] as String? ?? 'high'),
      title: json['title'] as String? ?? 'Mitigation Action',
      action: json['action'] as String? ?? '',
      type: json['type'] as String? ?? 'general',
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }
}
