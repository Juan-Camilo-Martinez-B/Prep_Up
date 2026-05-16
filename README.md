# Prep_Up - AI Interview Trainer

Prep_Up es una aplicación móvil desarrollada en Flutter diseñada para revolucionar la forma en que los profesionales se preparan para entrevistas laborales. Utilizando inteligencia artificial conversacional avanzada, reconocimiento de voz (STT) y síntesis de voz (TTS), la aplicación simula un entorno de entrevista realista, proporcionando retroalimentación técnica y comunicativa instantánea.

---

## 📖 Caso de Estudio y Problemática que Resuelve

### **La Problemática**
En el ámbito competitivo de la búsqueda de empleo, especialmente en roles técnicos y corporativos, muchos candidatos fallan en sus entrevistas no por falta de conocimientos, sino por ansiedad, dificultades en la comunicación estructurada o falta de práctica en la articulación de respuestas bajo presión. Encontrar un mentor técnico disponible para simular entrevistas de forma constante es difícil y costoso.

### **El Caso de Estudio / Solución (Prep_Up)**
Prep_Up actúa como un entrevistador inteligente disponible 24/7. Permite a los usuarios enfrentarse a simulaciones de entrevistas adaptadas a su rol específico, analizando sus respuestas en tiempo real mediante IA generativa. La plataforma evalúa no solo el conocimiento técnico, sino también la fluidez y confianza, entregando un reporte estructurado con puntos fuertes, áreas de mejora y respuestas sugeridas.

---

## 🎯 Objetivo General del Proyecto

Proporcionar una herramienta integral y accesible de simulación de entrevistas basada en Inteligencia Artificial que permita a los candidatos mejorar sus habilidades de respuesta, mitigar la ansiedad mediante la práctica constante y recibir retroalimentación objetiva, detallada y constructiva sobre su desempeño profesional.

---

## 🚀 Alcance y Funcionalidades Principales

* **Autenticación Segura y Recuperación OTP**: Registro, inicio de sesión y flujo premium de restablecimiento de contraseña mediante códigos de 6 dígitos enviados por correo.
* **Simulación Conversacional con IA**: Integración de Text-to-Speech (TTS) y Speech-to-Text (STT) usando Google Gemini para una experiencia "cara a cara" con preguntas adaptativas.
* **Validación y Sanitización de Inputs**: Implementación de `TextInputFormatter` para prevenir espacios accidentales al inicio en todos los campos críticos.
* **Evaluación y Feedback Profundo**: Análisis de respuestas con puntajes de dominio, comunicación y sugerencias de mejora personalizadas.
* **Dashboard y Estadísticas Evolutivas**: Visualización gráfica del progreso mediante gráficos de rendimiento y KPIs de usuario.
* **Estrategia Offline-First (Cache-First)**: Soporte híbrido que permite acceso instantáneo al historial y perfil desde SQLite con sincronización remota en segundo plano.
* **Internacionalización (i18n)**: Soporte completo bilingüe (Español/Inglés) gestionado a través de archivos `.arb`.
* **UI Premium y Adaptativa**: Diseño dinámico con modo oscuro/claro, animaciones de `flutter_animate` y estados de carga con `Skeletonizer` en todas las pantallas principales.

---

## 🏗️ Estructura General del Proyecto

El proyecto sigue una estructura limpia y escalable, dividiendo responsabilidades en capas claras dentro del directorio `lib/`:

