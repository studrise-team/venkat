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
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../auth/profile_page.dart';
import '../services/firebase_service.dart';
import '../models/event_model.dart';
import '../widgets/student_sidebar.dart';
import 'all_events_page.dart';

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
  DateTime? _lastBackPressTime;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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

  void _navigateFromHome(String action, {String? subject}) {
    if (_user == null) return;
    final className = _user!.classContext ?? 'Class 10';

    Widget page;
    switch (action) {
      case 'AI Quiz':
        page = QuizListView(exam: className, subject: subject, collection: 'daily_quizzes', title: 'AI Quizzes');
        break;
      case 'Live Classes':
        page = LiveClassView(exam: className, subject: subject);
        break;
      case 'Recorded Classes':
        page = VideoView(exam: className, subject: subject);
        break;
      case 'Material Links':
        page = NotesView(exam: className, subject: subject);
        break;
      case 'My Attendance':
        page = MyAttendanceView(className: className, studentName: _user!.name, subject: subject);
        break;
      case 'My Progress':
        page = MyProgressView(className: className, studentName: _user!.name, subject: subject);
        break;
      case 'Quiz Results':
        page = MyResultsView(className: className, studentId: _user!.uid, subject: subject);
        break;
      default:
        return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }



  // ---------------------------------------------------------------------------
  // Build helpers
  // ---------------------------------------------------------------------------
  Widget _buildHeader(bool isMobile) {
    final className = _user?.classContext ?? 'General';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        children: [
          if (isMobile) ...[
            IconButton(
              icon: const Icon(Icons.menu_rounded, color: AppColors.textPrimary),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            const SizedBox(width: 8),
          ],
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
          if (isMobile)
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


  // ---------------------------------------------------------------------------
  // Tab body builders
  // ---------------------------------------------------------------------------
  void _showSubjectActions(String subjectName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _SubjectActionSheet(
        subject: subjectName,
        onActionTap: (action) {
          Navigator.pop(context);
          _navigateFromHome(action, subject: subjectName);
        },
      ),
    );
  }

  Widget _buildHomeTab() {
    final className = _user?.classContext ?? 'General';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBanner('Daily Learning',
            'Access your classes, materials,\nand track your progress.',
            Icons.auto_stories_rounded),
        const SizedBox(height: 24),
        
        // Upcoming Events Carousel
        _buildEventsSection(),
        
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text('My Subjects',
              style: GoogleFonts.outfit(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
            stream: FirebaseService().getSubjects(className),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.primary));
              }
              final docs = snapshot.data ?? [];
              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.subject_rounded, color: AppColors.textMuted, size: 48),
                      const SizedBox(height: 12),
                      Text('No subjects found for $className',
                          style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  ),
                );
              }
              return GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: docs.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.3,
                ),
                itemBuilder: (_, i) {
                  final name = docs[i].data()['name'] ?? 'Untitled';
                  return _buildSubjectCard(name);
                },
              );
            },
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildSubjectCard(String name) {
    // Generate a consistent color based on name
    final colors = [
      const Color(0xFF6C63FF),
      const Color(0xFFe040fb),
      const Color(0xFFf7971e),
      const Color(0xFF38ef7d),
      const Color(0xFF00D4AA),
      const Color(0xFF00B8D9),
      const Color(0xFFFF6B6B),
    ];
    final color = colors[name.hashCode % colors.length];

    return GestureDetector(
      onTap: () => _showSubjectActions(name),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(Icons.menu_book_rounded, color: color, size: 24),
            ),
            const SizedBox(height: 10),
            Text(name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('School Events',
                  style: GoogleFonts.outfit(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AllEventsPage())),
                child: Text('View all',
                    style: GoogleFonts.outfit(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: StreamBuilder<List<EventModel>>(
            stream: FirebaseService().getEventsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.primary));
              }
              final events = snapshot.data ?? [];
              if (events.isEmpty) {
                return Center(
                  child: Text('No upcoming events',
                      style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 13)),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                scrollDirection: Axis.horizontal,
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  return _buildEventItem(event);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEventItem(EventModel event) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: event.imageUrl != null
                  ? Image.network(event.imageUrl!, width: double.infinity, fit: BoxFit.cover)
                  : Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
                      child: const Icon(Icons.event_available_rounded, color: Colors.white, size: 40),
                    ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 10, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(DateFormat('MMM dd, yyyy').format(event.date),
                          style: GoogleFonts.outfit(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(event.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(event.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 11)),
                ],
              ),
            ),
          ),
        ],
      ),
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
              className: className, studentName: _user!.name, showBackButton: false),
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
              className: className, studentId: _user!.uid, showBackButton: false),
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
              className: className, studentName: _user!.name, showBackButton: false),
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
      backgroundColor: AppColors.surface,
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

    final isMobile = MediaQuery.of(context).size.width < 800;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // If not on home tab, go back to home tab first
        if (_currentTab != _Tab.home) {
          setState(() => _currentTab = _Tab.home);
        } else {
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
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: AppColors.bg,
        drawer: isMobile
            ? StudentSidebar(
                user: _user,
                currentIndex: _Tab.values.indexOf(_currentTab),
                onTabSelected: (i) {
                  if (i == -1) {
                    Navigator.pop(context);
                    _openProfile();
                  } else {
                    setState(() => _currentTab = _Tab.values[i]);
                    Navigator.pop(context);
                  }
                },
                onLogout: () => _logout(context),
              )
            : null,
        bottomNavigationBar: isMobile ? _buildBottomNav() : null,
        body: LayoutBuilder(builder: (context, constraints) {
          // Re-calculate mobile state based on constraints for the body layout
          final isSmall = constraints.maxWidth < 800;

          final mainContent = Container(
            decoration: const BoxDecoration(gradient: AppColors.bgGradient),
            child: SafeArea(
              child: Column(
                children: [
                  _buildHeader(isSmall),
                  Expanded(child: _buildBody()),
                ],
              ),
            ),
          );

          if (isSmall) {
            return mainContent;
          }

          return Row(
            children: [
              StudentSidebar(
                isPermanent: true,
                user: _user,
                currentIndex: _Tab.values.indexOf(_currentTab),
                onTabSelected: (i) {
                  if (i == -1) {
                    _openProfile();
                  } else {
                    setState(() => _currentTab = _Tab.values[i]);
                  }
                },
                onLogout: () => _logout(context),
              ),
              Expanded(child: mainContent),
            ],
          );
        }),
      ),
    );
  }
}

