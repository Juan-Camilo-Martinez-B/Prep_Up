import 'package:prep_up/domain/entities/answer_evaluation_model.dart';
import 'package:prep_up/domain/entities/interview_feedback_model.dart';

class InterviewTurn {
  const InterviewTurn({
    required this.question,
    required this.answer,
    required this.evaluation,
    required this.feedback,
    required this.createdAt,
  });

  final String question;
  final String answer;
  final AnswerEvaluationModel evaluation;
  final InterviewFeedbackModel feedback;
  final DateTime createdAt;

  InterviewTurn copyWith({
    String? question,
    String? answer,
    AnswerEvaluationModel? evaluation,
    InterviewFeedbackModel? feedback,
    DateTime? createdAt,
  }) {
    return InterviewTurn(
      question: question ?? this.question,
      answer: answer ?? this.answer,
      evaluation: evaluation ?? this.evaluation,
      feedback: feedback ?? this.feedback,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class InterviewSession {
  const InterviewSession({
    required this.startedAt,
    required this.turns,
  });

  final DateTime startedAt;
  final List<InterviewTurn> turns;

  InterviewSession copyWith({
    DateTime? startedAt,
    List<InterviewTurn>? turns,
  }) {
    return InterviewSession(
      startedAt: startedAt ?? this.startedAt,
      turns: turns ?? this.turns,
    );
  }

  bool get hasTurns => turns.isNotEmpty;
}

