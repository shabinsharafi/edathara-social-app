import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../widgets/shared_widgets.dart';

class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key});

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  FeedbackType _type = FeedbackType.suggestion;
  final _msgCtrl = TextEditingController();
  File? _image;
  bool _isLoading = false;
  bool _submitted = false;

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: AppColors.mint),
              title: const Text('Camera'),
              onTap: () async {
                Navigator.pop(ctx);
                final x = await picker.pickImage(source: ImageSource.camera, imageQuality: 75);
                if (x != null) setState(() => _image = File(x.path));
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.mint),
              title: const Text('Gallery'),
              onTap: () async {
                Navigator.pop(ctx);
                final x = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
                if (x != null) setState(() => _image = File(x.path));
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_msgCtrl.text.trim().isEmpty) {
      showError(context, 'Please write your ${_type.name}');
      return;
    }
    final user = ref.read(currentAppUserProvider).valueOrNull;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(firestoreServiceProvider).submitFeedback(
        userId: user.uid,
        userName: user.name,
        type: _type,
        message: _msgCtrl.text.trim(),
        imageFile: _image,
      );
      if (mounted) setState(() => _submitted = true);
    } catch (e) {
      if (mounted) showError(context, 'Submission failed. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Suggestions & Complaints')),
      backgroundColor: AppColors.cream,
      body: _submitted ? _buildSuccess() : _buildForm(),
    );
  }

  Widget _buildSuccess() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.mint.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_outline,
                  color: AppColors.mint, size: 60),
            ).animate().scale(),
            const SizedBox(height: 20),
            Text('Thank you!', style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: 8),
            Text(
              'Your ${_type.name} has been submitted to the admin team. We appreciate your feedback!',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.slate, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              label: 'Submit Another',
              onPressed: () => setState(() {
                _submitted = false;
                _msgCtrl.clear();
                _image = null;
                _type = FeedbackType.suggestion;
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type Selector
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.mist,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: FeedbackType.values.map((t) {
                final isSelected = _type == t;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _type = t),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (t == FeedbackType.suggestion
                                ? AppColors.mint : AppColors.error)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            t == FeedbackType.suggestion ? '💡' : '⚠️',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            t == FeedbackType.suggestion ? 'Suggestion' : 'Complaint',
                            style: TextStyle(
                              color: isSelected ? Colors.white : AppColors.slate,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),

          // Message
          Text(
            'Your ${_type.name}',
            style: const TextStyle(fontWeight: FontWeight.w600,
                fontSize: 14, color: AppColors.slate),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _msgCtrl,
            maxLines: 6,
            decoration: InputDecoration(
              hintText: _type == FeedbackType.suggestion
                  ? 'Share your idea to improve the club...'
                  : 'Describe the issue you faced...',
            ),
          ),
          const SizedBox(height: 20),

          // Image Attach
          const Text('Attach Photo (optional)',
              style: TextStyle(fontWeight: FontWeight.w600,
                  fontSize: 14, color: AppColors.slate)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: _image != null ? 200 : 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: _image != null
                    ? Colors.transparent
                    : AppColors.mist,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _image != null ? AppColors.mint : AppColors.border,
                  width: _image != null ? 2 : 1,
                  style: BorderStyle.solid,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: _image != null
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(_image!, fit: BoxFit.cover),
                        Positioned(
                          top: 8, right: 8,
                          child: GestureDetector(
                            onTap: () => setState(() => _image = null),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(Icons.close,
                                  color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_photo_alternate_outlined,
                            size: 36, color: AppColors.slate),
                        const SizedBox(height: 8),
                        Text('Tap to add a photo',
                            style: TextStyle(color: AppColors.slate.withOpacity(0.7),
                                fontSize: 13)),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 32),

          PrimaryButton(
            label: 'Submit ${_type == FeedbackType.suggestion ? 'Suggestion' : 'Complaint'}',
            fullWidth: true,
            isLoading: _isLoading,
            icon: Icons.send_outlined,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
