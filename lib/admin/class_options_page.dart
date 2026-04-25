import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';
import 'subject_page.dart';
import 'class_student_list_page.dart';

class ClassOptionsPage extends StatelessWidget {
  final String className;
  const ClassOptionsPage({super.key, required this.className});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 24, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(className,
                            style: GoogleFonts.outfit(
                              color: AppColors.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            )),
                        Text('Select a module to manage',
                            style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      _OptionCard(
                        title: 'Student Progress',
                        subtitle: 'Manage individual student reports, grades and academic progress.',
                        icon: Icons.trending_up_rounded,
                        gradient: const LinearGradient(colors: [Color(0xFF38ef7d), Color(0xFF11998e)]),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ClassStudentListPage(className: className)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _OptionCard(
                        title: 'Academic Content',
                        subtitle: 'Manage subjects, live classes, quizzes, materials and attendance.',
                        icon: Icons.auto_stories_rounded,
                        gradient: AppColors.primaryGradient,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => SubjectPage(className: className)),
                        ),
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

class _OptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _OptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 20),
            Text(title,
                style: GoogleFonts.outfit(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                )),
            const SizedBox(height: 8),
            Text(subtitle,
                style: GoogleFonts.outfit(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.4,
                )),
            const SizedBox(height: 20),
            Row(
              children: [
                Text('Manage Now', 
                  style: GoogleFonts.outfit(
                    color: gradient.colors.last, 
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  )),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, color: gradient.colors.last, size: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
