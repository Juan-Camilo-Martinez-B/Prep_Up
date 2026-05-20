import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:prep_up/core/errors/user_friendly_error.dart';
import 'package:prep_up/core/localization/l10n_extensions.dart';
import 'package:prep_up/core/navigation/app_routes.dart';
import 'package:prep_up/domain/services/auth_service.dart';
import 'package:prep_up/presentation/widgets/app_card.dart';
import 'package:prep_up/presentation/widgets/app_primary_button.dart';
import 'package:prep_up/presentation/widgets/app_screen_scaffold.dart';

enum VerifyOtpType { signup, recovery }

class VerifyOtpScreen extends StatefulWidget {
  final String email;
  final VerifyOtpType type;

  const VerifyOtpScreen({
    super.key,
    required this.email,
    this.type = VerifyOtpType.signup,
  });

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  final _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _handleVerify() async {
    final otp = _controllers.map((c) => c.text).join();
    if (otp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa el código completo')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (widget.type == VerifyOtpType.signup) {
        await _authService.verifyEmailOTP(
          email: widget.email.trim(),
          token: otp.trim(),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Correo verificado con éxito!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(AppRoutes.dashboard, (route) => false);
        }
      } else {
        await _authService.verifyRecoveryOTP(
          email: widget.email.trim(),
          token: otp.trim(),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Código validado! Crea tu nueva contraseña.'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pushNamed(AppRoutes.resetPassword);
        }
      }
    } catch (e) {
      if (mounted) {
        final l10n = context.l10n;
        final message = userFriendlyErrorMessage(e, l10n);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onOtpChanged(int index, String value) {
    // Si se pega un código completo
    if (value.length > 1) {
      final chars = value.split('');
      for (var i = 0; i < chars.length && (index + i) < 6; i++) {
        _controllers[index + i].text = chars[i];
      }
      _focusNodes[index + (chars.length < 6 ? chars.length : 5)].requestFocus();
    } else {
      if (value.isNotEmpty && index < 5) {
        _focusNodes[index + 1].requestFocus();
      }
    }

    if (_controllers.every((c) => c.text.isNotEmpty)) {
      _handleVerify();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return PopScope(
      canPop: false,
      child: AppScreenScaffold(
        title: '',
        showBackButton: false,
        extendBodyBehindAppBar: true,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [scheme.primary.withValues(alpha: 0.05), scheme.surface],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  Hero(
                    tag: 'auth_icon',
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.shield_outlined,
                        size: 60,
                        color: scheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    widget.type == VerifyOtpType.signup
                        ? 'Verifica tu identidad'
                        : 'Recuperar contraseña',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                      children: [
                        TextSpan(
                          text: widget.type == VerifyOtpType.signup
                              ? 'Ingresa el código de 6 dígitos enviado a\n'
                              : 'Hemos enviado un código de seguridad a\n',
                        ),
                        TextSpan(
                          text: widget.email,
                          style: TextStyle(
                            color: scheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  AppCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 24,
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: List.generate(6, (index) {
                            return Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  right: index == 5 ? 0 : 6,
                                ),
                                child: TextField(
                                  controller: _controllers[index],
                                  focusNode: _focusNodes[index],
                                  textAlign: TextAlign.center,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(1),
                                  ],
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: scheme.primary,
                                  ),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: scheme.surfaceContainerHigh,
                                    counterText: '',
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                        color: scheme.outlineVariant.withValues(
                                          alpha: 0.5,
                                        ),
                                        width: 1,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                        color: scheme.primary,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  onChanged: (value) =>
                                      _onOtpChanged(index, value),
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 40),
                        if (_isLoading)
                          const CircularProgressIndicator()
                        else
                          AppPrimaryButton(
                            label: 'Verificar Código',
                            onPressed: _handleVerify,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '¿No recibiste el código? ',
                        style: theme.textTheme.bodyMedium,
                      ),
                      TextButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Código reenviado con éxito'),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Reenviar',
                          style: TextStyle(
                            color: scheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil(AppRoutes.login, (r) => false),
                    child: const Text('Volver al inicio de sesión'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
