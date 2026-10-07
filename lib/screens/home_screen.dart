import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/attempt.dart';
import '../models/user.dart';
import '../providers/attempt_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/buttons/primary_button.dart';
import '../widgets/buttons/secondary_button.dart';
import '../widgets/cards/recommendation_home_card.dart';
import 'history_screen.dart';
import 'login_screen.dart';
import 'questions_screen.dart';
import 'simulation_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          SecondaryButton(
            label: 'Cancelar',
            onPressed: () => Navigator.pop(dialogContext, false),
          ),
          PrimaryButton(
            label: 'Cerrar sesión',
            onPressed: () => Navigator.pop(dialogContext, true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authStateProvider.notifier).logout();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.value;
    final attemptsAsync = ref.watch(attemptsProvider);
    final attempts = attemptsAsync.valueOrNull;
    final totalAttempts = attempts?.length ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menú Principal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () => _confirmLogout(context, ref),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _HeroProfileCard(user: user, attempts: attempts),
                const SizedBox(height: AppSpacing.lg),
                const RecommendationHomeCard(),
                _MenuCard(
                  icon: Icons.play_circle_fill,
                  title: 'Empezar Simulacro',
                  subtitle: 'Pon a prueba tus conocimientos con tiempo',
                  badgeText: '40 preguntas • 40m',
                  badgeIcon: Icons.timer_outlined,
                  color: AppColors.success,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SimulationScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                _MenuCard(
                  icon: Icons.quiz,
                  title: 'Ver Preguntas',
                  subtitle: 'Practica con el banco oficial actualizado',
                  badgeText: 'Banco oficial',
                  badgeIcon: Icons.library_books_outlined,
                  color: AppColors.primary,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const QuestionsScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                _MenuCard(
                  icon: Icons.history,
                  title: 'Mi Historial de Simulacros',
                  subtitle: 'Consulta tus estadísticas y resultados',
                  badgeText: totalAttempts > 0
                      ? '$totalAttempts realizados'
                      : 'Seguimiento',
                  badgeIcon: Icons.insights_outlined,
                  color: AppColors.warning,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HistoryScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroProfileCard extends StatelessWidget {
  final User? user;
  final List<Attempt>? attempts;

  const _HeroProfileCard({required this.user, this.attempts});

  @override
  Widget build(BuildContext context) {
    final totalAttempts = attempts?.length ?? 0;
    final bestScore = attempts != null && attempts!.isNotEmpty
        ? attempts!.map((a) => a.score).reduce((max, s) => s > max ? s : max)
        : null;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.soft,
        border: Border.all(color: AppColors.border),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.08),
            AppColors.surface,
          ],
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    width: 2.5,
                  ),
                  boxShadow: AppShadows.soft,
                ),
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    user?.name.isNotEmpty == true
                        ? user!.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 22,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¡Hola, ${user?.name ?? 'Postulante'}!',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.infoSoftBg,
                            borderRadius: BorderRadius.circular(AppRadius.full),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              width: 0.8,
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.verified_user_outlined,
                                size: 12,
                                color: AppColors.primary,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'MTC • Brevete A-I',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _QuickStatItem(
                  icon: Icons.assignment_turned_in_outlined,
                  label: 'Simulacros',
                  value: totalAttempts > 0 ? '$totalAttempts dados' : '0 listos',
                  color: AppColors.primary,
                ),
              ),
              Container(width: 1, height: 38, color: AppColors.border),
              Expanded(
                child: _QuickStatItem(
                  icon: Icons.emoji_events_outlined,
                  label: 'Mejor récord',
                  value: bestScore != null ? '$bestScore / 40' : '-- / 40',
                  color: bestScore != null && bestScore >= 35
                      ? AppColors.success
                      : AppColors.warning,
                ),
              ),
              Container(width: 1, height: 38, color: AppColors.border),
              const Expanded(
                child: _QuickStatItem(
                  icon: Icons.check_circle_outline,
                  label: 'Meta MTC',
                  value: '35 / 40 mín.',
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickStatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _QuickStatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 10.5,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final String? badgeText;
  final IconData? badgeIcon;

  const _MenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.badgeText,
    this.badgeIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.soft,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.08),
            AppColors.surface,
          ],
        ),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(icon, size: 28, color: color),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (badgeText != null) ...[
                            const SizedBox(width: AppSpacing.xs),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.full),
                                border: Border.all(
                                  color: color.withValues(alpha: 0.25),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (badgeIcon != null) ...[
                                    Icon(badgeIcon, size: 11, color: color),
                                    const SizedBox(width: 3),
                                  ],
                                  Text(
                                    badgeText!,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Icon(Icons.chevron_right, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