```
lib/
├── core/             # Configuraciones globales, manejo de errores, navegación, enrutamiento, utils y localización (l10n extensions).
├── domain/           # Modelos de dominio (Entities), definición de servicios y reglas de negocio.
│   ├── entities/     # Modelos de datos (User, InterviewSession, AnswerEvaluation, etc.).
│   └── services/     # Lógica central e integración (GeminiService, CachedDatabaseService, SqfliteDatabaseService, SupabaseDatabaseService).
├── l10n/             # Archivos de traducción y delegados de localización (AppLocalizations).
├── presentation/     # Capa de Interfaz de Usuario (UI) y Controladores de estado.
│   ├── controllers/  # Providers/StateManagers (InterviewVoiceController, MediaDeviceController, etc.).
│   ├── screens/      # Vistas de la aplicación agrupadas por features (auth, dashboard, interview, analysis, tracking, profile).
│   └── widgets/      # Componentes visuales reutilizables (Botones, Tarjetas, Modales).
├── theme/            # Definición del Design System, paleta de colores y tipografía (AppTheme).
└── main.dart         # Punto de entrada, inyección de dependencias (Providers) y configuración principal.
```

---

## 🏛️ Arquitectura Utilizada

La aplicación implementa una variación de **Clean Architecture** enfocada al ecosistema de Flutter, separando estrictamente la presentación de la lógica de negocio y del acceso a datos.

* **Presentation Layer**: Encargada únicamente de dibujar la UI y reaccionar a los cambios de estado.
* **Domain / Business Logic Layer**: Administrada a través de Controladores (`ChangeNotifier`) que orquestan el flujo entre los servicios y la UI. Contiene las definiciones de modelos fuertemente tipados.
* **Data / Services Layer**: Clases de servicio dedicadas que encapsulan las llamadas a APIS externas y Bases de Datos. Implementa una estrategia **Offline-First (Cache-First)** mediante un decorador de caché (`CachedDatabaseService`) que expone capas local y remota para optimizar la latencia en la UI.

---

## 🧩 Patrones de Diseño Implementados

* **Provider / State Management**: Uso del patrón *Observer* mediante el paquete `provider` para la inyección de dependencias global (`MultiProvider` en `main.dart`) y manejo reactivo de estado en las vistas.
* **Dependency Injection (DI)**: Los servicios como `AuthService`, `GeminiService` y `SupabaseDatabaseService` se inyectan a los controladores para facilitar el testeo y la modularidad.
* **Adapter / Wrapper Pattern**: Servicios como `GeminiService` actúan como wrappers para estandarizar la comunicación HTTP con la API de Google, traduciendo excepciones genéricas a `GeminiException` y luego a la jerarquía de errores propia del sistema (`AppException`).
* **Factory Pattern**: Utilizado extensivamente en los modelos de dominio (`fromJson`, `toJson`) para serializar y deserializar respuestas estructuradas de las APIs.

---

## 🔄 Flujo General de la Aplicación

1. **Splash/Init**: Carga de configuración base (tema, idioma, variables de entorno) y verificación de sesión de Supabase.
2. **Auth**: Flujo de Login o Registro de usuario. Si la autenticación es exitosa, se navega al `Dashboard`.
3. **Dashboard / Home**: El usuario visualiza su progreso e historial. Puede iniciar una nueva simulación.
4. **Interview Setup**: El usuario selecciona el tipo de entrevista (Técnica, RH, Mixta), su rol profesional y duración.
5. **Interview Session (Voice/STT-TTS)**:
   * La IA saluda y formula la primera pregunta (mediante `flutter_tts`).
   * La app escucha automáticamente la respuesta del usuario (`speech_to_text`).
   * La respuesta es enviada a Gemini para validación y evaluación, generando métricas instantáneas y la siguiente pregunta adaptativa.
6. **Results Analysis**: Finalizada la sesión, se genera y consolida un `InterviewResultsModel`, presentando un resumen detallado del desempeño.

---

## 🛠️ Widgets, Componentes y Módulos Relevantes

* **`InterviewVoiceController`**: El motor de la entrevista. Maneja el ciclo de vida complejo de escuchar (micrófono), hablar (TTS), pausar y comunicarse de forma asíncrona con el backend generativo de IA para mantener un flujo conversacional natural.
* **`GeminiService`**: Servicio centralizado que estructura los *prompts* del sistema mediante schemas JSON estrictos.
* **Componentes Visuales de Vanguardia**: 
    *   `AnimatedTextKit`: Para el efecto de "escritura" en tiempo real de la IA.
    *   `FlutterAnimate`: Para transiciones fluidas y dinámicas en el Dashboard.
    *   `Skeletonizer`: Utilizado en Dashboard, Historial y Entrevista para una transición fluida entre estados de carga y datos reales.
    *   `AppPrimaryButton` y tarjetas con efectos "Glassmorphism".

