import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../app_theme.dart';
import '../services/auth_service.dart';
import 'tabs/attendance_tab.dart';
import 'tabs/quiz_tab.dart';
import 'tabs/profile_tab.dart';
import 'tabs/leaderboard_tab.dart';
import 'tabs/materials_tab.dart';

import '../widgets/logout_dialog.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _currentIndex = 0;
  Map<String, dynamic>? _userData;
  bool _loadingUser = true;

  final List<_NavItem> _navItems = const [
    _NavItem(icon: Icons.home_rounded, label: 'Home'),
    _NavItem(icon: Icons.calendar_today_rounded, label: 'Atten.'),
    _NavItem(icon: Icons.description_rounded, label: 'Academic'),
    _NavItem(icon: Icons.quiz_rounded, label: 'Quiz'),
    _NavItem(icon: Icons.person_rounded, label: 'Profile'),
  ];

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (mounted) {
      setState(() {
        _userData = doc.data();
        _loadingUser = false;
      });
    }
  }

  Widget _buildBody() {
    final isApproved = _userData?['isApproved'] ?? false;
    
    if (!isApproved) {
      return _buildPendingApprovalScreen();
    }

    switch (_currentIndex) {
      case 0:
        return _HomeTab(userData: _userData);
      case 1:
        return const AttendanceTab();
      case 2:
        return const MaterialsTab();
      case 3:
        return const QuizTab();
      case 4:
        return const ProfileTab();
      default:
        return const SizedBox();
    }
  }

  Future<void> _confirmLogout(BuildContext context) async {
    await LogoutDialog.show(context);
  }

  Widget _buildPendingApprovalScreen() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      decoration: const BoxDecoration(gradient: AppColors.bgGradient),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_person_rounded, size: 80, color: AppColors.error),
          ),
          const SizedBox(height: 32),
          Text('Access Restricted',
            style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          Text('Your registration is currently pending admin approval. You will gain full access once your profile is verified.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 15, color: AppColors.textSecondary, height: 1.5)),
          const SizedBox(height: 48),
          _actionButton(
            label: 'Check Status',
            onTap: _loadUser,
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () async {
              await AuthService().signOut();
              if (mounted) Navigator.pushReplacementNamed(context, '/login');
            },
            child: Text('Sign Out', style: GoogleFonts.outfit(color: AppColors.textMuted, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))
          ]
        ),
        alignment: Alignment.center,
        child: Text(label, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isApproved = _userData?['isApproved'] ?? false;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
        } else {
          // Check if there's anything to pop in the nested navigators if we had any,
          // but here we just confirm logout since it's the root dashboard.
          _confirmLogout(context);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: _loadingUser
            ? const Center(child: CircularProgressIndicator())
            : _buildBody(),
        bottomNavigationBar: (!isApproved || _loadingUser) ? null : _BottomNav(
          currentIndex: _currentIndex,
          items: _navItems,
          onTap: (i) => setState(() => _currentIndex = i),
        ),
      ),
    );
  }
}

