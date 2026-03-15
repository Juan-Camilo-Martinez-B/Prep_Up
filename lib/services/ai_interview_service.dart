import 'package:prep_up/models/interview_result_model.dart';
import 'package:prep_up/models/interview_session_model.dart';

abstract class AiInterviewService {
  Future<List<String>> generateQuestions({
    required InterviewType type,
    required String jobRole,
    required int count,
  });

  Future<InterviewResultModel> analyzeInterview({
    required InterviewSessionModel session,
    String? transcript,
    String? videoReference,
  });

  // TODO: conectar con servicio de IA para generar preguntas de entrevista.
  // TODO: conectar con servicio de IA para analizar entrevista y producir resultados.
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
  Future<InterviewResultModel> analyzeInterview({
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

    final probability = switch (session.type) {
      InterviewType.behavioral => 0.76,
      InterviewType.technical => 0.69,
      InterviewType.mixed => 0.72,
    };

    return InterviewResultModel(
      id: 'result_${session.id}',
      sessionId: session.id,
      userId: session.userId,
      analyzedAt: now,
      score: score,
      successProbability: probability,
      breakdown: const InterviewScoreBreakdownModel(
        bodyLanguage: 74,
        clarity: 70,
        confidence: 77,
      ),
      recommendations: const [
        'Mantén respuestas más estructuradas (situación, acción, resultado).',
        'Practica pausas cortas para mejorar claridad.',
        'Refuerza ejemplos con métricas y resultados concretos.',
      ],
    );
  }
}
