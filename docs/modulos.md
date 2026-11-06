# Módulos

Cada feature es una carpeta bajo `lib/features`. El estado de UI usa `provider`. Los controladores de entrevista y de dispositivos son `ChangeNotifier`. El tema y el idioma usan `InheritedNotifier` (`AppThemeScope`, `AppLocaleScope`).

## auth

Registro, login, OTP de alta, recuperación y nueva contraseña.

| Capa | Archivos |
| --- | --- |
| domain | `AuthGateway`, `SessionPreferences` |
| infrastructure | `AuthService`, `AuthPreferences` |
| presentation | splash, login, register, forgot password, verify OTP, reset password |

`AuthService` usa el cliente de Supabase Auth y, al registrar o entrar, hace `upsertUser` contra el `RelationalDatabaseService` que le inyecta `main`. Esa instancia es `SupabaseDatabaseService`, no la caché.

`AuthPreferences` guarda `remember_session` en `SharedPreferences`. Si el usuario no marca recordar sesión, Supabase arranca con `EmptyLocalStorage` y no conserva el token al cerrar la app.

Pantallas: leen `AuthGateway` y, en login, `SessionPreferences` desde `Provider`. No construyen el adapter.

## interview

Configuración de la simulación y la llamada de voz.

| Capa | Archivos |
| --- | --- |
| domain | `InterviewAiPort`, `GeminiException`, `AiInterviewService`, `VideoAnalysisService`, `VideoStorageService` |
| infrastructure | `GeminiService`, `GeminiAiInterviewService` |
| presentation | selección de tipo y rol, configuración, chequeo de dispositivos, llamada simulada, controladores |

`InterviewConfigController` guarda tipo, rol y duración mientras el usuario arma la entrevista. `MediaDeviceController` pide cámara y micrófono. `InterviewVoiceController` no está en el `Provider` global: la llamada simulada lo crea con el `InterviewAiPort` ya registrado.

El controlador de voz alterna TTS (`flutter_tts`) y STT (`speech_to_text`) y pide a la IA la apertura, la siguiente pregunta, la evaluación y el cierre.

`InterviewSessionController`, `AiInterviewService` y los puertos de video no participan del flujo actual. Quedan como contrato por si la entrevista pasa a tener vídeo analizado.

Tipos de dominio usados aquí, definidos en `shared/domain/entities/interview_tags.dart`:

- `InterviewType`: `technical`, `behavioral`, `mixed`
- `JobRole`: frontend, backend, mobile, UI/UX, data analyst, data scientist, QA, DevOps, product manager

## analysis

Después de la llamada. No tiene infrastructure.

`InterviewProcessingScreen` lee `InterviewAiPort`, `AuthGateway` y `RelationalDatabaseService`. Pide el análisis de la sesión, genera `InterviewResultsModel` y los guarda. Luego la app muestra resultado general, detalle y recomendaciones.

Los gráficos viven en `interview_statistics_widgets.dart`. El texto de feedback, en `feedback_content_widget.dart`.

## dashboard

Home. Lee `AuthGateway`, `RelationalDatabaseService` y, si el servicio también es `OfflineCache`, pinta usuario, historial y resultados locales antes de sincronizar.

Desde aquí se entra a una entrevista nueva, al historial, al perfil y a ajustes.

## tracking

`InterviewHistoryScreen` en `/tracking/interview-history`. Misma lectura cache-then-remote que el dashboard, limitada a sesiones y resultados. Al elegir una sesión abre el resultado general.

## profile

`UserProfileScreen` muestra el usuario y su actividad. También hace la lectura local primero cuando el servicio implementa `OfflineCache`.

## settings

Idioma y tema.

- El idioma lo persiste `AppLocaleController` en `SharedPreferences`. No entra en `AppSettingsModel`.
- El tema lo persiste `AppThemeController` en la base remota (`settings` de Supabase), no en la caché.

La pantalla de ajustes también puede leer y guardar `AppSettingsModel` por `RelationalDatabaseService` (la caché que ve el resto de la app). El controlador de tema, en cambio, usa la instancia remota que le pasó `main`. Un cambio de tema hecho solo en el controlador no queda garantizado en SQLite.

## shared

Modelos que cruzan módulos:

- `UserModel`
- `AppSettingsModel` y `AppThemeMode`
- `InterviewConfig`, `InterviewSession`, `InterviewTurn`
- `InterviewSessionModel` (fila persistida)
- `AnswerEvaluationModel`, `InterviewFeedbackModel`, `InterviewResultsModel`

Widgets de `shared/presentation/widgets`: `AppCard`, `AppLogo`, `AppPrimaryButton`, `AppScreenScaffold`.

## core

| Pieza | Rol |
| --- | --- |
| `AppRoutes`, `AppRouter` | nombres de ruta y construcción de páginas |
| `AppConfig` | `GEMINI_API_KEY`, `GEMINI_MODEL` y las URLs de la API |
| `userFriendlyErrorMessage` | traduce `GeminiException`, `AuthException` y fallos de red a texto de UI |
| `AppLocaleController` | locale `es` / `en` |
| `interview_l10n.dart` | etiquetas de tipo de entrevista y rol |

## theme

`AppThemeController` carga y guarda `AppThemeMode` (`system`, `light`, `dark`) para el usuario autenticado. `main.dart` arma los `ThemeData` claro y oscuro a partir de ese modo.
