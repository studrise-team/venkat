import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../app_theme.dart';

/// Full-featured parent dashboard showing child's attendance, fees, quiz results,
/// weekly contest results and profile information.
class ParentDashboard extends StatefulWidget {
  const ParentDashboard({super.key});

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  int _currentIndex = 0;
  Map<String, dynamic>? _parentData;
  Map<String, dynamic>? _childData;
  String? _childUid;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // Load parent document
    final parentDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    final pd = parentDoc.data();

    // Find child via childUid stored in parent doc, or query by parentUid
    String? childId = pd?['childUid'] as String?;
    Map<String, dynamic>? childData;

    if (childId != null) {
      final childDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(childId)
          .get();
      childData = childDoc.data();
    } else {
      // Try to find by parentUid field on student docs
      final q = await FirebaseFirestore.instance
          .collection('users')
          .where('parentUid', isEqualTo: uid)
          .limit(1)
          .get();
      if (q.docs.isNotEmpty) {
        childId = q.docs.first.id;
        childData = q.docs.first.data();
      }
    }

    if (mounted) {
      setState(() {
        _parentData = pd;
        _childData = childData;
        _childUid = childId;
        _loading = false;
      });
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Widget _buildBody() {
    if (_childData == null) {
      return _NoChildLinked(parentData: _parentData);
    }
    switch (_currentIndex) {
      case 0:
        return _OverviewTab(
            childData: _childData!, childUid: _childUid!);
      case 1:
        return _ParentAttendanceTab(childUid: _childUid!);
      case 2:
        return _ParentFeesTab(childUid: _childUid!);
      case 3:
        return _ParentQuizTab(childUid: _childUid!);
      default:
        return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: _buildBody(),
      bottomNavigationBar: _childData == null
          ? null
          : _ParentBottomNav(
              currentIndex: _currentIndex,
              onTap: (i) => setState(() => _currentIndex = i),
            ),
    );
  }
}

// ── No Child Linked ────────────────────────────────────────────────────────

class _NoChildLinked extends StatelessWidget {
  final Map<String, dynamic>? parentData;
  const _NoChildLinked({this.parentData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF14B8A6), Color(0xFF0F766E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 28),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Parent Portal',
                            style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800)),
                        Text(
                            'Welcome, ${parentData?['name'] ?? 'Parent'}!',
                            style: GoogleFonts.outfit(
                                color: Colors.white70, fontSize: 14)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      await FirebaseAuth.instance.signOut();
                      if (context.mounted) {
                        Navigator.pushReplacementNamed(context, '/login');
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.logout_rounded,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            const Expanded(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.family_restroom_rounded,
                          size: 64, color: AppColors.textMuted),
                      SizedBox(height: 16),
                      Text(
                        'No child account linked yet.',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Please ask the admin to link your child\'s account to your parent profile.',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bottom Nav ─────────────────────────────────────────────────────────────

class _ParentBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _ParentBottomNav(
      {required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = [
      {'icon': Icons.home_rounded, 'label': 'Overview'},
      {'icon': Icons.calendar_today_rounded, 'label': 'Attendance'},
      {'icon': Icons.receipt_long_rounded, 'label': 'Fees'},
      {'icon': Icons.quiz_rounded, 'label': 'Results'},
    ];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          )
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: List.generate(items.length, (i) {
              final selected = i == currentIndex;
              final gradients = [
                AppColors.primaryGradient,
                const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF047857)]),
                const LinearGradient(
                    colors: [Color(0xFFF97316), Color(0xFFEA580C)]),
                AppColors.accentGradient,
              ];
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: selected ? gradients[i] : null,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          items[i]['icon'] as IconData,
                          size: 22,
                          color: selected
                              ? Colors.white
                              : AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        items[i]['label'] as String,
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: selected
                              ? AppColors.primary
                              : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ── Overview Tab ───────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  final Map<String, dynamic> childData;
  final String childUid;
  const _OverviewTab({required this.childData, required this.childUid});

  @override
  Widget build(BuildContext context) {
    final name = childData['name'] ?? 'Student';
    final grade = childData['grade'] ?? '';
    final rollNumber = childData['rollNumber'] ?? '';

    return CustomScrollView(
      slivers: [
        // Header
        SliverToBoxAdapter(
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF14B8A6), Color(0xFF0F766E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(24, 52, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white.withValues(alpha: 0.25),
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'S',
                        style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name,
                              style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800)),
                          if (grade.isNotEmpty)
                            Text('Grade: $grade',
                                style: GoogleFonts.outfit(
                                    color: Colors.white70, fontSize: 13)),
                          if (rollNumber.isNotEmpty)
                            Text('Roll No: $rollNumber',
                                style: GoogleFonts.outfit(
                                    color: Colors.white60, fontSize: 12)),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () async {
                        await FirebaseAuth.instance.signOut();
                        if (context.mounted) {
                          Navigator.pushReplacementNamed(context, '/login');
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.logout_rounded,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Quick stats row
                Row(
                  children: [
                    _QuickStat('Attendance', _AttendanceValueFetcher(uid: childUid)),
                    const SizedBox(width: 10),
                    _QuickStatStr('Fee Status', _FeeStatusFetcher(uid: childUid)),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Announcements
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
            child: Text('📢 School Announcements',
                style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
          ),
        ),
        SliverToBoxAdapter(child: _AnnouncementsWidget()),

        // Recent Quiz Results
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
            child: Text('📊 Recent Quiz Results',
                style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
          ),
        ),
        SliverToBoxAdapter(child: _ParentRecentResults(uid: childUid)),

        const SliverToBoxAdapter(child: SizedBox(height: 28)),
      ],
    );
  }
}

class _QuickStat extends StatelessWidget {
  final String label;
  final Widget valueWidget;
  const _QuickStat(this.label, this.valueWidget);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.outfit(
                    fontSize: 11, color: Colors.white60)),
            valueWidget,
          ],
        ),
      ),
    );
  }
}

