import 'package:flutter/material.dart';
import 'package:prep_up/navigation/app_routes.dart';
import 'package:prep_up/widgets/app_card.dart';
import 'package:prep_up/widgets/app_primary_button.dart';
import 'package:prep_up/widgets/app_screen_scaffold.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  var _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
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
            subtitle: 'Te enviaremos un enlace (simulado)',
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
                AppPrimaryButton(
                  label: _sent ? 'Enviado' : 'Enviar enlace',
                  icon: _sent ? Icons.check_circle_rounded : Icons.send_rounded,
                  onPressed: _sent
                      ? null
                      : () {
                          // TODO: integrar recuperación de contraseña con backend.
                          setState(() => _sent = true);
                        },
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
