import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';
import 'student_quiz_results_page.dart';
import '../services/firebase_service.dart';
import 'subject_page.dart';
import 'manage_events_page.dart';
import 'class_options_page.dart';

class StudentManagementScreen extends StatefulWidget {
  const StudentManagementScreen({super.key});
  @override
  State<StudentManagementScreen> createState() => _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen> {
  static const _classes = [
    'Class 1', 'Class 2', 'Class 3', 'Class 4', 'Class 5',
    'Class 6', 'Class 7', 'Class 8', 'Class 9', 'Class 10',
    'Class 11', 'Class 12',
  ];

  String? _selectedClass;

  void _onClassTapped(String className) {
    setState(() => _selectedClass = className);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClassOptionsPage(className: className),
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
                        Text('Student Management',
                            style: GoogleFonts.outfit(
                              color: AppColors.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            )),
                        FutureBuilder<Map<String, dynamic>>(
                          future: FirebaseService().getStats(),
                          builder: (context, snapshot) {
                            final total = snapshot.data?['studentCount'] ?? 0;
                            return Text(
                                snapshot.connectionState == ConnectionState.waiting
                                    ? 'Fetching data...'
                                    : 'Select a class to manage progress and content • $total Registered',
                                style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 12));
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Class Selection
                      Text('Select Class',
                          style: GoogleFonts.outfit(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          )),
                      const SizedBox(height: 12),
                      FutureBuilder<Map<String, dynamic>>(
                        future: FirebaseService().getStats(),
                        builder: (context, snapshot) {
                          final breakdown = snapshot.data?['classBreakdown'] as Map<String, int>? ?? {};
                          
                          return LayoutBuilder(
                            builder: (context, constraints) {
                              final crossAxisCount = constraints.maxWidth > 600 ? 6 : 4;
                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                  childAspectRatio: 0.9,
                                ),
                                itemCount: _classes.length,
                                itemBuilder: (_, i) {
                                  final c = _classes[i];
                                  final selected = _selectedClass == c;
                                  final count = breakdown[c] ?? 0;
                                  
                                  return GestureDetector(
                                    onTap: () => _onClassTapped(c),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 180),
                                      decoration: BoxDecoration(
                                        gradient: selected ? AppColors.primaryGradient : null,
                                        color: selected ? null : AppColors.card,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: selected ? Colors.transparent : AppColors.cardBorder),
                                      ),
                                      child: Stack(
                                        children: [
                                          Center(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(c.replaceAll('Class ', ''),
                                                    style: GoogleFonts.outfit(
                                                      color: selected ? Colors.white : AppColors.textSecondary,
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w700,
                                                    )),
                                                if (count > 0)
                                                  Text('$count',
                                                      style: GoogleFonts.outfit(
                                                        color: selected ? Colors.white.withOpacity(0.7) : AppColors.textMuted,
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.w600,
                                                      )),
                                              ],
                                            ),
                                          ),
                                          if (count > 0 && !selected)
                                            Positioned(
                                              top: 6,
                                              right: 6,
                                              child: Container(
                                                width: 6,
                                                height: 6,
                                                decoration: const BoxDecoration(
                                                  color: AppColors.primary,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        }
                      ),

                      const SizedBox(height: 32),

                      // Global Management
                      Text('Global Management',
                          style: GoogleFonts.outfit(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          )),
                      const SizedBox(height: 12),
                      
                      _ManagementCard(
                        title: 'Manage Events',
                        subtitle: 'Add pictures, descriptions and news common to all students.',
                        icon: Icons.event_note_rounded,
                        gradient: AppColors.primaryGradient,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ManageEventsPage()),
                        ),
                      ),
                      
                      const SizedBox(height: 32),
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

class _ManagementCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _ManagementCard({
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
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.outfit(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      )),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: GoogleFonts.outfit(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      )),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 16),
          ],
        ),
      ),
    );
  }
}