class _QuickStatStr extends StatelessWidget {
  final String label;
  final Widget valueWidget;
  const _QuickStatStr(this.label, this.valueWidget);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.outfit(
                    fontSize: 11, color: Colors.white60)),
            valueWidget,
          ],
        ),
      ),
    );
  }
}

class _AttendanceValueFetcher extends StatefulWidget {
  final String uid;
  const _AttendanceValueFetcher({required this.uid});
  @override
  State<_AttendanceValueFetcher> createState() =>
      _AttendanceValueFetcherState();
}

class _AttendanceValueFetcherState
    extends State<_AttendanceValueFetcher> {
  String _value = '…';
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final monthKey = DateFormat('yyyy-MM').format(DateTime.now());
    final doc = await FirebaseFirestore.instance
        .collection('attendance')
        .doc(widget.uid)
        .collection('months')
        .doc(monthKey)
        .get();
    if (!mounted) return;
    if (doc.exists) {
      final days =
          Map<String, String>.from(doc.data()?['days'] ?? {});
      final present =
          days.values.where((v) => v == 'present').length;
      final total =
          days.values.where((v) => v != 'holiday').length;
      final pct = total == 0 ? 0 : (present / total * 100).round();
      setState(() => _value = '$pct%');
    } else {
      setState(() => _value = 'N/A');
    }
  }

  @override
  Widget build(BuildContext context) => Text(
        _value,
        style: GoogleFonts.outfit(
            fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
      );
}

class _FeeStatusFetcher extends StatefulWidget {
  final String uid;
  const _FeeStatusFetcher({required this.uid});
  @override
  State<_FeeStatusFetcher> createState() => _FeeStatusFetcherState();
}