---

## 🔌 APIs, Servicios e Integraciones Externas Utilizadas

* **Supabase (`supabase_flutter`)**: Backend as a Service para Autenticación y almacenamiento remoto.
* **SQLite (`sqflite`)**: Base de datos local para persistencia offline y caché de alto rendimiento.
* **Google Gemini API (`google_generative_ai` y llamadas HTTP custom)**: El núcleo intelectual de la app. Responsable de la generación conversacional adaptativa y la evaluación semántica y técnica del usuario.
* **`speech_to_text`**: API nativa de transcripción de audio a texto en tiempo real para capturar la respuesta del usuario.
* **`flutter_tts`**: Conversión de Texto a Voz nativa para dotar a la IA de una voz realista y localizada.
* **WebRTC / Permisos (`flutter_webrtc`, `camera`, `permission_handler`)**: Manejo profundo de hardware para asegurar el correcto acceso al micrófono y preparar bases para futuras entrevistas con video.

---

## 📦 Dependencias e Imports Externos Importantes

Definidas en el `pubspec.yaml`:
* `provider: ^6.1.2` (Inyección y Estado)
* `flutter_dotenv: ^5.1.0` (Gestión de secretos en archivo `.env`)
* `intl: ^0.20.2` y `flutter_localizations` (Internacionalización)
* `shared_preferences: ^2.3.2` (Preferencias de sesión)
* `sqflite` & `path` (Persistencia local relacional)
* `animated_text_kit`, `flutter_animate` & `skeletonizer` (Mejoras visuales y UX)
* `http: ^1.2.2` (Conexiones de red avanzadas)

---

## ⚙️ Consideraciones Técnicas Relevantes

* **Manejo de Respuestas AI**: Debido a la naturaleza probabilística de la IA, el `GeminiService` obliga a la API a responder en formato JSON estructurado y realiza *parsing* defensivo. Si la respuesta falla, existen fallbacks que garantizan que el flujo de la entrevista no se rompa (ej: `_fallbackQuestionsFromText`).
* **Seguridad (Zero Trust)**: Las credenciales y llaves de API NUNCA están codificadas en el repositorio. Se inyectan a través del entorno (`.env`).
* **Ciclo de Vida de Audio**: La app gestiona cuidadosamente los *locks* del micrófono y los altavoces, deteniendo el TTS automáticamente si el usuario interviene o cancela la sesión prematuramente.

---

## 🖥️ Recomendaciones de Uso y Ejecución

### **1. Requisitos Previos**
* SDK de Flutter configurado (Versión `^3.10.8` o superior).
* Cuenta y proyectos creados en **Supabase** y **Google AI Studio** (Gemini).

### **2. Configuración del Entorno**
Crea un archivo `.env` en la raíz del proyecto (a nivel del `pubspec.yaml`) con la siguiente estructura:
```env
SUPABASE_URL=tu_supabase_project_url
SUPABASE_ANON_KEY=tu_supabase_anon_key
GEMINI_API_KEY=tu_google_gemini_api_key
```

### **3. Compilación y Ejecución**
1. Instala las dependencias:
   ```bash
   flutter pub get
   ```
2. Si realizaste cambios en modelos/localización, asegúrate de generar el código automático:
   ```bash
   flutter gen-l10n
   ```
3. Ejecuta la aplicación en un emulador o dispositivo físico (se requiere dispositivo físico para probar funcionalidades del micrófono de manera óptima):
   ```bash
   flutter run
   ```

---

*Desarrollado con ❤️ usando Flutter.*
