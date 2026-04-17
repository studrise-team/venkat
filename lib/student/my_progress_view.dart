import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../app_theme.dart';

class MyProgressView extends StatelessWidget {
  final String className;
  final String studentName;
  final String? subject;
  const MyProgressView({super.key, required this.className, required this.studentName, this.subject});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
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
                          Text('My Academic Progress', style: GoogleFonts.outfit(
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
                        .collection('student_progress')
                        .where('exam', isEqualTo: className)
                        .where('studentName', isEqualTo: studentName);
                    if (subject != null) {
                      query = query.where('subject', isEqualTo: subject);
                    }
                    return query.snapshots();
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
                            const Icon(Icons.trending_up_rounded, color: AppColors.textMuted, size: 60),
                            const SizedBox(height: 16),
                            Text('No progress reports yet',
                                style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 16)),
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
                        return Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(data['term'] ?? 'Report', style: GoogleFonts.outfit(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
                                  const Spacer(),
                                  const Icon(Icons.verified_rounded, color: AppColors.success, size: 18),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _ScoreItem(label: 'Math', score: data['math'] ?? '-'),
                                  _ScoreItem(label: 'Science', score: data['science'] ?? '-'),
                                  _ScoreItem(label: 'English', score: data['english'] ?? '-'),
                                ],
                              ),
                              if (data['remarks'] != null && data['remarks'].toString().isNotEmpty) ...[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10)),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Teacher Remarks', style: GoogleFonts.outfit(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                                      const SizedBox(height: 4),
                                      Text(data['remarks'], style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 12, height: 1.4)),
                                    ],
                                  ),
                                ),
                              ],
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
}

class _ScoreItem extends StatelessWidget {
  final String label;
  final String score;
  const _ScoreItem({required this.label, required this.score});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(score, style: GoogleFonts.outfit(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w800)),
      ],
    );
  }
}
