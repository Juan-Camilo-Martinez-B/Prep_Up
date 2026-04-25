enum InterviewOutcome {
  approved,
  improve,
}

class InterviewResultsBreakdownModel {
  const InterviewResultsBreakdownModel({
    required this.communication,
    required this.technicalKnowledge,
    required this.confidence,
  });

  final int communication;
  final int technicalKnowledge;
  final int confidence;

  factory InterviewResultsBreakdownModel.fromJson(Map<String, dynamic> json) {
    return InterviewResultsBreakdownModel(
      communication: _toInt(json['communication']).clamp(0, 100).toInt(),
      technicalKnowledge:
          _toInt(json['technicalKnowledge']).clamp(0, 100).toInt(),
      confidence: _toInt(json['confidence']).clamp(0, 100).toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'communication': communication,
      'technicalKnowledge': technicalKnowledge,
      'confidence': confidence,
    };
  }
}

class InterviewResultsModel {
  const InterviewResultsModel({
    required this.id,
    required this.sessionId,
    required this.userId,
    required this.analyzedAt,
    required this.overallScore,
    required this.outcome,
    required this.breakdown,
    required this.highlights,
    required this.personalizedFeedback,
    required this.recommendations,
    required this.improvementTips,
  });

  final String id;
  final String sessionId;
  final String userId;
  final DateTime analyzedAt;
  final int overallScore;
  final InterviewOutcome outcome;
  final InterviewResultsBreakdownModel breakdown;
  final List<String> highlights;
  final String personalizedFeedback;
  final List<String> recommendations;
  final List<String> improvementTips;

  InterviewResultsModel copyWith({
    String? id,
    String? sessionId,
    String? userId,
    DateTime? analyzedAt,
    int? overallScore,
    InterviewOutcome? outcome,
    InterviewResultsBreakdownModel? breakdown,
    List<String>? highlights,
    String? personalizedFeedback,
    List<String>? recommendations,
    List<String>? improvementTips,
  }) {
    return InterviewResultsModel(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      userId: userId ?? this.userId,
      analyzedAt: analyzedAt ?? this.analyzedAt,
      overallScore: overallScore ?? this.overallScore,
      outcome: outcome ?? this.outcome,
      breakdown: breakdown ?? this.breakdown,
      highlights: highlights ?? this.highlights,
      personalizedFeedback: personalizedFeedback ?? this.personalizedFeedback,
      recommendations: recommendations ?? this.recommendations,
      improvementTips: improvementTips ?? this.improvementTips,
    );
  }

  factory InterviewResultsModel.fromJson(Map<String, dynamic> json) {
    final overallScore = _toInt(json['overallScore']).clamp(0, 100).toInt();
    final outcomeRaw = (json['outcome'] as String?) ?? '';
    final outcome = switch (outcomeRaw.trim().toLowerCase()) {
      'approved' || 'aprobado' => InterviewOutcome.approved,
      'improve' || 'mejorar' => InterviewOutcome.improve,
      _ => overallScore >= 70 ? InterviewOutcome.approved : InterviewOutcome.improve,
    };

    final highlights =
        (json['highlights'] as List?)?.whereType<String>().toList() ??
            const <String>[];
    final recommendations =
        (json['recommendations'] as List?)?.whereType<String>().toList() ??
            const <String>[];
    final improvementTips =
        (json['improvementTips'] as List?)?.whereType<String>().toList() ??
            const <String>[];

    return InterviewResultsModel(
      id: json['id'] as String? ?? '',
      sessionId: json['sessionId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      analyzedAt: json['analyzedAt'] != null 
          ? DateTime.parse(json['analyzedAt'] as String).toLocal()
          : DateTime.now(),
      overallScore: overallScore,
      outcome: outcome,
      breakdown: InterviewResultsBreakdownModel.fromJson(
        (json['breakdown'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      ),
      highlights: highlights,
      personalizedFeedback: (json['personalizedFeedback'] as String?) ?? '',
      recommendations: recommendations,
      improvementTips: improvementTips,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sessionId': sessionId,
      'userId': userId,
      'analyzedAt': analyzedAt.toUtc().toIso8601String(),
      'overallScore': overallScore,
      'outcome': outcome.name,
      'breakdown': breakdown.toJson(),
      'highlights': highlights,
      'personalizedFeedback': personalizedFeedback,
      'recommendations': recommendations,
      'improvementTips': improvementTips,
    };
  }
}

int _toInt(Object? value) {
  return switch (value) {
    int v => v,
    double v => v.round(),
    String v => int.tryParse(v) ?? 0,
    _ => 0,
  };
}

