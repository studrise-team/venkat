import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';
import '../app_theme.dart';
import '../widgets/logout_dialog.dart';
import '../services/firebase_service.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  DateTime? _lastBackPressTime;

  void _logout(BuildContext context) async {
    await LogoutDialog.show(context);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        
        final now = DateTime.now();
        if (_lastBackPressTime == null || 
            now.difference(_lastBackPressTime!) > const Duration(seconds: 3)) {
          _lastBackPressTime = now;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Press back again to exit',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
              width: 200,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              backgroundColor: AppColors.textPrimary.withOpacity(0.9),
            ),
          );
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: AppColors.bgGradient),
          child: SafeArea(
            child: Column(
              children: [
                // ── Header ─────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Admin Hub',
                                style: GoogleFonts.outfit(
                                  color: AppColors.textPrimary,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                )),
                            Text('Command Centre',
                                style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 13)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout_rounded, color: AppColors.textSecondary),
                        tooltip: 'Logout',
                        onPressed: () => _logout(context),
                      ),
                    ],
                  ),
                ),

                // ── Welcome banner ─────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        )
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Ready to Guide?',
                                  style: GoogleFonts.outfit(
                                      color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                              const SizedBox(height: 8),
                              Text('Manage exams, students, and\nacademic resources with ease.',
                                  style: GoogleFonts.outfit(color: Colors.white.withValues(alpha: 0.8), fontSize: 13, height: 1.5)),
                            ],
                          ),
                        ),
                        const Icon(Icons.auto_awesome_motion_rounded, color: Colors.white38, size: 64),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('MANAGEMENT CONSOLE',
                        style: GoogleFonts.outfit(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        )),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Menu Cards (Adaptive Grid/List) ────────────────────────
                Expanded(
                  child: FutureBuilder<Map<String, dynamic>>(
                    future: FirebaseService().getStats(),
                    builder: (context, snapshot) {
                      final studentCount = snapshot.data?['studentCount'] as int?;
                      
                      return LayoutBuilder(
                        builder: (context, constraints) {
                          final isTablet = constraints.maxWidth > 700;
                          final cards = _buildCards(context, studentCount: studentCount);
                          
                          if (isTablet) {
                            return GridView.count(
                              crossAxisCount: 2,
                              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 2.2,
                              children: cards,
                            );
                          }
                          return ListView.separated(
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                            itemCount: cards.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              return cards[index];
                            },
                          );
                        },
                      );
                    }
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCards(BuildContext context, {int? studentCount}) {
    return [
      _ActionCard(
        icon: Icons.library_books_rounded,
        gradient: AppColors.primaryGradient,
        title: 'Aspirants',
        subtitle: 'Mock Tests, Papers, Notes, Videos, Live Classes',
        onTap: () => Navigator.pushNamed(context, '/exam-management'),
      ),
      _ActionCard(
        icon: Icons.school_rounded,
        gradient: AppColors.accentGradient,
        title: 'School Students',
        subtitle: 'Class 1-12: Mock Tests, Live Classes, Attendance, Progress',
        info: studentCount != null ? '$studentCount Registered' : null,
        onTap: () => Navigator.pushNamed(context, '/student-management'),
      ),
    ];
  }
}

class _ActionCard extends StatefulWidget {
  final IconData icon;
  final LinearGradient gradient;
  final String title;
  final String subtitle;
  final String? info;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.gradient,
    required this.title,
    required this.subtitle,
    this.info,
    required this.onTap,
  });

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _isPressed ? widget.gradient.colors.first.withOpacity(0.3) : AppColors.cardBorder, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_isPressed ? 0.02 : 0.04),
                blurRadius: _isPressed ? 10 : 20,
                offset: Offset(0, _isPressed ? 4 : 8),
              )
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: widget.gradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: widget.gradient.colors.first.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Icon(widget.icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(widget.title,
                        style: GoogleFonts.outfit(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        )),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(widget.subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 12, height: 1.3)),
                        ),
                        if (widget.info != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: widget.gradient.colors.first.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(widget.info!,
                                style: GoogleFonts.outfit(
                                  color: widget.gradient.colors.first,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                )),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

