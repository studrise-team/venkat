import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../app_theme.dart';

/// Admin tab: mark and view attendance for all students.
class SAAttendanceTab extends StatefulWidget {
  const SAAttendanceTab({super.key});

  @override
  State<SAAttendanceTab> createState() => _SAAttendanceTabState();
}

class _SAAttendanceTabState extends State<SAAttendanceTab> {
  DateTime _selectedDate = DateTime.now();
  bool _saving = false;

  // studentId -> status
  final Map<String, String> _statusMap = {};

  String get _dateKey =>
      DateFormat('yyyy-MM-dd').format(_selectedDate);
  String get _monthKey =>
      DateFormat('yyyy-MM').format(_selectedDate);

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    // Load existing attendance records for this date
    final studentsSnap = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'student')
        .get();

    final Map<String, String> loaded = {};
    for (final doc in studentsSnap.docs) {
      final attDoc = await FirebaseFirestore.instance
          .collection('attendance')
          .doc(doc.id)
          .collection('months')
          .doc(_monthKey)
          .get();
      if (attDoc.exists) {
        final days =
            Map<String, String>.from(attDoc.data()?['days'] ?? {});
        loaded[doc.id] = days[_dateKey] ?? 'unmarked';
      } else {
        loaded[doc.id] = 'unmarked';
      }
    }
    if (mounted) setState(() => _statusMap..addAll(loaded));
  }

  Future<void> _saveAll() async {
    setState(() => _saving = true);
    for (final entry in _statusMap.entries) {
      if (entry.value == 'unmarked') continue;
      await FirebaseFirestore.instance
          .collection('attendance')
          .doc(entry.key)
          .collection('months')
          .doc(_monthKey)
          .set({
        'days': {_dateKey: entry.value}
      }, SetOptions(merge: true));
    }
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Attendance saved!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
        _statusMap.clear();
      });
      _loadExisting();
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Header
        SliverToBoxAdapter(
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF047857)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(24, 52, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mark Attendance',
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('Record daily roll call for students',
                    style: GoogleFonts.outfit(
                        color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today_rounded,
                            color: Colors.white, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('EEE, d MMM yyyy')
                              .format(_selectedDate),
                          style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_drop_down_rounded,
                            color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Leave Requests Horizontal List
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('leave_requests')
              .where('status', isEqualTo: 'pending')
              .snapshots(),
          builder: (context, snap) {
            if (!snap.hasData || snap.data!.docs.isEmpty) return const SliverToBoxAdapter(child: SizedBox());
            final docs = snap.data!.docs;
            return SliverToBoxAdapter(
              child: Container(
                height: 140,
                margin: const EdgeInsets.only(top: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text('Pending Leave Requests', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        scrollDirection: Axis.horizontal,
                        itemCount: docs.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, i) {
                          final d = docs[i].data() as Map<String, dynamic>;
                          final docId = docs[i].id;
                          return Container(
                            width: 260,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(d['studentName'] ?? 'Student', 
                                        style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13)),
                                    ),
                                    Text(d['date'] ?? '', 
                                      style: GoogleFonts.outfit(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(d['reason'] ?? '', 
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary)),
                                const Spacer(),
                                Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () => _handleLeave(docId, d, 'approved'),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 6),
                                          decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                          alignment: Alignment.center,
                                          child: Text('Approve', style: GoogleFonts.outfit(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w700)),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () => _handleLeave(docId, d, 'rejected'),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 6),
                                          decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                          alignment: Alignment.center,
                                          child: Text('Reject', style: GoogleFonts.outfit(fontSize: 11, color: AppColors.error, fontWeight: FontWeight.w700)),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        // Legend
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Legend('Present', AppColors.success),
                const SizedBox(width: 16),
                _Legend('Absent', AppColors.error),
                const SizedBox(width: 16),
                _Legend('Holiday', AppColors.warning),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 12)),

        // Students list
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: 'student')
              .snapshots(),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()));
            }
            if (snap.data!.docs.isEmpty) {
              return const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                      child: Text('No students enrolled.',
                          style:
                              TextStyle(color: AppColors.textMuted))),
                ),
              );
            }
            final docs = snap.data!.docs.toList();
            docs.sort((a, b) {
              final an = (a.data() as Map<String, dynamic>)['name'] ?? '';
              final bn = (b.data() as Map<String, dynamic>)['name'] ?? '';
              return an.toString().compareTo(bn.toString());
            });
            return SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final doc = docs[i];
                    final d = doc.data() as Map<String, dynamic>;
                    final name = d['name'] ?? 'Student';
                    final sid = doc.id;
                    final status =
                        _statusMap[sid] ?? 'unmarked';
                    return _AttendanceRow(
                      name: name,
                      rollNumber: d['rollNumber'] ?? '',
                      status: status,
                      onStatus: (s) {
                        setState(() => _statusMap[sid] = s);
                      },
                    );
                  },
                  childCount: docs.length,
                ),
              ),
            );
          },
        ),

        // Save button
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: GestureDetector(
              onTap: _saving ? null : _saveAll,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF047857)]),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text('💾 Save Attendance',
                        style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleLeave(String docId, Map<String, dynamic> data, String status) async {
    final studentId = data['studentId'];
    final date = data['date'];
    final month = date.substring(0, 7);

    final batch = FirebaseFirestore.instance.batch();
    batch.update(FirebaseFirestore.instance.collection('leave_requests').doc(docId), {
      'status': status,
    });

    if (status == 'approved') {
       batch.set(
        FirebaseFirestore.instance.collection('attendance').doc(studentId).collection('months').doc(month),
        { 'days': {date: 'holiday'} }, 
        SetOptions(merge: true)
      );
    }

    await batch.commit();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Leave Request $status'), backgroundColor: status == 'approved' ? AppColors.success : AppColors.error),
      );
    }
  }
}

class _AttendanceRow extends StatelessWidget {
  final String name;
  final String rollNumber;
  final String status;
  final ValueChanged<String> onStatus;
  const _AttendanceRow({
    required this.name,
    required this.rollNumber,
    required this.status,
    required this.onStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'S',
              style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                if (rollNumber.isNotEmpty)
                  Text('Roll: $rollNumber',
                      style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: AppColors.textSecondary)),
              ],
            ),
          ),
          // Status toggle buttons
          Row(
            children: [
              _StatusBtn('P', 'present', status, AppColors.success,
                  onStatus),
              const SizedBox(width: 6),
              _StatusBtn(
                  'A', 'absent', status, AppColors.error, onStatus),
              const SizedBox(width: 6),
              _StatusBtn('H', 'holiday', status, AppColors.warning,
                  onStatus),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBtn extends StatelessWidget {
  final String label, value, current;
  final Color color;
  final ValueChanged<String> onTap;
  const _StatusBtn(
      this.label, this.value, this.current, this.color, this.onTap);

  @override
  Widget build(BuildContext context) {
    final selected = current == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: selected ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.outfit(
            color: selected ? Colors.white : color,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final String label;
  final Color color;
  const _Legend(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
          width: 12,
          height: 12,
          decoration:
              BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label,
          style: GoogleFonts.outfit(
              fontSize: 12, color: AppColors.textSecondary)),
    ]);
  }
}
