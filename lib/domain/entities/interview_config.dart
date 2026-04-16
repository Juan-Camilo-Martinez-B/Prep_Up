enum InterviewConfigType {
  technical,
  rrhh,
  mixed,
}

enum InterviewMode {
  simulated,
  realtime,
}

class InterviewConfig {
  const InterviewConfig({
    this.type,
    this.jobRole = '',
    this.durationMinutes,
    this.mode,
  });

  final InterviewConfigType? type;
  final String jobRole;
  final int? durationMinutes;
  final InterviewMode? mode;

  bool get isComplete =>
      type != null &&
      jobRole.trim().isNotEmpty &&
      durationMinutes != null &&
      durationMinutes! > 0 &&
      mode != null;

  List<String> get missingFields {
    final fields = <String>[];
    if (type == null) fields.add('tipo de entrevista');
    if (jobRole.trim().isEmpty) fields.add('cargo');
    if (durationMinutes == null || durationMinutes! <= 0) {
      fields.add('duración');
    }
    if (mode == null) fields.add('modalidad');
    return fields;
  }

  InterviewConfig copyWith({
    InterviewConfigType? type,
    String? jobRole,
    int? durationMinutes,
    InterviewMode? mode,
    bool clearType = false,
    bool clearDuration = false,
    bool clearMode = false,
  }) {
    return InterviewConfig(
      type: clearType ? null : (type ?? this.type),
      jobRole: jobRole ?? this.jobRole,
      durationMinutes:
          clearDuration ? null : (durationMinutes ?? this.durationMinutes),
      mode: clearMode ? null : (mode ?? this.mode),
    );
  }
}

extension InterviewConfigTypeLabel on InterviewConfigType {
  String get label {
    return switch (this) {
      InterviewConfigType.technical => 'Técnica',
      InterviewConfigType.rrhh => 'RRHH',
      InterviewConfigType.mixed => 'Mixta',
    };
  }
}

extension InterviewModeLabel on InterviewMode {
  String get label {
    return switch (this) {
      InterviewMode.simulated => 'Simulada',
      InterviewMode.realtime => 'Tiempo real',
    };
  }
}