class _SubjectActionSheet extends StatelessWidget {
  final String subject;
  final Function(String) onActionTap;

  const _SubjectActionSheet({required this.subject, required this.onActionTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, spreadRadius: 0)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.menu_book_rounded, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Subject Actions',
                        style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1)),
                    Text(subject,
                        style: GoogleFonts.outfit(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 32),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.9,
            children: [
              _ActionItem(label: 'AI Quiz', icon: Icons.auto_awesome_rounded, color: const Color(0xFF6C63FF), onTap: () => onActionTap('AI Quiz')),
              _ActionItem(label: 'Live Class', icon: Icons.live_tv_rounded, color: const Color(0xFFe040fb), onTap: () => onActionTap('Live Classes')),
              _ActionItem(label: 'Recorded', icon: Icons.play_circle_fill_rounded, color: const Color(0xFFf7971e), onTap: () => onActionTap('Recorded Classes')),
              _ActionItem(label: 'Materials', icon: Icons.link_rounded, color: const Color(0xFF38ef7d), onTap: () => onActionTap('Material Links')),
              _ActionItem(label: 'Attendance', icon: Icons.how_to_reg_rounded, color: const Color(0xFF00D4AA), onTap: () => onActionTap('My Attendance')),
              _ActionItem(label: 'Progress', icon: Icons.trending_up_rounded, color: const Color(0xFF00B8D9), onTap: () => onActionTap('My Progress')),
              _ActionItem(label: 'Results', icon: Icons.history_edu_rounded, color: const Color(0xFFFF6B6B), onTap: () => onActionTap('Quiz Results')),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionItem({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(label,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
