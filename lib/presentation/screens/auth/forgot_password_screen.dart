import 'package:flutter/material.dart';
import 'package:prep_up/core/navigation/app_routes.dart';
import 'package:prep_up/domain/services/auth_service.dart';
import 'package:prep_up/presentation/widgets/app_card.dart';
import 'package:prep_up/presentation/widgets/app_primary_button.dart';
import 'package:prep_up/presentation/widgets/app_screen_scaffold.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _authService = AuthService();
  var _sent = false;
  var _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa tu email')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.resetPassword(_emailController.text.trim());
      setState(() => _sent = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enlace de recuperación enviado')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
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
    return AppScreenScaffold(
      title: 'Recuperar contraseña',
      background: const TechBackground(),
      body: ListView(
        children: [
          AppCard(
            title: 'Reinicia tu acceso',
            subtitle: 'Te enviaremos un enlace',
            leading: Icon(
              Icons.refresh_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
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
                const SizedBox(height: 16),
                if (_isLoading)
                  const CircularProgressIndicator()
                else
                  AppPrimaryButton(
                    label: _sent ? 'Enviado' : 'Enviar enlace',
                    icon: _sent ? Icons.check_circle_rounded : Icons.send_rounded,
                    onPressed: _sent ? null : _handleResetPassword,
                  ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.of(context)
                      .pushNamedAndRemoveUntil(AppRoutes.login, (r) => false),
                  child: const Text('Volver a Login'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
