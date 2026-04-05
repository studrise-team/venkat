import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../services/firebase_service.dart';
import '../providers/quiz_provider.dart';

/// Shows quiz list for Aspirant (Mock Tests or Daily Quiz)
class QuizListView extends StatelessWidget {
  final String exam;
  final String collection; // 'quizzes' or 'daily_quizzes'
  final String title;

  const QuizListView({
    super.key,
    required this.exam,
    required this.collection,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
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
                        Text(title, style: GoogleFonts.outfit(
                            color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
                        Text(exam, style: GoogleFonts.outfit(
                            color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
                  stream: FirebaseService().getQuizzesByExam(exam, collection: collection),
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
                            Text('No $title available yet',
                                style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 16)),
                            const SizedBox(height: 8),
                            Text('Check back soon!',
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
                        final qTitle = data['title'] ?? 'Untitled';
                        final qCount = data['questionCount'] ?? 0;
                        final ts = data['createdAt'] as Timestamp?;
                        final dateStr = ts != null ? '${ts.toDate().day}/${ts.toDate().month}/${ts.toDate().year}' : '';

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GestureDetector(
                            onTap: () async {
                              final provider = context.read<QuizProvider>();
                              
                              // Show generic loading if we don't want to rely solely on QuizScreen's loading state
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                              );

                              try {
                                await provider.loadQuestionsFromFirestore(doc.id, qTitle, collection: collection);
                                if (!context.mounted) return;
                                Navigator.pop(context); // hide loading
                                Navigator.pushNamed(context, '/quiz');
                              } catch (e) {
                                if (!context.mounted) return;
                                Navigator.pop(context); // hide loading
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load quiz: $e')));
                              }
                            },
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
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      gradient: collection == 'daily_quizzes'
                                          ? AppColors.accentGradient
                                          : AppColors.primaryGradient,
                                      borderRadius: BorderRadius.circular(13),
                                    ),
                                    child: Icon(
                                      collection == 'daily_quizzes' ? Icons.today_rounded : Icons.quiz_rounded,
                                      color: Colors.white, size: 26,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(qTitle, style: GoogleFonts.outfit(
                                            color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                                        const SizedBox(height: 4),
                                        Row(children: [
                                          const Icon(Icons.help_outline_rounded, color: AppColors.textMuted, size: 12),
                                          const SizedBox(width: 4),
                                          Text('$qCount Questions', style: GoogleFonts.outfit(
                                              color: AppColors.textSecondary, fontSize: 12)),
                                          if (dateStr.isNotEmpty) ...[
                                            const SizedBox(width: 8),
                                            Text('• $dateStr', style: GoogleFonts.outfit(
                                                color: AppColors.textMuted, fontSize: 11)),
                                          ],
                                        ]),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                    decoration: BoxDecoration(
                                      gradient: AppColors.primaryGradient,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text('Start', style: GoogleFonts.outfit(
                                        color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                                  ),
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
