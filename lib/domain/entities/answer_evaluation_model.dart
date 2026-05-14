class AnswerEvaluationModel {
  static const empty = AnswerEvaluationModel(
    overallScore: 0,
    subjectMastery: 0,
    strengths: <String>[],
    improvements: <String>[],
    suggestedAnswer: '',
    followUpQuestions: <String>[],
  );

  const AnswerEvaluationModel({
    required this.overallScore,
    required this.subjectMastery,
    required this.strengths,
    required this.improvements,
    required this.suggestedAnswer,
    required this.followUpQuestions,
  });

  final int overallScore;
  final int subjectMastery;
  final List<String> strengths;
  final List<String> improvements;
  final String suggestedAnswer;
  final List<String> followUpQuestions;

  factory AnswerEvaluationModel.fromJson(Map<String, dynamic> json) {
    final strengths =
        (json['strengths'] as List?)?.whereType<String>().toList() ??
            const <String>[];
    final improvements =
        (json['improvements'] as List?)?.whereType<String>().toList() ??
            const <String>[];
    final followUpQuestions =
        (json['followUpQuestions'] as List?)?.whereType<String>().toList() ??
            const <String>[];

    final overallScoreRaw = json['overallScore'];
    final overallScore = switch (overallScoreRaw) {
      int v => v,
      double v => v.round(),
      String v => int.tryParse(v) ?? 0,
      _ => 0,
    };

    final subjectMasteryRaw = json['subjectMastery'] ?? json['technicalKnowledge'] ?? 0;
    final subjectMastery = switch (subjectMasteryRaw) {
      int v => v,
      double v => v.round(),
      String v => int.tryParse(v) ?? 0,
      _ => 0,
    };

    return AnswerEvaluationModel(
      overallScore: overallScore.clamp(0, 100).toInt(),
      subjectMastery: subjectMastery.clamp(0, 100).toInt(),
      strengths: strengths,
      improvements: improvements,
      suggestedAnswer: (json['suggestedAnswer'] as String?) ?? '',
      followUpQuestions: followUpQuestions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'overallScore': overallScore,
      'subjectMastery': subjectMastery,
      'strengths': strengths,
      'improvements': improvements,
      'suggestedAnswer': suggestedAnswer,
      'followUpQuestions': followUpQuestions,
    };
  }

  @override
  String toString() {
    return 'AnswerEvaluationModel(overallScore: $overallScore, strengths: ${strengths.length}, improvements: ${improvements.length})';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AnswerEvaluationModel &&
            runtimeType == other.runtimeType &&
            overallScore == other.overallScore &&
            _listEquals(strengths, other.strengths) &&
            _listEquals(improvements, other.improvements) &&
            suggestedAnswer == other.suggestedAnswer &&
            _listEquals(followUpQuestions, other.followUpQuestions);
  }

  @override
  int get hashCode {
    return Object.hash(
      overallScore,
      Object.hashAll(strengths),
      Object.hashAll(improvements),
      suggestedAnswer,
      Object.hashAll(followUpQuestions),
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
