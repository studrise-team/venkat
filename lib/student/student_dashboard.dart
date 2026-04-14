import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../app_theme.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../widgets/logout_dialog.dart';
import '../aspirant/quiz_list_view.dart';
import '../aspirant/live_class_view.dart';
import '../aspirant/video_view.dart';
import '../aspirant/notes_view.dart';
import 'my_attendance_view.dart';
import 'my_progress_view.dart';
import 'my_results_view.dart';
import '../auth/profile_page.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  UserModel? _user;
  bool _loading = true;

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
        _loading = false;
      });
    }
  }

  void _logout(BuildContext context) async {
    await LogoutDialog.show(context);
  }

  static const _actions = [
    {'label': 'AI Quiz', 'icon': Icons.auto_awesome_rounded, 'color': Color(0xFF6C63FF)},
    {'label': 'Live Classes', 'icon': Icons.live_tv_rounded, 'color': Color(0xFFe040fb)},
    {'label': 'Recorded Classes', 'icon': Icons.play_circle_fill_rounded, 'color': Color(0xFFf7971e)},
    {'label': 'Material Links', 'icon': Icons.link_rounded, 'color': Color(0xFF38ef7d)},
    {'label': 'My Attendance', 'icon': Icons.how_to_reg_rounded, 'color': Color(0xFF00D4AA)},
    {'label': 'My Progress', 'icon': Icons.trending_up_rounded, 'color': Color(0xFF00B8D9)},
    {'label': 'Quiz Results', 'icon': Icons.history_edu_rounded, 'color': Color(0xFFFF6B6B)},
  ];

  void _navigate(String action) {
    if (_user == null) return;
    final className = _user!.classContext ?? 'Class 10';

    Widget page;
    switch (action) {
      case 'AI Quiz':
        page = QuizListView(exam: className, collection: 'daily_quizzes', title: 'AI Quizzes');
        break;
      case 'Live Classes':
        page = LiveClassView(exam: className);
        break;
      case 'Recorded Classes':
        page = VideoView(exam: className);
        break;
      case 'Material Links':
        page = NotesView(exam: className);
        break;
      case 'My Attendance':
        page = MyAttendanceView(className: className, studentName: _user!.name);
        break;
      case 'My Progress':
        page = MyProgressView(className: className, studentName: _user!.name);
        break;
      case 'Quiz Results':
        page = MyResultsView(className: className, studentId: _user!.uid);
        break;
      default:
        return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
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
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
    }

    final className = _user?.classContext ?? 'General';

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
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _openProfile,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(gradient: AppColors.accentGradient, shape: BoxShape.circle),
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
                              Text(_user?.name ?? 'Student',
                                  style: GoogleFonts.outfit(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
                              Text(className, style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 12)),
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
                 // Banner
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: AppColors.accentGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Daily Learning',
                                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              Text('Access your classes, materials,\nand track your progress.',
                                  style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13, height: 1.5)),
                            ],
                          ),
                        ),
                        const Icon(Icons.auto_stories_rounded, color: Colors.white30, size: 56),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: GridView.builder(
                      itemCount: _actions.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.1,
                      ),
                      itemBuilder: (_, i) {
                        final action = _actions[i];
                        final color = action['color'] as Color;
                        return GestureDetector(
                          onTap: () => _navigate(action['label'] as String),
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                                  child: Icon(action['icon'] as IconData, color: color, size: 28),
                                ),
                                const SizedBox(height: 12),
                                Text(action['label'] as String,
                                    style: GoogleFonts.outfit(
                                        color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
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
      ),
    );
  }
}
