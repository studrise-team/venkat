import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';
import '../services/firebase_service.dart';
import 'shared_widgets.dart';

class PreviousPapersPage extends StatelessWidget {
  final String exam;
  const PreviousPapersPage({super.key, required this.exam});

  @override
  Widget build(BuildContext context) {
    return AdminCrudPage(
      exam: exam,
      title: 'Previous Papers',
      collection: 'previous_papers',
      icon: Icons.description_rounded,
      gradient: AppColors.accentGradient,
      formBuilder: (data, onSave) =>
          _PaperForm(exam: exam, data: data, onSave: onSave),
      cardBuilder: (doc) => _PaperCard(doc: doc),
    );
  }
}

class _PaperCard extends StatelessWidget {
  final Map<String, dynamic> doc;
  const _PaperCard({required this.doc});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 70, 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                gradient: AppColors.accentGradient,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(doc['year']?.toString() ?? '',
                  style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(doc['subject'] ?? '',
                  style: GoogleFonts.outfit(
                      color: AppColors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600)),
            ),
          ]),
          const SizedBox(height: 8),
          Text(doc['topic'] ?? '',
              style: GoogleFonts.outfit(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
          if ((doc['description'] ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(doc['description'],
                style: GoogleFonts.outfit(
                    color: AppColors.textSecondary, fontSize: 12, height: 1.4),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ],
          if ((doc['driveLink'] ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.link_rounded, color: AppColors.accent, size: 14),
              const SizedBox(width: 4),
              Text('Drive Link',
                  style: GoogleFonts.outfit(
                      color: AppColors.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ]),
          ],
        ],
      ),
    );
  }
}

class _PaperForm extends StatefulWidget {
  final String exam;
  final Map<String, dynamic>? data;
  final VoidCallback onSave;
  const _PaperForm({required this.exam, this.data, required this.onSave});

  @override
  State<_PaperForm> createState() => _PaperFormState();
}

class _PaperFormState extends State<_PaperForm> {
  late final TextEditingController _yearCtrl;
  late final TextEditingController _subjectCtrl;
  late final TextEditingController _topicCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _linkCtrl;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final d = widget.data;
    _yearCtrl = TextEditingController(text: d?['year']?.toString() ?? '');
    _subjectCtrl = TextEditingController(text: d?['subject'] ?? '');
    _topicCtrl = TextEditingController(text: d?['topic'] ?? '');
    _descCtrl = TextEditingController(text: d?['description'] ?? '');
    _linkCtrl = TextEditingController(text: d?['driveLink'] ?? '');
  }

  @override
  void dispose() {
    for (var c in [_yearCtrl, _subjectCtrl, _topicCtrl, _descCtrl, _linkCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_topicCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      final payload = {
        'exam': widget.exam,
        'year': _yearCtrl.text.trim(),
        'subject': _subjectCtrl.text.trim(),
        'topic': _topicCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'driveLink': _linkCtrl.text.trim(),
      };
      final id = widget.data?['id'];
      if (id != null) {
        await FirebaseService().updateDocument('previous_papers', id, payload);
      } else {
        await FirebaseService().addDocument('previous_papers', payload);
      }
      widget.onSave();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminFormSheet(
      title: widget.data == null ? 'Add Previous Paper' : 'Edit Paper',
      isLoading: _loading,
      onSave: _save,
      fields: [
        AdminSheetField(controller: _yearCtrl, label: 'Year', icon: Icons.calendar_today_rounded, hint: 'e.g. 2024'),
        AdminSheetField(controller: _subjectCtrl, label: 'Subject', icon: Icons.subject_rounded, hint: 'e.g. Polity'),
        AdminSheetField(controller: _topicCtrl, label: 'Topic *', icon: Icons.topic_rounded, hint: 'e.g. Constitution'),
        AdminSheetField(controller: _descCtrl, label: 'Description', icon: Icons.info_outline_rounded, hint: 'Short description', maxLines: 3),
        AdminSheetField(controller: _linkCtrl, label: 'Google Drive Link', icon: Icons.link_rounded, hint: 'https://drive.google.com/...'),
      ],
    );
  }
}
