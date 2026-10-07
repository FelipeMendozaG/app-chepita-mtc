import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/discussion.dart';
import '../providers/discussion_provider.dart';
import '../services/discussion_service.dart';
import '../theme/app_theme.dart';
import '../widgets/states/custom_empty_state.dart';
import '../widgets/states/custom_error_state.dart';
import '../widgets/states/custom_loading_state.dart';
import 'create_discussion_screen.dart';
import 'discussion_detail_screen.dart';

class DiscussionsScreen extends ConsumerWidget {
  const DiscussionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final discussions = ref.watch(discussionsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Debates')),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Nuevo debate',
        onPressed: () async {
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const CreateDiscussionScreen()),
          );
          if (created == true) ref.invalidate(discussionsProvider);
        },
        child: const Icon(Icons.add),
      ),
      body: discussions.when(
        loading: () => const CustomLoadingState(message: 'Cargando debates...'),
        error: (error, stackTrace) => CustomErrorState(
          message: 'Error: $error',
          onRetry: () => ref.invalidate(discussionsProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const CustomEmptyState(
              icon: Icons.forum_outlined,
              title: 'Aún no hay debates',
              subtitle: 'Sé el primero en iniciar una conversación',
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(discussionsProvider);
              await ref.read(discussionsProvider.future);
            },
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                96,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) =>
                  _DiscussionCard(discussion: items[index]),
            ),
          );
        },
      ),
    );
  }
}

class _DiscussionCard extends StatelessWidget {
  final Discussion discussion;
  const _DiscussionCard({required this.discussion});

  @override
  Widget build(BuildContext context) {
    final imageUri = DiscussionService.resolveImageUri(discussion.imageUrl);
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DiscussionDetailScreen(discussion: discussion),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    child: Text(
                      discussion.author.name.isNotEmpty
                          ? discussion.author.name[0].toUpperCase()
                          : '?',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      discussion.author.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  _StatusChip(closed: discussion.isClosed),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _elapsed(discussion.createdAt),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (imageUri != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Image.network(
                    imageUri.toString(),
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              Text(
                discussion.title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                discussion.content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.textMuted, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _elapsed(DateTime? date) {
    if (date == null) return 'Fecha no disponible';
    final difference = DateTime.now().difference(date);
    if (difference.inMinutes < 1) return 'Hace un momento';
    if (difference.inHours < 1) return 'Hace ${difference.inMinutes} min';
    if (difference.inDays < 1) return 'Hace ${difference.inHours} h';
    if (difference.inDays < 30) return 'Hace ${difference.inDays} días';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class _StatusChip extends StatelessWidget {
  final bool closed;
  const _StatusChip({required this.closed});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(closed ? 'Cerrado' : 'Abierto'),
      labelStyle: TextStyle(
        fontSize: 12,
        color: closed ? AppColors.textMuted : AppColors.success,
        fontWeight: FontWeight.w700,
      ),
      backgroundColor: closed
          ? AppColors.border
          : AppColors.success.withValues(alpha: 0.12),
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
    );
  }
}
