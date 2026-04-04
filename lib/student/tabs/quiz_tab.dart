import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../app_theme.dart';
import '../../providers/quiz_provider.dart';

class QuizTab extends StatefulWidget {
  const QuizTab({super.key});

  @override
  State<QuizTab> createState() => _QuizTabState();
}

class _QuizTabState extends State<QuizTab> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Header ──────────────────────────────────────────────
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(28),
              bottomRight: Radius.circular(28),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 52, 20, 16),
          child: Column(
            children: [
              Text('Daily Quizzes',
                  style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('Test your knowledge every day!',
                  style: GoogleFonts.outfit(
                      color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabCtrl,
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  labelStyle: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700, fontSize: 13),
                  unselectedLabelStyle: GoogleFonts.outfit(fontSize: 13),
                  labelColor: AppColors.primary,
                  unselectedLabelColor: Colors.white,
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'Available'),
                    Tab(text: 'My Results'),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── Content ─────────────────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              _AvailableQuizzes(uid: _uid),
              _QuizResults(uid: _uid),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Available Quizzes ──────────────────────────────────────────────────────

class _AvailableQuizzes extends StatelessWidget {
  final String uid;
  const _AvailableQuizzes({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('student_quizzes')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return _EmptyState(
            icon: Icons.quiz_rounded,
            message: 'No quizzes available yet',
            subtitle: 'Your admin will post daily quizzes here.',
          );
        }
        final docs = snap.data!.docs;
        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final d = docs[i].data() as Map<String, dynamic>;
            final quizId = docs[i].id;
            return _QuizCard(
              quizId: quizId,
              data: d,
              uid: uid,
            );
          },
        );
      },
    );
  }
}

class _QuizCard extends StatelessWidget {
  final String quizId;
  final Map<String, dynamic> data;
  final String uid;

  const _QuizCard({
    required this.quizId,
    required this.data,
    required this.uid,
  });

  @override
  Widget build(BuildContext context) {
    final title = data['title'] ?? 'Quiz';
    final subject = data['subject'] ?? '';
    final questions = (data['questions'] as List?)?.length ?? 0;
    final duration = data['durationMinutes'] ?? 10;
    final createdAt = data['createdAt'] as Timestamp?;
    final dateStr = createdAt != null
        ? '${createdAt.toDate().day}/${createdAt.toDate().month}/${createdAt.toDate().year}'
        : '';

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('student_quiz_results')
          .doc('${uid}_$quizId')
          .get(),
      builder: (context, resultSnap) {
        final alreadyTaken = resultSnap.data?.exists ?? false;
        final Map<String, dynamic> rData = alreadyTaken
            ? (resultSnap.data!.data() as Map<String, dynamic>?) ?? {}
            : {};
        final score = alreadyTaken ? rData['score'] : null;
        final total = alreadyTaken ? rData['total'] : null;

        return GestureDetector(
          onTap: alreadyTaken
              ? null
              : () => _startQuiz(context, quizId, data),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: alreadyTaken
                    ? AppColors.success.withOpacity(0.3)
                    : AppColors.cardBorder,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: alreadyTaken
                        ? const LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF059669)])
                        : AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    alreadyTaken
                        ? Icons.check_circle_rounded
                        : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 2),
                      if (subject.isNotEmpty)
                        Text(subject,
                            style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: AppColors.textSecondary)),
                      Row(
                        children: [
                          Icon(Icons.help_outline_rounded,
                              size: 12, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Text('$questions Qs',
                              style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  color: AppColors.textMuted)),
                          const SizedBox(width: 12),
                          Icon(Icons.timer_outlined,
                              size: 12, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Text('${duration}m',
                              style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  color: AppColors.textMuted)),
                          const SizedBox(width: 12),
                          Text(dateStr,
                              style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  color: AppColors.textMuted)),
                        ],
                      ),
                    ],
                  ),
                ),
                if (alreadyTaken && score != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$score/$total',
                      style: GoogleFonts.outfit(
                          color: AppColors.success,
                          fontWeight: FontWeight.w800,
                          fontSize: 13),
                    ),
                  )
                else
                  const Icon(Icons.arrow_forward_ios_rounded,
                      size: 14, color: AppColors.textMuted),
              ],
            ),
          ),
        );
      },
    );
  }

  void _startQuiz(
      BuildContext context, String quizId, Map<String, dynamic> data) async {
    final provider = context.read<QuizProvider>();
    await provider.loadQuestionsFromFirestore(quizId, data['title'] ?? 'Quiz', collection: 'student_quizzes');
    if (context.mounted) {
      if (provider.state == QuizState.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.errorMessage), backgroundColor: AppColors.error),
        );
      } else {
        Navigator.pushNamed(context, '/quiz');
      }
    }
  }
}

// ── Quiz Results ───────────────────────────────────────────────────────────

// ── Quiz Results ───────────────────────────────────────────────────────────

class _QuizResults extends StatelessWidget {
  final String uid;
  const _QuizResults({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('student_quiz_results')
          .where('studentId', isEqualTo: uid)
          .orderBy('submittedAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return _EmptyState(
            icon: Icons.assignment_outlined,
            message: 'No quiz attempts yet',
            subtitle: 'Take a quiz to see your results here.',
          );
        }
        final docs = snap.data!.docs;
        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final d = docs[i].data() as Map<String, dynamic>;
            final score = d['score'] ?? 0;
            final total = d['total'] ?? 1;
            final pct = (score / total * 100).round();
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: pct >= 70
                          ? AppColors.primaryGradient
                          : pct >= 40
                              ? AppColors.accentGradient
                              : const LinearGradient(
                                  colors: [
                                      Color(0xFFEF4444),
                                      Color(0xFFDC2626)
                                    ]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text('$pct%',
                        style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(d['quizTitle'] ?? 'Quiz',
                            style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: AppColors.textPrimary)),
                        Text('$score / $total correct',
                            style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ── Empty State ────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.message,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardLight,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            Text(message,
                style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text(subtitle,
                style: GoogleFonts.outfit(
                    fontSize: 13, color: AppColors.textSecondary),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
