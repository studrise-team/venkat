import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';
import '../services/firebase_service.dart';
import 'shared_widgets.dart';

class StudentProgressPage extends StatelessWidget {
  final String className;
  final String? subject;
  final String? studentName;
  const StudentProgressPage({super.key, required this.className, this.subject, this.studentName});

  @override
  Widget build(BuildContext context) {
    return AdminCrudPage(
      exam: className,
      subject: subject,
      studentName: studentName,
      title: 'Student Progress',
      collection: 'student_progress',
      icon: Icons.trending_up_rounded,
      gradient: const LinearGradient(colors: [Color(0xFF38ef7d), Color(0xFF11998e)]),
      formBuilder: (data, onSave) => _ProgressForm(
        className: className, 
        subject: subject, 
        studentName: studentName,
        data: data, 
        onSave: onSave
      ),
      cardBuilder: (doc) => _ProgressCard(doc: doc),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final Map<String, dynamic> doc;
  const _ProgressCard({required this.doc});

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> scores = doc['scores'] ?? {};
    
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
          const SizedBox(height: 16),
          if (scores.isNotEmpty)
            Wrap(
              spacing: 16,
              runSpacing: 12,
              children: scores.entries.map((e) => _ScoreIndicator(label: e.key, score: e.value.toString())).toList(),
            )
          else if (doc['math'] != null || doc['science'] != null || doc['english'] != null)
            Row(
              children: [
                if (doc['math'] != null) _ScoreIndicator(label: 'Math', score: doc['math']),
                if (doc['science'] != null) _ScoreIndicator(label: 'Science', score: doc['science']),
                if (doc['english'] != null) _ScoreIndicator(label: 'English', score: doc['english']),
              ],
            )
          else
            Text('No scores recorded', style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 12)),
          
          if (doc['remarks'] != null && doc['remarks'].toString().isNotEmpty) ...[
            const SizedBox(height: 16),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 9, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(score, style: GoogleFonts.outfit(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _ProgressForm extends StatefulWidget {
  final String className;
  final String? subject;
  final String? studentName;
  final Map<String, dynamic>? data;
  final VoidCallback onSave;
  const _ProgressForm({required this.className, this.subject, this.studentName, this.data, required this.onSave});

  @override
  State<_ProgressForm> createState() => _ProgressFormState();
}

class _ProgressFormState extends State<_ProgressForm> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _termCtrl;
  late final TextEditingController _remarksCtrl;
  final Map<String, TextEditingController> _subjectCtrls = {};
  List<String> _subjects = [];
  bool _loading = false;
  bool _fetchingSubjects = true;

  @override
  void initState() {
    super.initState();
    final d = widget.data;
    _nameCtrl = TextEditingController(text: d?['studentName'] ?? widget.studentName ?? '');
    _termCtrl = TextEditingController(text: d?['term'] ?? 'Term 1');
    _remarksCtrl = TextEditingController(text: d?['remarks'] ?? '');
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    try {
      final snap = await FirebaseService().getSubjects(widget.className).first;
      _subjects = snap.map((s) => s['name'] as String).toList();
      
      final existingScores = widget.data?['scores'] as Map<String, dynamic>? ?? {};
      
      for (var subject in _subjects) {
        _subjectCtrls[subject] = TextEditingController(text: existingScores[subject]?.toString() ?? '');
      }
      
      // Fallback for legacy data
      if (widget.data != null && existingScores.isEmpty) {
        if (widget.data!['math'] != null) _subjectCtrls['Math'] = TextEditingController(text: widget.data!['math']);
        if (widget.data!['science'] != null) _subjectCtrls['Science'] = TextEditingController(text: widget.data!['science']);
        if (widget.data!['english'] != null) _subjectCtrls['English'] = TextEditingController(text: widget.data!['english']);
        if (!_subjects.contains('Math')) _subjects.insert(0, 'Math');
        if (!_subjects.contains('Science')) _subjects.insert(1, 'Science');
        if (!_subjects.contains('English')) _subjects.insert(2, 'English');
      }

    } catch (e) {
      debugPrint('Error loading subjects: $e');
    } finally {
      if (mounted) setState(() => _fetchingSubjects = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _termCtrl.dispose();
    _remarksCtrl.dispose();
    for (var c in _subjectCtrls.values) {
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
      final Map<String, String> scores = {};
      _subjectCtrls.forEach((key, controller) {
        if (controller.text.trim().isNotEmpty) {
          scores[key] = controller.text.trim();
        }
      });

      final payload = {
        'exam': widget.className,
        'subject': widget.subject,
        'studentName': _nameCtrl.text.trim(),
        'term': _termCtrl.text.trim(),
        'scores': scores,
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
    if (_fetchingSubjects) {
      return const SizedBox(height: 300, child: Center(child: CircularProgressIndicator()));
    }

    return AdminFormSheet(
      title: widget.data == null ? 'Record Progress' : 'Edit Progress',
      isLoading: _loading,
      onSave: _save,
      fields: [
        AdminSheetField(
          controller: _nameCtrl, 
          label: 'Student Name *', 
          icon: Icons.person_rounded, 
          hint: 'e.g. Rahul Sharma',
          readOnly: widget.studentName != null,
        ),
        AdminSheetField(controller: _termCtrl, label: 'Term / Exam Type', icon: Icons.event_note_rounded, hint: 'e.g. Quarterly Exam'),
        
        const SizedBox(height: 8),
        Text('SUBJECT SCORES', style: GoogleFonts.outfit(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
        const SizedBox(height: 12),
        
        if (_subjects.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text('No subjects added for this class. Add subjects in the Subjects section first.', 
                style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 13, height: 1.5)),
          )
        else
          ..._subjects.map((s) => AdminSheetField(
                controller: _subjectCtrls[s]!, 
                label: '$s Score', 
                icon: Icons.book_rounded, 
                hint: 'e.g. 85/100'
              )),

        AdminSheetField(controller: _remarksCtrl, label: 'Remarks', icon: Icons.comment_rounded, hint: 'How is the student performing?', maxLines: 2),
      ],
    );
  }
}
