import 'package:flutter/foundation.dart';
import 'package:prep_up/domain/entities/interview_config.dart';
import 'package:prep_up/domain/entities/interview_tags.dart';

class InterviewConfigController extends ChangeNotifier {
  InterviewConfig _config = const InterviewConfig();

  InterviewConfig get config => _config;

  bool get isComplete => _config.isComplete;

  void reset() {
    _config = const InterviewConfig();
    notifyListeners();
  }

  void setType(InterviewType value) {
    _config = _config.copyWith(type: value);
    notifyListeners();
  }

  void setJobRole(JobRole value) {
    _config = _config.copyWith(jobRole: value);
    notifyListeners();
  }

  void setDurationMinutes(int value) {
    _config = _config.copyWith(durationMinutes: value);
    notifyListeners();
  }
}

