enum AppThemeMode {
  system,
  light,
  dark,
}

class AppSettingsModel {
  const AppSettingsModel({
    required this.themeMode,
  });

  final AppThemeMode themeMode;

  factory AppSettingsModel.defaults() {
    return const AppSettingsModel(
      themeMode: AppThemeMode.system,
    );
  }

  AppSettingsModel copyWith({
    AppThemeMode? themeMode,
  }) {
    return AppSettingsModel(
      themeMode: themeMode ?? this.themeMode,
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'themeMode': themeMode.name,
    };
  }

  @override
  String toString() {
    return 'AppSettingsModel(themeMode: ${themeMode.name})';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AppSettingsModel &&
            runtimeType == other.runtimeType &&
            themeMode == other.themeMode;
  }

  @override
  int get hashCode {
    return themeMode.hashCode;
  }
}
