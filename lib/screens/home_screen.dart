import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';
import '../services/firebase_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<Map<String, dynamic>> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _loadStats();
  }

  Future<Map<String, dynamic>> _loadStats() async {
    try {
      return await FirebaseService().getStats();
    } catch (_) {
      return {'quizCount': 0, 'totalQuestions': 0, 'avgScore': 0.0};
    }
  }

  void _refresh() {
    setState(() {
      _statsFuture = _loadStats();
    });
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
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.quiz_rounded,
                              color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Mock Test',
                          style: GoogleFonts.outfit(
                            color: AppColors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        // Refresh stats button
                        IconButton(
                          onPressed: _refresh,
                          icon: const Icon(Icons.refresh_rounded,
                              color: AppColors.textMuted, size: 22),
                          tooltip: 'Refresh Stats',
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'What would\nyou like to do?',
                      style: GoogleFonts.outfit(
                        color: AppColors.textPrimary,
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Upload PDFs, generate MCQs, or take a mock test.',
                      style: GoogleFonts.outfit(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Role cards ─────────────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      _RoleCard(
                        icon: Icons.admin_panel_settings_rounded,
                        gradient: AppColors.primaryGradient,
                        title: 'Admin Panel',
                        subtitle:
                            'Upload PDFs or images, extract text via OCR, and create MCQs with AI. Quizzes saved to Firestore.',
                        badge: 'UPLOAD & MANAGE',
                        onTap: () =>
                            Navigator.pushNamed(context, '/upload'),
                      ),
                      const SizedBox(height: 16),
                      _RoleCard(
                        icon: Icons.school_rounded,
                        gradient: AppColors.accentGradient,
                        title: 'Take Mock Test',
                        subtitle:
                            'Choose a quiz uploaded by admin and test your knowledge. Results saved automatically.',
                        badge: 'STUDENT MODE',
                        onTap: () =>
                            Navigator.pushNamed(context, '/quiz-list'),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Stats row (live from Firestore) ─────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
                child: FutureBuilder<Map<String, dynamic>>(
                  future: _statsFuture,
                  builder: (context, snapshot) {
                    final quizCount =
                        snapshot.data?['quizCount'] as int? ?? 0;
                    final totalQ =
                        snapshot.data?['totalQuestions'] as int? ?? 0;
                    final avg =
                        snapshot.data?['avgScore'] as double? ?? 0.0;
                    final loading =
                        snapshot.connectionState == ConnectionState.waiting;

                    return Row(
                      children: [
                        _StatChip(
                          icon: Icons.upload_file,
                          label: loading ? '—' : '$quizCount Quizzes',
                        ),
                        const SizedBox(width: 12),
                        _StatChip(
                          icon: Icons.quiz,
                          label: loading ? '—' : '$totalQ Questions',
                        ),
                        const SizedBox(width: 12),
                        _StatChip(
                          icon: Icons.star_rounded,
                          label: loading
                              ? '—'
                              : '${avg.toStringAsFixed(0)}% Avg',
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Role Card ──────────────────────────────────────────────────────────────
class _RoleCard extends StatefulWidget {
  final IconData icon;
  final LinearGradient gradient;
  final String title;
  final String subtitle;
  final String badge;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.gradient,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.onTap,
  });

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0,
      upperBound: 0.03,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(20),
            border:
                Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  gradient: widget.gradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child:
                    Icon(widget.icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 18),
              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        gradient: widget.gradient,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        widget.badge,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.title,
                      style: GoogleFonts.outfit(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle,
                      style: GoogleFonts.outfit(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded,
                  color: AppColors.textMuted, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Stat Chip ──────────────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: AppColors.cardBorder),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 18),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.outfit(
                  color: AppColors.textSecondary, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
