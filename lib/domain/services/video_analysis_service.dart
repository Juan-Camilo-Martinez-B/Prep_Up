abstract class VideoAnalysisService {
  Future<Map<String, double>> analyzeBodyLanguage({
    required String videoReference,
  });

  // TODO: enviar video a servicio de análisis gestual / lenguaje corporal.
}

class FakeVideoAnalysisService implements VideoAnalysisService {
  @override
  Future<Map<String, double>> analyzeBodyLanguage({
    required String videoReference,
  }) async {
    return const {
      'bodyLanguage': 0.74,
      'eyeContact': 0.68,
      'posture': 0.71,
      'gestures': 0.63,
    };
  }
}
