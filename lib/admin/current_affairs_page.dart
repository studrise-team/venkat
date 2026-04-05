import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';
import '../services/firebase_service.dart';
import 'shared_widgets.dart';

class CurrentAffairsPage extends StatelessWidget {
  final String exam;
  const CurrentAffairsPage({super.key, required this.exam});

  @override
  Widget build(BuildContext context) {
    return AdminCrudPage(
      exam: exam,
      title: 'Current Affairs',
      collection: 'current_affairs',
      icon: Icons.newspaper_rounded,
      gradient: const LinearGradient(
        colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      formBuilder: (data, onSave) =>
          _CAForm(exam: exam, data: data, onSave: onSave),
      cardBuilder: (doc) => _CACard(doc: doc),
    );
  }
}

class _CACard extends StatelessWidget {
  final Map<String, dynamic> doc;
  const _CACard({required this.doc});

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
            const Icon(Icons.calendar_month_rounded,
                color: AppColors.accentOrange, size: 14),
            const SizedBox(width: 4),
            Text(doc['date'] ?? '',
                style: GoogleFonts.outfit(
                    color: AppColors.accentOrange,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 6),
          Text(doc['title'] ?? '',
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
          if ((doc['link'] ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.link_rounded, color: AppColors.accent, size: 14),
              const SizedBox(width: 4),
              Text('PDF / Drive Link',
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

class _CAForm extends StatefulWidget {
  final String exam;
  final Map<String, dynamic>? data;
  final VoidCallback onSave;
  const _CAForm({required this.exam, this.data, required this.onSave});

  @override
  State<_CAForm> createState() => _CAFormState();
}

class _CAFormState extends State<_CAForm> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _dateCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _linkCtrl;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final d = widget.data;
    _titleCtrl = TextEditingController(text: d?['title'] ?? '');
    _dateCtrl = TextEditingController(text: d?['date'] ?? '');
    _descCtrl = TextEditingController(text: d?['description'] ?? '');
    _linkCtrl = TextEditingController(text: d?['link'] ?? '');
  }

  @override
  void dispose() {
    for (var c in [_titleCtrl, _dateCtrl, _descCtrl, _linkCtrl]) c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) {
      showAdminSnackBar(context, 'Title is required.', type: AdminSnackType.warning);
      return;
    }
    setState(() => _loading = true);
    try {
      final Map<String, dynamic> payload = {
        'exam': widget.exam,
        'title': _titleCtrl.text.trim(),
        'date': _dateCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'link': _linkCtrl.text.trim(),
      };
      final id = widget.data?['id'];
      if (id != null) {
        await FirebaseService().updateDocument('current_affairs', id, payload);
      } else {
        await FirebaseService().addDocument('current_affairs', payload);
      }
      if (mounted) {
        showAdminSnackBar(context, 'Current Affairs saved successfully!');
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
    return AdminFormSheet(
      title: widget.data == null ? 'Add Current Affairs' : 'Edit Current Affairs',
      isLoading: _loading,
      onSave: _save,
      fields: [
        AdminSheetField(controller: _titleCtrl, label: 'Title *', icon: Icons.title_rounded, hint: 'e.g. March 2026 Current Affairs'),
        AdminSheetField(controller: _dateCtrl, label: 'Date', icon: Icons.calendar_today_rounded, hint: 'e.g. 29 March 2026'),
        AdminSheetField(controller: _descCtrl, label: 'Description', icon: Icons.info_outline_rounded, hint: 'Brief description', maxLines: 3),
        AdminSheetField(controller: _linkCtrl, label: 'PDF / Drive Link', icon: Icons.link_rounded, hint: 'https://...'),
      ],
    );
  }
}
