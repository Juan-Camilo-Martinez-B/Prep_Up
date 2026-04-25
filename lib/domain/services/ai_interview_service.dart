import 'package:prep_up/domain/entities/interview_results_model.dart';
import 'package:prep_up/domain/entities/interview_session_model.dart';

abstract class AiInterviewService {
  Future<List<String>> generateQuestions({
    required InterviewType type,
    required String jobRole,
    required int count,
  });

  Future<InterviewResultsModel> analyzeInterview({
    required InterviewSessionModel session,
    String? transcript,
    String? videoReference,
  });
}

class FakeAiInterviewService implements AiInterviewService {
  @override
  Future<List<String>> generateQuestions({
    required InterviewType type,
    required String jobRole,
    required int count,
  }) async {
    final header = switch (type) {
      InterviewType.behavioral => 'Conductual',
      InterviewType.technical => 'Técnica',
      InterviewType.mixed => 'Mixta',
    };

    final safeCount = count <= 0 ? 5 : count;
    return List.generate(
      safeCount,
      (index) => '[$header][$jobRole] Pregunta simulada #${index + 1}',
    );
  }

  @override
  Future<InterviewResultsModel> analyzeInterview({
    required InterviewSessionModel session,
    String? transcript,
    String? videoReference,
  }) async {
    final now = DateTime.now().toUtc();

    final score = switch (session.type) {
      InterviewType.behavioral => 78,
      InterviewType.technical => 72,
      InterviewType.mixed => 75,
    };

    final outcome = score >= 70 ? InterviewOutcome.approved : InterviewOutcome.improve;

    return InterviewResultsModel(
      id: 'result_${session.id}',
      sessionId: session.id,
      userId: session.userId,
      analyzedAt: now,
      overallScore: score,
      outcome: outcome,
      breakdown: const InterviewResultsBreakdownModel(
        communication: 74,
        technicalKnowledge: 70,
        confidence: 77,
      ),
      highlights: const ['Buena comunicación'],
      personalizedFeedback: 'El candidato mostró buenas habilidades comunicativas.',
      recommendations: const [
        'Mantén respuestas más estructuradas (situación, acción, resultado).',
        'Practica pausas cortas para mejorar claridad.',
        'Refuerza ejemplos con métricas y resultados concretos.',
      ],
      improvementTips: const ['Tip 1', 'Tip 2'],
    );
  }
}
