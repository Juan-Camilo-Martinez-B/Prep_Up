# Persistencia

Hay cuatro almacenes. No todos los flujos pasan por los cuatro.

| Almacén | Qué guarda | Quién lo usa |
| --- | --- | --- |
| Supabase Auth | email, contraseña, sesión, OTP | `AuthService` |
| Supabase Postgres | `users`, `settings`, `interview_sessions`, `interview_results` | `SupabaseDatabaseService` |
| SQLite `prep_up_local.db` | las mismas cuatro tablas | `SqfliteDatabaseService` |
| SharedPreferences | `remember_session`, idioma | `AuthPreferences`, `AppLocaleController` |

## Tablas

Supabase y SQLite repiten el mismo conjunto lógico.

`users`: `id`, `email`, `display_name`, `photo_url`, `created_at`, `updated_at`.

`settings`: `user_id`, `theme_mode`, `updated_at`.

`interview_sessions`: `id`, `user_id`, `type`, `job_role`, `status`, `question_count`, `time_limit_seconds`, `video_reference`, `turns` (JSON), `created_at`, `updated_at`.

`interview_results`: `id`, `session_id`, `user_id`, `score`, `outcome`, `breakdown`, `highlights`, `personalized_feedback`, `recommendations`, `improvement_tips`, tiempos de respuesta, `valid_answers_count`, `analyzed_at`. Los campos de listas van como JSON en SQLite.

La base local se crea en la versión 1 dentro de `SqfliteDatabaseService`. No hay migraciones posteriores.

## Política de la caché

`CachedDatabaseService` decora un remoto y un local. Es el objeto registrado como `RelationalDatabaseService`.

Lectura (`getUserById`, historial, resultados, ajustes): intenta remoto. Si hay dato, lo copia al local y lo devuelve. Si el remoto falla o no hay fila, devuelve el local.

Escritura (`upsertUser`, sesión, resultado, ajustes): escribe primero en local y después intenta el remoto. Un fallo remoto se registra y no revierte lo local. No hay cola de reintento.

`OfflineCache` no cambia esa política. Solo expone tres lecturas directas al SQLite, las que la UI usa para pintar antes de esperar la red:

- `readUser`
- `readHistory`
- `readResults`

Dashboard, perfil e historial hacen `if (dbService is OfflineCache)` y leen eso. Después llaman a los métodos normales del puerto, que sincronizan con Supabase.

## Qué no pasa por la caché

| Flujo | Dónde escribe |
| --- | --- |
| Alta y reparación de perfil en login, registro y OTP | `AuthService` → `SupabaseDatabaseService` |
| Tema aplicado por `AppThemeController` | el mismo `SupabaseDatabaseService` que recibe el controlador |
| Idioma | `SharedPreferences` |
| Recordar sesión | `SharedPreferences` |

Por eso un perfil recién creado puede existir en Supabase y todavía no en SQLite hasta que otra pantalla lo lea por la caché. Un tema cambiado desde el controlador puede no estar en la base local.

Unificar esos dos flujos con `CachedDatabaseService` es un cambio de comportamiento, no un detalle de carpetas. No está hecho.

## Variables

En `.env`, en la raíz del proyecto. El archivo está declarado como asset en `pubspec.yaml`. No se commitea.

```env
SUPABASE_URL=
SUPABASE_ANON_KEY=
GEMINI_API_KEY=
GEMINI_MODEL=
```

`GEMINI_MODEL` es opcional. Si falta, `AppConfig` usa `gemini-1.5-flash-latest`.
