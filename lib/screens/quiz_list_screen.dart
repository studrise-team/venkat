import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../providers/quiz_provider.dart';
import '../services/firebase_service.dart';

class QuizListScreen extends StatelessWidget {
  const QuizListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Mock Tests',
          style: GoogleFonts.outfit(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 20),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseService().getQuizzesStream(),
        builder: (context, snapshot) {
          // ── Loading ──────────────────────────────────────────────────────
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          // ── Error ────────────────────────────────────────────────────────
          if (snapshot.hasError) {
            return _buildError(snapshot.error.toString());
          }

          final docs = snapshot.data?.docs ?? [];

          // ── Empty state ──────────────────────────────────────────────────
          if (docs.isEmpty) {
            return _buildEmpty(context);
          }

          // ── Quiz list ────────────────────────────────────────────────────
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, i) {
              final doc = docs[i];
              final data = doc.data();
              final title =
                  (data['title'] as String?) ?? 'Untitled Quiz';
              final qCount = (data['questionCount'] as int?) ?? 0;
              final ts = data['createdAt'];
              String dateStr = '';
              if (ts is Timestamp) {
                final dt = ts.toDate();
                dateStr =
                    '${dt.day}/${dt.month}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
              }

              return _QuizCard(
                index: i + 1,
                quizId: doc.id,
                title: title,
                questionCount: qCount,
                dateStr: dateStr,
                exam: data['exam'] ?? '',
                subject: data['subject'],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.card,
                shape: BoxShape.circle,
                border:
                    Border.all(color: AppColors.cardBorder),
              ),
              child: const Icon(Icons.quiz_outlined,
                  color: AppColors.textMuted, size: 56),
            ),
            const SizedBox(height: 24),
            Text(
              'No Quizzes Yet',
              style: GoogleFonts.outfit(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Text(
              'Ask your admin to upload and parse a question paper first.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.6),
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: () =>
                  Navigator.pushNamed(context, '/upload'),
              icon: const Icon(Icons.upload_file_rounded,
                  color: AppColors.primary, size: 18),
              label: Text('Go to Admin Upload',
                  style: GoogleFonts.outfit(color: AppColors.primary)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded,
                color: AppColors.error, size: 52),
            const SizedBox(height: 16),
            Text('Failed to load quizzes',
                style: GoogleFonts.outfit(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(error,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                    color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

// ── Quiz Card ──────────────────────────────────────────────────────────────
class _QuizCard extends StatefulWidget {
  final int index;
  final String quizId;
  final String title;
  final int questionCount;
  final String dateStr;
  final String exam;
  final String? subject;

  const _QuizCard({
    required this.index,
    required this.quizId,
    required this.title,
    required this.questionCount,
    required this.dateStr,
    required this.exam,
    this.subject,
  });

  @override
  State<_QuizCard> createState() => _QuizCardState();
}

class _QuizCardState extends State<_QuizCard> {
  bool _loading = false;

  Future<void> _startQuiz() async {
    setState(() => _loading = true);
    try {
      final provider = context.read<QuizProvider>();
      provider.setExamContext(widget.exam, subject: widget.subject);
      await provider.loadQuestionsFromFirestore(
          widget.quizId, widget.title);
      if (!mounted) return;
      if (provider.state == QuizState.active) {
        Navigator.pushNamed(context, '/quiz');
      } else {
        _showError(provider.errorMessage);
      }
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(msg,
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 13)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const gradients = [
      AppColors.primaryGradient,
      AppColors.accentGradient,
      LinearGradient(
        colors: [AppColors.accentOrange, AppColors.warning],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ];
    final gradient = gradients[(widget.index - 1) % gradients.length];

    return GestureDetector(
      onTap: _loading ? null : _startQuiz,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border:
              Border.all(color: AppColors.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // ── Index badge ────────────────────────────────────────────
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  '${widget.index}',
                  style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // ── Title + meta ───────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: GoogleFonts.outfit(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _MetaChip(
                        icon: Icons.help_outline_rounded,
                        label: '${widget.questionCount} Questions',
                        color: AppColors.primary,
                      ),
                      if (widget.dateStr.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        _MetaChip(
                          icon: Icons.calendar_today_rounded,
                          label: widget.dateStr,
                          color: AppColors.textMuted,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // ── Start button ───────────────────────────────────────────
            const SizedBox(width: 12),
            _loading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        color: AppColors.primary, strokeWidth: 2.5),
                  )
                : Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: gradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.play_arrow_rounded,
                        color: Colors.white, size: 22),
                  ),
          ],
        ),
      ),
    );
  }
}

// ── Meta chip ──────────────────────────────────────────────────────────────
class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MetaChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(label,
            style:
                GoogleFonts.outfit(color: color, fontSize: 11)),
      ],
    );
  }
}
