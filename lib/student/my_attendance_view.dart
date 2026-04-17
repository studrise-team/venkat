import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../app_theme.dart';

class MyAttendanceView extends StatelessWidget {
  final String className;
  final String studentName;
  final String? subject;
  final bool showBackButton;
  const MyAttendanceView({super.key, required this.className, required this.studentName, this.subject, this.showBackButton = true});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Header
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
                          Text('My Attendance', style: GoogleFonts.outfit(
                              color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
                          Text(subject != null ? '$studentName • $subject' : studentName, 
                              style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: (() {
                    var query = FirebaseFirestore.instance
                        .collection('student_attendance')
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
                    final records = docs.map((d) => d.data()).toList();

                    if (records.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.how_to_reg_rounded, color: AppColors.textMuted, size: 60),
                            const SizedBox(height: 16),
                            Text('No records found',
                                style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 16)),
                          ],
                        ),
                      );
                    }

                    // Stats
                    final present = records.where((e) => e['status'] == 'Present').length;
                    final total = records.length;
                    final pct = total > 0 ? (present / total) : 0.0;

                    return CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                // Stats Card
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    gradient: AppColors.primaryGradient,
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
                                  ),
                                  child: Row(
                                    children: [
                                      _CircularPct(pct: pct),
                                      const SizedBox(width: 24),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Attendance', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12)),
                                            Text('${(pct * 100).toStringAsFixed(0)}%', style: GoogleFonts.outfit(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800)),
                                            const SizedBox(height: 4),
                                            Text('$present days present out of $total', style: GoogleFonts.outfit(color: Colors.white60, fontSize: 11)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 32),
                                // Graph Section
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Trend Graph', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 16)),
                                    const Icon(Icons.trending_up_rounded, color: AppColors.primary),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  height: 160,
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                                  decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.cardBorder)),
                                  child: _TrendGraph(records: records),
                                ),
                                const SizedBox(height: 32),
                                Align(alignment: Alignment.centerLeft, child: Text('History', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 16))),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ),
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, i) {
                              final data = records[i];
                              final isPresent = data['status'] == 'Present';

                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.cardBorder)),
                                  child: Row(
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(data['date'] ?? '', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                                          Text(data['subject'] ?? 'General', style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 11)),
                                        ],
                                      ),
                                      const Spacer(),
                                      _StatusBadge(isPresent: isPresent),
                                    ],
                                  ),
                                ),
                              );
                            },
                            childCount: records.length,
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 40)),
                      ],
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

class _CircularPct extends StatelessWidget {
  final double pct;
  const _CircularPct({required this.pct});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 70,
      height: 70,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(value: pct, strokeWidth: 8, backgroundColor: Colors.white12, valueColor: const AlwaysStoppedAnimation(Colors.white)),
          Center(child: Icon(Icons.auto_graph_rounded, color: Colors.white, size: 24)),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isPresent;
  const _StatusBadge({required this.isPresent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: (isPresent ? AppColors.success : AppColors.error).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
      child: Text(isPresent ? 'PRESENT' : 'ABSENT', style: GoogleFonts.outfit(color: isPresent ? AppColors.success : AppColors.error, fontSize: 10, fontWeight: FontWeight.w800)),
    );
  }
}

class _TrendGraph extends StatelessWidget {
  final List<Map<String, dynamic>> records;
  const _TrendGraph({required this.records});

  @override
  Widget build(BuildContext context) {
    // Basic trend: 0 for Absent, 1 for Present
    final sorted = List<Map<String, dynamic>>.from(records)..sort((a,b) {
      try {
        final df = DateFormat('dd/MM/yyyy');
        return df.parse(a['date']).compareTo(df.parse(b['date']));
      } catch (e) { return 0; }
    });

    final spots = <FlSpot>[];
    for(int i = 0; i < sorted.length; i++) {
       spots.add(FlSpot(i.toDouble(), (sorted[i]['status'] == 'Present' ? 1.0 : 0.0)));
    }

    if(spots.length < 2) return const Center(child: Text('More data needed for trend', style: TextStyle(fontSize: 10)));

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            gradient: const LinearGradient(colors: [AppColors.primary, AppColors.accent]),
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(show: true, gradient: LinearGradient(colors: [AppColors.primary.withValues(alpha: 0.3), AppColors.primary.withValues(alpha: 0.01)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
          ),
        ],
      ),
    );
  }
}
