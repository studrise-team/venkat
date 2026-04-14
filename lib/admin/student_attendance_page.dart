import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../app_theme.dart';
import '../services/firebase_service.dart';
import 'shared_widgets.dart';

class StudentAttendancePage extends StatefulWidget {
  final String className;
  const StudentAttendancePage({super.key, required this.className});

  @override
  State<StudentAttendancePage> createState() => _StudentAttendancePageState();
}

class _StudentAttendancePageState extends State<StudentAttendancePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text('${widget.className} Attendance', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13),
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'Mark', icon: Icon(Icons.how_to_reg_rounded)),
            Tab(text: 'Records', icon: Icon(Icons.list_alt_rounded)),
            Tab(text: 'Analytics', icon: Icon(Icons.analytics_rounded)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _MarkAttendanceTab(className: widget.className),
          _RecordsTab(className: widget.className),
          _AttendanceAnalyticsTab(className: widget.className),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PART 1: MARK ATTENDANCE
// ─────────────────────────────────────────────────────────────────────────────

class _MarkAttendanceTab extends StatefulWidget {
  final String className;
  const _MarkAttendanceTab({required this.className});

  @override
  State<_MarkAttendanceTab> createState() => _MarkAttendanceTabState();
}

class _MarkAttendanceTabState extends State<_MarkAttendanceTab> {
  DateTime _selectedDate = DateTime.now();
  final _subjectCtrl = TextEditingController(text: 'General');
  List<Map<String, dynamic>> _students = [];
  Map<String, String> _statuses = {}; // studentId -> status
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() => _loading = true);
    final list = await FirebaseService().getStudentsByClass(widget.className);
    for (var s in list) {
      _statuses[s['uid']] = 'Present';
    }
    setState(() {
      _students = list;
      _loading = false;
    });
  }

  Future<void> _save() async {
    if (_subjectCtrl.text.trim().isEmpty) {
      showAdminSnackBar(context, 'Subject is required.', type: AdminSnackType.warning);
      return;
    }
    setState(() => _saving = true);
    try {
      final dateStr = DateFormat('dd/MM/yyyy').format(_selectedDate);
      final records = _students.map((s) => {
        'studentId': s['uid'],
        'studentName': s['name'],
        'exam': widget.className,
        'subject': _subjectCtrl.text.trim(),
        'date': dateStr,
        'status': _statuses[s['uid']] ?? 'Present',
      }).toList();

      await FirebaseService().saveBulkAttendance(records);
      if (mounted) showAdminSnackBar(context, 'Attendance marked successfully!');
    } catch (e) {
      if (mounted) showAdminSnackBar(context, 'Error: $e', type: AdminSnackType.error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    if (_students.isEmpty) return const Center(child: Text('No students registered for this class.'));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2024),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) setState(() => _selectedDate = date);
                        },
                        child: _InfoTile(label: 'Date', value: DateFormat('dd MMM, yyyy').format(_selectedDate), icon: Icons.calendar_today_rounded),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AdminSheetField(controller: _subjectCtrl, label: 'Subject', icon: Icons.subject_rounded, hint: 'e.g. Mathematics'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _students.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final s = _students[i];
              final status = _statuses[s['uid']] ?? 'Present';
              final isPresent = status == 'Present';

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    CircleAvatar(backgroundColor: AppColors.primary.withValues(alpha: 0.1), child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 20)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(s['name'] ?? 'Student', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                    ),
                    Row(
                      children: [
                        _StatusToggle(label: 'P', selected: isPresent, color: AppColors.success, onTap: () => setState(() => _statuses[s['uid']] = 'Present')),
                        const SizedBox(width: 8),
                        _StatusToggle(label: 'A', selected: !isPresent, color: AppColors.error, onTap: () => setState(() => _statuses[s['uid']] = 'Absent')),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: AdminButton(label: 'Save Attendance', icon: Icons.save_rounded, isLoading: _saving, onPressed: _save),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PART 2: VIEWS/RECORDS
// ─────────────────────────────────────────────────────────────────────────────

class _RecordsTab extends StatelessWidget {
  final String className;
  const _RecordsTab({required this.className});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirebaseService().getAttendanceStream(className),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final records = snapshot.data ?? [];
        if (records.isEmpty) return const Center(child: Text('No attendance records found.'));

        // Group by Date for cleaner UI
        final grouped = <String, List<Map<String, dynamic>>>{};
        for (var r in records) {
          final d = r['date'] ?? 'No Date';
          grouped.putIfAbsent(d, () => []).add(r);
        }

        final dates = grouped.keys.toList();

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: dates.length,
          itemBuilder: (context, i) {
            final date = dates[i];
            final items = grouped[date]!;
            final presentCount = items.where((e) => e['status'] == 'Present').length;

            return ExpansionTile(
              title: Text(date, style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
              subtitle: Text('$presentCount / ${items.length} Present', style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary)),
              children: items.map((r) => ListTile(
                title: Text(r['studentName'] ?? 'Student', style: GoogleFonts.outfit(fontSize: 14)),
                subtitle: Text(r['subject'] ?? 'General', style: GoogleFonts.outfit(fontSize: 11)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _MiniStatusBadge(status: r['status']),
                    IconButton(
                      icon: const Icon(Icons.edit_rounded, size: 18, color: AppColors.primary),
                      onPressed: () => _editRecord(context, r),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_rounded, size: 18, color: AppColors.error),
                      onPressed: () => FirebaseService().deleteDocument('student_attendance', r['id']),
                    ),
                  ],
                ),
              )).toList(),
            );
          },
        );
      },
    );
  }

  void _editRecord(BuildContext context, Map<String, dynamic> record) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditAttendanceSheet(record: record),
    );
  }
}

