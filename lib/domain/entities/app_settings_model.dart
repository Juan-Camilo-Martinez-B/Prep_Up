enum AppThemeMode {
  system,
  light,
  dark,
}

class AppSettingsModel {
  const AppSettingsModel({
    required this.themeMode,
    required this.enableHaptics,
    required this.enableNotifications,
  });

  final AppThemeMode themeMode;
  final bool enableHaptics;
  final bool enableNotifications;

  factory AppSettingsModel.defaults() {
    return const AppSettingsModel(
      themeMode: AppThemeMode.system,
      enableHaptics: true,
      enableNotifications: true,
    );
  }

  AppSettingsModel copyWith({
    AppThemeMode? themeMode,
    bool? enableHaptics,
    bool? enableNotifications,
  }) {
    return AppSettingsModel(
      themeMode: themeMode ?? this.themeMode,
      enableHaptics: enableHaptics ?? this.enableHaptics,
      enableNotifications: enableNotifications ?? this.enableNotifications,
    );
  }

  factory AppSettingsModel.fromJson(Map<String, dynamic> json) {
    final themeRaw = (json['themeMode'] as String?) ?? 'system';
    final themeMode = AppThemeMode.values.firstWhere(
      (e) => e.name == themeRaw,
      orElse: () => AppThemeMode.system,
    );

    return AppSettingsModel(
      themeMode: themeMode,
      enableHaptics: (json['enableHaptics'] as bool?) ?? true,
      enableNotifications: (json['enableNotifications'] as bool?) ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'themeMode': themeMode.name,
      'enableHaptics': enableHaptics,
      'enableNotifications': enableNotifications,
    };
  }

  @override
  String toString() {
    return 'AppSettingsModel(themeMode: ${themeMode.name}, enableHaptics: $enableHaptics, enableNotifications: $enableNotifications)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AppSettingsModel &&
            runtimeType == other.runtimeType &&
            themeMode == other.themeMode &&
            enableHaptics == other.enableHaptics &&
            enableNotifications == other.enableNotifications;
  }

  @override
  int get hashCode {
    return Object.hash(themeMode, enableHaptics, enableNotifications);
  }
}
