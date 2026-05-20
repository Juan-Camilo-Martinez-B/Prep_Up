import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:prep_up/core/errors/user_friendly_error.dart';
import 'package:prep_up/core/localization/l10n_extensions.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:prep_up/core/navigation/app_routes.dart';
import 'package:prep_up/domain/services/auth_service.dart';
import 'package:prep_up/domain/services/auth_preferences.dart';
import 'package:prep_up/presentation/widgets/app_card.dart';
import 'package:prep_up/presentation/widgets/app_logo.dart';
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
        final l10n = context.l10n;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.loginEmailVerified),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
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

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  Future<void> _handleLogin() async {
    final l10n = context.l10n;
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.authFillAllFields)));
      return;
    }

    if (!_isValidEmail(email)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.authInvalidEmail)));
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.signIn(email: email, password: password);
      await AuthPreferences.setRememberSession(_rememberSession);

      if (mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(AppRoutes.dashboard, (route) => false);
      }
    } on AuthException catch (e) {
      debugPrint('AuthException during login: $e');
      if (mounted) {
        final message = userFriendlyErrorMessage(
          e,
          l10n,
          authAction: AuthAction.login,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      debugPrint('Unexpected error during login: $e');
      if (mounted) {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: scheme.surface.withValues(alpha: isDark ? 0.3 : 0.6),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: scheme.surfaceContainerHighest.withValues(
            alpha: isDark ? 0.4 : 0.8,
          ),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: scheme.primary, width: 1.5),
      ),
      labelStyle: TextStyle(color: scheme.onSurfaceVariant),
      prefixIconColor: scheme.primary,
    );

    return PopScope(
      canPop: true,
      child: AppScreenScaffold(
        title: '',
        showBackButton: false,
        extendBodyBehindAppBar: true,
        background: const TechBackground(),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 48,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            AppLogo(size: 80),
                            const SizedBox(height: 24),
                            Text(
                              l10n.loginTitle,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.loginSubtitle,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 48),
                      // Main Form Card
                      AppCard(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              inputFormatters: [
                                FilteringTextInputFormatter.deny(RegExp(r'\s')),
                              ],
                              decoration: inputDecoration.copyWith(
                                labelText: l10n.emailLabel,
                                prefixIcon: const Icon(
                                  Icons.alternate_email_rounded,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _passwordController,
                              obscureText: _obscure,
                              inputFormatters: [
                                FilteringTextInputFormatter.deny(
                                  RegExp(r'^\s+'),
                                ),
                              ],
                              decoration: inputDecoration.copyWith(
                                labelText: l10n.passwordLabel,
                                prefixIcon: const Icon(
                                  Icons.lock_outline_rounded,
                                ),
                                suffixIcon: IconButton(
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure),
                                  icon: Icon(
                                    _obscure
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              runSpacing: 8,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: Checkbox(
                                        value: _rememberSession,
                                        onChanged: (v) => setState(
                                          () => _rememberSession = v ?? false,
                                        ),
                                        activeColor: scheme.primary,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      l10n.rememberSession,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: scheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(
                                    context,
                                  ).pushNamed(AppRoutes.forgotPassword),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    minimumSize: Size.zero,
                                  ),
                                  child: Text(
                                    l10n.forgotPasswordLink,
                                    style: TextStyle(
                                      color: scheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            if (_isLoading)
                              const Center(child: CircularProgressIndicator())
                            else
                              AppPrimaryButton(
                                label: l10n.loginButton,
                                icon: Icons.arrow_forward_rounded,
                                onPressed: _handleLogin,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Bottom Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            l10n.loginNoAccount,
                            style: TextStyle(color: scheme.onSurfaceVariant),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(
                              context,
                            ).pushNamed(AppRoutes.register),
                            child: Text(
                              l10n.loginRegisterHere,
                              style: TextStyle(
                                color: scheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
