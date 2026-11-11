# Documentación de Prep_Up

Prep_Up es un cliente Flutter. Autenticación y datos remotos viven en Supabase. La entrevista la genera Groq (`openai/gpt-oss-120b`), llamado desde la app. El código es un monolito modular con puertos hexagonales: un solo binario, un módulo por carpeta, y los adapters construidos solo en `lib/main.dart`.

## Índice

| Documento | Para qué sirve |
| --- | --- |
| [Arquitectura](arquitectura.md) | Decisión, capas, regla de dependencia y composition root |
| [Módulos](modulos.md) | Qué hay en cada feature y qué puerto usa |
| [Persistencia](persistencia.md) | Supabase, SQLite, caché y qué flujo escribe dónde |
| [Flujos](flujos.md) | Rutas, sesión de voz y análisis |
| [Desarrollo](desarrollo.md) | Cómo correr, probar y agregar un módulo sin romper la frontera |
| [Integración en Linear](integracion-linear.md) | Tablero, documentos y cómo el check de GitHub Actions llega a una issue |
| [Integración en Linear (Word)](Integracion_en_Linear.docx) | El mismo informe, con las capturas, para abrir en Word |

El diagrama de clases histórico está en [Prep_Up_UML_Class_Diagram.drawio](Prep_Up_UML_Class_Diagram.drawio). La estructura de carpetas vigente es la de [Arquitectura](arquitectura.md), no la de ese diagrama si discrepan.
