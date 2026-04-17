import 'package:flutter/material.dart';
import 'package:prep_up/core/localization/interview_l10n.dart';
import 'package:prep_up/core/localization/l10n_extensions.dart';
import 'package:prep_up/core/navigation/app_routes.dart';
import 'package:prep_up/domain/entities/interview_tags.dart';
import 'package:prep_up/presentation/controllers/interview_config_controller.dart';
import 'package:prep_up/presentation/widgets/app_primary_button.dart';
import 'package:prep_up/presentation/widgets/app_screen_scaffold.dart';
import 'package:provider/provider.dart';

class SelectJobRoleScreen extends StatefulWidget {
  const SelectJobRoleScreen({super.key});

  @override
  State<SelectJobRoleScreen> createState() => _SelectJobRoleScreenState();
}

class _SelectJobRoleScreenState extends State<SelectJobRoleScreen> {
  final _searchController = TextEditingController();
  JobRole? _selected;

  @override
  void initState() {
    super.initState();
    _selected = context.read<InterviewConfigController>().config.jobRole;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final query = _searchController.text.trim().toLowerCase();
    final filtered = JobRole.values
        .where(
          (r) => query.isEmpty || r.label(l10n).toLowerCase().contains(query),
        )
        .toList();

    return AppScreenScaffold(
      title: l10n.selectJobRoleTitle,
      background: const TechBackground(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Text(
                  l10n.selectJobRoleHeadline,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.0,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.selectJobRoleSubtitle,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    color: scheme.surfaceBright,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: scheme.primary.withValues(alpha: 0.15),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    border: Border.all(
                      color: scheme.primary.withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      hintText: l10n.selectJobRoleSearchHint,
                      hintStyle: TextStyle(
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w400,
                      ),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(left: 12.0, right: 8.0),
                        child: Icon(
                          Icons.search_rounded,
                          color: scheme.primary,
                          size: 28,
                        ),
                      ),
                      suffixIcon: query.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.close_rounded,
                                color: scheme.onSurfaceVariant,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.selectJobRoleSuggested,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        l10n.selectJobRoleNoResults,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.error,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final role = filtered[index];
                      return GestureDetector(
                        onTap: () {
                          FocusManager.instance.primaryFocus?.unfocus();
                          setState(() => _selected = role);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          alignment: Alignment.centerLeft,
                          decoration: BoxDecoration(
                            gradient: _selected == role
                                ? LinearGradient(
                                    colors: [scheme.primary, scheme.tertiary],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            color: _selected == role
                                ? null
                                : scheme.surfaceBright,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: _selected == role
                                  ? Colors.transparent
                                  : scheme.outlineVariant.withValues(
                                      alpha: 0.4,
                                    ),
                              width: 1.5,
                            ),
                            boxShadow: [
                              if (_selected == role)
                                BoxShadow(
                                  color: scheme.primary.withValues(alpha: 0.4),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                            ],
                          ),
                          child: Row(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: _selected == role
                                      ? Colors.white.withValues(alpha: 0.25)
                                      : scheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  Icons.work_outline_rounded,
                                  color: _selected == role
                                      ? Colors.white
                                      : scheme.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 300),
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium!
                                      .copyWith(
                                        fontWeight: _selected == role
                                            ? FontWeight.bold
                                            : FontWeight.w600,
                                        color: _selected == role
                                            ? scheme.onPrimary
                                            : scheme.onSurface,
                                        fontSize: 16,
                                      ),
                                  child: Text(role.label(l10n)),
                                ),
                              ),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                transitionBuilder: (child, animation) =>
                                    ScaleTransition(
                                      scale: animation,
                                      child: child,
                                    ),
                                child: _selected == role
                                    ? const Icon(
                                        Icons.check_circle_rounded,
                                        color: Colors.white,
                                        size: 24,
                                        key: ValueKey('checked'),
                                      )
                                    : Icon(
                                        Icons.radio_button_unchecked_rounded,
                                        color: scheme.onSurfaceVariant
                                            .withValues(alpha: 0.4),
                                        size: 24,
                                        key: const ValueKey('unchecked'),
                                      ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                AppPrimaryButton(
                  label: l10n.genericContinue,
                  icon: Icons.arrow_forward_rounded,
                  onPressed: () {
                    if (_selected == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.selectJobRoleError),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }
                    context.read<InterviewConfigController>().setJobRole(
                      _selected!,
                    );
                    Navigator.of(
                      context,
                    ).pushNamed(AppRoutes.interviewConfiguration);
                  },
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    l10n.genericBack,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
