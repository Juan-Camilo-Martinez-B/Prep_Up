import 'package:flutter/material.dart';
import 'package:prep_up/l10n/app_localizations.dart';
import 'package:prep_up/core/utils/ai_utils.dart';

class FeedbackContentWidget extends StatelessWidget {
  const FeedbackContentWidget({
    super.key,
    required this.content,
    this.title,
    this.icon,
    this.color,
  });

  final String content;
  final String? title;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final l10n = AppLocalizations.of(context)!;

    final displayColor = color ?? scheme.primary;
    final displayIcon = icon ?? Icons.auto_awesome_rounded;

    // Sanitize content first (extra layer of safety for data from DB)
    final sanitizedContent = AiUtils.sanitizeAIText(content, l10n);

    // Process content to detect bullet points and split paragraphs
    final lines = sanitizedContent
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Row(
            children: [
              Icon(displayIcon, size: 20, color: displayColor),
              const SizedBox(width: 10),
              Text(
                title!,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: displayColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: displayColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: displayColor.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: lines.map((line) {
              final isBullet = line.startsWith('•') ||
                  line.startsWith('-') ||
                  line.startsWith('*') ||
                  RegExp(r'^\d+[\.\)]').hasMatch(line);

              final cleanLine = isBullet
                  ? line.replaceFirst(RegExp(r'^[\-\*•\d\.\)]+\s*'), '')
                  : line;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isBullet)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, right: 10),
                        child: Icon(
                          Icons.arrow_right_rounded,
                          size: 16,
                          color: displayColor,
                        ),
                      ),
                    Expanded(
                      child: Text(
                        cleanLine,
                        style: textTheme.bodyMedium?.copyWith(
                          height: 1.5,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class SectionFeedbackCard extends StatelessWidget {
  const SectionFeedbackCard({
    super.key,
    required this.title,
    required this.items,
    required this.icon,
    required this.color,
  });

  final String title;
  final List<String> items;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12, top: 20),
          child: Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 10),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.1)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle_outline_rounded, 
                     size: 18, color: color),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        )),
      ],
    );
  }
}
