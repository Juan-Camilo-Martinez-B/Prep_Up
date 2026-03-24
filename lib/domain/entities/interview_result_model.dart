class InterviewScoreBreakdownModel {
  const InterviewScoreBreakdownModel({
    required this.bodyLanguage,
    required this.clarity,
    required this.confidence,
  });

  final int bodyLanguage;
  final int clarity;
  final int confidence;

  factory InterviewScoreBreakdownModel.fromJson(Map<String, dynamic> json) {
    return InterviewScoreBreakdownModel(
      bodyLanguage: (json['bodyLanguage'] as int?) ?? 0,
      clarity: (json['clarity'] as int?) ?? 0,
      confidence: (json['confidence'] as int?) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bodyLanguage': bodyLanguage,
      'clarity': clarity,
      'confidence': confidence,
    };
  }

  @override
  String toString() {
    return 'InterviewScoreBreakdownModel(bodyLanguage: $bodyLanguage, clarity: $clarity, confidence: $confidence)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is InterviewScoreBreakdownModel &&
            runtimeType == other.runtimeType &&
            bodyLanguage == other.bodyLanguage &&
            clarity == other.clarity &&
            confidence == other.confidence;
  }

  @override
  int get hashCode {
    return Object.hash(bodyLanguage, clarity, confidence);
  }
}

class InterviewResultModel {
  const InterviewResultModel({
    required this.id,
    required this.sessionId,
    required this.userId,
    required this.analyzedAt,
    required this.score,
    required this.successProbability,
    required this.breakdown,
    required this.recommendations,
  });

  final String id;
  final String sessionId;
  final String userId;
  final DateTime analyzedAt;
  final int score;
  final double successProbability;
  final InterviewScoreBreakdownModel breakdown;
  final List<String> recommendations;

  // TODO: guardar resultado de entrevista en base de datos relacional.
  // TODO: conectar con servicio de IA para generar análisis y recomendaciones.
  // TODO: enviar video a servicio de análisis gestual para métricas detalladas.

  InterviewResultModel copyWith({
    String? id,
    String? sessionId,
    String? userId,
    DateTime? analyzedAt,
    int? score,
    double? successProbability,
    InterviewScoreBreakdownModel? breakdown,
    List<String>? recommendations,
  }) {
    return InterviewResultModel(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      userId: userId ?? this.userId,
      analyzedAt: analyzedAt ?? this.analyzedAt,
      score: score ?? this.score,
      successProbability: successProbability ?? this.successProbability,
      breakdown: breakdown ?? this.breakdown,
      recommendations: recommendations ?? this.recommendations,
    );
  }

  factory InterviewResultModel.fromJson(Map<String, dynamic> json) {
    final recommendations = (json['recommendations'] as List?)
            ?.whereType<String>()
            .toList() ??
        const <String>[];

    final successProbabilityRaw = json['successProbability'];
    final successProbability = switch (successProbabilityRaw) {
      double v => v,
      int v => v.toDouble(),
      String v => double.tryParse(v) ?? 0.0,
      _ => 0.0,
    };

    return InterviewResultModel(
      id: (json['id'] as String?) ?? '',
      sessionId: (json['sessionId'] as String?) ?? '',
      userId: (json['userId'] as String?) ?? '',
      analyzedAt: DateTime.tryParse((json['analyzedAt'] as String?) ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      score: (json['score'] as int?) ?? 0,
      successProbability: successProbability,
      breakdown: InterviewScoreBreakdownModel.fromJson(
        (json['breakdown'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      ),
      recommendations: recommendations,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sessionId': sessionId,
      'userId': userId,
      'analyzedAt': analyzedAt.toUtc().toIso8601String(),
      'score': score,
      'successProbability': successProbability,
      'breakdown': breakdown.toJson(),
      'recommendations': recommendations,
    };
  }

  @override
  String toString() {
    return 'InterviewResultModel(id: $id, sessionId: $sessionId, userId: $userId, score: $score, successProbability: $successProbability)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is InterviewResultModel &&
            runtimeType == other.runtimeType &&
            id == other.id &&
            sessionId == other.sessionId &&
            userId == other.userId &&
            analyzedAt == other.analyzedAt &&
            score == other.score &&
            successProbability == other.successProbability &&
            breakdown == other.breakdown &&
            _listEquals(recommendations, other.recommendations);
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      sessionId,
      userId,
      analyzedAt,
      score,
      successProbability,
      breakdown,
      Object.hashAll(recommendations),
    );
  }
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
