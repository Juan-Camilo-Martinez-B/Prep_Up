import 'dart:convert';

import 'package:prep_up/domain/entities/interview_results_model.dart';
import 'package:prep_up/domain/entities/interview_session_model.dart';
import 'package:prep_up/domain/services/ai_interview_service.dart';
import 'package:prep_up/domain/services/gemini_service.dart';

class GeminiAiInterviewService implements AiInterviewService {
  GeminiAiInterviewService({GeminiService? geminiService})
      : _geminiService = geminiService ?? GeminiService();

  final GeminiService _geminiService;

  @override
  Future<List<String>> generateQuestions({
    required InterviewType type,
    required String jobRole,
    required int count,
  }) {
    return _geminiService.generateInterviewQuestions(
      type: type,
      jobRole: jobRole,
      count: count,
    );
  }

  @override
  Future<InterviewResultsModel> analyzeInterview({
    required InterviewSessionModel session,
    String? transcript,
    String? videoReference,
  }) async {
    final safeTranscript = (transcript ?? '').trim();
    if (safeTranscript.isEmpty) {
      throw const GeminiException(
        'No hay transcript disponible para analizar la entrevista.',
      );
    }

    final systemInstruction =
        'Eres un evaluador experto de entrevistas. Respondes en español. '
        'Devuelve JSON válido sin texto adicional.';

    final prompt = '''
Analiza el transcript de una entrevista simulada y genera un resultado cuantitativo.
Rol: "${session.jobRole}"
Tipo: "${session.type.name}"
Transcript:
"""$safeTranscript"""

Devuelve SOLO JSON con este esquema exacto:
{
  "overallScore": 0,
  "outcome": "approved",
  "breakdown": { "communication": 0, "technicalKnowledge": 0, "confidence": 0 },
  "highlights": ["..."],
  "personalizedFeedback": "...",
  "recommendations": ["..."],
  "improvementTips": ["..."]
}

Reglas:
- overallScore 0..100
- outcome: "approved" o "improve"
- breakdown: enteros 0..100
- recommendations: 3..6 recomendaciones accionables
- Sin markdown
''';

    final raw = await _geminiService.sendPrompt(
      prompt: prompt,
      systemInstruction: systemInstruction,
      temperature: 0.3,
      maxOutputTokens: 1400,
    );

    final decoded = _tryDecodeJsonMap(_extractJsonText(raw)) ??
        <String, dynamic>{'recommendations': <String>[]};

    final now = DateTime.now().toUtc();
    final id = 'result_${session.id}';
    final score = _toInt(decoded['overallScore']).clamp(0, 100).toInt();
    final outcomeRaw = (decoded['outcome'] as String?) ?? '';
    final outcome = switch (outcomeRaw.trim().toLowerCase()) {
      'approved' || 'aprobado' => InterviewOutcome.approved,
      'improve' || 'mejorar' => InterviewOutcome.improve,
      _ => score >= 70 ? InterviewOutcome.approved : InterviewOutcome.improve,
    };

    return InterviewResultsModel(
      id: id,
      sessionId: session.id,
      userId: session.userId,
      analyzedAt: now,
      overallScore: score,
      outcome: outcome,
      breakdown: InterviewResultsBreakdownModel.fromJson(
        (decoded['breakdown'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      ),
      highlights: ((decoded['highlights'] as List?)
              ?.whereType<String>()
              .toList() ??
          const <String>[]),
      personalizedFeedback: (decoded['personalizedFeedback'] as String?) ?? '',
      recommendations: ((decoded['recommendations'] as List?)
              ?.whereType<String>()
              .toList() ??
          const <String>[]),
      improvementTips: ((decoded['improvementTips'] as List?)
              ?.whereType<String>()
              .toList() ??
          const <String>[]),
    );
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

Map<String, dynamic>? _tryDecodeJsonMap(String text) {
  try {
    final decoded = jsonDecode(text);
    if (decoded is Map<String, dynamic>) return decoded;
  } catch (_) {}
  return null;
}

String _extractJsonText(String raw) {
  final trimmed = raw.trim();
  final fenceStart = trimmed.indexOf('```');
  if (fenceStart == -1) return trimmed;
  final fenceEnd = trimmed.lastIndexOf('```');
  if (fenceEnd == -1 || fenceEnd <= fenceStart) return trimmed;
  final inside = trimmed.substring(fenceStart + 3, fenceEnd).trim();
  final firstNewline = inside.indexOf('\n');
  if (firstNewline == -1) return inside.trim();
  final firstLine = inside.substring(0, firstNewline).trim().toLowerCase();
  final rest = inside.substring(firstNewline + 1).trim();
  if (firstLine == 'json') return rest;
  return inside.trim();
}
