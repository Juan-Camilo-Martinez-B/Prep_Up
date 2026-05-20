import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:prep_up/core/errors/user_friendly_error.dart';
import 'package:prep_up/core/localization/l10n_extensions.dart';
import 'package:prep_up/core/navigation/app_routes.dart';
import 'package:prep_up/domain/services/auth_service.dart';
import 'package:prep_up/presentation/widgets/app_card.dart';
import 'package:prep_up/presentation/widgets/app_primary_button.dart';
import 'package:prep_up/presentation/widgets/app_screen_scaffold.dart';
import 'package:prep_up/presentation/screens/auth/verify_otp_screen.dart';

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
    final l10n = context.l10n;
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.forgotPasswordEnterEmail)));
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.resetPassword(_emailController.text.trim());
      setState(() => _sent = true);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.forgotPasswordSent)));
        // Navegar a la verificación con OTP
        Navigator.of(context).pushNamed(
          AppRoutes.verifyOtp,
          arguments: {
            'email': _emailController.text.trim(),
            'type': VerifyOtpType.recovery,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        final message = userFriendlyErrorMessage(
          e,
          l10n,
          authAction: AuthAction.resetPassword,
        );
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PopScope(
      canPop: false,
      child: AppScreenScaffold(
        title: '',
        showBackButton: false,
        extendBodyBehindAppBar: true,
        background: const TechBackground(),
        body: ListView(
          children: [
            AppCard(
              title: l10n.forgotPasswordCardTitle,
              subtitle: l10n.forgotPasswordCardSubtitle,
              leading: Icon(
                Icons.refresh_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    inputFormatters: [
                      FilteringTextInputFormatter.deny(RegExp(r'\s')),
                    ],
                    decoration: InputDecoration(
                      labelText: l10n.emailLabel,
                      prefixIcon: const Icon(Icons.alternate_email_rounded),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_isLoading)
                    const CircularProgressIndicator()
                  else
                    AppPrimaryButton(
                      label: _sent
                          ? l10n.forgotPasswordSentShort
                          : l10n.forgotPasswordSendLink,
                      icon: _sent
                          ? Icons.check_circle_rounded
                          : Icons.send_rounded,
                      onPressed: _sent ? null : _handleResetPassword,
                    ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil(AppRoutes.login, (r) => false),
                    child: Text(l10n.forgotPasswordBackToLogin),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
