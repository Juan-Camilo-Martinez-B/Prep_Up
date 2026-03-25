import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:prep_up/core/navigation/app_routes.dart';
import 'package:prep_up/domain/services/auth_service.dart';
import 'package:prep_up/domain/services/auth_preferences.dart';
import 'package:prep_up/presentation/widgets/app_card.dart';
import 'package:prep_up/presentation/widgets/app_primary_button.dart';
import 'package:prep_up/presentation/widgets/app_screen_scaffold.dart';

class LoginScreen extends StatefulWidget {
  final bool isVerified;
  const LoginScreen({super.key, this.isVerified = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  var _obscure = true;
  var _isLoading = false;
  var _rememberSession = false;

  @override
  void initState() {
    super.initState();
    AuthPreferences.getRememberSession().then((value) {
      if (mounted) {
        setState(() {
          _rememberSession = value;
        });
      }
    });
    if (widget.isVerified) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '¡Correo verificado con éxito! Ya puedes iniciar sesión.',
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
          ),
        );

        // Si el SDK de Supabase ya procesó el token y el usuario está autenticado,
        // podríamos redirigir al dashboard tras una breve espera.
        if (_authService.currentUser != null) {
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil(AppRoutes.dashboard, (route) => false);
            }
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      await AuthPreferences.setRememberSession(_rememberSession);

      if (mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(AppRoutes.dashboard, (route) => false);
      }
    } on AuthException catch (e) {
      if (mounted) {
        String message = 'Error al iniciar sesión';
        if (e.message.contains('Email not confirmed')) {
          message =
              'Tu cuenta aún no ha sido confirmada. Por favor verifica tu bandeja de entrada.';
        } else if (e.message.contains('Invalid login credentials')) {
          message = 'Credenciales incorrectas. Inténtalo de nuevo.';
        } else {
          message = e.message;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error inesperado: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppScreenScaffold(
      title: 'Iniciar sesión',
      background: const TechBackground(),
      body: ListView(
        children: [
          AppCard(
            title: 'Bienvenido de vuelta',
            subtitle: 'Tu entrenamiento continúa',
            leading: Icon(Icons.lock_outline, color: scheme.primary),
            child: Column(
              children: [
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.alternate_email_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.password_rounded),
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _obscure = !_obscure),
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text('Mantener sesión iniciada'),
                  value: _rememberSession,
                  onChanged: (v) => setState(() {
                    _rememberSession = v ?? false;
                  }),
                ),
                const SizedBox(height: 8),
                if (_isLoading)
                  const CircularProgressIndicator()
                else
                  AppPrimaryButton(
                    label: 'Entrar',
                    icon: Icons.arrow_forward_rounded,
                    onPressed: _handleLogin,
                  ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(
                        context,
                      ).pushNamed(AppRoutes.forgotPassword),
                      child: const Text('Olvidé mi contraseña'),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () =>
                          Navigator.of(context).pushNamed(AppRoutes.register),
                      child: const Text('Crear cuenta'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Tip: practica como si fuera real. Ajusta el ritmo y la claridad.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
