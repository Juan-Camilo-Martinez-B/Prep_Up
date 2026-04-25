import 'package:flutter/material.dart';
import 'package:prep_up/core/localization/l10n_extensions.dart';
import 'package:prep_up/core/navigation/app_routes.dart';
import 'package:prep_up/domain/entities/user_model.dart';
import 'package:prep_up/domain/services/auth_service.dart';
import 'package:prep_up/domain/services/relational_database_service.dart';
import 'package:prep_up/domain/services/supabase_database_service.dart';
import 'package:prep_up/presentation/widgets/app_card.dart';
import 'package:prep_up/presentation/widgets/app_primary_button.dart';
import 'package:prep_up/presentation/widgets/app_screen_scaffold.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final RelationalDatabaseService _dbService = SupabaseDatabaseService();
  final AuthService _authService = AuthService();
  UserModel? _user;
  int _interviewCount = 0;
  double _avgScore = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final currentUser = _authService.currentUser;
    if (currentUser != null) {
      final user = await _dbService.getUserById(currentUser.id);
      
      final history = await _dbService.getInterviewHistoryForUser(currentUser.id);
      int count = 0;
      double totalScore = 0;
      
      for (final session in history) {
        final result = await _dbService.getInterviewResultForSession(session.id);
        if (result != null) {
          totalScore += result.score;
          count++;
        }
      }
      
      if (mounted) {
        setState(() {
          _user = user;
          _interviewCount = count;
          _avgScore = count > 0 ? totalScore / count : 0;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showEditProfileModal() {
    if (_user == null) return;
    
    final nameController = TextEditingController(text: _user!.displayName);
    final occupationController = TextEditingController(text: _user!.occupation ?? '');
    final phoneController = TextEditingController(text: _user!.phone ?? '');
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final l10n = context.l10n;
        
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
                'Editar Perfil', // TODO: Move to .arb in Phase 7
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Nombre', // TODO: Move to .arb in Phase 7
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: occupationController,
                decoration: InputDecoration(
                  labelText: 'Ocupación', // TODO: Move to .arb in Phase 7
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.work_outline_rounded),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Teléfono', // TODO: Move to .arb in Phase 7
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 24),
              AppPrimaryButton(
                label: l10n.genericSave,
                onPressed: () async {
                  final updatedUser = _user!.copyWith(
                    displayName: nameController.text.trim(),
                    occupation: occupationController.text.trim(),
                    phone: phoneController.text.trim(),
                    updatedAt: DateTime.now(),
                  );
                  
                  // Show loading dialog
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (c) => const Center(child: CircularProgressIndicator()),
                  );
                  
                  await _dbService.upsertUser(updatedUser);
                  
                  // Dismiss loading and bottom sheet
                  if (context.mounted) {
                    Navigator.pop(context); // close dialog
                    Navigator.pop(context); // close sheet
                    setState(() {
                      _user = updatedUser;
                    });
                  }
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
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
            subtitle: _user?.occupation ?? l10n.profileDemoSubtitle,
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
            child: Column(
              children: [
                _StatRow(
                  leftLabel: l10n.profileStatInterviews,
                  leftValue: _interviewCount.toString(),
                  rightLabel: l10n.profileStatAvgScore,
                  rightValue: _avgScore.toStringAsFixed(0),
                ),
                const SizedBox(height: 10),
                _StatRow(
                  leftLabel: l10n.profileStatStreak,
                  leftValue: '0',
                  rightLabel: l10n.profileStatLevel,
                  rightValue: _interviewCount > 5
                      ? 'Pro' // Temporarily hardcoded, move to .arb in Phase 7
                      : 'Rookie',
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AppCard(
            title: l10n.profileAchievementsTitle,
            subtitle: l10n.profileAchievementsSubtitle,
            leading: Icon(Icons.emoji_events_rounded, color: scheme.secondary),
            child: Column(
              children: [
                _AchievementTile(
                  icon: Icons.bolt_rounded,
                  title: l10n.profileAchievementFirstWeekTitle,
                  subtitle: l10n.profileAchievementFirstWeekSubtitle,
                ),
                const SizedBox(height: 10),
                _AchievementTile(
                  icon: Icons.psychology_alt_rounded,
                  title: l10n.profileAchievementAiModeTitle,
                  subtitle: l10n.profileAchievementAiModeSubtitle,
                ),
              ],
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

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: scheme.primary.withValues(alpha: 0.12),
          ),
          child: Icon(icon, color: scheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