class _FeeStatusFetcherState extends State<_FeeStatusFetcher> {
  String _value = '…';
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final monthKey = DateFormat('yyyy-MM').format(DateTime.now());
    final doc = await FirebaseFirestore.instance
        .collection('fees')
        .doc(widget.uid)
        .collection('months')
        .doc(monthKey)
        .get();
    if (!mounted) return;
    setState(() =>
        _value = (doc.data()?['status'] ?? 'Pending').toString());
  }

  @override
  Widget build(BuildContext context) => Text(
        _value,
        style: GoogleFonts.outfit(
            fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
      );
}

class _AnnouncementsWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('announcements')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text('No announcements yet.',
                  style: GoogleFonts.outfit(color: AppColors.textMuted)),
            ),
          );
        }
        return SizedBox(
          height: 90,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: snap.data!.docs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final d = snap.data!.docs[i].data() as Map<String, dynamic>;
              return Container(
                width: 240,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.cardBorder),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d['title'] ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    Text(d['body'] ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _ParentRecentResults extends StatelessWidget {
  final String uid;
  const _ParentRecentResults({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('student_quiz_results')
          .where('studentId', isEqualTo: uid)
          .orderBy('submittedAt', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: AppColors.cardLight,
                  borderRadius: BorderRadius.circular(14)),
              child: Text('No quiz attempts yet.',
                  style:
                      GoogleFonts.outfit(color: AppColors.textMuted)),
            ),
          );
        }
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: snap.data!.docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final d = snap.data!.docs[i].data() as Map<String, dynamic>;
            final score = d['score'] ?? 0;
            final total = d['total'] ?? 1;
            final pct = (score / total * 100).round();
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.cardBorder),
                borderRadius: BorderRadius.circular(14),
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

// ── Parent Attendance Tab ──────────────────────────────────────────────────

class _ParentAttendanceTab extends StatefulWidget {
  final String childUid;
  const _ParentAttendanceTab({required this.childUid});
  @override
  State<_ParentAttendanceTab> createState() =>
      _ParentAttendanceTabState();
}

class _ParentAttendanceTabState extends State<_ParentAttendanceTab> {
  DateTime _focusedMonth = DateTime.now();
  Map<String, String> _attendanceMap = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMonth();
  }

  Future<void> _loadMonth() async {
    setState(() => _loading = true);
    final monthKey = DateFormat('yyyy-MM').format(_focusedMonth);
    final snap = await FirebaseFirestore.instance
        .collection('attendance')
        .doc(widget.childUid)
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

  int get _daysInMonth =>
      DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
  int get _firstWeekday =>
      DateTime(_focusedMonth.year, _focusedMonth.month, 1).weekday % 7;
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
        Container(
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
          padding: const EdgeInsets.fromLTRB(20, 52, 20, 24),
          child: Column(
            children: [
              Text("Child's Attendance",
                  style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _Bubble('Present', '$_present'),
                  _Bubble('Absent', '$_absent'),
                  _Bubble('Rate',
                      '${(_pct * 100).toStringAsFixed(0)}%'),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _pct,
                  minHeight: 8,
                  backgroundColor: Colors.white24,
                  valueColor: AlwaysStoppedAnimation<Color>(
                      _pct >= 0.75 ? Colors.white : AppColors.warning),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _pct >= 0.75
                    ? '✅ Attendance is good!'
                    : '⚠️ Attendance below 75%!',
                style:
                    GoogleFonts.outfit(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  setState(() => _focusedMonth =
                      DateTime(_focusedMonth.year, _focusedMonth.month - 1));
                  _loadMonth();
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: AppColors.cardLight,
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.chevron_left_rounded),
                ),
              ),
              Text(DateFormat('MMMM yyyy').format(_focusedMonth),
                  style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              GestureDetector(
                onTap: () {
                  final now = DateTime.now();
                  if (_focusedMonth.year == now.year &&
                      _focusedMonth.month == now.month) return;
                  setState(() => _focusedMonth =
                      DateTime(_focusedMonth.year, _focusedMonth.month + 1));
                  _loadMonth();
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: AppColors.cardLight,
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.chevron_right_rounded),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
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
                                  _focusedMonth.month, day));
                          final status = _attendanceMap[dateKey];
                          final isToday = DateTime.now().day == day &&
                              DateTime.now().month ==
                                  _focusedMonth.month &&
                              DateTime.now().year == _focusedMonth.year;
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
                                  ? Border.all(
                                      color: AppColors.primary, width: 2)
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Text('$day',
                                style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: isToday
                                        ? FontWeight.w800
                                        : FontWeight.w500,
                                    color: textColor)),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _LegendDot('Present', AppColors.success),
                          const SizedBox(width: 16),
                          _LegendDot('Absent', AppColors.error),
                          const SizedBox(width: 16),
                          _LegendDot('Holiday', AppColors.warning),
                        ],
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  final String label, value;
  const _Bubble(this.label, this.value);
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value,
          style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white)),
      Text(label,
          style:
              GoogleFonts.outfit(fontSize: 12, color: Colors.white70)),
    ]);
  }
}