class _EditAttendanceSheet extends StatefulWidget {
  final Map<String, dynamic> record;
  const _EditAttendanceSheet({required this.record});

  @override
  State<_EditAttendanceSheet> createState() => _EditAttendanceSheetState();
}

class _EditAttendanceSheetState extends State<_EditAttendanceSheet> {
  late String _status;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _status = widget.record['status'] ?? 'Present';
  }

  @override
  Widget build(BuildContext context) {
    return AdminFormSheet(
      title: 'Edit Record',
      isLoading: _loading,
      onSave: () async {
        setState(() => _loading = true);
        await FirebaseService().updateDocument('student_attendance', widget.record['id'], {'status': _status});
        if (mounted) {
          Navigator.pop(context);
          showAdminSnackBar(context, 'Updated!');
        }
      },
      fields: [
        Text(widget.record['studentName'] ?? '', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 16)),
        Text(widget.record['date'] ?? '', style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 20),
        Row(
          children: [
            _StatusChoice(label: 'Present', selected: _status == 'Present', color: AppColors.success, onTap: () => setState(() => _status = 'Present')),
            const SizedBox(width: 12),
            _StatusChoice(label: 'Absent', selected: _status == 'Absent', color: AppColors.error, onTap: () => setState(() => _status = 'Absent')),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PART 3: ANALYTICS
// ─────────────────────────────────────────────────────────────────────────────

class _AttendanceAnalyticsTab extends StatelessWidget {
  final String className;
  const _AttendanceAnalyticsTab({required this.className});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirebaseService().getAttendanceStream(className),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final records = snapshot.data ?? [];
        if (records.isEmpty) return const Center(child: Text('Add records to see analytics.'));

        // Calculate stats
        final present = records.where((e) => e['status'] == 'Present').length;
        final total = records.length;
        final pct = total > 0 ? (present / total) : 0.0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Summary', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 18)),
              const SizedBox(height: 16),
              Row(
                children: [
                  _StatCard(label: 'Overall %', value: '${(pct * 100).toStringAsFixed(1)}%', color: AppColors.primary),
                  const SizedBox(width: 16),
                  _StatCard(label: 'Total Entries', value: '$total', color: AppColors.accent),
                ],
              ),
              const SizedBox(height: 32),
              Text('Attendance Trend', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: AttendanceLineChart(records: records),
              ),
              const SizedBox(height: 32),
              Text('Individual Performance', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 16),
              // Simulating student wise list
              ..._buildStudentLeaderboard(records),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildStudentLeaderboard(List<Map<String, dynamic>> records) {
    final map = <String, List<bool>>{};
    for (var r in records) {
      final name = r['studentName'] ?? 'Unknown';
      map.putIfAbsent(name, () => []).add(r['status'] == 'Present');
    }

    final sorted = map.entries.toList()..sort((a, b) {
      final aPct = a.value.where((e) => e).length / a.value.length;
      final bPct = b.value.where((e) => e).length / b.value.length;
      return bPct.compareTo(aPct);
    });

    return sorted.take(5).map((e) {
      final pCount = e.value.where((x) => x).length;
      final total = e.value.length;
      final pct = pCount / total;
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.cardBorder)),
          child: Row(
            children: [
              Text(e.key, style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13)),
              const Spacer(),
              Text('${(pct * 100).toStringAsFixed(0)}%', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: pct > 0.75 ? AppColors.success : AppColors.warning)),
            ],
          ),
        ),
      );
    }).toList();
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

