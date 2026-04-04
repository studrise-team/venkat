import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../services/firebase_service.dart';
import '../providers/quiz_provider.dart';

class MockTestPage extends StatelessWidget {
  final String exam;
  const MockTestPage({super.key, required this.exam});

  Future<void> _deleteQuiz(BuildContext context, String quizId, String title) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Quiz', style: GoogleFonts.outfit(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        content: Text('Delete "$title"? This cannot be undone.',
            style: GoogleFonts.outfit(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: GoogleFonts.outfit(color: AppColors.textSecondary))),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: Text('Delete', style: GoogleFonts.outfit(color: AppColors.error, fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (ok == true) {
      await FirebaseService().deleteQuiz(quizId);
    }
  }

  void _addQuiz(BuildContext context) {
    context.read<QuizProvider>().setExamContext(exam, collection: 'quizzes');
    context.read<QuizProvider>().reset();
    Navigator.pushNamed(context, '/upload');
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
                          Text('Mock Tests', style: GoogleFonts.outfit(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
                          Text(exam, style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _addQuiz(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
                  stream: FirebaseService().getQuizzesByExam(exam),
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
                            const Icon(Icons.quiz_rounded, color: AppColors.textMuted, size: 60),
                            const SizedBox(height: 16),
                            Text('No Mock Tests yet', style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 16)),
                            const SizedBox(height: 8),
                            Text('Tap + to upload a PDF and create one',
                                style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 13)),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      itemCount: docs.length,
                      itemBuilder: (_, i) {
                        final doc = docs[i];
                        final data = doc.data();
                        final title = data['title'] ?? 'Untitled';
                        final qCount = data['questionCount'] ?? 0;
                        final ts = data['createdAt'] as Timestamp?;
                        final dateStr = ts != null
                            ? _formatDate(ts.toDate())
                            : '';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    gradient: AppColors.primaryGradient,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.quiz_rounded, color: Colors.white, size: 24),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(title, style: GoogleFonts.outfit(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                                      const SizedBox(height: 4),
                                      Row(children: [
                                        const Icon(Icons.help_outline_rounded, color: AppColors.textMuted, size: 12),
                                        const SizedBox(width: 4),
                                        Text('$qCount Questions', style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 12)),
                                        if (dateStr.isNotEmpty) ...[
                                          const SizedBox(width: 10),
                                          Text('• $dateStr', style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 11)),
                                        ],
                                      ]),
                                    ],
                                  ),
                                ),
                                Column(
                                  children: [
                                    _ActionBtn(
                                      icon: Icons.delete_rounded,
                                      color: AppColors.error,
                                      onTap: () => _deleteQuiz(context, doc.id, title),
                                    ),
                                  ],
                                ),
                              ],
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

  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }
}