class _LegendDot extends StatelessWidget {
  final String label;
  final Color color;
  const _LegendDot(this.label, this.color);
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label,
          style: GoogleFonts.outfit(
              fontSize: 12, color: AppColors.textSecondary)),
    ]);
  }
}

// ── Parent Fees Tab ────────────────────────────────────────────────────────

class _ParentFeesTab extends StatelessWidget {
  final String childUid;
  const _ParentFeesTab({required this.childUid});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF97316), Color(0xFFEA580C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(24, 52, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Child's Fee Status",
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('Track monthly tuition payments',
                    style: GoogleFonts.outfit(
                        color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 20),
                _CurrentFeeWidget(uid: childUid),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
            child: Text('📋 Payment History',
                style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
          ),
        ),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('fees')
              .doc(childUid)
              .collection('months')
              .orderBy('month', descending: true)
              .snapshots(),
          builder: (context, snap) {
            if (!snap.hasData || snap.data!.docs.isEmpty) {
              return const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: Text('No payment records found.',
                        style:
                            TextStyle(color: AppColors.textMuted)),
                  ),
                ),
              );
            }
            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final d = snap.data!.docs[i].data()
                      as Map<String, dynamic>;
                  final status =
                      (d['status'] ?? 'pending').toString().toLowerCase();
                  final isPaid = status == 'paid';
                  return Container(
                    margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppColors.cardBorder),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          height: 48,
                          width: 48,
                          decoration: BoxDecoration(
                            color: isPaid
                                ? AppColors.success.withValues(alpha: 0.1)
                                : AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            isPaid
                                ? Icons.check_circle_outline_rounded
                                : Icons.cancel_outlined,
                            color: isPaid
                                ? AppColors.success
                                : AppColors.error,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(d['month'] ?? '',
                                  style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: AppColors.textPrimary)),
                              Text(
                                  isPaid
                                      ? 'Paid on ${d['paidOn'] ?? ''}'
                                      : 'Payment Pending',
                                  style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        Text('₹${d['amount'] ?? '—'}',
                            style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: isPaid
                                    ? AppColors.success
                                    : AppColors.error)),
                      ],
                    ),
                  );
                },
                childCount: snap.data!.docs.length,
              ),
            );
          },
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 28)),
      ],
    );
  }
}

class _CurrentFeeWidget extends StatefulWidget {
  final String uid;
  const _CurrentFeeWidget({required this.uid});
  @override
  State<_CurrentFeeWidget> createState() => _CurrentFeeWidgetState();
}

