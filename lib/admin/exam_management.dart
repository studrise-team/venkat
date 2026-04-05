import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';
import 'mock_test_page.dart';
import 'previous_papers_page.dart';
import 'current_affairs_page.dart';
import 'notes_page.dart';
import 'video_classes_page.dart';
import 'daily_quiz_page.dart';
import 'live_class_page.dart';

class ExamManagementScreen extends StatefulWidget {
  const ExamManagementScreen({super.key});
  @override
  State<ExamManagementScreen> createState() => _ExamManagementScreenState();
}

class _ExamManagementScreenState extends State<ExamManagementScreen> {
  static const _exams = [
    'DSC', 'APPSC', 'Police', 'Railway', 'Banking',
    'Group 1', 'Group 2', 'Group 3', 'Group 4',
  ];
  static const _actions = [
    'Mock Tests', 'Previous Papers', 'Current Affairs',
    'Notes', 'Video Classes', 'Daily Quiz', 'Live Class',
  ];

  String? _selectedExam;
  String? _selectedAction;

  static const _examIcons = <String, IconData>{
    'DSC': Icons.menu_book_rounded,
    'APPSC': Icons.account_balance_rounded,
    'Police': Icons.local_police_rounded,
    'Railway': Icons.train_rounded,
    'Banking': Icons.account_balance_wallet_rounded,
    'Group 1': Icons.looks_one_rounded,
    'Group 2': Icons.looks_two_rounded,
    'Group 3': Icons.looks_3_rounded,
    'Group 4': Icons.looks_4_rounded,
  };

  static const _actionIcons = <String, IconData>{
    'Mock Tests': Icons.quiz_rounded,
    'Previous Papers': Icons.description_rounded,
    'Current Affairs': Icons.newspaper_rounded,
    'Notes': Icons.note_rounded,
    'Video Classes': Icons.play_circle_rounded,
    'Daily Quiz': Icons.today_rounded,
    'Live Class': Icons.live_tv,
  };

  void _navigate() {
    if (_selectedExam == null || _selectedAction == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select both Exam and Action.',
              style: GoogleFonts.outfit()),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    final exam = _selectedExam!;
    final action = _selectedAction!;

    Widget page;
    switch (action) {
      case 'Mock Tests':
        page = MockTestPage(exam: exam);
        break;
      case 'Previous Papers':
        page = PreviousPapersPage(exam: exam);
        break;
      case 'Current Affairs':
        page = CurrentAffairsPage(exam: exam);
        break;
      case 'Notes':
        page = NotesPage(exam: exam);
        break;
      case 'Video Classes':
        page = VideoClassesPage(exam: exam);
        break;
      case 'Daily Quiz':
        page = DailyQuizPage(exam: exam);
        break;
      case 'Live Class':
        page = LiveClassPage(exam: exam);
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
                padding: const EdgeInsets.fromLTRB(8, 12, 24, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: AppColors.textPrimary),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Exam Management',
                            style: GoogleFonts.outfit(
                              color: AppColors.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            )),
                        Text('Select exam and action to manage',
                            style: GoogleFonts.outfit(
                                color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Exam Selection ─────────────────────────────────
                      Text('Select Exam',
                          style: GoogleFonts.outfit(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          )),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final crossAxisCount = constraints.maxWidth > 600 ? 5 : 3;
                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: constraints.maxWidth > 600 ? 1.4 : 1.1,
                            ),
                            itemCount: _exams.length,
                            itemBuilder: (_, i) {
                              final e = _exams[i];
                              final selected = _selectedExam == e;
                              return GestureDetector(
                                onTap: () => setState(() => _selectedExam = e),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  decoration: BoxDecoration(
                                    gradient: selected
                                        ? AppColors.primaryGradient
                                        : null,
                                    color: selected ? null : AppColors.card,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: selected
                                          ? Colors.transparent
                                          : AppColors.cardBorder,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        _examIcons[e] ?? Icons.book_rounded,
                                        color: selected
                                            ? Colors.white
                                            : AppColors.primary,
                                        size: 26,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(e,
                                          style: GoogleFonts.outfit(
                                            color: selected
                                                ? Colors.white
                                                : AppColors.textSecondary,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          textAlign: TextAlign.center),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),

                      const SizedBox(height: 28),

                      // ── Action Selection ───────────────────────────────
                      Text('Select Action',
                          style: GoogleFonts.outfit(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          )),
                      const SizedBox(height: 12),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _actions.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final a = _actions[i];
                          final selected = _selectedAction == a;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedAction = a),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 14),
                              decoration: BoxDecoration(
                                gradient: selected
                                    ? AppColors.accentGradient
                                    : null,
                                color: selected ? null : AppColors.card,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: selected
                                      ? Colors.transparent
                                      : AppColors.cardBorder,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _actionIcons[a] ?? Icons.chevron_right,
                                    color: selected
                                        ? Colors.white
                                        : AppColors.accent,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 14),
                                  Text(a,
                                      style: GoogleFonts.outfit(
                                        color: selected
                                            ? Colors.white
                                            : AppColors.textPrimary,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      )),
                                  const Spacer(),
                                  if (selected)
                                    const Icon(Icons.check_rounded,
                                        color: Colors.white, size: 18),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 32),

                      // ── Enter Button ───────────────────────────────────
                      GestureDetector(
                        onTap: _navigate,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 17),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.arrow_forward_rounded,
                                  color: Colors.white, size: 22),
                              const SizedBox(width: 10),
                              Text('Enter',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  )),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
