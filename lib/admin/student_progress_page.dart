import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';
import '../services/firebase_service.dart';
import 'shared_widgets.dart';

class StudentProgressPage extends StatelessWidget {
  final String className;
  const StudentProgressPage({super.key, required this.className});

  @override
  Widget build(BuildContext context) {
    return AdminCrudPage(
      exam: className,
      title: 'Student Progress',
      collection: 'student_progress',
      icon: Icons.trending_up_rounded,
      gradient: const LinearGradient(colors: [Color(0xFF38ef7d), Color(0xFF11998e)]),
      formBuilder: (data, onSave) => _ProgressForm(className: className, data: data, onSave: onSave),
      cardBuilder: (doc) => _ProgressCard(doc: doc),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final Map<String, dynamic> doc;
  const _ProgressCard({required this.doc});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(doc['studentName'] ?? 'Unknown Student',
                    style: GoogleFonts.outfit(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  doc['term'] ?? 'Term 1',
                  style: GoogleFonts.outfit(color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _ScoreIndicator(label: 'Math', score: doc['math'] ?? '-'),
              _ScoreIndicator(label: 'Science', score: doc['science'] ?? '-'),
              _ScoreIndicator(label: 'English', score: doc['english'] ?? '-'),
            ],
          ),
          if (doc['remarks'] != null && doc['remarks'].toString().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('REMARKS', style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
            const SizedBox(height: 4),
            Text(doc['remarks'], style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 12, height: 1.4)),
          ],
        ],
      ),
    );
  }
}

class _ScoreIndicator extends StatelessWidget {
  final String label;
  final String score;
  const _ScoreIndicator({required this.label, required this.score});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 9, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(score, style: GoogleFonts.outfit(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ProgressForm extends StatefulWidget {
  final String className;
  final Map<String, dynamic>? data;
  final VoidCallback onSave;
  const _ProgressForm({required this.className, this.data, required this.onSave});

  @override
  State<_ProgressForm> createState() => _ProgressFormState();
}

class _ProgressFormState extends State<_ProgressForm> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _termCtrl;
  late final TextEditingController _mathCtrl;
  late final TextEditingController _sciCtrl;
  late final TextEditingController _engCtrl;
  late final TextEditingController _remarksCtrl;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final d = widget.data;
    _nameCtrl = TextEditingController(text: d?['studentName'] ?? '');
    _termCtrl = TextEditingController(text: d?['term'] ?? 'Term 1');
    _mathCtrl = TextEditingController(text: d?['math'] ?? '');
    _sciCtrl = TextEditingController(text: d?['science'] ?? '');
    _engCtrl = TextEditingController(text: d?['english'] ?? '');
    _remarksCtrl = TextEditingController(text: d?['remarks'] ?? '');
  }

  @override
  void dispose() {
    for (var c in [_nameCtrl, _termCtrl, _mathCtrl, _sciCtrl, _engCtrl, _remarksCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      showAdminSnackBar(context, 'Student name is required.', type: AdminSnackType.warning);
      return;
    }
    setState(() => _loading = true);
    try {
      final payload = {
        'exam': widget.className,
        'studentName': _nameCtrl.text.trim(),
        'term': _termCtrl.text.trim(),
        'math': _mathCtrl.text.trim(),
        'science': _sciCtrl.text.trim(),
        'english': _engCtrl.text.trim(),
        'remarks': _remarksCtrl.text.trim(),
        'updatedAt': DateTime.now().toIso8601String(),
      };
      
      if (widget.data?['id'] != null) {
        await FirebaseService().updateDocument('student_progress', widget.data!['id'], payload);
      } else {
        await FirebaseService().addDocument('student_progress', payload);
      }
      
      if (mounted) {
        showAdminSnackBar(context, 'Progress report saved!');
        widget.onSave();
      }
    } catch (e) {
      if (mounted) showAdminSnackBar(context, 'Error: $e', type: AdminSnackType.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminFormSheet(
      title: widget.data == null ? 'Record Progress' : 'Edit Progress',
      isLoading: _loading,
      onSave: _save,
      fields: [
        AdminSheetField(controller: _nameCtrl, label: 'Student Name *', icon: Icons.person_rounded, hint: 'e.g. Rahul Sharma'),
        AdminSheetField(controller: _termCtrl, label: 'Term / Exam Type', icon: Icons.event_note_rounded, hint: 'e.g. Quarterly Exam'),
        Row(
          children: [
            Expanded(child: AdminSheetField(controller: _mathCtrl, label: 'Math Score', icon: Icons.calculate_rounded, hint: 'e.g. 85/100')),
            const SizedBox(width: 12),
            Expanded(child: AdminSheetField(controller: _sciCtrl, label: 'Science Score', icon: Icons.biotech_rounded, hint: 'e.g. 90/100')),
          ],
        ),
        AdminSheetField(controller: _engCtrl, label: 'English Score', icon: Icons.language_rounded, hint: 'e.g. 88/100'),
        AdminSheetField(controller: _remarksCtrl, label: 'Remarks', icon: Icons.comment_rounded, hint: 'How is the student performing?', maxLines: 2),
      ],
    );
  }
}
