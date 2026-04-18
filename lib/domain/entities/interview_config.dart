import 'package:prep_up/domain/entities/interview_tags.dart';

enum InterviewConfigField { type, jobRole, duration, mode }

class InterviewConfig {
  const InterviewConfig({
    this.type,
    this.jobRole,
    this.durationMinutes,
    this.mode,
  });

  final InterviewConfigType? type;
  final JobRole? jobRole;
  final int? durationMinutes;
  final InterviewMode? mode;

  bool get isComplete =>
      type != null &&
      jobRole != null &&
      durationMinutes != null &&
      durationMinutes! > 0;

  List<InterviewConfigField> get missingFields {
    final fields = <InterviewConfigField>[];
    if (type == null) fields.add(InterviewConfigField.type);
    if (jobRole == null) fields.add(InterviewConfigField.jobRole);
    if (durationMinutes == null || durationMinutes! <= 0) {
      fields.add(InterviewConfigField.duration);
    }
    return fields;
  }

  InterviewConfig copyWith({
    InterviewConfigType? type,
    JobRole? jobRole,
    int? durationMinutes,
    InterviewMode? mode,
    bool clearType = false,
    bool clearDuration = false,
    bool clearMode = false,
    bool clearJobRole = false,
  }) {
    return InterviewConfig(
      type: clearType ? null : (type ?? this.type),
      jobRole: clearJobRole ? null : (jobRole ?? this.jobRole),
      durationMinutes: clearDuration
          ? null
          : (durationMinutes ?? this.durationMinutes),
      mode: clearMode ? null : (mode ?? this.mode),
    );
  }
}
