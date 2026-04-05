import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../providers/quiz_provider.dart';
import '../models/question_model.dart';
import '../widgets/option_tile.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  Timer? _timer;
  int _timeLeft = 30;
  int _lastIndex = 0;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timeLeft = 30;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
      } else {
        _autoAdvance();
      }
    });
  }

  void _autoAdvance() {
    final provider = context.read<QuizProvider>();
    final isLast = provider.currentIndex == provider.questions.length - 1;
    if (isLast) {
      _timer?.cancel();
      provider.submitQuiz();
      Navigator.pushReplacementNamed(context, '/result');
    } else {
      provider.nextQuestion();
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<QuizProvider>(
      builder: (context, provider, _) {
        if (provider.questions.isEmpty) {
          return _buildEmpty(context);
        }
        return _buildQuiz(context, provider);
      },
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.quiz_outlined,
                color: AppColors.textMuted, size: 64),
            const SizedBox(height: 16),
            Text('No questions loaded.',
                style: GoogleFonts.outfit(
                    color: AppColors.textSecondary, fontSize: 16)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/upload'),
              child: const Text('Upload Questions'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuiz(BuildContext context, QuizProvider provider) {
    final questions = provider.questions;
    final idx = provider.currentIndex;
    final current = questions[idx];
    final total = questions.length;
    final progress = (idx + 1) / total;
    // Reset timer if index changed via provider (e.g. from previous/next)
    if (idx != _lastIndex) {
      _lastIndex = idx;
      // Schedule to avoid setState during build
      Future.microtask(() => _startTimer());
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ---- Top bar ----
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => _confirmExit(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: const Icon(Icons.close_rounded,
                          color: AppColors.textSecondary, size: 20),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _timeLeft <= 5 ? AppColors.error.withValues(alpha: 0.2) : AppColors.cardLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _timeLeft <= 5 ? AppColors.error : AppColors.accent.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.timer_outlined, 
                          size: 16, 
                          color: _timeLeft <= 5 ? AppColors.error : AppColors.accent),
                        const SizedBox(width: 6),
                        Text(
                          '00:${_timeLeft.toString().padLeft(2, "0")}',
                          style: GoogleFonts.outfit(
                              color: _timeLeft <= 5 ? AppColors.error : AppColors.accent, 
                              fontWeight: FontWeight.w600,
                              fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ---- Question Numbers Bar ----
            Container(
              height: 44,
              margin: const EdgeInsets.only(bottom: 5),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: total,
                itemBuilder: (context, i) {
                  final isCurrent = i == idx;
                  final answered = provider.selectedAnswers.containsKey(i);
                  final Color color = answered ? AppColors.success : AppColors.warning;
                  return GestureDetector(
                    onTap: () => provider.jumpToQuestion(i),
                    child: Container(
                      width: 40,
                      height: 40,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: isCurrent ? 1.0 : 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: color,
                          width: isCurrent ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${i + 1}',
                          style: GoogleFonts.outfit(
                            color: isCurrent ? Colors.white : color,
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // ---- Question ----
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Question number badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Q${idx + 1}',
                        style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Question text
                    Text(
                      current.question,
                      style: GoogleFonts.outfit(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Options
                    ...List.generate(current.options.length, (i) {
                      final option = current.options[i];
                      final selected = provider.selectedAnswers[idx];
                      return OptionTile(
                        label: String.fromCharCode(65 + i), // A, B, C, D
                        text: option,
                        isSelected: selected == option,
                        onTap: () => provider.selectAnswer(idx, option),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // ---- Navigation ----
            _buildNavBar(context, provider, idx, total, current),
          ],
        ),
      ),
    );
  }

  Widget _buildNavBar(BuildContext context, QuizProvider provider, int idx,
      int total, QuestionModel current) {
    final isFirst = idx == 0;
    final isLast = idx == total - 1;
    final allAnswered =
        provider.selectedAnswers.length == total;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border:
            Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Previous
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isFirst ? null : provider.previousQuestion,
                  icon: const Icon(Icons.arrow_back_rounded, size: 16),
                  label: Text('Prev',
                      style: GoogleFonts.outfit(fontSize: 14)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: BorderSide(color: isFirst ? Colors.transparent : AppColors.cardBorder),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Next
              Expanded(
                child: OutlinedButton(
                  onPressed: isLast ? null : provider.nextQuestion,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: isLast ? Colors.transparent : AppColors.primary.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Next',
                          style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward_rounded, size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Submit Quiz (Always Available)
          GestureDetector(
            onTap: () {
              if (allAnswered) {
                _timer?.cancel();
                provider.submitQuiz();
                Navigator.pushReplacementNamed(context, '/result');
              } else {
                _showSubmitDialog(context, provider);
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Submit Quiz',
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.check_circle_rounded,
                      color: Colors.white, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmExit(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Exit Quiz?',
            style: GoogleFonts.outfit(color: AppColors.textPrimary)),
        content: Text('Your progress will be lost.',
            style: GoogleFonts.outfit(color: AppColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel',
                  style: GoogleFonts.outfit(color: AppColors.textSecondary))),
          TextButton(
            onPressed: () {
              _timer?.cancel();
              Navigator.pop(context);
              Navigator.pop(context); // Properly close quiz without splashing
            },
            child: Text('Exit',
                style: GoogleFonts.outfit(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _showSubmitDialog(BuildContext context, QuizProvider provider) {
    final unanswered = provider.questions.length -
        provider.selectedAnswers.length;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Submit Quiz?',
            style: GoogleFonts.outfit(color: AppColors.textPrimary)),
        content: Text(
          '$unanswered question${unanswered != 1 ? 's' : ''} left unanswered. Submit anyway?',
          style: GoogleFonts.outfit(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Keep Going',
                  style: GoogleFonts.outfit(color: AppColors.textSecondary))),
          TextButton(
            onPressed: () {
              _timer?.cancel();
              Navigator.pop(context);
              provider.submitQuiz();
              Navigator.pushReplacementNamed(context, '/result');
            },
            child: Text('Submit',
                style: GoogleFonts.outfit(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}
