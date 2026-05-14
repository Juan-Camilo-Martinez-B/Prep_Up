import 'package:prep_up/domain/entities/answer_evaluation_model.dart';
import 'package:prep_up/domain/entities/interview_feedback_model.dart';

class InterviewTurn {
  const InterviewTurn({
    required this.question,
    required this.answer,
    required this.evaluation,
    required this.feedback,
    required this.createdAt,
    required this.responseDurationSeconds,
  });

  final String question;
  final String answer;
  final AnswerEvaluationModel evaluation;
  final InterviewFeedbackModel feedback;
  final DateTime createdAt;
  final int responseDurationSeconds;

  InterviewTurn copyWith({
    String? question,
    String? answer,
    AnswerEvaluationModel? evaluation,
    InterviewFeedbackModel? feedback,
    DateTime? createdAt,
    int? responseDurationSeconds,
  }) {
    return InterviewTurn(
      question: question ?? this.question,
      answer: answer ?? this.answer,
      evaluation: evaluation ?? this.evaluation,
      feedback: feedback ?? this.feedback,
      createdAt: createdAt ?? this.createdAt,
      responseDurationSeconds:
          responseDurationSeconds ?? this.responseDurationSeconds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'answer': answer,
      'evaluation': evaluation.toJson(),
      'feedback': feedback.toJson(),
      'createdAt': createdAt.toUtc().toIso8601String(),
      'responseDurationSeconds': responseDurationSeconds,
    };
  }

  factory InterviewTurn.fromJson(Map<String, dynamic> json) {
    return InterviewTurn(
      question: (json['question'] as String?) ?? '',
      answer: (json['answer'] as String?) ?? '',
      evaluation: AnswerEvaluationModel.fromJson(
        (json['evaluation'] as Map?)?.cast<String, dynamic>() ?? {},
      ),
      feedback: InterviewFeedbackModel.fromJson(
        (json['feedback'] as Map?)?.cast<String, dynamic>() ?? {},
      ),
      createdAt: DateTime.tryParse((json['createdAt'] as String?) ?? '') ??
          DateTime.now(),
      responseDurationSeconds: (json['responseDurationSeconds'] as int?) ?? 0,
    );
  }
}

class InterviewSession {
  const InterviewSession({required this.startedAt, required this.turns});

  final DateTime startedAt;
  final List<InterviewTurn> turns;

  InterviewSession copyWith({DateTime? startedAt, List<InterviewTurn>? turns}) {
    return InterviewSession(
      startedAt: startedAt ?? this.startedAt,
      turns: turns ?? this.turns,
    );
  }

  bool get hasTurns => turns.isNotEmpty;

  Map<String, dynamic> toJson() {
    return {
      'startedAt': startedAt.toUtc().toIso8601String(),
      'turns': turns.map((t) => t.toJson()).toList(),
    };
  }

  factory InterviewSession.fromJson(Map<String, dynamic> json) {
    return InterviewSession(
      startedAt: DateTime.tryParse((json['startedAt'] as String?) ?? '') ??
          DateTime.now(),
      turns: (json['turns'] as List?)
              ?.map((t) => InterviewTurn.fromJson(t as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}

