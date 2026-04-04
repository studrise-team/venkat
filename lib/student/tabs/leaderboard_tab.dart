import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../app_theme.dart';

class LeaderboardTab extends StatefulWidget {
  const LeaderboardTab({super.key});

  @override
  State<LeaderboardTab> createState() => _LeaderboardTabState();
}

class _LeaderboardTabState extends State<LeaderboardTab>
    with SingleTickerProviderStateMixin {
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
        // ── Header ──────────────────────────────────────────────────
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: AppColors.accentGradient,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(28),
              bottomRight: Radius.circular(28),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 52, 20, 16),
          child: Column(
            children: [
              const Icon(Icons.emoji_events_rounded,
                  color: Colors.white, size: 36),
              const SizedBox(height: 8),
              Text('Leaderboard',
                  style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('Compete with your peers!',
                  style: GoogleFonts.outfit(
                      color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
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
                  labelColor: const Color(0xFF0F766E),
                  unselectedLabelColor: Colors.white,
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'Weekly'),
                    Tab(text: 'All-Time'),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── Content ─────────────────────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              _RankList(type: 'weekly', uid: _uid),
              _RankList(type: 'allTime', uid: _uid),
            ],
          ),
        ),
      ],
    );
  }
}

class _RankList extends StatelessWidget {
  final String type;
  final String uid;
  const _RankList({required this.type, required this.uid});

  @override
  Widget build(BuildContext context) {
    // We compute leaderboard from student_quiz_results
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('student_quiz_results')
          .orderBy('submittedAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.leaderboard_rounded,
                    size: 48, color: AppColors.textMuted),
                const SizedBox(height: 12),
                Text('No data yet',
                    style: GoogleFonts.outfit(
                        color: AppColors.textMuted, fontSize: 14)),
              ],
            ),
          );
        }

        // Aggregate scores per student
        final docs = snap.data!.docs;
        final now = DateTime.now();
        final Map<String, _StudentScore> scores = {};

        for (final doc in docs) {
          final d = doc.data() as Map<String, dynamic>;
          final studentId = d['studentId'] as String? ?? '';
          final score = (d['score'] as num?)?.toInt() ?? 0;
          final total = (d['total'] as num?)?.toInt() ?? 1;
          final submittedAt = d['submittedAt'] as Timestamp?;

          // For weekly, only include results from last 7 days
          if (type == 'weekly' && submittedAt != null) {
            final diff = now.difference(submittedAt.toDate()).inDays;
            if (diff > 7) continue;
          }

          if (!scores.containsKey(studentId)) {
            scores[studentId] = _StudentScore(
                studentId: studentId, totalScore: 0, totalQuestions: 0, quizCount: 0);
          }
          scores[studentId]!.totalScore += score;
          scores[studentId]!.totalQuestions += total;
          scores[studentId]!.quizCount += 1;
        }

        final sorted = scores.values.toList()
          ..sort((a, b) => b.totalScore.compareTo(a.totalScore));

        if (sorted.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.leaderboard_rounded,
                    size: 48, color: AppColors.textMuted),
                const SizedBox(height: 12),
                Text('No results this ${type == 'weekly' ? 'week' : 'period'}',
                    style: GoogleFonts.outfit(
                        color: AppColors.textMuted, fontSize: 14)),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: sorted.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final s = sorted[i];
            final isMe = s.studentId == uid;
            final rank = i + 1;
            return _RankCard(
              rank: rank,
              score: s,
              isMe: isMe,
            );
          },
        );
      },
    );
  }
}

class _StudentScore {
  final String studentId;
  int totalScore;
  int totalQuestions;
  int quizCount;

  _StudentScore({
    required this.studentId,
    required this.totalScore,
    required this.totalQuestions,
    required this.quizCount,
  });
}

class _RankCard extends StatelessWidget {
  final int rank;
  final _StudentScore score;
  final bool isMe;

  const _RankCard({
    required this.rank,
    required this.score,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(score.studentId)
          .get(),
      builder: (context, userSnap) {
        final Map<String, dynamic> uData = userSnap.data?.exists == true
            ? (userSnap.data!.data() as Map<String, dynamic>?) ?? {}
            : {};
        final userName = uData['name'] ?? 'Student';

        Color rankColor;
        IconData? trophy;
        if (rank == 1) {
          rankColor = const Color(0xFFFFD700);
          trophy = Icons.emoji_events_rounded;
        } else if (rank == 2) {
          rankColor = const Color(0xFFC0C0C0);
          trophy = Icons.emoji_events_rounded;
        } else if (rank == 3) {
          rankColor = const Color(0xFFCD7F32);
          trophy = Icons.emoji_events_rounded;
        } else {
          rankColor = AppColors.textMuted;
          trophy = null;
        }

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isMe
                ? AppColors.primary.withValues(alpha: 0.08)
                : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isMe ? AppColors.primary : AppColors.cardBorder,
              width: isMe ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              // Rank
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: rank <= 3
                      ? rankColor.withValues(alpha: 0.15)
                      : AppColors.cardLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: trophy != null
                    ? Icon(trophy, color: rankColor, size: 22)
                    : Text('#$rank',
                        style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textSecondary)),
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(userName.toString(),
                            style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: AppColors.textPrimary)),
                        if (isMe) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('YOU',
                                style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w800)),
                          ),
                        ],
                      ],
                    ),
                    Text('${score.quizCount} quizzes taken',
                        style: GoogleFonts.outfit(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              // Score
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${score.totalScore}',
                      style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary)),
                  Text('/ ${score.totalQuestions}',
                      style: GoogleFonts.outfit(
                          fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
