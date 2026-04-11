import 'package:flutter/material.dart';

class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isExpanded = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    final canPress = onPressed != null && !isLoading;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final child = isLoading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
          )
        : icon == null
            ? Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16))
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 20),
                  const SizedBox(width: 10),
                  Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                ],
              );

    final button = Container(
      height: 54, // slightly taller for premium feel
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: canPress ? [
          BoxShadow(
            color: scheme.primary.withValues(alpha: isDark ? 0.35 : 0.25),
            blurRadius: 16,
            spreadRadius: 1,
            offset: const Offset(0, 6),
          ),
        ] : null,
      ),
      child: FilledButton(
        onPressed: canPress ? onPressed : null,
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 54),
          foregroundColor: Colors.white,
          backgroundColor: scheme.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: child,
      ),
    );

    if (!isExpanded) return button;

    return SizedBox(
      width: double.infinity,
      child: button,
    );
  }
}
