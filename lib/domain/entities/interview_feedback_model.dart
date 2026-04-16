class InterviewFeedbackModel {
  const InterviewFeedbackModel({
    required this.summary,
    required this.actionItems,
    required this.keyPhrasesToUse,
  });

  final String summary;
  final List<String> actionItems;
  final List<String> keyPhrasesToUse;

  factory InterviewFeedbackModel.fromJson(Map<String, dynamic> json) {
    final actionItems =
        (json['actionItems'] as List?)?.whereType<String>().toList() ??
            const <String>[];
    final keyPhrasesToUse =
        (json['keyPhrasesToUse'] as List?)?.whereType<String>().toList() ??
            const <String>[];

    return InterviewFeedbackModel(
      summary: (json['summary'] as String?) ?? '',
      actionItems: actionItems,
      keyPhrasesToUse: keyPhrasesToUse,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'summary': summary,
      'actionItems': actionItems,
      'keyPhrasesToUse': keyPhrasesToUse,
    };
  }

  @override
  String toString() {
    return 'InterviewFeedbackModel(summary: $summary, actionItems: ${actionItems.length})';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is InterviewFeedbackModel &&
            runtimeType == other.runtimeType &&
            summary == other.summary &&
            _listEquals(actionItems, other.actionItems) &&
            _listEquals(keyPhrasesToUse, other.keyPhrasesToUse);
  }

  @override
  int get hashCode {
    return Object.hash(
      summary,
      Object.hashAll(actionItems),
      Object.hashAll(keyPhrasesToUse),
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

