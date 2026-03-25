import 'package:flutter/material.dart';
import 'package:prep_up/core/navigation/app_routes.dart';
import 'package:prep_up/domain/services/auth_service.dart';
import 'package:prep_up/presentation/widgets/app_primary_button.dart';
import 'package:prep_up/presentation/widgets/app_screen_scaffold.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  void _checkAuth() {
    // Pequeña espera para mostrar el splash o asegurar que el cliente esté listo
    Future.delayed(const Duration(seconds: 1), () {
      if (_authService.currentUser != null) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(AppRoutes.dashboard);
        }
      } else {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(AppRoutes.login);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppScreenScaffold(
      title: 'AI Interview Trainer',
      centerTitle: true,
      background: const TechBackground(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                colors: [
                  scheme.primary.withValues(alpha: 0.18),
                  scheme.secondary.withValues(alpha: 0.16),
                ],
              ),
              border: Border.all(
                color: scheme.primary.withValues(alpha: 0.22),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.primary.withValues(alpha: 0.18),
                  ),
                  child: Icon(
                    Icons.smart_toy_outlined,
                    color: scheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Entrena entrevistas con IA',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Simula. Aprende. Mejora.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Prepárate para tu próximo trabajo con una experiencia visual y tecnológica.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const Spacer(),
          AppPrimaryButton(
            label: 'Iniciar sesión',
            icon: Icons.login_rounded,
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.login),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.register),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('Crear cuenta'),
          ),
          const SizedBox(height: 10),
          Text(
            'Sesión protegida por Supabase.',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
