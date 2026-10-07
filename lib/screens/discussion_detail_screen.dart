import 'package:flutter/material.dart';

import '../models/discussion.dart';
import '../services/discussion_service.dart';
import '../theme/app_theme.dart';
import '../widgets/buttons/primary_button.dart';

class DiscussionDetailScreen extends StatefulWidget {
  final Discussion discussion;
  const DiscussionDetailScreen({super.key, required this.discussion});

  @override
  State<DiscussionDetailScreen> createState() => _DiscussionDetailScreenState();
}

class _DiscussionDetailScreenState extends State<DiscussionDetailScreen> {
  final _replyController = TextEditingController();
  final _service = DiscussionService();
  bool _sending = false;

  Discussion get discussion => widget.discussion;

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _reply() async {
    if (_replyController.text.trim().isEmpty) return;
    setState(() => _sending = true);
    try {
      await _service.reply(discussion.id, _replyController.text.trim());
      _replyController.clear();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Respuesta enviada')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('No se pudo responder: $error')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _askAction({
    required String title,
    required String label,
    required Future<void> Function(String) action,
  }) async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: InputDecoration(labelText: label),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null || value.isEmpty) return;
    try {
      await action(value);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Acción completada')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo completar la acción: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUri = DiscussionService.resolveImageUri(discussion.imageUrl);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del debate'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'close') {
                _askAction(
                  title: 'Cerrar debate',
                  label: 'Razón del cierre',
                  action: (reason) => _service.close(discussion.id, reason),
                );
              } else {
                _askAction(
                  title: 'Reportar debate',
                  label: 'Motivo del reporte',
                  action: (reason) => _service.report(discussion.id, reason),
                );
              }
            },
            itemBuilder: (_) => [
              if (!discussion.isClosed)
                const PopupMenuItem(
                  value: 'close',
                  child: Text('Cerrar debate'),
                ),
              const PopupMenuItem(value: 'report', child: Text('Reportar')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          if (discussion.isClosed)
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              margin: const EdgeInsets.only(bottom: AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(
                'Este debate está cerrado${discussion.closedReason == null ? '' : ': ${discussion.closedReason}'}.',
              ),
            ),
          if (imageUri != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: Image.network(
                imageUri.toString(),
                height: 220,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          if (imageUri != null) const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              CircleAvatar(
                child: Text(discussion.author.name[0].toUpperCase()),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                discussion.author.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            discussion.title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            discussion.content,
            style: const TextStyle(
              fontSize: 16,
              height: 1.6,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          if (!discussion.isClosed) ...[
            TextField(
              controller: _replyController,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Escribe una respuesta',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              label: 'Responder',
              isLoading: _sending,
              onPressed: _reply,
            ),
          ],
        ],
      ),
    );
  }
}
