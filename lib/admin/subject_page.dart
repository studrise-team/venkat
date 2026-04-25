import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';
import '../services/firebase_service.dart';
import 'shared_widgets.dart';
import 'daily_quiz_page.dart';
import 'live_class_page.dart';
import 'video_classes_page.dart';
import 'notes_page.dart';
import 'student_attendance_page.dart';
import 'student_progress_page.dart';
import 'student_quiz_results_page.dart';

class SubjectPage extends StatefulWidget {
  final String className;
  const SubjectPage({super.key, required this.className});

  @override
  State<SubjectPage> createState() => _SubjectPageState();
}

class _SubjectPageState extends State<SubjectPage> {
  final TextEditingController _subjectCtrl = TextEditingController();
  bool _isLoading = false;

  static const _actions = [
    'Mock Test / PDF to MCQs',
    'Live Classes',
    'Recorded Classes',
    'Material Links',
    'Attendance',
    'Quiz Result History',
  ];

  static const _actionIcons = <String, IconData>{
    'Mock Test / PDF to MCQs': Icons.auto_awesome_rounded,
    'Live Classes': Icons.live_tv_rounded,
    'Recorded Classes': Icons.play_circle_fill_rounded,
    'Material Links': Icons.link_rounded,
    'Attendance': Icons.how_to_reg_rounded,
    'Quiz Result History': Icons.history_edu_rounded,
  };

  void _showAddSubjectDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AdminFormSheet(
        title: 'Add Subject',
        isLoading: _isLoading,
        onSave: () async {
          if (_subjectCtrl.text.trim().isEmpty) return;
          Navigator.pop(context);
          await _addSubject(_subjectCtrl.text.trim());
          _subjectCtrl.clear();
        },
        fields: [
          AdminSheetField(
            controller: _subjectCtrl,
            label: 'Subject Name',
            icon: Icons.subject_rounded,
            hint: 'e.g. Mathematics',
          ),
        ],
      ),
    );
  }

  Future<void> _addSubject(String name) async {
    setState(() => _isLoading = true);
    try {
      await FirebaseService().addSubject(widget.className, name);
      if (mounted) showAdminSnackBar(context, 'Subject added successfully');
    } catch (e) {
      if (mounted) showAdminSnackBar(context, 'Error adding subject: $e', type: AdminSnackType.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showActions(String subjectName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
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
            Text('Actions for $subjectName',
                style: GoogleFonts.outfit(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            Flexible(
              child: GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.9,
                ),
                itemCount: _actions.length,
                itemBuilder: (context, index) {
                  final action = _actions[index];
                  final icon = _actionIcons[action] ?? Icons.circle;
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToContextualPage(action, subjectName);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(icon, color: AppColors.primary, size: 24),
                          const SizedBox(height: 8),
                          Text(
                            action.split(' ').first,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              color: AppColors.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToContextualPage(String action, String subject) {
    Widget page;
    switch (action) {
      case 'Mock Test / PDF to MCQs':
        page = DailyQuizPage(exam: widget.className, subject: subject);
        break;
      case 'Live Classes':
        page = LiveClassPage(exam: widget.className, subject: subject);
        break;
      case 'Recorded Classes':
        page = VideoClassesPage(exam: widget.className, subject: subject);
        break;
      case 'Material Links':
        page = NotesPage(exam: widget.className, subject: subject);
        break;
      case 'Attendance':
        page = StudentAttendancePage(className: widget.className, subject: subject);
        break;
      case 'Quiz Result History':
        page = StudentQuizResultsPage(className: widget.className, subject: subject);
        break;
      default:
        return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Subjects', style: GoogleFonts.outfit(
                              color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
                          Text(widget.className, style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: _showAddSubjectDialog,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: StreamBuilder(
                  stream: FirebaseService().getSubjects(widget.className),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                    }
                    final docs = snapshot.data ?? [];
                    if (docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.subject_rounded, color: AppColors.textMuted, size: 60),
                            const SizedBox(height: 16),
                            Text('No Subjects yet',
                                style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 16)),
                            const SizedBox(height: 8),
                            Text('Tap + to add a subject',
                                style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 13)),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final name = doc['name'] ?? 'Untitled';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GestureDetector(
                            onTap: () => _showActions(name),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.cardBorder),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.book_rounded, color: AppColors.primary, size: 20),
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    name,
                                    style: GoogleFonts.outfit(
                                      color: AppColors.textPrimary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                                    onPressed: () async {
                                      final ok = await showDialog<bool>(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          backgroundColor: AppColors.surface,
                                          title: Text('Delete Subject', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                                          content: Text('Delete "$name"? All content associated will remain but the category will be removed.', style: GoogleFonts.outfit()),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
                                            TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Delete', style: TextStyle(color: AppColors.error))),
                                          ],
                                        ),
                                      );
                                      if (ok == true) {
                                        await FirebaseService().deleteSubject(doc.id);
                                      }
                                    },
                                  ),
                                  const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