class _InfoTile extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _InfoTile({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 11)),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(icon, size: 14, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(value, style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 14)),
          ],
        ),
      ],
    );
  }
}

class _StatusToggle extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _StatusToggle({required this.label, required this.selected, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(color: selected ? color : AppColors.cardBorder),
        ),
        child: Center(child: Text(label, style: GoogleFonts.outfit(color: selected ? Colors.white : AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 12))),
      ),
    );
  }
}

class _StatusChoice extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _StatusChoice({required this.label, required this.selected, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.1) : AppColors.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? color : AppColors.cardBorder),
          ),
          child: Center(child: Text(label, style: GoogleFonts.outfit(color: selected ? color : AppColors.textSecondary, fontWeight: FontWeight.w700))),
        ),
      ),
    );
  }
}

class _MiniStatusBadge extends StatelessWidget {
  final String? status;
  const _MiniStatusBadge({this.status});

  @override
  Widget build(BuildContext context) {
    final isPresent = status == 'Present';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: (isPresent ? AppColors.success : AppColors.error).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(status?.toUpperCase() ?? 'P', style: GoogleFonts.outfit(color: isPresent ? AppColors.success : AppColors.error, fontSize: 8, fontWeight: FontWeight.w800)),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withValues(alpha: 0.2))),
        child: Column(
          children: [
            Text(value, style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 24, color: color)),
            Text(label, style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

// ── Chart Widget ─────────────────────────────────────────────────────────────

class AttendanceLineChart extends StatelessWidget {
  final List<Map<String, dynamic>> records;
  const AttendanceLineChart({super.key, required this.records});

  @override
  Widget build(BuildContext context) {
    // Logic to aggregate average daily presence
    final dailyMap = <String, List<bool>>{};
    for (var r in records) {
      final date = r['date'] ?? 'Unknown';
      dailyMap.putIfAbsent(date, () => []).add(r['status'] == 'Present');
    }

    // Sort dates
    final sortedDates = dailyMap.keys.toList()..sort((a,b) {
      try {
        final df = DateFormat('dd/MM/yyyy');
        return df.parse(a).compareTo(df.parse(b));
      } catch (e) { return 0; }
    });

    final spots = <FlSpot>[];
    for (int i = 0; i < sortedDates.length; i++) {
      final dayEntries = dailyMap[sortedDates[i]]!;
      final pCount = dayEntries.where((x) => x).length;
      final pct = pCount / dayEntries.length;
      spots.add(FlSpot(i.toDouble(), pct * 100));
    }

    if (spots.isEmpty) return const Center(child: Text('Not enough data'));

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
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(show: true, gradient: LinearGradient(colors: [AppColors.primary.withValues(alpha: 0.2), AppColors.accent.withValues(alpha: 0.01)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
          ),
        ],
      ),
    );
  }
}
