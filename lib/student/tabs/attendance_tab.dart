import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../app_theme.dart';

class AttendanceTab extends StatefulWidget {
  const AttendanceTab({super.key});

  @override
  State<AttendanceTab> createState() => _AttendanceTabState();
}

class _AttendanceTabState extends State<AttendanceTab> {
  DateTime _focusedMonth = DateTime.now();
  Map<String, String> _attendanceMap = {}; // 'yyyy-MM-dd' -> 'present'|'absent'|'holiday'
  bool _loading = true;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _loadMonth();
  }

  void _loadMonth() async {
    setState(() => _loading = true);
    final monthKey = DateFormat('yyyy-MM').format(_focusedMonth);
    final snap = await FirebaseFirestore.instance
        .collection('attendance')
        .doc(_uid)
        .collection('months')
        .doc(monthKey)
        .get();
    if (mounted) {
      setState(() {
        _attendanceMap = snap.exists
            ? Map<String, String>.from(snap.data()?['days'] ?? {})
            : {};
        _loading = false;
      });
    }
  }

  void _prevMonth() {
    setState(() => _focusedMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month - 1));
    _loadMonth();
  }

  void _nextMonth() {
    final now = DateTime.now();
    if (_focusedMonth.year == now.year && _focusedMonth.month == now.month) return;
    setState(() => _focusedMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month + 1));
    _loadMonth();
  }

  int get _daysInMonth =>
      DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
  int get _firstWeekday =>
      DateTime(_focusedMonth.year, _focusedMonth.month, 1).weekday % 7; // 0=Sun

  int get _present =>
      _attendanceMap.values.where((v) => v == 'present').length;
  int get _absent =>
      _attendanceMap.values.where((v) => v == 'absent').length;
  int get _total => _present + _absent;
  double get _pct => _total == 0 ? 0 : _present / _total;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Header ────────────────────────────────────────────────────────
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(28),
              bottomRight: Radius.circular(28),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 52, 20, 24),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Attendance',
                      style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800)),
                  GestureDetector(
                    onTap: () {
                      final dashboard = context.findAncestorStateOfType<State>();
                      if (dashboard != null && dashboard.runtimeType.toString().contains('Dashboard')) {
                         (dashboard as dynamic)._confirmLogout(context);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.logout_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatBubble('Present', '$_present', AppColors.success),
                  _StatBubble('Absent', '$_absent', AppColors.error),
                  _StatBubble(
                      'Rate',
                      '${(_pct * 100).toStringAsFixed(0)}%',
                      _pct >= 0.75 ? AppColors.success : AppColors.warning),
                ],
              ),
              const SizedBox(height: 14),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _pct,
                  minHeight: 8,
                  backgroundColor: Colors.white24,
                  valueColor: AlwaysStoppedAnimation<Color>(
                      _pct >= 0.75 ? AppColors.success : AppColors.warning),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _pct >= 0.75
                    ? '✅ Attendance is good!'
                    : '⚠️ Attendance below 75% – improve now!',
                style: GoogleFonts.outfit(
                    color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),

        // ── Month Navigator ──────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: _prevMonth,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: AppColors.cardLight,
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.chevron_left_rounded,
                      color: AppColors.textPrimary),
                ),
              ),
              Text(
                DateFormat('MMMM yyyy').format(_focusedMonth),
                style: GoogleFonts.outfit(
                    fontSize: 16, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary),
              ),
              GestureDetector(
                onTap: _nextMonth,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: AppColors.cardLight,
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.chevron_right_rounded,
                      color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
        ),

        // ── Calendar ────────────────────────────────────────────────────
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      // Day labels
                      Row(
                        children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                            .map((d) => Expanded(
                                  child: Center(
                                    child: Text(d,
                                        style: GoogleFonts.outfit(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textMuted)),
                                  ),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 8),
                      // Grid
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          mainAxisSpacing: 6,
                          crossAxisSpacing: 6,
                          childAspectRatio: 1,
                        ),
                        itemCount: _daysInMonth + _firstWeekday,
                        itemBuilder: (context, idx) {
                          if (idx < _firstWeekday) return const SizedBox();
                          final day = idx - _firstWeekday + 1;
                          final dateKey = DateFormat('yyyy-MM-dd').format(
                            DateTime(_focusedMonth.year,
                                _focusedMonth.month, day),
                          );
                          final status = _attendanceMap[dateKey];
                          final isToday =
                              DateTime.now().day == day &&
                                  DateTime.now().month ==
                                      _focusedMonth.month &&
                                  DateTime.now().year ==
                                      _focusedMonth.year;
                          return _DayCell(
                              day: day,
                              status: status,
                              isToday: isToday);
                        },
                      ),
                      const SizedBox(height: 16),
                      // Legend
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _Legend('Present', AppColors.success),
                          const SizedBox(width: 16),
                          _Legend('Absent', AppColors.error),
                          const SizedBox(width: 16),
                          _Legend('Holiday', AppColors.warning),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Leave Request Button
                      GestureDetector(
                        onTap: _showLeaveDialog,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.cardLight,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.emergency_outlined, color: AppColors.primary, size: 18),
                              const SizedBox(width: 8),
                              Text('Request Leave', 
                                style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                            ],
                          ),
                        ),
                      ),
                       const SizedBox(height: 24),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  void _showLeaveDialog() {
    final reasonCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Apply for Leave', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                
                // Date Picker
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Select Date', style: GoogleFonts.outfit(fontSize: 14, color: AppColors.textSecondary)),
                  subtitle: Text(DateFormat('EEE, d MMM yyyy').format(selectedDate), 
                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  trailing: const Icon(Icons.calendar_month_rounded, color: AppColors.primary),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 30)),
                    );
                    if (d != null) setModalState(() => selectedDate = d);
                  },
                ),
                const SizedBox(height: 16),
                
                // Reason Field
                TextField(
                  controller: reasonCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Reason for leave...',
                    hintStyle: GoogleFonts.outfit(color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.cardLight,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 24),
                
                GestureDetector(
                  onTap: () async {
                    if (reasonCtrl.text.isEmpty) return;
                    
                    await FirebaseFirestore.instance.collection('leave_requests').add({
                      'studentId': _uid,
                      'studentName': FirebaseAuth.instance.currentUser?.displayName ?? 'Student',
                      'date': DateFormat('yyyy-MM-dd').format(selectedDate),
                      'reason': reasonCtrl.text.trim(),
                      'status': 'pending',
                      'createdAt': FieldValue.serverTimestamp(),
                    });
                    
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Leave request submitted!'), backgroundColor: AppColors.success),
                      );
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text('Submit Request', 
                      style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatBubble extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatBubble(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Colors.white)),
        Text(label,
            style: GoogleFonts.outfit(fontSize: 12, color: Colors.white70)),
      ],
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
          width: 12, height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label,
          style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary)),
    ]);
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final String? status;
  final bool isToday;
  const _DayCell({required this.day, this.status, required this.isToday});

  @override
  Widget build(BuildContext context) {
    Color bg = AppColors.cardLight;
    Color textColor = AppColors.textPrimary;
    if (status == 'present') {
      bg = AppColors.success;
      textColor = Colors.white;
    } else if (status == 'absent') {
      bg = AppColors.error;
      textColor = Colors.white;
    } else if (status == 'holiday') {
      bg = AppColors.warning;
      textColor = Colors.white;
    }
    return Container(
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: isToday
            ? Border.all(color: AppColors.primary, width: 2)
            : null,
      ),
      alignment: Alignment.center,
      child: Text('$day',
          style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
              color: textColor)),
    );
  }
}
