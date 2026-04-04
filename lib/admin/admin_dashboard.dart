import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';
import '../services/auth_service.dart';
import '../services/ai_service.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  void _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Logout',
            style: GoogleFonts.outfit(
                color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to logout?',
            style: GoogleFonts.outfit(color: AppColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel',
                  style: GoogleFonts.outfit(color: AppColors.textSecondary))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Logout',
                  style: GoogleFonts.outfit(
                      color: AppColors.error, fontWeight: FontWeight.w600))),
        ],
      ),
    );
    if (confirm == true) {
      await AuthService().signOut();
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  void _showAIConfigDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Gemini AI Config', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Enter your Gemini API Key to enable the AI Study Partner.',
                style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              decoration: InputDecoration(
                labelText: 'API Key',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.isNotEmpty) {
                await AIService().updateApiKey(ctrl.text.trim());
                if (ctx.mounted) Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('AI Key updated successfully!')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6)),
            child: const Text('Save Key', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              // ── Header ─────────────────────────────────────────────────
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.admin_panel_settings_rounded,
                          color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Admin Dashboard',
                              style: GoogleFonts.outfit(
                                color: AppColors.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              )),
                          Text('Manage exams & students',
                              style: GoogleFonts.outfit(
                                  color: AppColors.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout_rounded,
                          color: AppColors.textSecondary),
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
                            Text('Welcome, Admin!',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                )),
                            const SizedBox(height: 4),
                            Text(
                                'Manage all exam content\nfrom here.',
                                style: GoogleFonts.outfit(
                                    color: Colors.white70, fontSize: 13, height: 1.5)),
                          ],
                        ),
                      ),
                      const Icon(Icons.school_rounded,
                          color: Colors.white30, size: 60),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Management',
                      style: GoogleFonts.outfit(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      )),
                ),
              ),
              const SizedBox(height: 12),

              // ── Menu Cards ─────────────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      _DashCard(
                        icon: Icons.library_books_rounded,
                        gradient: AppColors.primaryGradient,
                        title: 'Examination Management',
                        subtitle:
                            'Mock Tests, Previous Papers, Notes, Videos, Daily Quiz, Live Classes',
                        onTap: () => Navigator.pushNamed(
                            context, '/exam-management'),
                      ),
                      const SizedBox(height: 16),
                      _DashCard(
                        icon: Icons.people_rounded,
                        gradient: AppColors.accentGradient,
                        title: 'Student Management',
                        subtitle: 'View enrolled students, track attendance, and fees',
                        onTap: () => Navigator.pushNamed(context, '/student-admin'),
                      ),
                      const SizedBox(height: 16),
                      _DashCard(
                        icon: Icons.auto_awesome_rounded,
                        gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFD946EF)]),
                        title: 'AI Companion Config',
                        subtitle: 'Set Gemini API key for student study partner',
                        onTap: () => _showAIConfigDialog(context),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashCard extends StatefulWidget {
  final IconData icon;
  final LinearGradient gradient;
  final String title;
  final String subtitle;
  final String? badge;
  final VoidCallback? onTap;

  const _DashCard({
    required this.icon,
    required this.gradient,
    required this.title,
    required this.subtitle,
    this.badge,
    this.onTap,
  });

  @override
  State<_DashCard> createState() => _DashCardState();
}

class _DashCardState extends State<_DashCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap != null ? (_) => setState(() => _isHovered = true) : null,
      onTapUp: widget.onTap != null ? (_) => setState(() => _isHovered = false) : null,
      onTapCancel: widget.onTap != null ? () => setState(() => _isHovered = false) : null,
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isHovered ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutBack,
        child: AnimatedOpacity(
          opacity: widget.onTap == null ? 0.6 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.cardBorder),
              boxShadow: _isHovered ? [
                BoxShadow(
                  color: widget.gradient.colors.first.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                )
              ] : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: widget.gradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(widget.icon, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.badge != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(widget.badge!,
                              style: GoogleFonts.outfit(
                                  color: AppColors.warning,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1)),
                        ),
                        const SizedBox(height: 4),
                      ],
                      Text(widget.title,
                          style: GoogleFonts.outfit(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          )),
                      const SizedBox(height: 4),
                      Text(widget.subtitle,
                          style: GoogleFonts.outfit(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            height: 1.4,
                          )),
                    ],
                  ),
                ),
                if (widget.onTap != null)
                  const Icon(Icons.arrow_forward_ios_rounded,
                      color: AppColors.textMuted, size: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
