enum InterviewOutcome {
  approved,
  improve,
}

class InterviewResultsBreakdownModel {
  const InterviewResultsBreakdownModel({
    required this.communication,
    required this.technicalKnowledge,
    required this.confidence,
    required this.subjectMastery,
  });

  final int communication;
  final int technicalKnowledge;
  final int confidence;
  final int subjectMastery;

  InterviewResultsBreakdownModel copyWith({
    int? communication,
    int? technicalKnowledge,
    int? confidence,
    int? subjectMastery,
  }) {
    return InterviewResultsBreakdownModel(
      communication: communication ?? this.communication,
      technicalKnowledge: technicalKnowledge ?? this.technicalKnowledge,
      confidence: confidence ?? this.confidence,
      subjectMastery: subjectMastery ?? this.subjectMastery,
    );
  }

  factory InterviewResultsBreakdownModel.fromJson(Map<String, dynamic> json) {
    return InterviewResultsBreakdownModel(
      communication: _toInt(json['communication']).clamp(0, 100).toInt(),
      technicalKnowledge:
          _toInt(json['technicalKnowledge'] ?? json['subjectMastery']).clamp(0, 100).toInt(),
      confidence: _toInt(json['confidence']).clamp(0, 100).toInt(),
      subjectMastery: _toInt(json['subjectMastery'] ?? json['technicalKnowledge']).clamp(0, 100).toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'communication': communication,
      'technicalKnowledge': technicalKnowledge,
      'confidence': confidence,
      'subjectMastery': subjectMastery,
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
    required this.averageResponseSeconds,
    required this.totalResponseSeconds,
    required this.validAnswersCount,
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
  final int averageResponseSeconds;
  final int totalResponseSeconds;
  final int validAnswersCount;

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
    int? averageResponseSeconds,
    int? totalResponseSeconds,
    int? validAnswersCount,
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
      averageResponseSeconds:
          averageResponseSeconds ?? this.averageResponseSeconds,
      totalResponseSeconds: totalResponseSeconds ?? this.totalResponseSeconds,
      validAnswersCount: validAnswersCount ?? this.validAnswersCount,
    );
  }

  factory InterviewResultsModel.fromJson(Map<String, dynamic> json) {
    final overallScore = _toInt(json['overallScore']).clamp(0, 100).toInt();
    final outcomeRaw = (json['outcome'] as String?) ?? '';
    final outcome = switch (outcomeRaw.trim().toLowerCase()) {
      'approved' || 'aprobado' => InterviewOutcome.approved,
      'improve' || 'mejorar' => InterviewOutcome.improve,
      _ => overallScore >= 70
          ? InterviewOutcome.approved
          : InterviewOutcome.improve,
    };

    return InterviewResultsModel(
      id: (json['id'] as String?) ?? '',
      sessionId: (json['sessionId'] as String?) ?? '',
      userId: (json['userId'] as String?) ?? '',
      analyzedAt: DateTime.tryParse((json['analyzedAt'] as String?) ?? '') ??
          DateTime.now(),
      overallScore: overallScore,
      outcome: outcome,
      breakdown: InterviewResultsBreakdownModel.fromJson(
        (json['breakdown'] as Map?)?.cast<String, dynamic>() ?? {},
      ),
      highlights: (json['highlights'] as List?)?.cast<String>() ?? const [],
      personalizedFeedback: (json['personalizedFeedback'] as String?) ?? '',
      recommendations:
          (json['recommendations'] as List?)?.cast<String>() ?? const [],
      improvementTips:
          (json['improvementTips'] as List?)?.cast<String>() ?? const [],
      averageResponseSeconds: _toInt(json['averageResponseSeconds']).toInt(),
      totalResponseSeconds: _toInt(json['totalResponseSeconds']).toInt(),
      validAnswersCount: _toInt(json['validAnswersCount']).toInt(),
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
      'averageResponseSeconds': averageResponseSeconds,
      'totalResponseSeconds': totalResponseSeconds,
      'validAnswersCount': validAnswersCount,
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

