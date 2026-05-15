import 'package:flutter/material.dart';
import 'package:prep_up/core/errors/user_friendly_error.dart';
import 'package:prep_up/core/localization/app_locale.dart';
import 'package:prep_up/core/localization/l10n_extensions.dart';
import 'package:prep_up/core/navigation/app_routes.dart';
import 'package:prep_up/domain/entities/app_settings_model.dart';
import 'package:prep_up/domain/services/auth_service.dart';
import 'package:prep_up/domain/services/relational_database_service.dart';
import 'package:prep_up/domain/services/supabase_database_service.dart';
import 'package:prep_up/presentation/widgets/app_card.dart';
import 'package:prep_up/presentation/widgets/app_screen_scaffold.dart';
import 'package:prep_up/theme/app_theme.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final RelationalDatabaseService _dbService = SupabaseDatabaseService();
  final AuthService _authService = AuthService();

  AppSettingsModel? _settings;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final l10n = context.l10n;
    final user = _authService.currentUser;
    if (user != null) {
      try {
        final settings = await _dbService.getSettingsForUser(user.id);
        if (!mounted) return;
        setState(() {
          _settings = settings ?? AppSettingsModel.defaults();
          _isLoading = false;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _settings = AppSettingsModel.defaults();
          _isLoading = false;
        });
        final message = userFriendlyErrorMessage(e, l10n);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateSettings(AppSettingsModel newSettings) async {
    final l10n = context.l10n;
    final previous = _settings;
    setState(() => _settings = newSettings);
    final user = _authService.currentUser;
    if (user != null) {
      try {
        await _dbService.saveSettingsForUser(user.id, newSettings);
      } catch (e) {
        if (!mounted) return;
        setState(() => _settings = previous);
        final message = userFriendlyErrorMessage(e, l10n);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final themeController = AppThemeScope.of(context);
    final themeMode = themeController.themeMode;
    final localeController = AppLocaleScope.of(context);
    final locale = localeController.locale.languageCode;

    if (_isLoading) {
      return AppScreenScaffold(
        title: l10n.settingsTitle,
        centerTitle: true,
        background: const TechBackground(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return AppScreenScaffold(
      title: l10n.settingsTitle,
      centerTitle: true,
      background: const TechBackground(),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 60),
        children: [
          // Header del perfil creativo
          Center(
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [scheme.primary, scheme.secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: scheme.primary.withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).scaffoldBackgroundColor,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.person_rounded,
                          size: 50,
                          color: scheme.primary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.myProfile,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    l10n.freeAccount,
                    style: TextStyle(
                      color: scheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          Text(
            l10n.personalization,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.color_lens_rounded,
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        l10n.visualTheme,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SegmentedButton<AppThemeMode>(
                  style: SegmentedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  segments: [
                    ButtonSegment(
                      value: AppThemeMode.system,
                      label: Text(
                        l10n.themeSystem,
                        style: const TextStyle(fontSize: 12),
                      ),
                      icon: const Icon(Icons.phone_android_rounded, size: 16),
                    ),
                    ButtonSegment(
                      value: AppThemeMode.light,
                      label: Text(
                        l10n.themeLight,
                        style: const TextStyle(fontSize: 12),
                      ),
                      icon: const Icon(Icons.light_mode_rounded, size: 16),
                    ),
                    ButtonSegment(
                      value: AppThemeMode.dark,
                      label: Text(
                        l10n.themeDark,
                        style: const TextStyle(fontSize: 12),
                      ),
                      icon: const Icon(Icons.dark_mode_rounded, size: 16),
                    ),
                  ],
                  selected: {themeMode},
                  onSelectionChanged: (selection) async {
                    final newMode = selection.first;
                    themeController.setThemeMode(newMode);
                    if (_settings != null) {
                      await _updateSettings(
                        _settings!.copyWith(themeMode: newMode),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.language_rounded,
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        l10n.language,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SegmentedButton<String>(
                  style: SegmentedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  segments: [
                    ButtonSegment(
                      value: 'es',
                      label: Text(
                        l10n.languageOptionSpanish,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                    ButtonSegment(
                      value: 'en',
                      label: Text(
                        l10n.languageOptionEnglish,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ],
                  selected: {locale},
                  onSelectionChanged: (selection) {
                    final next = selection.first;
                    localeController.setLocale(Locale(next));
                    // Language is usually stored in local preferences or we can add it to settings if we want
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                SwitchListTile(
                  value: _settings?.enableHaptics ?? true,
                  onChanged: (v) {
                    if (_settings != null) {
                      _updateSettings(_settings!.copyWith(enableHaptics: v));
                    }
                  },
                  title: Text(l10n.hapticFeedback),
                  subtitle: Text(
                    l10n.hapticSubtitle,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: scheme.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.vibration_rounded,
                      color: scheme.secondary,
                    ),
                  ),
                  activeThumbColor: scheme.primary,
                ),
                const Divider(height: 1, indent: 64),
                SwitchListTile(
                  value: _settings?.enableNotifications ?? true,
                  onChanged: (v) {
                    if (_settings != null) {
                      _updateSettings(
                        _settings!.copyWith(enableNotifications: v),
                      );
                    }
                  },
                  title: Text(l10n.pushNotifications),
                  subtitle: Text(
                    l10n.pushNotificationsSubtitle,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orangeAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.notifications_active_rounded,
                      color: Colors.orangeAccent,
                    ),
                  ),
                  activeThumbColor: scheme.primary,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          Text(
            l10n.privacyAndAnalytics,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: scheme.tertiary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.video_camera_front_rounded,
                      color: scheme.tertiary,
                    ),
                  ),
                  title: Text(l10n.myRecordingsBeta),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {},
                ),
                const Divider(height: 1, indent: 64),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.pinkAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.face_retouching_natural_rounded,
                      color: Colors.pinkAccent,
                    ),
                  ),
                  title: Text(l10n.expertFacialAnalysis),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.onSurface.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      l10n.comingSoon,
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                  onTap: () {},
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
          AppCard(
            padding: EdgeInsets.zero,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () async {
                final auth = context.read<AuthService>();
                final navigator = Navigator.of(context);
                await auth.signOut();
                if (!mounted) return;
                navigator.pushNamedAndRemoveUntil(
                  AppRoutes.login,
                  (r) => false,
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.logout_rounded, color: Colors.redAccent),
                    const SizedBox(width: 8),
                    Text(
                      l10n.signOutButton,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
