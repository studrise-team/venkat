import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';
import 'notes_view.dart';
import 'video_view.dart';
import 'live_class_view.dart';
import 'quiz_list_view.dart';

class ExamActionScreen extends StatelessWidget {
  final String exam;
  const ExamActionScreen({super.key, required this.exam});

  static const _actions = [
    {'label': 'Mock Tests', 'icon': Icons.quiz_rounded, 'color': Color(0xFF6C63FF)},
    {'label': 'Previous Papers', 'icon': Icons.description_rounded, 'color': Color(0xFF00D4AA)},
    {'label': 'Current Affairs', 'icon': Icons.newspaper_rounded, 'color': Color(0xFFFF6B6B)},
    {'label': 'Notes', 'icon': Icons.note_rounded, 'color': Color(0xFF38ef7d)},
    {'label': 'Video Classes', 'icon': Icons.play_circle_rounded, 'color': Color(0xFFf7971e)},
    {'label': 'Daily Quiz', 'icon': Icons.today_rounded, 'color': Color(0xFF00B8D9)},
    {'label': 'Live Class', 'icon': Icons.live_tv, 'color': Color(0xFFe040fb)},
  ];

  void _navigate(BuildContext context, String action) {
    Widget page;
    switch (action) {
      case 'Mock Tests':
        page = QuizListView(exam: exam, collection: 'quizzes', title: 'Mock Tests');
        break;
      case 'Previous Papers':
        page = PaperView(exam: exam);
        break;
      case 'Current Affairs':
        page = CurrentAffairsView(exam: exam);
        break;
      case 'Notes':
        page = NotesView(exam: exam);
        break;
      case 'Video Classes':
        page = VideoView(exam: exam);
        break;
      case 'Daily Quiz':
        page = QuizListView(exam: exam, collection: 'daily_quizzes', title: 'Daily Quiz');
        break;
      case 'Live Class':
        page = LiveClassView(exam: exam);
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
                        Text(exam, style: GoogleFonts.outfit(
                          color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w800)),
                        Text('Choose a section', style: GoogleFonts.outfit(
                            color: AppColors.textSecondary, fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action list
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ListView.separated(
                    itemCount: _actions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) {
                      final action = _actions[i];
                      final label = action['label'] as String;
                      final icon = action['icon'] as IconData;
                      final color = action['color'] as Color;
                      return GestureDetector(
                        onTap: () => _navigate(context, label),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(icon, color: color, size: 24),
                              ),
                              const SizedBox(width: 16),
                              Text(label, style: GoogleFonts.outfit(
                                color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                              const Spacer(),
                              Icon(Icons.arrow_forward_ios_rounded, color: color.withValues(alpha: 0.6), size: 15),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
