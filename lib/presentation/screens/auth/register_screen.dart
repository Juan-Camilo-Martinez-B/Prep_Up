import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:prep_up/core/localization/l10n_extensions.dart';
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

  bool _isPasswordStrong(String password) {
    if (password.length < 8) return false;
    if (!password.contains(RegExp(r'[A-Z]'))) return false;
    if (!password.contains(RegExp(r'[a-z]'))) return false;
    if (!password.contains(RegExp(r'[0-9]'))) return false;
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) return false;
    return true;
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  Future<void> _handleRegister() async {
    final l10n = context.l10n;
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final occupation = _occupationController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty ||
        email.isEmpty ||
        phone.isEmpty ||
        occupation.isEmpty ||
        password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.authFillAllFields)));
      return;
    }

    if (!_isValidEmail(email)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.registerInvalidEmail)));
      return;
    }

    if (phone.length != 10) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.registerPhoneLengthError)));
      return;
    }

    if (!_isPasswordStrong(password)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.registerWeakPassword)));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Verificar duplicados antes de intentar el registro
      final emailExists = await _authService.isEmailRegistered(email);
      if (emailExists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.registerEmailAlreadyExists),
              backgroundColor: Colors.orange,
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      await _authService.signUp(
        email: email,
        password: password,
        metadata: {'full_name': name, 'phone': phone, 'occupation': occupation},
        emailRedirectTo: 'io.supabase.prepup://login-callback',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 6),
            content: Text(l10n.registerSuccess),
          ),
        );
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(AppRoutes.dashboard, (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.registerError}: ${e.toString()}')),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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

    return AppScreenScaffold(
      title: '', // Emptied for immersive effect
      showBackButton: true,
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
                          Icon(
                            Icons.person_add_alt_1_rounded,
                            size: 64,
                            color: scheme.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.registerTitle,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.registerSubtitle,
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
                            controller: _nameController,
                            inputFormatters: [
                              FilteringTextInputFormatter.deny(RegExp(r'^\s+')),
                            ],
                            decoration: inputDecoration.copyWith(
                              labelText: l10n.fullNameLabel,
                              prefixIcon: const Icon(Icons.badge_outlined),
                            ),
                          ),
                          const SizedBox(height: 16),
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
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10),
                            ],
                            decoration: inputDecoration.copyWith(
                              labelText: l10n.phoneLabel,
                              prefixIcon: const Icon(
                                Icons.phone_android_rounded,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _occupationController,
                            inputFormatters: [
                              FilteringTextInputFormatter.deny(RegExp(r'^\s+')),
                            ],
                            decoration: inputDecoration.copyWith(
                              labelText: l10n.occupationLabel,
                              prefixIcon: const Icon(
                                Icons.work_outline_rounded,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscure,
                            inputFormatters: [
                              FilteringTextInputFormatter.deny(RegExp(r'\s')),
                            ],
                            decoration: inputDecoration.copyWith(
                              labelText: l10n.passwordLabel,
                              prefixIcon: const Icon(Icons.password_rounded),
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
                          const SizedBox(height: 32),
                          if (_isLoading)
                            const Center(child: CircularProgressIndicator())
                          else
                            AppPrimaryButton(
                              label: l10n.registerButton,
                              icon: Icons.how_to_reg_rounded,
                              onPressed: _handleRegister,
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
                          l10n.registerAlreadyMember,
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(
                            context,
                          ).pushReplacementNamed(AppRoutes.login),
                          child: Text(
                            l10n.loginButton,
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
    );
  }
}
