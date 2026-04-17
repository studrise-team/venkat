import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';
import '../services/firebase_service.dart';
import 'shared_widgets.dart';

class VideoClassesPage extends StatelessWidget {
  final String exam;
  final String? subject;
  const VideoClassesPage({super.key, required this.exam, this.subject});

  @override
  Widget build(BuildContext context) {
    return AdminCrudPage(
      exam: exam,
      subject: subject,
      title: 'Video Classes',
      collection: 'video_classes',
      icon: Icons.play_circle_rounded,
      gradient: const LinearGradient(
        colors: [Color(0xFFf7971e), Color(0xFFffd200)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      formBuilder: (data, onSave) =>
          _VideoForm(exam: exam, subject: subject, data: data, onSave: onSave),
      cardBuilder: (doc) => _VideoCard(doc: doc),
    );
  }
}

class _VideoCard extends StatelessWidget {
  final Map<String, dynamic> doc;
  const _VideoCard({required this.doc});

  @override
  Widget build(BuildContext context) {
    final isYouTube = doc['type'] == 'YouTube';
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 70, 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: (isYouTube ? Colors.red : AppColors.primary)
                  .withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isYouTube
                  ? Icons.smart_display_rounded
                  : Icons.drive_folder_upload_rounded,
              color: isYouTube ? Colors.red : AppColors.primary,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: (isYouTube ? Colors.red : AppColors.primary)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(doc['type'] ?? 'YouTube',
                        style: GoogleFonts.outfit(
                            color: isYouTube ? Colors.red : AppColors.primary,
                            fontSize: 9,
                            fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(doc['subject'] ?? '',
                        style: GoogleFonts.outfit(
                            color: AppColors.textSecondary,
                            fontSize: 9,
                            fontWeight: FontWeight.w600)),
                  ),
                ]),
                const SizedBox(height: 6),
                Text(doc['topic'] ?? '',
                    style: GoogleFonts.outfit(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
                if ((doc['description'] ?? '').isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(doc['description'],
                      style: GoogleFonts.outfit(
                          color: AppColors.textSecondary, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoForm extends StatefulWidget {
  final String exam;
  final String? subject;
  final Map<String, dynamic>? data;
  final VoidCallback onSave;
  const _VideoForm({required this.exam, this.subject, this.data, required this.onSave});

  @override
  State<_VideoForm> createState() => _VideoFormState();
}

class _VideoFormState extends State<_VideoForm> {
  late final TextEditingController _subjectCtrl;
  late final TextEditingController _topicCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _linkCtrl;
  String _videoType = 'YouTube';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final d = widget.data;
    _subjectCtrl = TextEditingController(text: d?['subject'] ?? widget.subject ?? '');
    _topicCtrl = TextEditingController(text: d?['topic'] ?? '');
    _descCtrl = TextEditingController(text: d?['description'] ?? '');
    _linkCtrl = TextEditingController(text: d?['link'] ?? '');
    _videoType = d?['type'] ?? 'YouTube';
  }

  @override
  void dispose() {
    for (var c in [_subjectCtrl, _topicCtrl, _descCtrl, _linkCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_topicCtrl.text.trim().isEmpty) {
      showAdminSnackBar(context, 'Topic is required.', type: AdminSnackType.warning);
      return;
    }
    if (_linkCtrl.text.trim().isEmpty) {
      showAdminSnackBar(context, 'Video link is required.', type: AdminSnackType.warning);
      return;
    }
    setState(() => _loading = true);
    try {
      final Map<String, dynamic> payload = {
        'exam': widget.exam,
        'subject': widget.subject ?? _subjectCtrl.text.trim(),
        'topic': _topicCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'link': _linkCtrl.text.trim(),
        'type': _videoType,
      };
      final id = widget.data?['id'];
      if (id != null) {
        await FirebaseService().updateDocument('video_classes', id, payload);
      } else {
        await FirebaseService().addDocument('video_classes', payload);
      }
      if (mounted) {
        showAdminSnackBar(context, 'Video Class saved successfully!');
        widget.onSave();
      }
    } catch (e) {
      if (mounted) {
        showAdminSnackBar(context, 'Error saving: $e', type: AdminSnackType.error);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.textMuted,
                      borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 18),
            Text(
                widget.data == null ? 'Add Video Class' : 'Edit Video Class',
                style: GoogleFonts.outfit(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 18),
            if (widget.subject == null) ...[
              AdminSheetField(controller: _subjectCtrl, label: 'Subject', icon: Icons.subject_rounded, hint: 'e.g. History'),
              const SizedBox(height: 14),
            ],
            AdminSheetField(controller: _topicCtrl, label: 'Topic *', icon: Icons.topic_rounded, hint: 'e.g. Maurya Empire'),
            const SizedBox(height: 14),
            AdminSheetField(controller: _descCtrl, label: 'Description', icon: Icons.info_outline_rounded, hint: 'Brief description', maxLines: 2),
            const SizedBox(height: 14),
            Text('Video Type',
                style: GoogleFonts.outfit(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(children: [
              _TypeChip(
                  label: 'YouTube',
                  icon: Icons.smart_display_rounded,
                  color: Colors.red,
                  selected: _videoType == 'YouTube',
                  onTap: () => setState(() => _videoType = 'YouTube')),
              const SizedBox(width: 12),
              _TypeChip(
                  label: 'Drive',
                  icon: Icons.drive_folder_upload_rounded,
                  color: AppColors.primary,
                  selected: _videoType == 'Drive',
                  onTap: () => setState(() => _videoType = 'Drive')),
            ]),
            const SizedBox(height: 14),
            AdminSheetField(
              controller: _linkCtrl,
              label: 'Video Link *',
              icon: Icons.link_rounded,
              hint: _videoType == 'YouTube'
                  ? 'https://youtube.com/...'
                  : 'https://drive.google.com/...',
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Material(
                color: Colors.transparent,
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: InkWell(
                    onTap: _loading ? null : _save,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_loading)
                            const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                          else
                            const Icon(Icons.save_rounded,
                                color: Colors.white, size: 20),
                          const SizedBox(width: 10),
                          Text(_loading ? 'Saving…' : 'Save',
                              style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _TypeChip(
      {required this.label,
      required this.icon,
      required this.color,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.2) : AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: selected
                    ? color
                    : AppColors.cardBorder),
          ),
          child: Column(children: [
            Icon(icon,
                color: selected ? color : AppColors.textMuted, size: 22),
            const SizedBox(height: 4),
            Text(label,
                style: GoogleFonts.outfit(
                    color: selected ? color : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    );
  }
}
