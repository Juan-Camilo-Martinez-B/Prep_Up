import 'package:flutter/material.dart';
import 'package:prep_up/core/localization/l10n_extensions.dart';
import 'package:prep_up/core/navigation/app_routes.dart';
import 'package:prep_up/domain/entities/interview_session_model.dart';
import 'package:prep_up/domain/services/auth_service.dart';
import 'package:prep_up/domain/services/relational_database_service.dart';
import 'package:prep_up/domain/services/supabase_database_service.dart';
import 'package:prep_up/presentation/widgets/app_card.dart';
import 'package:prep_up/presentation/widgets/app_primary_button.dart';
import 'package:prep_up/presentation/widgets/app_screen_scaffold.dart';
import 'package:intl/intl.dart';

class InterviewHistoryScreen extends StatefulWidget {
  const InterviewHistoryScreen({super.key});

  @override
  State<InterviewHistoryScreen> createState() => _InterviewHistoryScreenState();
}

class _InterviewHistoryScreenState extends State<InterviewHistoryScreen> {
  final RelationalDatabaseService _dbService = SupabaseDatabaseService();
  final AuthService _authService = AuthService();
  List<InterviewSessionModel> _history = [];
  Map<String, int> _scores = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final user = _authService.currentUser;
    if (user != null) {
      final history = await _dbService.getInterviewHistoryForUser(user.id);
      final Map<String, int> scores = {};

      for (final session in history) {
        final result = await _dbService.getInterviewResultForSession(
          session.id,
        );
        if (result != null) {
          scores[session.id] = result.score;
        }
      }

      if (mounted) {
        setState(() {
          _history = history;
          _scores = scores;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (_isLoading) {
      return const AppScreenScaffold(
        title: '',
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return AppScreenScaffold(
      title: l10n.historyTitle,
      background: const TechBackground(),
      body: ListView(
        children: [
          if (_history.isEmpty)
            AppCard(
              title: l10n.statsNoDataTitle,
              subtitle: l10n.statsNoDataSubtitle,
              child: const SizedBox.shrink(),
            )
          else
            ..._history.map((session) {
              final score = _scores[session.id]?.toString() ?? '--';
              final date = DateFormat.yMMMd(
                Localizations.localeOf(context).languageCode,
              ).format(session.createdAt);

              return Column(
                children: [
                  AppCard(
                    title: session.jobRole,
                    subtitle: '${session.type.name.toUpperCase()} • $date',
                    onTap: () async {
                      final result = await _dbService
                          .getInterviewResultForSession(session.id);
                      if (result != null && context.mounted) {
                        Navigator.of(context).pushNamed(
                          AppRoutes.generalResults,
                          arguments: {'results': result, 'session': session},
                        );
                      }
                    },
                    leading: _ScoreBadge(score: score),
                    trailing: const Icon(Icons.arrow_forward_rounded),
                  ),
                  const SizedBox(height: 12),
                ],
              );
            }),
          const SizedBox(height: 12),
          AppPrimaryButton(
            label: l10n.backToDashboard,
            icon: Icons.home_rounded,
            onPressed: () => Navigator.of(
              context,
            ).pushNamedAndRemoveUntil(AppRoutes.dashboard, (r) => false),
          ),
        ],
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({required this.score});

  final String score;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final value = int.tryParse(score) ?? 0;
    final color = value >= 80
        ? scheme.primary
        : value >= 70
        ? scheme.secondary
        : scheme.error;

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.16),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Center(
        child: Text(
          score,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(color: color),
        ),
      ),
    );
  }
}
