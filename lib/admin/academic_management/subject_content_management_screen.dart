import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class SubjectContentManagementScreen extends StatefulWidget {
  final String classId;
  final String className;
  final String subjectId;
  final String subjectName;

  const SubjectContentManagementScreen({
    super.key,
    required this.classId,
    required this.className,
    required this.subjectId,
    required this.subjectName,
  });

  @override
  State<SubjectContentManagementScreen> createState() => _SubjectContentManagementScreenState();
}

class _SubjectContentManagementScreenState extends State<SubjectContentManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Syllabus/Chapters ──────────────────────────────────────────────────────

  void _addChapter() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add Chapter', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: InputDecoration(
                labelText: 'Chapter Title',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Topics/Description',
                alignLabelWithHint: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (titleCtrl.text.trim().isNotEmpty) {
                await _firestore
                    .collection('academic_classes')
                    .doc(widget.classId)
                    .collection('subjects')
                    .doc(widget.subjectId)
                    .collection('syllabus')
                    .add({
                  'title': titleCtrl.text.trim(),
                  'description': descCtrl.text.trim(),
                  'order': DateTime.now().millisecondsSinceEpoch,
                });
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Video Classes ──────────────────────────────────────────────────────────

  void _addVideo() {
    final titleCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add Video Lesson', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: InputDecoration(
                labelText: 'Lesson Title',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlCtrl,
              decoration: InputDecoration(
                labelText: 'YouTube/Video URL',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (titleCtrl.text.trim().isNotEmpty && urlCtrl.text.trim().isNotEmpty) {
                await _firestore
                    .collection('academic_classes')
                    .doc(widget.classId)
                    .collection('subjects')
                    .doc(widget.subjectId)
                    .collection('videos')
                    .add({
                  'title': titleCtrl.text.trim(),
                  'url': urlCtrl.text.trim(),
                  'createdAt': FieldValue.serverTimestamp(),
                });
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE91E63)),
            child: const Text('Add video', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Tests/Quizzes ──────────────────────────────────────────────────────────

  void _addTest() {
    final titleCtrl = TextEditingController();
    final quizIdCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Link Test/Quiz', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: InputDecoration(
                labelText: 'Test Name',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: quizIdCtrl,
              decoration: InputDecoration(
                labelText: 'Quiz ID (from Quizzes section)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (titleCtrl.text.trim().isNotEmpty) {
                await _firestore
                    .collection('academic_classes')
                    .doc(widget.classId)
                    .collection('subjects')
                    .doc(widget.subjectId)
                    .collection('tests')
                    .add({
                  'title': titleCtrl.text.trim(),
                  'quizId': quizIdCtrl.text.trim(),
                  'createdAt': FieldValue.serverTimestamp(),
                });
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF9800)),
            child: const Text('Add Test', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Study Materials ────────────────────────────────────────────────────────

  void _addMaterial() {
    final titleCtrl = TextEditingController();
    final linkCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add Study Material', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: InputDecoration(
                labelText: 'Material Title',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: linkCtrl,
              decoration: InputDecoration(
                labelText: 'File Link / drive link',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (titleCtrl.text.trim().isNotEmpty) {
                await _firestore
                    .collection('academic_classes')
                    .doc(widget.classId)
                    .collection('subjects')
                    .doc(widget.subjectId)
                    .collection('materials')
                    .add({
                  'title': titleCtrl.text.trim(),
                  'link': linkCtrl.text.trim(),
                  'createdAt': FieldValue.serverTimestamp(),
                });
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00B894)),
            child: const Text('Add Material', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.subjectName, style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 18)),
            Text('${widget.className} • Content Management', style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Syllabus'),
            Tab(text: 'Videos'),
            Tab(text: 'Tests'),
            Tab(text: 'Materials'),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildSyllabusTab(),
            _buildVideosTab(),
            _buildTestsTab(),
            _buildMaterialsTab(),
          ],
        ),
      ),
    );
  }

  // ── Syllabus View ─────────────────────────────────────────────────────────

  Widget _buildSyllabusTab() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: _addChapter,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('academic_classes')
            .doc(widget.classId)
            .collection('subjects')
            .doc(widget.subjectId)
            .collection('syllabus')
            .orderBy('order')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return _emptyState('Click + to add chapters/syllabus content');
          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final d = docs[i];
              return _ContentTile(
                title: d['title'],
                subtitle: d['description'] ?? '',
                icon: Icons.bookmark_added_rounded,
                iconColor: AppColors.primary,
                suffix: IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                  onPressed: () => d.reference.delete(),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ── Videos View ──────────────────────────────────────────────────────────

  Widget _buildVideosTab() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: _addVideo,
        backgroundColor: const Color(0xFFE91E63),
        child: const Icon(Icons.video_library_rounded, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('academic_classes')
            .doc(widget.classId)
            .collection('subjects')
            .doc(widget.subjectId)
            .collection('videos')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return _emptyState('Upload video lessons for this subject');
          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final d = docs[i];
              return _ContentTile(
                title: d['title'],
                subtitle: d['url'],
                icon: Icons.play_circle_fill_rounded,
                iconColor: const Color(0xFFE91E63),
                onTap: () async {
                  final uri = Uri.parse(d['url']);
                  if (await canLaunchUrl(uri)) launchUrl(uri);
                },
                suffix: IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                  onPressed: () => d.reference.delete(),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ── Tests View ────────────────────────────────────────────────────────────

  Widget _buildTestsTab() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: _addTest,
        backgroundColor: const Color(0xFFFF9800),
        child: const Icon(Icons.quiz_rounded, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('academic_classes')
            .doc(widget.classId)
            .collection('subjects')
            .doc(widget.subjectId)
            .collection('tests')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return _emptyState('Link quizzes/tests to this subject');
          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final d = docs[i];
              return _ContentTile(
                title: d['title'],
                subtitle: 'Quiz ID: ${d['quizId']}',
                icon: Icons.assignment_turned_in_rounded,
                iconColor: const Color(0xFFFF9800),
                suffix: IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                  onPressed: () => d.reference.delete(),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ── Materials View ────────────────────────────────────────────────────────

  Widget _buildMaterialsTab() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: _addMaterial,
        backgroundColor: const Color(0xFF00B894),
        child: const Icon(Icons.description_rounded, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('academic_classes')
            .doc(widget.classId)
            .collection('subjects')
            .doc(widget.subjectId)
            .collection('materials')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return _emptyState('Upload study materials for this subject');
          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final d = docs[i];
              return _ContentTile(
                title: d['title'],
                subtitle: d['link'],
                icon: Icons.insert_drive_file_rounded,
                iconColor: const Color(0xFF00B894),
                onTap: () async {
                   if (d['link'].toString().startsWith('http')) {
                      final uri = Uri.parse(d['link']);
                      if (await canLaunchUrl(uri)) launchUrl(uri);
                   }
                },
                suffix: IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                  onPressed: () => d.reference.delete(),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _emptyState(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.textMuted.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(msg, style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 13)),
        ],
      ),
    );
  }
}

class _ContentTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Widget? suffix;
  final VoidCallback? onTap;

  const _ContentTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    this.suffix,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 15)),
        subtitle: subtitle.isNotEmpty
            ? Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary))
            : null,
        trailing: suffix,
      ),
    );
  }
}
