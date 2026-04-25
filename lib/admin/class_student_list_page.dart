import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';
import '../services/firebase_service.dart';
import 'student_progress_page.dart';

class ClassStudentListPage extends StatefulWidget {
  final String className;
  const ClassStudentListPage({super.key, required this.className});

  @override
  State<ClassStudentListPage> createState() => _ClassStudentListPageState();
}

class _ClassStudentListPageState extends State<ClassStudentListPage> {
  String _searchQuery = '';

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
                        Text('Select Student',
                            style: GoogleFonts.outfit(
                              color: AppColors.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            )),
                        Text(widget.className,
                            style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                  style: GoogleFonts.outfit(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search students...',
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.card,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: FirebaseService().getStudentsByClass(widget.className),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                    }
                    var students = snapshot.data ?? [];
                    
                    if (_searchQuery.isNotEmpty) {
                      students = students.where((s) => (s['name'] ?? '').toString().toLowerCase().contains(_searchQuery)).toList();
                    }

                    if (students.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.people_outline_rounded, color: AppColors.textMuted, size: 60),
                            const SizedBox(height: 16),
                            Text(_searchQuery.isEmpty ? 'No students registered' : 'No students found',
                                style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 16)),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      itemCount: students.length,
                      itemBuilder: (_, i) {
                        final student = students[i];
                        final name = student['name'] ?? 'Unknown Student';
                        final email = student['email'] ?? '';
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => StudentProgressPage(
                                  className: widget.className,
                                  studentName: name,
                                ),
                              ),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.cardBorder),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: AppColors.primary.withOpacity(0.1),
                                    child: Text(name[0].toUpperCase(), 
                                      style: GoogleFonts.outfit(color: AppColors.primary, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(name, style: GoogleFonts.outfit(
                                          color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                                        if (email.isNotEmpty)
                                          Text(email, style: GoogleFonts.outfit(
                                            color: AppColors.textSecondary, fontSize: 11)),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 14),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
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
