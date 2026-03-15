import 'package:flutter/material.dart';
import 'package:prep_up/models/app_settings_model.dart';
import 'package:prep_up/navigation/app_theme.dart';
import 'package:prep_up/navigation/app_routes.dart';
import 'package:prep_up/widgets/app_card.dart';
import 'package:prep_up/widgets/app_primary_button.dart';
import 'package:prep_up/widgets/app_screen_scaffold.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  var _haptics = true;
  var _notifications = true;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final themeController = AppThemeScope.of(context);
    final themeMode = themeController.themeMode;

    return AppScreenScaffold(
      title: 'Configuración',
      background: const TechBackground(),
      body: ListView(
        children: [
          AppCard(
            title: 'Estilo',
            subtitle: 'Personaliza tu experiencia',
            leading: Icon(Icons.palette_outlined, color: scheme.primary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SegmentedButton<AppThemeMode>(
                  segments: const [
                    ButtonSegment(
                      value: AppThemeMode.system,
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('Sistema'),
                      ),
                      icon: Icon(Icons.phone_android_rounded),
                    ),
                    ButtonSegment(
                      value: AppThemeMode.light,
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('Claro'),
                      ),
                      icon: Icon(Icons.light_mode_rounded),
                    ),
                    ButtonSegment(
                      value: AppThemeMode.dark,
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('Oscuro'),
                      ),
                      icon: Icon(Icons.dark_mode_rounded),
                    ),
                  ],
                  selected: {themeMode},
                  onSelectionChanged: (selection) {
                    themeController.setThemeMode(selection.first);
                  },
                ),
                const SizedBox(height: 14),
                SwitchListTile.adaptive(
                  value: _haptics,
                  onChanged: (v) {
                    setState(() => _haptics = v);
                    // TODO: persistir settings en base de datos relacional.
                  },
                  title: const Text('Haptics'),
                  subtitle: const Text('Feedback sutil al interactuar'),
                  secondary: const Icon(Icons.vibration_rounded),
                  contentPadding: EdgeInsets.zero,
                ),
                SwitchListTile.adaptive(
                  value: _notifications,
                  onChanged: (v) {
                    setState(() => _notifications = v);
                    // TODO: persistir settings en base de datos relacional.
                  },
                  title: const Text('Notificaciones'),
                  subtitle: const Text('Recordatorios de práctica'),
                  secondary: const Icon(Icons.notifications_active_rounded),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AppCard(
            title: 'Privacidad',
            subtitle: 'Videos y análisis',
            leading: Icon(Icons.security_rounded, color: scheme.secondary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.video_camera_back_rounded,
                    color: scheme.secondary,
                  ),
                  title: const Text('Almacenamiento de videos'),
                  subtitle: const Text('Pendiente de integración'),
                  trailing: Icon(
                    Icons.hourglass_top_rounded,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.face_retouching_natural_rounded,
                    color: scheme.secondary,
                  ),
                  title: const Text('Análisis gestual'),
                  subtitle: const Text('Pendiente de integración'),
                  trailing: Icon(
                    Icons.hourglass_top_rounded,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AppPrimaryButton(
            label: 'Volver al Dashboard',
            icon: Icons.home_rounded,
            onPressed: () => Navigator.of(
              context,
            ).pushNamedAndRemoveUntil(AppRoutes.dashboard, (route) => false),
          ),
        ],
      ),
    );
  }
}
