import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prep_up/core/utils/ai_utils.dart';
import 'package:prep_up/l10n/app_localizations.dart';

void main() {
  late AppLocalizations l10n;

  setUpAll(() {
    l10n = lookupAppLocalizations(const Locale('es'));
  });

  test('un texto vacío usa el fallback', () {
    expect(AiUtils.sanitizeAIText('   ', l10n), l10n.errorAiFallbackFeedback);
  });

  test('saca el feedback de un bloque markdown con JSON', () {
    const raw = '''
```json
{"personalizedFeedback": "Explicaste la caché con un ejemplo claro."}
```
''';

    expect(
      AiUtils.sanitizeAIText(raw, l10n),
      'Explicaste la caché con un ejemplo claro.',
    );
  });

  test('un JSON de puntaje sin texto usable no se lee en voz', () {
    const raw = '{"overallScore": 80, "highlights": ["corta"]}';

    expect(AiUtils.sanitizeAIText(raw, l10n), l10n.errorAIFailureFriendly);
  });

  test('quita marcas de markdown de una frase hablable', () {
    expect(
      AiUtils.sanitizeAIText(
        '**Bien.** _Sigue_ con un ejemplo concreto.',
        l10n,
      ),
      'Bien. Sigue con un ejemplo concreto.',
    );
  });
}
