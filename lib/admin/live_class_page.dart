import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';
import '../services/firebase_service.dart';
import 'shared_widgets.dart';

class LiveClassPage extends StatelessWidget {
  final String exam;
  const LiveClassPage({super.key, required this.exam});

  @override
  Widget build(BuildContext context) {
    return AdminCrudPage(
      exam: exam,
      title: 'Live Classes',
      collection: 'live_classes',
      icon: Icons.live_tv,
      gradient: const LinearGradient(
        colors: [Color(0xFFe040fb), Color(0xFF7c4dff)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      formBuilder: (data, onSave) =>
          _LiveForm(exam: exam, data: data, onSave: onSave),
      cardBuilder: (doc) => _LiveCard(doc: doc),
    );
  }
}

class _LiveCard extends StatelessWidget {
  final Map<String, dynamic> doc;
  const _LiveCard({required this.doc});

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
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color:
                    const Color(0xFFe040fb).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(children: [
                const Icon(Icons.circle,
                    color: Color(0xFFe040fb), size: 6),
                const SizedBox(width: 4),
                Text('LIVE',
                    style: GoogleFonts.outfit(
                        color: const Color(0xFFe040fb),
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1)),
              ]),
            ),
            const SizedBox(width: 8),
            Text('${doc['date'] ?? ''} • ${doc['time'] ?? ''}',
                style: GoogleFonts.outfit(
                    color: AppColors.textSecondary, fontSize: 11)),
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
                    color: AppColors.textSecondary, fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ],
        ],
      ),
    );
  }
}

class _LiveForm extends StatefulWidget {
  final String exam;
  final Map<String, dynamic>? data;
  final VoidCallback onSave;
  const _LiveForm({required this.exam, this.data, required this.onSave});

  @override
  State<_LiveForm> createState() => _LiveFormState();
}

class _LiveFormState extends State<_LiveForm> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _dateCtrl;
  late final TextEditingController _timeCtrl;
  late final TextEditingController _linkCtrl;
  late final TextEditingController _descCtrl;
  bool _loading = false;

  static const _months = [
    'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'
  ];

  @override
  void initState() {
    super.initState();
    final d = widget.data;
    _titleCtrl = TextEditingController(text: d?['title'] ?? '');
    _dateCtrl = TextEditingController(text: d?['date'] ?? '');
    _timeCtrl = TextEditingController(text: d?['time'] ?? '');
    _linkCtrl = TextEditingController(text: d?['youtubeLink'] ?? '');
    _descCtrl = TextEditingController(text: d?['description'] ?? '');
  }

  @override
  void dispose() {
    for (var c in [_titleCtrl, _dateCtrl, _timeCtrl, _linkCtrl, _descCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      _dateCtrl.text =
          '${picked.day} ${_months[picked.month - 1]} ${picked.year}';
    }
  }

  Future<void> _pickTime() async {
    final picked =
        await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null) {
      if (!mounted) return;
      _timeCtrl.text = picked.format(context);
    }
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) {
      showAdminSnackBar(context, 'Class title is required.', type: AdminSnackType.warning);
      return;
    }
    setState(() => _loading = true);
    try {
      final Map<String, dynamic> payload = {
        'exam': widget.exam,
        'title': _titleCtrl.text.trim(),
        'date': _dateCtrl.text.trim(),
        'time': _timeCtrl.text.trim(),
        'youtubeLink': _linkCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
      };
      final id = widget.data?['id'];
      if (id != null) {
        await FirebaseService().updateDocument('live_classes', id, payload);
      } else {
        await FirebaseService().addDocument('live_classes', payload);
      }
      if (mounted) {
        showAdminSnackBar(context, 'Live Class saved successfully!');
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
                widget.data == null ? 'Add Live Class' : 'Edit Live Class',
                style: GoogleFonts.outfit(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 18),
            AdminSheetField(controller: _titleCtrl, label: 'Class Title *', icon: Icons.title_rounded, hint: 'e.g. APPSC GS Live Session'),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: _pickDate,
                  child: AbsorbPointer(
                    child: AdminSheetField(controller: _dateCtrl, label: 'Date', icon: Icons.calendar_today_rounded, hint: 'Pick date'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: _pickTime,
                  child: AbsorbPointer(
                    child: AdminSheetField(controller: _timeCtrl, label: 'Time', icon: Icons.access_time_rounded, hint: 'Pick time'),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 14),
            AdminSheetField(controller: _linkCtrl, label: 'YouTube Link *', icon: Icons.smart_display_rounded, hint: 'https://youtube.com/...'),
            const SizedBox(height: 14),
            AdminSheetField(controller: _descCtrl, label: 'Description', icon: Icons.info_outline_rounded, hint: 'What will be covered', maxLines: 3),
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
