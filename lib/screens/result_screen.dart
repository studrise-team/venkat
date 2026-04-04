import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../providers/quiz_provider.dart';
import '../models/result_model.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QuizProvider>();
    final result = provider.result;

    if (result == null) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(child: Text('No result yet.')),
      );
    }

    final pct = result.percentage;
    final (grade, gradeColor) = _grade(pct);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ---- Header / Score card ----
            SliverToBoxAdapter(
              child: _ScoreHeader(
                  result: result, pct: pct, grade: grade, gradeColor: gradeColor),
            ),

            // ---- Stats row ----
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    _StatBox(
                        label: 'Correct',
                        value: '${result.correctAnswers}',
                        color: AppColors.success),
                    const SizedBox(width: 12),
                    _StatBox(
                        label: 'Wrong',
                        value: '${result.wrongAnswers}',
                        color: AppColors.error),
                    const SizedBox(width: 12),
                    _StatBox(
                        label: 'Skipped',
                        value:
                            '${result.totalQuestions - result.correctAnswers - result.wrongAnswers}',
                        color: AppColors.warning),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 28)),

            // ---- Review heading ----
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'Review Answers',
                  style: GoogleFonts.outfit(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 14)),

            // ---- Review list ----
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverList.separated(
                itemCount: result.answers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final rec = result.answers[i];
                  return _ReviewCard(index: i + 1, record: rec);
                },
              ),
            ),

            // ---- Buttons ----
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
              sliver: SliverToBoxAdapter(
                child: Column(
                  children: [
                    // Retry
                    GestureDetector(
                      onTap: () {
                        provider.resetQuiz();
                        Navigator.pushReplacementNamed(context, '/quiz');
                      },
                      child: Container(
                        width: double.infinity,
                        padding:
                            const EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.replay_rounded,
                                color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text('Retry Quiz',
                                style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Translate to Telugu
                    GestureDetector(
                      onTap: () async {
                        await context.read<QuizProvider>().translateResultsToTelugu();
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          gradient: AppColors.accentGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.translate_rounded,
                                color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text('View in Telugu (తెలుగు)',
                                style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Home
                    OutlinedButton.icon(
                      onPressed: () {
                        provider.reset();
                        Navigator.pushNamedAndRemoveUntil(
                            context, '/', (_) => false);
                      },
                      icon: const Icon(Icons.home_rounded,
                          color: AppColors.textSecondary),
                      label: Text('Back to Home',
                          style: GoogleFonts.outfit(
                              color: AppColors.textSecondary)),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        side: BorderSide(
                            color: AppColors.cardBorder),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  (String, Color) _grade(double pct) {
    if (pct >= 90) return ('A+', AppColors.success);
    if (pct >= 75) return ('A', AppColors.success);
    if (pct >= 60) return ('B', AppColors.accent);
    if (pct >= 50) return ('C', AppColors.warning);
    return ('F', AppColors.error);
  }
}

// ============================================================
class _ScoreHeader extends StatelessWidget {
  final ResultModel result;
  final double pct;
  final String grade;
  final Color gradeColor;

  const _ScoreHeader(
      {required this.result,
      required this.pct,
      required this.grade,
      required this.gradeColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Quiz Complete! 🎉',
            style: GoogleFonts.outfit(
                color: Colors.white70, fontSize: 14, letterSpacing: 1),
          ),
          const SizedBox(height: 16),
          // Grade circle
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: AppColors.cardBorder,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                grade,
                style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${result.correctAnswers} / ${result.totalQuestions}',
            style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            '${pct.toStringAsFixed(1)}% Score',
            style: GoogleFonts.outfit(
                color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 20),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct / 100,
              backgroundColor: AppColors.cardBorder,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBox(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(value,
                style: GoogleFonts.outfit(
                    color: color,
                    fontSize: 28,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(label,
                style: GoogleFonts.outfit(
                    color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

// ============================================================
class _ReviewCard extends StatelessWidget {
  final int index;
  final AnswerRecord record;

  const _ReviewCard({required this.index, required this.record});

  @override
  Widget build(BuildContext context) {
    final correct = record.isCorrect;
    final skipped = record.selectedAnswer == null;
    final color = skipped
        ? AppColors.warning
        : (correct ? AppColors.success : AppColors.error);
    final icon = skipped
        ? Icons.remove_circle_outline_rounded
        : (correct
            ? Icons.check_circle_rounded
            : Icons.cancel_rounded);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text('Q$index',
                  style: GoogleFonts.outfit(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          Text(record.question,
              style: GoogleFonts.outfit(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.5)),
          const SizedBox(height: 10),
          if (!skipped && !correct) ...[
            _AnswerRow(
                label: 'Your answer',
                text: record.selectedAnswer ?? '-',
                color: AppColors.error),
            const SizedBox(height: 6),
          ],
          _AnswerRow(
              label: 'Correct answer',
              text: record.correctAnswer,
              color: AppColors.success),
        ],
      ),
    );
  }
}

class _AnswerRow extends StatelessWidget {
  final String label;
  final String text;
  final Color color;

  const _AnswerRow(
      {required this.label, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ',
            style: GoogleFonts.outfit(
                color: AppColors.textMuted, fontSize: 11)),
        Expanded(
          child: Text(text,
              style: GoogleFonts.outfit(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
