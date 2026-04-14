import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';
import 'daily_quiz_page.dart';
import 'live_class_page.dart';
import 'video_classes_page.dart';
import 'notes_page.dart';
import 'student_attendance_page.dart';
import 'student_progress_page.dart';
import 'student_quiz_results_page.dart';
import '../services/firebase_service.dart';

class StudentManagementScreen extends StatefulWidget {
  const StudentManagementScreen({super.key});
  @override
  State<StudentManagementScreen> createState() => _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen> {
  static const _classes = [
    'Class 1', 'Class 2', 'Class 3', 'Class 4', 'Class 5',
    'Class 6', 'Class 7', 'Class 8', 'Class 9', 'Class 10',
    'Class 11', 'Class 12',
  ];

  static const _actions = [
    'AI Quiz / PDF to MCQs',
    'Live Classes',
    'Recorded Classes',
    'Material Links',
    'Attendance',
    'Progress',
    'Quiz Result History',
  ];

  String? _selectedClass;
  String? _selectedAction;

  static const _actionIcons = <String, IconData>{
    'AI Quiz / PDF to MCQs': Icons.auto_awesome_rounded,
    'Live Classes': Icons.live_tv_rounded,
    'Recorded Classes': Icons.play_circle_fill_rounded,
    'Material Links': Icons.link_rounded,
    'Attendance': Icons.how_to_reg_rounded,
    'Progress': Icons.trending_up_rounded,
    'Quiz Result History': Icons.history_edu_rounded,
  };

  void _navigate() {
    if (_selectedClass == null || _selectedAction == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select both Class and Action.', style: GoogleFonts.outfit()),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    final className = _selectedClass!;
    final action = _selectedAction!;

    Widget page;
    switch (action) {
      case 'AI Quiz / PDF to MCQs':
        page = DailyQuizPage(exam: className);
        break;
      case 'Live Classes':
        page = LiveClassPage(exam: className);
        break;
      case 'Recorded Classes':
        page = VideoClassesPage(exam: className);
        break;
      case 'Material Links':
        page = NotesPage(exam: className);
        break;
      case 'Attendance':
        page = StudentAttendancePage(className: className);
        break;
      case 'Progress':
        page = StudentProgressPage(className: className);
        break;
      case 'Quiz Result History':
        page = StudentQuizResultsPage(className: className);
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
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Student Management',
                            style: GoogleFonts.outfit(
                              color: AppColors.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            )),
                        FutureBuilder<Map<String, dynamic>>(
                          future: FirebaseService().getStats(),
                          builder: (context, snapshot) {
                            final total = snapshot.data?['studentCount'] ?? 0;
                            return Text(
                                snapshot.connectionState == ConnectionState.waiting
                                    ? 'Fetching registration data...'
                                    : 'Select class and action • $total Registered',
                                style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 12));
                          },
                        ),
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
                      // Class Selection
                      Text('Select Class',
                          style: GoogleFonts.outfit(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          )),
                      const SizedBox(height: 12),
                      FutureBuilder<Map<String, dynamic>>(
                        future: FirebaseService().getStats(),
                        builder: (context, snapshot) {
                          final breakdown = snapshot.data?['classBreakdown'] as Map<String, int>? ?? {};
                          
                          return LayoutBuilder(
                            builder: (context, constraints) {
                              final crossAxisCount = constraints.maxWidth > 600 ? 6 : 4;
                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                  childAspectRatio: 0.9,
                                ),
                                itemCount: _classes.length,
                                itemBuilder: (_, i) {
                                  final c = _classes[i];
                                  final selected = _selectedClass == c;
                                  final count = breakdown[c] ?? 0;
                                  
                                  return GestureDetector(
                                    onTap: () => setState(() => _selectedClass = c),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 180),
                                      decoration: BoxDecoration(
                                        gradient: selected ? AppColors.primaryGradient : null,
                                        color: selected ? null : AppColors.card,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: selected ? Colors.transparent : AppColors.cardBorder),
                                      ),
                                      child: Stack(
                                        children: [
                                          Center(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(c.replaceAll('Class ', ''),
                                                    style: GoogleFonts.outfit(
                                                      color: selected ? Colors.white : AppColors.textSecondary,
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w700,
                                                    )),
                                                if (count > 0)
                                                  Text('$count',
                                                      style: GoogleFonts.outfit(
                                                        color: selected ? Colors.white.withOpacity(0.7) : AppColors.textMuted,
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.w600,
                                                      )),
                                              ],
                                            ),
                                          ),
                                          if (count > 0 && !selected)
                                            Positioned(
                                              top: 6,
                                              right: 6,
                                              child: Container(
                                                width: 6,
                                                height: 6,
                                                decoration: const BoxDecoration(
                                                  color: AppColors.primary,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        }
                      ),

                      const SizedBox(height: 28),

                      // Action Selection
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
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                              decoration: BoxDecoration(
                                gradient: selected ? AppColors.accentGradient : null,
                                color: selected ? null : AppColors.card,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: selected ? Colors.transparent : AppColors.cardBorder),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _actionIcons[a] ?? Icons.chevron_right,
                                    color: selected ? Colors.white : AppColors.accent,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 14),
                                  Text(a,
                                      style: GoogleFonts.outfit(
                                        color: selected ? Colors.white : AppColors.textPrimary,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      )),
                                  const Spacer(),
                                  if (selected) const Icon(Icons.check_rounded, color: Colors.white, size: 18),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 32),

                      // Enter Button
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
                              const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 22),
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
