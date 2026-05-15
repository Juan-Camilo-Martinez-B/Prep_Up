import 'dart:convert';
import 'package:prep_up/l10n/app_localizations.dart';

class AiUtils {
  const AiUtils._();

  static String sanitizeAIText(String raw, AppLocalizations l10n) {
    var cleaned = raw.trim();

    if (cleaned.isEmpty) return l10n.errorGeminiFallbackFeedback;

    // 1. Remove markdown blocks if present
    final fenceStart = cleaned.indexOf('```');
    if (fenceStart != -1) {
      final fenceEnd = cleaned.lastIndexOf('```');
      if (fenceEnd != -1 && fenceEnd > fenceStart) {
        final inside = cleaned.substring(fenceStart + 3, fenceEnd).trim();
        final firstNewline = inside.indexOf('\n');
        cleaned = (firstNewline != -1)
            ? inside.substring(firstNewline + 1).trim()
            : inside;
      }
    }

    // 2. If it still looks like JSON, try to extract the specific text field
    if (cleaned.startsWith('{') && cleaned.contains('}')) {
      try {
        final decoded = jsonDecode(cleaned);
        if (decoded is Map) {
          final text = decoded['personalizedFeedback'] ??
              decoded['summary'] ??
              decoded['feedback'] ??
              decoded['text'];
          if (text is String && text.isNotEmpty) {
            cleaned = text;
          }
        }
      } catch (_) {
        // Not valid JSON
      }
    }

    // 3. Robust check: if it still has JSON-like structure, it's probably raw JSON
    // especially if it starts with { and has "overallScore" etc.
    if (cleaned.startsWith('{') || cleaned.contains('"overallScore"')) {
      // Last ditch effort: regex for anything that looks like "personalizedFeedback": "..."
      final match = RegExp(r'"(?:personalizedFeedback|summary|feedback|text)"\s*:\s*"([^"]+)"').firstMatch(cleaned);
      if (match != null && match.group(1) != null) {
        cleaned = match.group(1)!;
      } else {
        // If we can't extract a message, it's technical jargon
        return l10n.errorAIFailureFriendly;
      }
    }

    // 4. Remove Markdown formatting symbols (asterisks, underscores, hashes, backticks)
    cleaned = cleaned.replaceAll(RegExp(r'[*_#`~]'), '');

    // 5. Clean up markdown list prefixes at start of lines or phrases
    cleaned = cleaned.replaceAll(RegExp(r'^\s*[-+*]\s+', multiLine: true), '');
    cleaned = cleaned.replaceAll(RegExp(r'\s*[-+*]\s+'), ' ');

    // 6. Remove common JSON artifacts if they leaked
    cleaned = cleaned.replaceAll(RegExp(r'["\{\}\[\]]'), '');
    cleaned = cleaned.replaceAll(RegExp(r'^[a-zA-Z0-9]+:\s*'), ''); // Remove keys like "summary:"

    // 7. Normalize whitespace and newlines for natural speech flow
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();

    // 8. Final check: if it's too short or contains only technical jargon, return localized error
    if (cleaned.length < 10 ||
        cleaned.contains('personalizedFeedback') ||
        cleaned.contains('overallScore')) {
      return l10n.errorAIFailureFriendly;
    }

    return cleaned;
  }
}
