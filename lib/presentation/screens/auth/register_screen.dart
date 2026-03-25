import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:prep_up/core/navigation/app_routes.dart';
import 'package:prep_up/domain/services/auth_service.dart';
import 'package:prep_up/presentation/widgets/app_card.dart';
import 'package:prep_up/presentation/widgets/app_primary_button.dart';
import 'package:prep_up/presentation/widgets/app_screen_scaffold.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _occupationController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  var _obscure = true;
  var _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _occupationController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _nameController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _occupationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        metadata: {
          'full_name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'occupation': _occupationController.text.trim(),
        },
        emailRedirectTo: 'io.supabase.prepup://login-callback',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            duration: Duration(seconds: 6),
            content: Text(
              'Registro exitoso. Se ha enviado un correo de confirmación. Por favor verifícalo antes de iniciar sesión.',
            ),
          ),
        );
        // Redirigir a login en lugar de dashboard
        Navigator.of(context).pushReplacementNamed(AppRoutes.login);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al registrarse: ${e.toString()}')),
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
      title: 'Crear cuenta',
      background: const TechBackground(),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          AppCard(
            title: 'Perfil Profesional',
            subtitle: 'Únete a la plataforma de entrenamiento líder',
            leading: Icon(
              Icons.person_add_alt_1_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre Completo',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo Electrónico',
                    prefixIcon: Icon(Icons.alternate_email_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Número de Teléfono',
                    prefixIcon: Icon(Icons.phone_android_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _occupationController,
                  decoration: const InputDecoration(
                    labelText: 'Ocupación / Cargo',
                    prefixIcon: Icon(Icons.work_outline_rounded),
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
                const SizedBox(height: 24),
                if (_isLoading)
                  const CircularProgressIndicator()
                else
                  AppPrimaryButton(
                    label: 'Registrarse',
                    icon: Icons.how_to_reg_rounded,
                    onPressed: _handleRegister,
                  ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('¿Ya eres miembro?'),
                    TextButton(
                      onPressed: () =>
                          Navigator.of(context).pushNamed(AppRoutes.login),
                      child: const Text('Inicia Sesión'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
