import 'package:flutter/material.dart';
import 'package:prep_up/core/errors/user_friendly_error.dart';
import 'package:prep_up/core/localization/l10n_extensions.dart';
import 'package:prep_up/core/navigation/app_routes.dart';
import 'package:prep_up/domain/entities/user_model.dart';
import 'package:prep_up/domain/services/auth_service.dart';
import 'package:prep_up/domain/services/relational_database_service.dart';
import 'package:prep_up/presentation/widgets/app_card.dart';
import 'package:prep_up/presentation/widgets/app_primary_button.dart';
import 'package:prep_up/presentation/widgets/app_screen_scaffold.dart';
import 'package:prep_up/core/localization/interview_l10n.dart';
import 'package:provider/provider.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  UserModel? _user;
  int _interviewCount = 0;
  double _avgScore = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  Future<void> _loadUserData() async {
    final authService = context.read<AuthService>();
    final dbService = context.read<RelationalDatabaseService>();
    final l10n = context.l10n;

    final currentUser = authService.currentUser;
    if (currentUser == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final user = await dbService.getUserById(currentUser.id);
      final history = await dbService.getInterviewHistoryForUser(
        currentUser.id,
      );

      final results = await Future.wait(
        history.map((s) => dbService.getInterviewResultForSession(s.id)),
      );

      var count = 0;
      var totalScore = 0.0;

      for (final result in results) {
        if (result != null) {
          totalScore += result.overallScore;
          count++;
        }
      }

      if (!mounted) return;
      setState(() {
        _user = user;
        _interviewCount = count;
        _avgScore = count > 0 ? totalScore / count : 0;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      final message = userFriendlyErrorMessage(e, l10n);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _showEditProfileModal() {
    if (_user == null) return;

    final nameController = TextEditingController(text: _user!.displayName);
    final phoneController = TextEditingController(text: _user!.phone ?? '');
    UserOccupation? selectedOccupation = _user!.occupation;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final l10n = context.l10n;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.profileEditTitle,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: l10n.profileEditName,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<UserOccupation>(
                value: selectedOccupation,
                onChanged: (val) {
                  setModalState(() {
                    selectedOccupation = val;
                  });
                },
                items: UserOccupation.values.map((occ) {
                  return DropdownMenuItem(
                    value: occ,
                    child: Text(occ.label(l10n)),
                  );
                }).toList(),
                decoration: InputDecoration(
                  labelText: l10n.profileEditOccupation,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.work_outline_rounded),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: l10n.profileEditPhone,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 24),
              AppPrimaryButton(
                label: l10n.genericSave,
                onPressed: () async {
                  final updatedUser = _user!.copyWith(
                    displayName: nameController.text.trim(),
                    occupation: selectedOccupation,
                    phone: phoneController.text.trim(),
                    updatedAt: DateTime.now(),
                  );

                  // Show loading dialog
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (c) =>
                        const Center(child: CircularProgressIndicator()),
                  );

                  try {
                    final dbService = context.read<RelationalDatabaseService>();
                    await dbService.upsertUser(updatedUser);
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    Navigator.pop(context);
                    setState(() {
                      _user = updatedUser;
                    });
                  } catch (e) {
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    final message = userFriendlyErrorMessage(e, l10n);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(message),
                        backgroundColor: Theme.of(context).colorScheme.error,
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    if (_isLoading) {
      return const AppScreenScaffold(
        title: '',
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return AppScreenScaffold(
      title: l10n.profileTitle,
      background: const TechBackground(),
      body: ListView(
        children: [
          AppCard(
            title: _user?.displayName ?? l10n.profileDemoName,
            subtitle: _user?.occupation?.label(l10n),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    scheme.primary.withValues(alpha: 0.35),
                    scheme.secondary.withValues(alpha: 0.30),
                  ],
                ),
              ),
              child: Icon(
                Icons.person_rounded,
                color: scheme.onPrimaryContainer,
              ),
            ),
            trailing: IconButton(
              icon: Icon(Icons.edit_rounded, color: scheme.primary),
              onPressed: _showEditProfileModal,
            ),
            child: _StatRow(
              leftLabel: l10n.profileStatInterviews,
              leftValue: _interviewCount.toString(),
              rightLabel: l10n.profileStatAvgScore,
              rightValue: _avgScore.toStringAsFixed(0),
            ),
          ),
          const SizedBox(height: 14),
          AppPrimaryButton(
            label: l10n.backToDashboard,
            icon: Icons.home_rounded,
            onPressed: () => Navigator.of(
              context,
            ).pushNamedAndRemoveUntil(AppRoutes.dashboard, (route) => false),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.leftLabel,
    required this.leftValue,
    required this.rightLabel,
    required this.rightValue,
  });

  final String leftLabel;
  final String leftValue;
  final String rightLabel;
  final String rightValue;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: _MiniStat(label: leftLabel, value: leftValue),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MiniStat(label: rightLabel, value: rightValue),
        ),
        const SizedBox(width: 0),
        Icon(
          Icons.auto_awesome_rounded,
          color: scheme.primary.withValues(alpha: 0.6),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelMedium),
          const SizedBox(height: 6),
          Text(value, style: theme.textTheme.headlineSmall),
        ],
      ),
    );
  }
}

