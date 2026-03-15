import 'package:flutter/material.dart';
import 'package:prep_up/navigation/app_routes.dart';
import 'package:prep_up/widgets/app_primary_button.dart';
import 'package:prep_up/widgets/app_screen_scaffold.dart';

class AppRouter {
  const AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final name = settings.name ?? '';
    final spec = _specFor(name);

    return MaterialPageRoute<void>(
      settings: settings,
      builder: (context) => _RoutePlaceholderPage(spec: spec),
    );
  }

  static _PageSpec _specFor(String routeName) {
    return switch (routeName) {
      AppRoutes.splash => const _PageSpec(
          title: 'AI Interview Trainer',
          subtitle: 'Splash Screen',
          primaryRoutes: [AppRoutes.login, AppRoutes.register],
        ),
      AppRoutes.login => const _PageSpec(
          title: 'Iniciar sesión',
          subtitle: 'Login',
          primaryRoutes: [AppRoutes.dashboard],
          secondaryRoutes: [AppRoutes.forgotPassword, AppRoutes.register],
        ),
      AppRoutes.register => const _PageSpec(
          title: 'Crear cuenta',
          subtitle: 'Registro',
          primaryRoutes: [AppRoutes.dashboard],
          secondaryRoutes: [AppRoutes.login],
        ),
      AppRoutes.forgotPassword => const _PageSpec(
          title: 'Recuperar contraseña',
          subtitle: 'Reset de contraseña',
          primaryRoutes: [AppRoutes.login],
        ),
      AppRoutes.dashboard => const _PageSpec(
          title: 'Dashboard',
          subtitle: 'Inicio',
          primaryRoutes: [
            AppRoutes.selectInterviewType,
            AppRoutes.profile,
            AppRoutes.interviewHistory,
            AppRoutes.statistics,
            AppRoutes.settings,
          ],
        ),
      AppRoutes.profile => const _PageSpec(
          title: 'Perfil',
          subtitle: 'Perfil de usuario',
          primaryRoutes: [AppRoutes.dashboard],
        ),
      AppRoutes.settings => const _PageSpec(
          title: 'Configuración',
          subtitle: 'Preferencias de la app',
          primaryRoutes: [AppRoutes.dashboard],
        ),
      AppRoutes.selectInterviewType => const _PageSpec(
          title: 'Preparación',
          subtitle: 'Selección de tipo de entrevista',
          primaryRoutes: [AppRoutes.selectJobRole],
          secondaryRoutes: [AppRoutes.dashboard],
        ),
      AppRoutes.selectJobRole => const _PageSpec(
          title: 'Preparación',
          subtitle: 'Selección de puesto / área laboral',
          primaryRoutes: [AppRoutes.interviewConfiguration],
          secondaryRoutes: [AppRoutes.selectInterviewType],
        ),
      AppRoutes.interviewConfiguration => const _PageSpec(
          title: 'Preparación',
          subtitle: 'Configuración de entrevista',
          primaryRoutes: [AppRoutes.deviceCheck],
          secondaryRoutes: [AppRoutes.selectJobRole],
        ),
      AppRoutes.deviceCheck => const _PageSpec(
          title: 'Preparación',
          subtitle: 'Verificación de cámara y micrófono',
          primaryRoutes: [AppRoutes.simulatedCall],
          secondaryRoutes: [AppRoutes.interviewConfiguration],
        ),
      AppRoutes.simulatedCall => const _PageSpec(
          title: 'Simulación',
          subtitle: 'Videollamada simulada',
          primaryRoutes: [AppRoutes.interviewProcessing],
          secondaryRoutes: [AppRoutes.deviceCheck],
        ),
      AppRoutes.interviewProcessing => const _PageSpec(
          title: 'Análisis',
          subtitle: 'Analizando tu entrevista con IA...',
          primaryRoutes: [AppRoutes.generalResults],
          secondaryRoutes: [AppRoutes.simulatedCall],
        ),
      AppRoutes.generalResults => const _PageSpec(
          title: 'Resultados',
          subtitle: 'Resultados generales',
          primaryRoutes: [AppRoutes.detailedAnalysis],
          secondaryRoutes: [AppRoutes.dashboard],
        ),
      AppRoutes.detailedAnalysis => const _PageSpec(
          title: 'Análisis',
          subtitle: 'Análisis detallado',
          primaryRoutes: [AppRoutes.recommendations],
          secondaryRoutes: [AppRoutes.generalResults],
        ),
      AppRoutes.recommendations => const _PageSpec(
          title: 'Recomendaciones',
          subtitle: 'Sugerencias',
          primaryRoutes: [AppRoutes.dashboard],
          secondaryRoutes: [AppRoutes.detailedAnalysis, AppRoutes.repeatInterview],
        ),
      AppRoutes.interviewHistory => const _PageSpec(
          title: 'Historial',
          subtitle: 'Historial de entrevistas',
          primaryRoutes: [AppRoutes.dashboard],
        ),
      AppRoutes.statistics => const _PageSpec(
          title: 'Estadísticas',
          subtitle: 'Gráficos / placeholders',
          primaryRoutes: [AppRoutes.dashboard],
        ),
      AppRoutes.repeatInterview => const _PageSpec(
          title: 'Repetir entrevista',
          subtitle: 'Iniciar nueva simulación',
          primaryRoutes: [AppRoutes.selectInterviewType],
          secondaryRoutes: [AppRoutes.dashboard],
        ),
      _ => _PageSpec(
          title: 'Ruta no encontrada',
          subtitle: routeName.isEmpty ? 'Sin nombre' : routeName,
          primaryRoutes: const [AppRoutes.splash],
          secondaryRoutes: AppRoutes.all,
        ),
    };
  }
}