// ── Bottom Nav ─────────────────────────────────────────────────────────────

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final List<_NavItem> items;
  final ValueChanged<int> onTap;

  const _BottomNav({
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
              final item = items[i];
              final selected = i == currentIndex;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            gradient:
                                selected ? AppColors.primaryGradient : null,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            item.icon,
                            size: 22,
                            color: selected
                                ? Colors.white
                                : AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
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
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ── Home Tab ───────────────────────────────────────────────────────────────

class _HomeTab extends StatelessWidget {
  final Map<String, dynamic>? userData;

  const _HomeTab({this.userData});

  @override
  Widget build(BuildContext context) {
    final name = userData?['name'] ?? 'Student';
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final today = DateTime.now();
    final dateStr =
        '${today.day} ${_monthName(today.month)} ${today.year}';

    return CustomScrollView(
      slivers: [
        //Header
        SliverToBoxAdapter(
          child: Container(
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(24, 56, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Hello, 👋',
                              style: GoogleFonts.outfit(
                                  color: Colors.white70, fontSize: 14)),
                          Text(name,
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              )),
                          const SizedBox(height: 4),
                          Text(dateStr,
                              style: GoogleFonts.outfit(
                                  color: Colors.white60, fontSize: 13)),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => (context.findAncestorStateOfType<_StudentDashboardState>())?._confirmLogout(context),
                      child: const CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.white24,
                        child: Icon(Icons.logout_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                //Today's Quick Stats
                Row(
                  children: [
                    _QuickStat(
                      icon: Icons.check_circle_rounded,
                      label: 'Today',
                      value: 'Present',
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 12),
                    _QuickStat(
                      icon: Icons.stars_rounded,
                      label: 'XP',
                      value: '${userData?['xp'] ?? 0}',
                      color: Colors.orangeAccent,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        //Daily Learning Tip
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFEDD5)),
              ),
              child: Row(
                children: [
                   Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF97316),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lightbulb_outline_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Daily Tip', 
                          style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFFC2410C))),
                        const SizedBox(height: 2),
                        Text('Break complex topics into 25-minute study blocks (Pomodoro) for 20% better retention!',
                          style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF7C2D12), height: 1.4)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        //Announcements
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Text('📢 Announcements',
                style: GoogleFonts.outfit(
                    fontSize: 16, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
          ),
        ),
        SliverToBoxAdapter(child: _AnnouncementsSection()),

        //Quick Actions
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Text('⚡ Quick Actions',
                style: GoogleFonts.outfit(
                    fontSize: 16, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: constraints.maxWidth > 600 ? 1.6 : 1.4,
                  children: [
                    _ActionCard(
                      icon: Icons.quiz_rounded,
                      label: 'Today\'s Quiz',
                      subtitle: 'Attempt now',
                      gradient: AppColors.primaryGradient,
                      onTap: () => (context.findAncestorStateOfType<_StudentDashboardState>())?.setState(() {
                        (context.findAncestorStateOfType<_StudentDashboardState>())?._currentIndex = 3;
                      }),
                    ),
                    _ActionCard(
                      icon: Icons.description_rounded,
                      label: 'Academic Hub',
                      subtitle: 'Notes & Files',
                      gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFD946EF)]),
                      onTap: () => (context.findAncestorStateOfType<_StudentDashboardState>())?.setState(() {
                        (context.findAncestorStateOfType<_StudentDashboardState>())?._currentIndex = 2;
                      }),
                    ),
                    _ActionCard(
                      icon: Icons.workspace_premium_rounded,
                      label: 'Certificates',
                      subtitle: 'My vault',
                      onTap: () => Navigator.pushNamed(context, '/certificates'),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF06B6D4), Color(0xFF0EA5E9)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    _ActionCard(
                      icon: Icons.emoji_events_rounded,
                      label: 'Contest',
                      subtitle: 'Peer vs Peer',
                      gradient: AppColors.accentGradient,
                      onTap: () {},
                    ),
                  ],
                );
              },
            ),
          ),
        ),

        //Recent Quiz Results
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
            child: Text('📊 Recent Quiz Results',
                style: GoogleFonts.outfit(
                    fontSize: 16, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
          ),
        ),
        SliverToBoxAdapter(child: _RecentResultsSection(uid: uid)),

        const SliverToBoxAdapter(child: SizedBox(height: 28)),
      ],
    );
  }

  String _monthName(int month) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month];
  }
}

// ── Sub-Widgets ────────────────────────────────────────────────────────────

class _QuickStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _QuickStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.outfit(
                        fontSize: 11, color: Colors.white60)),
                Text(value,
                    style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AnnouncementsSection extends StatelessWidget {
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
        final docs = snap.data!.docs;
        return SizedBox(
          height: 100,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final d = docs[i].data() as Map<String, dynamic>;
              return Container(
                width: 260,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.cardBorder),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
                  ]
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d['title'] ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 6),
                    Text(d['body'] ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                            fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
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

class _ActionCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final LinearGradient gradient;
  final VoidCallback? onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.gradient,
    this.onTap,
  });

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isHovered = true),
      onTapUp: (_) => setState(() => _isHovered = false),
      onTapCancel: () => setState(() => _isHovered = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isHovered ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutBack,
        child: Container(
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: widget.gradient.colors.first.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(widget.icon, color: Colors.white, size: 20),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.label,
                      style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                  Text(widget.subtitle,
                      style: GoogleFonts.outfit(
                          color: Colors.white70, fontSize: 11)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentResultsSection extends StatelessWidget {
  final String uid;
  const _RecentResultsSection({required this.uid});

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
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text('No quizzes attempted yet.',
                  style: GoogleFonts.outfit(color: AppColors.textMuted)),
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
                              : const LinearGradient(colors: [
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
