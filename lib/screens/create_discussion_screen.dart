import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/discussion_service.dart';
import '../theme/app_theme.dart';
import '../widgets/buttons/primary_button.dart';

class CreateDiscussionScreen extends StatefulWidget {
  const CreateDiscussionScreen({super.key});

  @override
  State<CreateDiscussionScreen> createState() => _CreateDiscussionScreenState();
}

class _CreateDiscussionScreenState extends State<CreateDiscussionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _service = DiscussionService();
  String? _imagePath;
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) setState(() => _imagePath = picked.path);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await _service.createDiscussion(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        imagePath: _imagePath,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo crear el debate: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo debate')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Título'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Ingresa un título'
                  : null,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _contentController,
              minLines: 5,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: '¿Qué quieres conversar?',
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Escribe el contenido del debate'
                  : null,
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.image_outlined),
              label: Text(
                _imagePath == null ? 'Adjuntar imagen' : 'Imagen seleccionada',
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: 'Publicar debate',
              isLoading: _saving,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
