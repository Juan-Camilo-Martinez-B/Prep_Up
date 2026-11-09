# Desarrollo

## Requisitos

- Flutter con Dart `^3.10.8` (el SDK declarado en `pubspec.yaml`).
- Un proyecto de Supabase con Auth y las tablas `users`, `settings`, `interview_sessions` e `interview_results`.
- Una API key de Groq.
- Un dispositivo físico para probar micrófono y TTS con fidelidad. El emulador alcanza para el resto de la navegación.

## Arranque

En la raíz del repo:

```bash
flutter pub get
flutter gen-l10n
flutter run
```

`.env` junto a `pubspec.yaml`:

```env
SUPABASE_URL=https://<proyecto>.supabase.co
SUPABASE_ANON_KEY=<anon>
GROQ_API_KEY=<key>
GROQ_MODEL=openai/gpt-oss-120b
```

`flutter gen-l10n` hace falta cuando cambian `lib/l10n/app_en.arb` o `lib/l10n/app_es.arb`. La configuración está en `l10n.yaml`: el template es el inglés y la clase generada es `AppLocalizations`.

## Pruebas

```bash
flutter analyze
flutter test
```

| Archivo | Qué cubre |
| --- | --- |
| `test/widget_test.dart` | La app arranca en splash con una base falsa y Supabase de prueba |
| `test/i18n_validation_test.dart` | Las claves EN y ES coinciden, las pantallas migradas no dejan literales sueltos en títulos, y el idioma se guarda |
| `test/features/interview/infrastructure/groq_service_test.dart` | El adapter de Groq con un `MockClient`: formato de la petición (URL, `Authorization`, `messages`, `reasoning_effort`, límite de tokens), errores de la API, de red y de JSON, falta de key, límite de tokens agotado, y el parseo de preguntas y evaluaciones. No usa red ni key |

No hay pruebas de la caché Supabase/SQLite, y los tests del adapter no validan la calidad de las respuestas del modelo real. Un cambio en el texto de los prompts o en el orden local/remoto no queda cubierto por la suite actual.

`flutter analyze` puede reportar avisos ya presentes (widgets sin uso, algún import sin usar). Un error de compilación sí indica que la frontera o un import quedó roto.

## Agregar una pantalla a un módulo que ya existe

1. Créala en `lib/features/<modulo>/presentation/`.
2. Registra la ruta en `AppRoutes` y el `switch` de `AppRouter`.
3. Pide dependencias con `context.read` del puerto (`AuthGateway`, `RelationalDatabaseService`, `InterviewAiPort`). No importes `supabase_database_service.dart`, `sqflite_database_service.dart` ni `groq_service.dart`.
4. Si el texto es visible, añádelo en los dos ARB y corre `flutter gen-l10n`.
5. Si la pantalla entra en la lista de `test/i18n_validation_test.dart`, no dejes `title:` ni `subtitle:` con un string literal.

## Agregar un módulo

1. Crea `lib/features/<nombre>/presentation/`.
2. Si habla con un sistema externo, declara el puerto en `domain/` y el adapter en `infrastructure/`.
3. Construye el adapter en `main` y regístralo en el `MultiProvider` por el tipo del puerto.
4. La presentación solo importa el puerto.

Si el dato lo comparten varios módulos, el modelo va a `lib/shared/domain/entities/` y, si se persiste, el método nuevo va a `RelationalDatabaseService` y a los tres adapters (Supabase, SQLite y caché).

## Idioma de la IA

Los prompts salen de `AppLocalizations` según el locale activo (`es` o `en`). Cambiar un prompt es cambiar la clave en los dos ARB, no hardcodear el texto en `GroqService`.

## Límites al tocar persistencia

- No pases `CachedDatabaseService` a `AuthService` ni a `AppThemeController` si el objetivo es solo reordenar carpetas. Hoy esos dos escriben en Supabase a propósito.
- No leas `.local` desde una pantalla. Usa `OfflineCache`.
- La clave de Groq sigue en el cliente. Sacarla a una función de Supabase es otro corte: cambia `AppConfig`, el adapter y el `.env`.
