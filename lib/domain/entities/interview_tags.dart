enum InterviewConfigType {
  technical,
  rrhh,
  mixed,
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

enum InterviewMode {
  simulated,
  realtime,
}

extension InterviewModeLabel on InterviewMode {
  String get label {
    return switch (this) {
      InterviewMode.simulated => 'Simulada',
      InterviewMode.realtime => 'Tiempo real',
    };
  }
}

enum JobRole {
  frontendDeveloper('Frontend Developer'),
  backendDeveloper('Backend Developer'),
  mobileDeveloper('Mobile Developer'),
  uiUxDesigner('UI/UX Designer'),
  dataAnalyst('Data Analyst'),
  dataScientist('Data Scientist'),
  qaTester('QA Tester'),
  devOps('DevOps'),
  productManager('Product Manager');

  const JobRole(this.label);
  final String label;
}
