import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

// ---------------------------------------------------------------------------
// Tab indices
// ---------------------------------------------------------------------------
enum _Tab { home, attendance, history, progress }

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  UserModel? _user;
  bool _loading = true;
  _Tab _currentTab = _Tab.home;

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

  void _openProfile() {
    if (_user == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProfilePage(user: _user!)),
    ).then((_) => _loadUser());
  }

  // ---------------------------------------------------------------------------
  // Home tab – quick-action grid
  // ---------------------------------------------------------------------------
  static const _homeActions = [
    {'label': 'AI Quiz', 'icon': Icons.auto_awesome_rounded, 'color': Color(0xFF6C63FF)},
    {'label': 'Live Classes', 'icon': Icons.live_tv_rounded, 'color': Color(0xFFe040fb)},
    {'label': 'Recorded Classes', 'icon': Icons.play_circle_fill_rounded, 'color': Color(0xFFf7971e)},
    {'label': 'Material Links', 'icon': Icons.link_rounded, 'color': Color(0xFF38ef7d)},
    {'label': 'My Attendance', 'icon': Icons.how_to_reg_rounded, 'color': Color(0xFF00D4AA)},
    {'label': 'My Progress', 'icon': Icons.trending_up_rounded, 'color': Color(0xFF00B8D9)},
    {'label': 'Quiz Results', 'icon': Icons.history_edu_rounded, 'color': Color(0xFFFF6B6B)},
  ];

  void _navigateFromHome(String action) {
    if (_user == null) return;
    final className = _user!.classContext ?? 'Class 10';

    // Map certain home-grid taps to bottom-nav tabs for seamless UX
    switch (action) {
      case 'My Attendance':
        setState(() => _currentTab = _Tab.attendance);
        return;
      case 'My Progress':
        setState(() => _currentTab = _Tab.progress);
        return;
      case 'Quiz Results':
        setState(() => _currentTab = _Tab.history);
        return;
    }

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
      default:
        return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }



  // ---------------------------------------------------------------------------
  // Build helpers
  // ---------------------------------------------------------------------------
  Widget _buildHeader() {
    final className = _user?.classContext ?? 'General';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        children: [
          GestureDetector(
            onTap: _openProfile,
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                  gradient: AppColors.accentGradient, shape: BoxShape.circle),
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
                      style: GoogleFonts.outfit(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700)),
                  Text(className,
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
    );
  }

  Widget _buildBanner(String title, String subtitle, IconData icon) {
    return Padding(
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
                  Text(title,
                      style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: GoogleFonts.outfit(
                          color: Colors.white70, fontSize: 13, height: 1.5)),
                ],
              ),
            ),
            Icon(icon, color: Colors.white30, size: 56),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(Map<String, Object> action, VoidCallback onTap) {
    final color = action['color'] as Color;
    return GestureDetector(
      onTap: onTap,
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
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(action['icon'] as IconData, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(action['label'] as String,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Tab body builders
  // ---------------------------------------------------------------------------
  Widget _buildHomeTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBanner('Daily Learning',
            'Access your classes, materials,\nand track your progress.',
            Icons.auto_stories_rounded),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text('Quick Access',
              style: GoogleFonts.outfit(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: GridView.builder(
              itemCount: _homeActions.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
              ),
              itemBuilder: (_, i) {
                final action = _homeActions[i];
                return _buildActionCard(
                    action,
                    () => _navigateFromHome(action['label'] as String));
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildAttendanceTab() {
    final className = _user?.classContext ?? 'Class 10';
    return Column(
      children: [
        _buildBanner('My Attendance',
            'View your daily attendance\nrecords and status.',
            Icons.how_to_reg_rounded),
        const SizedBox(height: 16),
        Expanded(
          child: MyAttendanceView(
              className: className, studentName: _user!.name),
        ),
      ],
    );
  }



  Widget _buildHistoryTab() {
    final className = _user?.classContext ?? 'Class 10';
    return Column(
      children: [
        _buildBanner('Quiz History',
            'Review your past quiz attempts\nand scores.',
            Icons.history_edu_rounded),
        const SizedBox(height: 16),
        Expanded(
          child: MyResultsView(
              className: className, studentId: _user!.uid),
        ),
      ],
    );
  }

  Widget _buildProgressTab() {
    final className = _user?.classContext ?? 'Class 10';
    return Column(
      children: [
        _buildBanner('My Progress',
            'Track your learning journey\nand performance over time.',
            Icons.trending_up_rounded),
        const SizedBox(height: 16),
        Expanded(
          child: MyProgressView(
              className: className, studentName: _user!.name),
        ),
      ],
    );
  }

  Widget _buildBody() {
    switch (_currentTab) {
      case _Tab.home:
        return _buildHomeTab();
      case _Tab.attendance:
        return _buildAttendanceTab();
      case _Tab.history:
        return _buildHistoryTab();
      case _Tab.progress:
        return _buildProgressTab();
    }
  }

  // ---------------------------------------------------------------------------
  // Bottom nav
  // ---------------------------------------------------------------------------
  BottomNavigationBar _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _Tab.values.indexOf(_currentTab),
      onTap: (i) => setState(() => _currentTab = _Tab.values[i]),
      backgroundColor: const Color(0xFF1A1A2E),
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
      selectedLabelStyle:
          GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600),
      unselectedLabelStyle: GoogleFonts.outfit(fontSize: 11),
      type: BottomNavigationBarType.fixed,
      elevation: 16,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_rounded),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.how_to_reg_rounded),
          label: 'Attendance',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.history_edu_rounded),
          label: 'History',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.trending_up_rounded),
          label: 'Progress',
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Root build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
          body: Center(
              child: CircularProgressIndicator(color: AppColors.primary)));
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // If not on home tab, go back to home tab first
        if (_currentTab != _Tab.home) {
          setState(() => _currentTab = _Tab.home);
        } else {
          _logout(context);
        }
      },
      child: Scaffold(
        bottomNavigationBar: _buildBottomNav(),
        body: Container(
          decoration: const BoxDecoration(gradient: AppColors.bgGradient),
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
