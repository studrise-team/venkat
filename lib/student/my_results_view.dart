import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../app_theme.dart';

class MyResultsView extends StatefulWidget {
  final String className;
  final String studentId;
  final String? subject;
  final bool showBackButton;
  const MyResultsView({super.key, required this.className, required this.studentId, this.subject, this.showBackButton = true});

  @override
  State<MyResultsView> createState() => _MyResultsViewState();
}

class _MyResultsViewState extends State<MyResultsView> {
  late Stream<QuerySnapshot<Map<String, dynamic>>> _resultsStream;

  @override
  void initState() {
    super.initState();
    _initStream();
  }

  void _initStream() {
    var query = FirebaseFirestore.instance
        .collection('student_quiz_results')
        .where('exam', isEqualTo: widget.className)
        .where('studentId', isEqualTo: widget.studentId);
    
    if (widget.subject != null) {
      query = query.where('subject', isEqualTo: widget.subject);
    }
    
    _resultsStream = query.snapshots();
  }

  @override
  void didUpdateWidget(MyResultsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.className != widget.className || 
        oldWidget.studentId != widget.studentId || 
        oldWidget.subject != widget.subject) {
      _initStream();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(widget.showBackButton ? 8 : 24, 12, 16, 0),
                child: Row(
                  children: [
                    if (widget.showBackButton)
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
                          Text(widget.subject != null ? '${widget.className} • ${widget.subject}' : widget.className, 
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
                  stream: _resultsStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 40),
                              const SizedBox(height: 16),
                              Text('Query Error', style: GoogleFonts.outfit(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Text(snapshot.error.toString(), 
                                textAlign: TextAlign.center,
                                style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 12)),
                              if (snapshot.error.toString().contains('index'))
                                Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: Text('This query needs a Firestore index. Check the link in your debug console.', 
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.outfit(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600)),
                                ),
                            ],
                          ),
                        ),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                    }
                    
                    // Sort in memory to avoid index requirements
                    final docs = snapshot.data?.docs.toList() ?? [];
                    docs.sort((a, b) {
                      final t1 = a.data()['submittedAt'] as Timestamp?;
                      final t2 = b.data()['submittedAt'] as Timestamp?;
                      if (t1 == null) return -1;
                      if (t2 == null) return 1;
                      return t2.compareTo(t1);
                    });

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
