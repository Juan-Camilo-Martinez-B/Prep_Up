import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:prep_up/core/localization/app_locale.dart';
import 'package:prep_up/domain/entities/interview_results_model.dart';
import 'package:prep_up/domain/entities/interview_session_model.dart';
import 'package:prep_up/domain/entities/interview_tags.dart';
import 'package:prep_up/domain/services/ai_interview_service.dart';
import 'package:prep_up/domain/services/gemini_service.dart';
import 'package:prep_up/l10n/app_localizations.dart';

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
    final l10n = lookupAppLocalizations(AppLocaleRuntime.locale);
    return _geminiService.generateInterviewQuestions(
      type: type,
      jobRole: jobRole,
      count: count,
      l10n: l10n,
    );
  }

  @override
  Future<InterviewResultsModel> analyzeInterview({
    required InterviewSessionModel session,
    String? transcript,
    String? videoReference,
  }) async {
    // This method is deprecated in favor of GeminiService.generateInterviewResults
    // used directly in controllers.
    throw UnimplementedError(
      'GeminiAiInterviewService.analyzeInterview is deprecated. Use GeminiService directly.',
    );
  }
}
