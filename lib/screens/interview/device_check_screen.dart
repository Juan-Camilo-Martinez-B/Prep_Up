import 'package:flutter/material.dart';
import 'package:prep_up/navigation/app_routes.dart';
import 'package:prep_up/widgets/app_card.dart';
import 'package:prep_up/widgets/app_primary_button.dart';
import 'package:prep_up/widgets/app_screen_scaffold.dart';

class DeviceCheckScreen extends StatefulWidget {
  const DeviceCheckScreen({super.key});

  @override
  State<DeviceCheckScreen> createState() => _DeviceCheckScreenState();
}

class _DeviceCheckScreenState extends State<DeviceCheckScreen> {
  var _cameraOk = true;
  var _micOk = true;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppScreenScaffold(
      title: 'Preparación',
      background: const TechBackground(),
      body: ListView(
        children: [
          AppCard(
            title: 'Checklist de equipo',
            subtitle: 'Cámara y micrófono (placeholders)',
            leading: Icon(Icons.checklist_rounded, color: scheme.primary),
            child: Column(
              children: [
                _CheckTile(
                  icon: Icons.videocam_rounded,
                  title: 'Cámara',
                  value: _cameraOk,
                  onChanged: (v) => setState(() => _cameraOk = v),
                ),
                const SizedBox(height: 10),
                _CheckTile(
                  icon: Icons.mic_rounded,
                  title: 'Micrófono',
                  value: _micOk,
                  onChanged: (v) => setState(() => _micOk = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AppCard(
            title: 'Vista previa',
            subtitle: 'Tu cámara (simulada)',
            leading: Icon(Icons.camera_alt_outlined, color: scheme.secondary),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    colors: [
                      scheme.primary.withValues(alpha: 0.22),
                      scheme.secondary.withValues(alpha: 0.18),
                    ],
                  ),
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.55),
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.videocam_outlined,
                    size: 42,
                    color: scheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          AppPrimaryButton(
            label: 'Iniciar simulación',
            icon: Icons.play_arrow_rounded,
            onPressed: (_cameraOk && _micOk)
                ? () {
                    // TODO: validar permisos de cámara/micrófono y configurar captura.
                    Navigator.of(context).pushNamed(AppRoutes.simulatedCall);
                  }
                : null,
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('Atrás'),
          ),
        ],
      ),
    );
  }
}

class _CheckTile extends StatelessWidget {
  const _CheckTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, color: value ? scheme.primary : scheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(child: Text(title)),
          Switch.adaptive(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
