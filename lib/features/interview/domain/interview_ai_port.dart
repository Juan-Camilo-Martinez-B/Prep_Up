import 'package:prep_up/l10n/app_localizations.dart';
import 'package:prep_up/shared/domain/entities/answer_evaluation_model.dart';
import 'package:prep_up/shared/domain/entities/interview_config.dart';
import 'package:prep_up/shared/domain/entities/interview_feedback_model.dart';
import 'package:prep_up/shared/domain/entities/interview_results_model.dart';
import 'package:prep_up/shared/domain/entities/interview_session.dart';
import 'package:prep_up/shared/domain/entities/interview_tags.dart';

/// Puerto de la entrevista con IA. La presentación depende de este contrato;
/// el adapter de Gemini vive en infrastructure.
abstract class InterviewAiPort {
  List<String> getRandomFocusAreas(AppLocalizations l10n, [int count = 5]);

  Future<String> sendPrompt({
    required String prompt,
    String? systemInstruction,
    double temperature = 0.7,
    int maxOutputTokens = 1024,
  });

  Future<List<String>> generateInterviewQuestions({
    required InterviewType type,
    required JobRole? role,
    required String jobRoleLabel,
    required int count,
    required AppLocalizations l10n,
    List<String>? selectedFocus,
  });

  Future<AnswerEvaluationModel> evaluateUserAnswer({
    required String question,
    required String userAnswer,
    required JobRole? role,
    required String jobRoleLabel,
    required AppLocalizations l10n,
    InterviewType type = InterviewType.mixed,
  });

  Future<InterviewFeedbackModel> generateFeedback({
    required String question,
    required String userAnswer,
    required AnswerEvaluationModel evaluation,
    required JobRole? role,
    required String jobRoleLabel,
    required AppLocalizations l10n,
  });

  Future<InterviewSession> analyzeInterviewSession({
    required InterviewConfig config,
    required InterviewSession session,
    required AppLocalizations l10n,
  });

  Future<String> generateNextQuestion({
    required JobRole? role,
    required String jobRoleLabel,
    required InterviewType type,
    required List<InterviewTurn> turns,
    required List<String> selectedFocus,
    required AppLocalizations l10n,
  });

  Future<String> generateClosingMessage({
    required JobRole? role,
    required String jobRoleLabel,
    required AppLocalizations l10n,
  });

  Future<String> generateOpeningQuestion({
    required JobRole? role,
    required String jobRoleLabel,
    required InterviewType type,
    required List<String> selectedFocus,
    required AppLocalizations l10n,
  });

  Future<String> generateConversationalNextQuestion({
    required JobRole? role,
    required String jobRoleLabel,
    required InterviewType type,
    required String lastQuestion,
    required String lastAnswer,
    required List<InterviewTurn> turns,
    required List<String> selectedFocus,
    required AppLocalizations l10n,
  });

  Future<InterviewResultsModel> generateInterviewResults({
    required InterviewConfig config,
    required InterviewSession session,
    required AppLocalizations l10n,
  });
}
