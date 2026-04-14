import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../widgets/logout_dialog.dart';
import '../auth/profile_page.dart';

class AspirantDashboard extends StatefulWidget {
  const AspirantDashboard({super.key});

  @override
  State<AspirantDashboard> createState() => _AspirantDashboardState();
}

class _AspirantDashboardState extends State<AspirantDashboard> {
  UserModel? _user;
  bool _loadingUser = true;

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

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await AuthService().getCurrentUserProfile();
    if (mounted) {
      setState(() {
        _user = user;
        _loadingUser = false;
      });
    }
  }

  void _logout(BuildContext context) async {
    await LogoutDialog.show(context);
  }

  void _openProfile() {
    if (_user == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProfilePage(user: _user!)),
    ).then((_) => _loadUser());
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingUser) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _logout(context);
      },
      child: Scaffold(
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
                      GestureDetector(
                        onTap: _openProfile,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person_rounded, color: Colors.white, size: 22),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: _openProfile,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_user?.name ?? 'Aspirant',
                                  style: GoogleFonts.outfit(
                                      color: AppColors.textPrimary,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700)),
                              Text('Choose your exam',
                                  style: GoogleFonts.outfit(
                                      color: AppColors.textSecondary, fontSize: 12)),
                            ],
                          ),
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
                              Text('Ready to Excel?',
                                  style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700)),
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
                    child: Text('Select Exam',
                        style: GoogleFonts.outfit(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        )),
                  ),
                ),
                const SizedBox(height: 12),

                // ── Exam Grid ──────────────────────────────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final crossAxisCount = constraints.maxWidth > 600 ? 5 : 3;
                        return GridView.builder(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: constraints.maxWidth > 600 ? 1.2 : 0.95,
                          ),
                          itemCount: _exams.length,
                          itemBuilder: (_, i) {
                            final exam = _exams[i];
                            final color = exam['color'] as Color;
                            final name = exam['name'] as String;
                            final icon = exam['icon'] as IconData;
                            return _ExamCard(
                              name: name,
                              icon: icon,
                              color: color,
                              onTap: () => Navigator.pushNamed(
                                context,
                                '/aspirant-exam-actions',
                                arguments: name,
                              ),
                            );
                          },
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
      ),
    );
  }
}

class _ExamCard extends StatefulWidget {
  final String name;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ExamCard({
    required this.name,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<_ExamCard> createState() => _ExamCardState();
}

class _ExamCardState extends State<_ExamCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _isPressed ? widget.color.withOpacity(0.5) : AppColors.cardBorder,
              width: _isPressed ? 1.5 : 1.0,
            ),
            boxShadow: _isPressed
                ? [
                    BoxShadow(
                      color: widget.color.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(widget.icon, color: widget.color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                widget.name,
                style: GoogleFonts.outfit(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
