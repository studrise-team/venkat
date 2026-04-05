import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../app_theme.dart';
import '../services/auth_service.dart';
import 'student_admin_tabs/sa_students_tab.dart';
import 'student_admin_tabs/sa_attendance_tab.dart';
import 'student_admin_tabs/sa_quiz_tab.dart';
import 'student_admin_tabs/sa_announcements_tab.dart';

import '../widgets/logout_dialog.dart';

/// Admin dashboard specifically for managing tuition center *students*.
class StudentAdminDashboard extends StatefulWidget {
  const StudentAdminDashboard({super.key});

  @override
  State<StudentAdminDashboard> createState() =>
      _StudentAdminDashboardState();
}

class _StudentAdminDashboardState extends State<StudentAdminDashboard> {
  int _currentIndex = 0;

  Widget _buildPage() {
    switch (_currentIndex) {
      case 0:
        return _HomeOverviewTab(
            onNavigate: (i) => setState(() => _currentIndex = i));
      case 1:
        return const SAStudentsTab();
      case 2:
        return const SAAttendanceTab();
      case 3:
        return const SAQuizTab();
      case 4:
        return const SAAnnouncementsTab();
      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> _confirmLogout(BuildContext context) async {
    await LogoutDialog.show(context);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
        } else {
           // Go back to Admin Hub if possible, otherwise confirm logout
           if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
           } else {
              _confirmLogout(context);
           }
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: _buildPage(),
        bottomNavigationBar: _AdminBottomNav(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
        ),
      ),
    );
  }
}

// ── Bottom Nav ─────────────────────────────────────────────────────────────

class _AdminBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _AdminBottomNav(
      {required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = [
      {'icon': Icons.home_rounded, 'label': 'Home'},
      {'icon': Icons.people_rounded, 'label': 'Students'},
      {'icon': Icons.calendar_today_rounded, 'label': 'Attend.'},
      {'icon': Icons.quiz_rounded, 'label': 'Quiz'},
      {'icon': Icons.campaign_rounded, 'label': 'Announce'},
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
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          gradient:
                              selected ? AppColors.primaryGradient : null,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          items[i]['icon'] as IconData,
                          size: 20,
                          color: selected
                              ? Colors.white
                              : AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        items[i]['label'] as String,
                        style: GoogleFonts.outfit(
                          fontSize: 9,
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

// ── Home Overview Tab ──────────────────────────────────────────────────────

class _HomeOverviewTab extends StatelessWidget {
  final ValueChanged<int> onNavigate;
  const _HomeOverviewTab({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Header
        SliverToBoxAdapter(
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
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
                    GestureDetector(
                      onTap: () {
                         if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                         } else {
                            (context.findAncestorStateOfType<_StudentAdminDashboardState>())?._confirmLogout(context);
                         }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.arrow_back_rounded,
                            color: Colors.white, size: 20),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Student Admin',
                              style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800)),
                          Text('Tuition Center Management',
                              style: GoogleFonts.outfit(
                                  color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  DateFormat('EEEE, d MMMM yyyy').format(DateTime.now()),
                  style: GoogleFonts.outfit(
                      color: Colors.white60, fontSize: 13),
                ),
              ],
            ),
          ),
        ),

        // Stats Cards
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
            child: Text('📊 Today\'s Overview',
                style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
          ),
        ),
        SliverToBoxAdapter(child: _StatsRow()),

        // Quick Actions
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
            child: Text('⚡ Quick Actions',
                style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: [
                _ActionTile(
                  icon: Icons.people_rounded,
                  label: 'Manage Students',
                  subtitle: 'View & edit profiles',
                  gradient: AppColors.primaryGradient,
                  onTap: () => onNavigate(1),
                ),
                _ActionTile(
                  icon: Icons.calendar_today_rounded,
                  label: 'Mark Attendance',
                  subtitle: 'Today\'s roll call',
                  gradient: const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF047857)]),
                  onTap: () => onNavigate(2),
                ),
                _ActionTile(
                  icon: Icons.quiz_rounded,
                  label: 'Quiz Hub',
                  subtitle: 'Daily quiz & results',
                  gradient: AppColors.accentGradient,
                  onTap: () => onNavigate(3),
                ),
                _ActionTile(
                  icon: Icons.campaign_rounded,
                  label: 'Announcements',
                  subtitle: 'Central broadcasts',
                  gradient: const LinearGradient(
                      colors: [Color(0xFFF97316), Color(0xFFEA580C)]),
                  onTap: () => onNavigate(4),
                ),
              ],
            ),
          ),
        ),

        // Recent Announcements
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('📢 Recent Announcements',
                    style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(child: _RecentAnnouncements()),

        const SliverToBoxAdapter(child: SizedBox(height: 28)),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _StatCard(
            label: 'Total Students',
            gradient: AppColors.primaryGradient,
            icon: Icons.people_rounded,
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('role', isEqualTo: 'student')
                .snapshots(),
          ),
          const SizedBox(width: 12),
          _StatCard(
            label: 'Active Batches',
            gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF047857)]),
            icon: Icons.class_rounded,
            stream: FirebaseFirestore.instance
                .collection('batches')
                .snapshots(),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final LinearGradient gradient;
  final IconData icon;
  final Stream<QuerySnapshot> stream;
  const _StatCard({
    required this.label,
    required this.gradient,
    required this.icon,
    required this.stream,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (context, snap) {
          final count = snap.data?.docs.length ?? 0;
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: Colors.white70, size: 24),
                const SizedBox(height: 8),
                Text('$count',
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800)),
                Text(label,
                    style: GoogleFonts.outfit(
                        color: Colors.white70, fontSize: 12)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ActionTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final LinearGradient gradient;
  final VoidCallback onTap;
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  State<_ActionTile> createState() => _ActionTileState();
}

class _ActionTileState extends State<_ActionTile> {
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
            boxShadow: _isHovered ? [
              BoxShadow(
                color: widget.gradient.colors.first.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ] : null,
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

class _RecentAnnouncements extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('announcements')
          .orderBy('createdAt', descending: true)
          .limit(3)
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
              child: Text('No announcements yet.',
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
            final d =
                snap.data!.docs[i].data() as Map<String, dynamic>;
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
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.campaign_rounded,
                        color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(d['title'] ?? '',
                            style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: AppColors.textPrimary)),
                        Text(d['body'] ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
