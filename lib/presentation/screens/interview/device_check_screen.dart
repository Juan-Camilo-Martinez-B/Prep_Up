import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:prep_up/core/localization/interview_l10n.dart';
import 'package:prep_up/core/localization/l10n_extensions.dart';
import 'package:prep_up/core/navigation/app_routes.dart';
import 'package:prep_up/presentation/controllers/interview_config_controller.dart';
import 'package:prep_up/presentation/controllers/media_device_controller.dart';
import 'package:prep_up/presentation/widgets/app_card.dart';
import 'package:prep_up/presentation/widgets/app_primary_button.dart';
import 'package:prep_up/presentation/widgets/app_screen_scaffold.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class DeviceCheckScreen extends StatefulWidget {
  const DeviceCheckScreen({super.key});

  @override
  State<DeviceCheckScreen> createState() => _DeviceCheckScreenState();
}

class _DeviceCheckScreenState extends State<DeviceCheckScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MediaDeviceController>().start();
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final interviewController = context.watch<InterviewConfigController>();
    final media = context.watch<MediaDeviceController>();

    return AppScreenScaffold(
      title: l10n.deviceCheckTitle,
      background: const TechBackground(),
      body: ListView(
        children: [
          AppCard(
            title: l10n.deviceCheckChecklistTitle,
            subtitle: l10n.deviceCheckChecklistSubtitle,
            leading: Icon(Icons.checklist_rounded, color: scheme.primary),
            child: Column(
              children: [
                _DeviceStatusTile(
                  icon: Icons.videocam_rounded,
                  title: l10n.deviceCheckCamera,
                  isActive: media.isCameraReady,
                  permissionStatus: media.cameraPermission,
                  isBusy: media.isInitializingCamera,
                  onRequest: media.requestPermissions,
                  onRetry: media.initCamera,
                  onOpenSettings: media.openSettings,
                ),
                const SizedBox(height: 10),
                _DeviceStatusTile(
                  icon: Icons.mic_rounded,
                  title: l10n.deviceCheckMicrophone,
                  isActive: media.isMicrophoneReady,
                  permissionStatus: media.microphonePermission,
                  isBusy: media.isStartingMicrophone,
                  onRequest: media.requestPermissions,
                  onRetry: media.startMicrophone,
                  onOpenSettings: media.openSettings,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AppCard(
            title: l10n.deviceCheckPreviewTitle,
            subtitle: media.isCameraReady
                ? l10n.deviceCheckCameraActive
                : l10n.deviceCheckCameraUnavailable,
            leading: Icon(Icons.camera_alt_outlined, color: scheme.secondary),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (media.isCameraReady && media.cameraController != null)
                      FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: media.cameraController!.value.previewSize?.height ?? 1,
                          height: media.cameraController!.value.previewSize?.width ?? 1,
                          child: CameraPreview(media.cameraController!),
                        ),
                      )
                    else
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              scheme.primary.withValues(alpha: 0.22),
                              scheme.secondary.withValues(alpha: 0.18),
                            ],
                          ),
                          border: Border.all(
                            color: scheme.outlineVariant.withValues(
                              alpha: 0.55,
                            ),
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.videocam_off_rounded,
                            size: 42,
                            color: scheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    if (media.lastError != null)
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          margin: const EdgeInsets.all(10),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: scheme.surfaceContainerHighest.withValues(
                              alpha: 0.85,
                            ),
                            border: Border.all(
                              color: scheme.outlineVariant.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                          child: Text(
                            media.lastError!,
                            style: Theme.of(context).textTheme.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          AppPrimaryButton(
            label: l10n.deviceCheckStartInterview,
            icon: Icons.play_arrow_rounded,
            onPressed: (media.isCameraReady && media.isMicrophoneReady)
                ? () {
                    if (!interviewController.isComplete) {
                      final missing = interviewController.config.missingFields
                          .map((f) => f.label(l10n))
                          .join(', ');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            l10n.interviewCompleteMissingFields(missing),
                          ),
                        ),
                      );
                      return;
                    }

                    Navigator.of(context).pushReplacementNamed(
                      AppRoutes.simulatedCall,
                    );
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
            child: Text(l10n.genericBack),
          ),
        ],
      ),
    );
  }
}

class _DeviceStatusTile extends StatelessWidget {
  const _DeviceStatusTile({
    required this.icon,
    required this.title,
    required this.isActive,
    required this.permissionStatus,
    required this.isBusy,
    required this.onRequest,
    required this.onRetry,
    required this.onOpenSettings,
  });

  final IconData icon;
  final String title;
  final bool isActive;
  final PermissionStatus permissionStatus;
  final bool isBusy;
  final Future<void> Function() onRequest;
  final Future<void> Function() onRetry;
  final Future<void> Function() onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final status = permissionStatus;
    final isDenied = status.isDenied;
    final isPermanentlyDenied =
        status.isPermanentlyDenied || status.isRestricted;

    final subtitle = isActive
        ? l10n.deviceStatusActive
        : isBusy
        ? l10n.deviceStatusEnabling
        : isPermanentlyDenied
        ? l10n.deviceStatusPermissionBlocked
        : isDenied
        ? l10n.deviceStatusPermissionDenied
        : l10n.deviceStatusUnavailable;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: isActive ? scheme.primary : scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (isPermanentlyDenied)
            TextButton(
              onPressed: () => onOpenSettings(),
              child: Text(l10n.deviceStatusOpenSettings),
            )
          else if (!isActive)
            TextButton(
              onPressed: () async {
                await onRequest();
                await onRetry();
              },
              child: Text(l10n.deviceStatusAllow),
            )
          else
            Icon(Icons.check_circle_rounded, color: scheme.primary),
        ],
      ),
    );
  }
}