class _PageSpec {
  const _PageSpec({
    required this.title,
    required this.subtitle,
    required this.primaryRoutes,
    this.secondaryRoutes = const [],
  });

  final String title;
  final String subtitle;
  final List<String> primaryRoutes;
  final List<String> secondaryRoutes;
}

class _RoutePlaceholderPage extends StatelessWidget {
  const _RoutePlaceholderPage({
    required this.spec,
  });

  final _PageSpec spec;

  @override
  Widget build(BuildContext context) {
    return AppScreenScaffold(
      title: spec.title,
      body: ListView(
        children: [
          Text(
            spec.subtitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          for (final routeName in spec.primaryRoutes) ...[
            AppPrimaryButton(
              label: _labelForRoute(routeName),
              onPressed: () => Navigator.of(context).pushNamed(routeName),
            ),
            const SizedBox(height: 12),
          ],
          if (spec.secondaryRoutes.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Accesos',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 12),
            for (final routeName in spec.secondaryRoutes) ...[
              OutlinedButton(
                onPressed: () => Navigator.of(context).pushNamed(routeName),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(_labelForRoute(routeName)),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ],
      ),
    );
  }

  String _labelForRoute(String routeName) {
    return switch (routeName) {
      AppRoutes.splash => 'Ir a Splash',
      AppRoutes.login => 'Ir a Login',
      AppRoutes.register => 'Ir a Registro',
      AppRoutes.forgotPassword => 'Recuperar contraseña',
      AppRoutes.dashboard => 'Ir a Dashboard',
      AppRoutes.profile => 'Perfil',
      AppRoutes.settings => 'Configuración',
      AppRoutes.selectInterviewType => 'Seleccionar tipo de entrevista',
      AppRoutes.selectJobRole => 'Seleccionar puesto / área',
      AppRoutes.interviewConfiguration => 'Configurar entrevista',
      AppRoutes.deviceCheck => 'Preparación (cámara y micrófono)',
      AppRoutes.simulatedCall => 'Iniciar videollamada simulada',
      AppRoutes.interviewProcessing => 'Procesar entrevista',
      AppRoutes.generalResults => 'Ver resultados generales',
      AppRoutes.detailedAnalysis => 'Ver análisis detallado',
      AppRoutes.recommendations => 'Ver recomendaciones',
      AppRoutes.interviewHistory => 'Historial de entrevistas',
      AppRoutes.statistics => 'Estadísticas',
      AppRoutes.repeatInterview => 'Repetir entrevista',
      _ => routeName,
    };
  }
}
