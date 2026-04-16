import 'package:flutter/foundation.dart';
import 'package:prep_up/domain/entities/interview_config.dart';

class InterviewConfigController extends ChangeNotifier {
  InterviewConfig _config = const InterviewConfig();

  InterviewConfig get config => _config;

  bool get isComplete => _config.isComplete;

  void reset() {
    _config = const InterviewConfig();
    notifyListeners();
  }

  void setType(InterviewConfigType value) {
    _config = _config.copyWith(type: value);
    notifyListeners();
  }

  void setJobRole(String value) {
    _config = _config.copyWith(jobRole: value.trim());
    notifyListeners();
  }

  void setDurationMinutes(int value) {
    _config = _config.copyWith(durationMinutes: value);
    notifyListeners();
  }

  void setMode(InterviewMode value) {
    _config = _config.copyWith(mode: value);
    notifyListeners();
  }
}

