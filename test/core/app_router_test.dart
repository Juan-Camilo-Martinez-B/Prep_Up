import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prep_up/core/navigation/app_router.dart';
import 'package:prep_up/core/navigation/app_routes.dart';

void main() {
  test('el callback de Supabase abre el login', () {
    final route = AppRouter.onGenerateRoute(
      const RouteSettings(name: '/login-callback?code=abc'),
    );

    expect(route.settings.name, AppRoutes.login);
  });

  test('una ruta desconocida conserva el nombre recibido', () {
    final route = AppRouter.onGenerateRoute(
      const RouteSettings(name: '/no-existe'),
    );

    expect(route.settings.name, '/no-existe');
  });

  test('el catálogo de rutas no repite caminos', () {
    expect(AppRoutes.all.toSet(), hasLength(AppRoutes.all.length));
    expect(AppRoutes.all, contains(AppRoutes.simulatedCall));
    expect(AppRoutes.all, contains(AppRoutes.interviewHistory));
  });
}
