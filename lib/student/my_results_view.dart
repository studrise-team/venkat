import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../app_theme.dart';

class MyResultsView extends StatelessWidget {
  final String className;
  final String studentId;
  final String? subject;
  final bool showBackButton;
  const MyResultsView({super.key, required this.className, required this.studentId, this.subject, this.showBackButton = true});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(showBackButton ? 8 : 24, 12, 16, 0),
                child: Row(
                  children: [
                    if (showBackButton)
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
                        onPressed: () => Navigator.pop(context),
                      ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('My Quiz Results', style: GoogleFonts.outfit(
                              color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
                          Text(subject != null ? '$className • $subject' : className, 
                              style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: (() {
                    var query = FirebaseFirestore.instance
                        .collection('student_quiz_results')
                        .where('exam', isEqualTo: className)
                        .where('studentId', isEqualTo: studentId);
                    if (subject != null) {
                      query = query.where('subject', isEqualTo: subject);
                    }
                    return query.orderBy('submittedAt', descending: true).snapshots();
                  })(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                    }
                    final docs = snapshot.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.history_edu_rounded, color: AppColors.textMuted, size: 60),
                            const SizedBox(height: 16),
                            Text('No quiz results yet',
                                style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 16)),
                            const SizedBox(height: 8),
                            Text('Take a quiz to see your score here!',
                                style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 13)),
                          ],
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) {
                        final data = docs[i].data();
                        final score = data['score'] ?? 0;
                        final total = data['total'] ?? 0;
                        final percentage = (data['percentage'] ?? 0.0) as double;
                        final ts = data['submittedAt'] as Timestamp?;
                        final dateStr = ts != null ? _formatDate(ts.toDate()) : 'Recently';

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: Row(
                            children: [
                              _ScoreCircle(percentage: percentage),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(data['quizTitle'] ?? 'Untitled Quiz',
                                        style: GoogleFonts.outfit(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 4),
                                    Text('Score: $score/$total • $dateStr',
                                        style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 11)),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
                            ],
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

  String _formatDate(DateTime d) => '${d.day}/${d.month} ${d.hour}:${d.minute.toString().padLeft(2, '0')}';
}

class _ScoreCircle extends StatelessWidget {
  final double percentage;
  const _ScoreCircle({required this.percentage});

  @override
  Widget build(BuildContext context) {
    final color = percentage >= 75 ? AppColors.success : (percentage >= 40 ? AppColors.warning : AppColors.error);
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Center(
        child: Text('${percentage.toInt()}%',
            style: GoogleFonts.outfit(color: color, fontSize: 12, fontWeight: FontWeight.w800)),
      ),
    );
  }
}
