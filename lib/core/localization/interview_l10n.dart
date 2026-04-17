import 'package:prep_up/domain/entities/interview_config.dart';
import 'package:prep_up/domain/entities/interview_tags.dart';
import 'package:prep_up/l10n/app_localizations.dart';

extension InterviewConfigTypeL10n on InterviewConfigType {
  String label(AppLocalizations l10n) {
    return switch (this) {
      InterviewConfigType.technical => l10n.interviewTypeTechnical,
      InterviewConfigType.rrhh => l10n.interviewTypeBehavioral,
      InterviewConfigType.mixed => l10n.interviewTypeMixed,
    };
  }
}

extension InterviewModeL10n on InterviewMode {
  String label(AppLocalizations l10n) {
    return switch (this) {
      InterviewMode.simulated => l10n.interviewModeSimulated,
      InterviewMode.realtime => l10n.interviewModeRealtime,
    };
  }
}

extension JobRoleL10n on JobRole {
  String label(AppLocalizations l10n) {
    return switch (this) {
      JobRole.frontendDeveloper => l10n.jobRoleFrontendDeveloper,
      JobRole.backendDeveloper => l10n.jobRoleBackendDeveloper,
      JobRole.mobileDeveloper => l10n.jobRoleMobileDeveloper,
      JobRole.uiUxDesigner => l10n.jobRoleUiUxDesigner,
      JobRole.dataAnalyst => l10n.jobRoleDataAnalyst,
      JobRole.dataScientist => l10n.jobRoleDataScientist,
      JobRole.qaTester => l10n.jobRoleQaTester,
      JobRole.devOps => l10n.jobRoleDevOps,
      JobRole.productManager => l10n.jobRoleProductManager,
    };
  }
}

extension InterviewConfigMissingFieldL10n on InterviewConfigField {
  String label(AppLocalizations l10n) {
    return switch (this) {
      InterviewConfigField.type => l10n.interviewMissingFieldType,
      InterviewConfigField.jobRole => l10n.interviewMissingFieldJobRole,
      InterviewConfigField.duration => l10n.interviewMissingFieldDuration,
      InterviewConfigField.mode => l10n.interviewMissingFieldMode,
    };
  }
}

