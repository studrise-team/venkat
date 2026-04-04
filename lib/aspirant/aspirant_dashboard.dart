import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';
import '../services/auth_service.dart';

class AspirantDashboard extends StatelessWidget {
  const AspirantDashboard({super.key});

  static const _exams = [
    {'name': 'DSC', 'icon': Icons.menu_book_rounded, 'color': Color(0xFF6C63FF)},
    {'name': 'APPSC', 'icon': Icons.account_balance_rounded, 'color': Color(0xFF00D4AA)},
    {'name': 'Police', 'icon': Icons.local_police_rounded, 'color': Color(0xFFFF5252)},
    {'name': 'Railway', 'icon': Icons.train_rounded, 'color': Color(0xFF00B8D9)},
    {'name': 'Banking', 'icon': Icons.account_balance_wallet_rounded, 'color': Color(0xFFFF7043)},
    {'name': 'Group 1', 'icon': Icons.looks_one_rounded, 'color': Color(0xFF9C5CF7)},
    {'name': 'Group 2', 'icon': Icons.looks_two_rounded, 'color': Color(0xFF38ef7d)},
    {'name': 'Group 3', 'icon': Icons.looks_3_rounded, 'color': Color(0xFFFFB300)},
    {'name': 'Group 4', 'icon': Icons.looks_4_rounded, 'color': Color(0xFF26C6DA)},
  ];

  void _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Logout', style: GoogleFonts.outfit(
            color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to logout?',
            style: GoogleFonts.outfit(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: GoogleFonts.outfit(color: AppColors.textSecondary))),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: Text('Logout', style: GoogleFonts.outfit(
                  color: AppColors.error, fontWeight: FontWeight.w600))),
        ],
      ),
    );
    if (confirm == true) {
      await AuthService().signOut();
      if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
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
              // ── Header ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.school_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Astar Learning', style: GoogleFonts.outfit(
                            color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
                          Text('Choose your exam', style: GoogleFonts.outfit(
                              color: AppColors.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout_rounded, color: AppColors.textSecondary),
                      onPressed: () => _logout(context),
                    ),
                  ],
                ),
              ),

              // ── Banner ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Ready to Excel?', style: GoogleFonts.outfit(
                              color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text('Pick an exam below to\naccess all resources.',
                                style: GoogleFonts.outfit(
                                    color: Colors.white70, fontSize: 13, height: 1.5)),
                          ],
                        ),
                      ),
                      const Icon(Icons.emoji_events_rounded, color: Colors.white30, size: 56),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Select Exam', style: GoogleFonts.outfit(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  )),
                ),
              ),
              const SizedBox(height: 12),

              // ── Exam Grid ───────────────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.05,
                    ),
                    itemCount: _exams.length,
                    itemBuilder: (_, i) {
                      final exam = _exams[i];
                      final color = exam['color'] as Color;
                      final name = exam['name'] as String;
                      final icon = exam['icon'] as IconData;
                      return GestureDetector(
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/aspirant-exam-actions',
                          arguments: name,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                                color: AppColors.cardBorder),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(icon, color: color, size: 24),
                              ),
                              const SizedBox(height: 8),
                              Text(name, style: GoogleFonts.outfit(
                                color: AppColors.textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ), textAlign: TextAlign.center),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
