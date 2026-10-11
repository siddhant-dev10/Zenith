import 'risk_level.dart';

class Recommendation {
  final String id;
  final RiskLevel priority;
  final String title;
  final String action;
  final String type; // 'blur', 'crop', 'scrub_exif', 'do_not_share', 'rotate', 'solid_censor'
  final bool isCompleted;

  // Architectural extensions for actionable risk remediation
  final String? findingRef;
  final int estimatedRiskReduction;
  final bool automatable;

  const Recommendation({
    required this.id,
    required this.priority,
    required this.title,
    required this.action,
    required this.type,
    this.isCompleted = false,
    this.findingRef,
    this.estimatedRiskReduction = 15,
    this.automatable = true,
  });

  Recommendation copyWith({
    String? id,
    RiskLevel? priority,
    String? title,
    String? action,
    String? type,
    bool? isCompleted,
    String? findingRef,
    int? estimatedRiskReduction,
    bool? automatable,
  }) {
    return Recommendation(
      id: id ?? this.id,
      priority: priority ?? this.priority,
      title: title ?? this.title,
      action: action ?? this.action,
      type: type ?? this.type,
      isCompleted: isCompleted ?? this.isCompleted,
      findingRef: findingRef ?? this.findingRef,
      estimatedRiskReduction:
          estimatedRiskReduction ?? this.estimatedRiskReduction,
      automatable: automatable ?? this.automatable,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'priority': priority.name,
    'title': title,
    'action': action,
    'type': type,
    'isCompleted': isCompleted,
    'findingRef': findingRef,
    'estimatedRiskReduction': estimatedRiskReduction,
    'automatable': automatable,
  };

  factory Recommendation.fromJson(Map<String, dynamic> json) {
    return Recommendation(
      id:
          json['id'] as String? ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      priority: RiskLevel.fromString(json['priority'] as String? ?? 'high'),
      title: json['title'] as String? ?? 'Mitigation Action',
      action: json['action'] as String? ?? '',
      type: json['type'] as String? ?? 'general',
      isCompleted: json['isCompleted'] as bool? ?? false,
      findingRef: json['findingRef'] as String?,
      estimatedRiskReduction:
          (json['estimatedRiskReduction'] as num?)?.toInt() ?? 15,
      automatable: json['automatable'] as bool? ?? true,
    );
  }
}
