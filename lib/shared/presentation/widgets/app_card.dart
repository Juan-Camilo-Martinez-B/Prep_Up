import 'dart:ui';
import 'package:flutter/material.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.child,
  });

  final String? title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final content = Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null ||
              subtitle != null ||
              leading != null ||
              trailing != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (leading != null) ...[leading!, const SizedBox(width: 12)],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (title != null)
                        Text(title!, style: theme.textTheme.titleMedium),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: 12), trailing!],
              ],
            ),
          if ((title != null ||
                  subtitle != null ||
                  leading != null ||
                  trailing != null) &&
              child != null)
            const SizedBox(height: 12),
          ...[child].whereType<Widget>(),
        ],
      ),
    );

    // Glassmorphism implementation
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: scheme.surfaceContainerHighest.withValues(alpha: isDark ? 0.3 : 0.8),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: isDark ? 0.05 : 0.03),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Material(
            color: scheme.surface.withValues(alpha: isDark ? 0.6 : 0.85),
            child: InkWell(
              onTap: onTap,
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}