class _CurrentFeeWidgetState extends State<_CurrentFeeWidget> {
  Map<String, dynamic>? _feeData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final monthKey = DateFormat('yyyy-MM').format(DateTime.now());
    final doc = await FirebaseFirestore.instance
        .collection('fees')
        .doc(widget.uid)
        .collection('months')
        .doc(monthKey)
        .get();
    if (mounted) {
      setState(() {
        _feeData = doc.data();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.white));
    }
    final status = _feeData?['status'] ?? 'Pending';
    final amount = _feeData?['amount'] ?? '—';
    final dueDate = _feeData?['dueDate'] ?? '—';
    final isPaid = status.toString().toLowerCase() == 'paid';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isPaid ? Icons.check_circle_rounded : Icons.pending_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("This Month's Fee",
                    style: GoogleFonts.outfit(
                        color: Colors.white70, fontSize: 12)),
                Text('₹$amount',
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800)),
                Text('Due: $dueDate',
                    style: GoogleFonts.outfit(
                        color: Colors.white60, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isPaid ? AppColors.success : AppColors.error,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isPaid ? 'PAID' : 'DUE',
              style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Parent Quiz Results Tab ────────────────────────────────────────────────

class _ParentQuizTab extends StatelessWidget {
  final String childUid;
  const _ParentQuizTab({required this.childUid});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: AppColors.accentGradient,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(24, 52, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Quiz & Contest Results',
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text("Your child's academic performance",
                    style: GoogleFonts.outfit(
                        color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
        ),

        // Daily Quiz Results
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
            child: Text('📝 Daily Quiz Results',
                style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
          ),
        ),

        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('quiz_results')
              .where('studentId', isEqualTo: childUid)
              .orderBy('submittedAt', descending: true)
              .limit(10)
              .snapshots(),
          builder: (context, snap) {
            if (!snap.hasData || snap.data!.docs.isEmpty) {
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                        color: AppColors.cardLight,
                        borderRadius: BorderRadius.circular(14)),
                    child: Text('No quiz results yet.',
                        style:
                            GoogleFonts.outfit(color: AppColors.textMuted)),
                  ),
                ),
              );
            }
            return SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final d = snap.data!.docs[i].data()
                        as Map<String, dynamic>;
                    final score = d['score'] ?? 0;
                    final total = d['total'] ?? 1;
                    final pct = (score / total * 100).round();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border:
                              Border.all(color: AppColors.cardBorder),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                gradient: pct >= 70
                                    ? AppColors.primaryGradient
                                    : pct >= 40
                                        ? AppColors.accentGradient
                                        : const LinearGradient(colors: [
                                            Color(0xFFEF4444),
                                            Color(0xFFDC2626)
                                          ]),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: Text('$pct%',
                                  style: GoogleFonts.outfit(
                                      fontSize: 12,
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
                      ),
                    );
                  },
                  childCount: snap.data!.docs.length,
                ),
              ),
            );
          },
        ),

        // Weekend Contest Results
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
            child: Text('🏆 Weekend Contest Results',
                style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
          ),
        ),

        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('contest_results')
              .where('studentId', isEqualTo: childUid)
              .orderBy('week', descending: true)
              .limit(5)
              .snapshots(),
          builder: (context, snap) {
            if (!snap.hasData || snap.data!.docs.isEmpty) {
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                        color: AppColors.cardLight,
                        borderRadius: BorderRadius.circular(14)),
                    child: Text('No contest results yet.',
                        style:
                            GoogleFonts.outfit(color: AppColors.textMuted)),
                  ),
                ),
              );
            }
            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final d = snap.data!.docs[i].data()
                        as Map<String, dynamic>;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: AppColors.cardBorder),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                gradient: AppColors.accentGradient,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: Text('#${d['rank'] ?? '—'}',
                                  style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white)),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Week ${d['week'] ?? ''}',
                                      style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: AppColors.textPrimary)),
                                  Text(
                                      'Score: ${d['score'] ?? '—'} | Rank: ${d['rank'] ?? '—'}',
                                      style: GoogleFonts.outfit(
                                          fontSize: 12,
                                          color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: snap.data!.docs.length,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
