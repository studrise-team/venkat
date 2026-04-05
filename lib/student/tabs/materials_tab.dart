import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app_theme.dart';

class MaterialsTab extends StatefulWidget {
  const MaterialsTab({super.key});

  @override
  State<MaterialsTab> createState() => _MaterialsTabState();
}

class _MaterialsTabState extends State<MaterialsTab> {
  String? _selectedClassId;
  String? _selectedClassName;
  String? _selectedSubjectId;
  String? _selectedSubjectName;

  bool _loading = true;
  bool _isApproved = false;

  @override
  void initState() {
    super.initState();
    _identifyStudentClass();
  }

  Future<void> _identifyStudentClass() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (mounted) {
      setState(() {
        _selectedClassId = doc.data()?['classId'];
        _isApproved = doc.data()?['isApproved'] ?? false;
        _loading = false;
        if (_selectedClassId != null) _loadClassName(_selectedClassId!);
      });
    }
  }

  Future<void> _loadClassName(String id) async {
    final doc = await FirebaseFirestore.instance.collection('academic_classes').doc(id).get();
    if (mounted && doc.exists) setState(() => _selectedClassName = doc.data()?['name']);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_selectedClassId == null || !_isApproved) return _restrictedView();

    return Column(
      children: [
        // ── Header ────────────────────────────────────────────────────────
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFD946EF)]),
            borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 64, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Academic Hub', style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(_selectedSubjectId != null ? 'Browsing: $_selectedSubjectName' : 'Class: ${_selectedClassName ?? "Loading..."}',
                  style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13)),
            ],
          ),
        ),

        // ── Breadcrumbs ───────────────────────────────────────────────────
        if (_selectedSubjectId != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                _crumb(_selectedClassName ?? 'Class', false, () => setState(() => _selectedSubjectId = null)),
                const Icon(Icons.chevron_right, size: 16, color: AppColors.textMuted),
                _crumb(_selectedSubjectName ?? 'Subject', true, () {}),
              ],
            ),
          ),

        // ── Body ──────────────────────────────────────────────────────────
        Expanded(child: _selectedSubjectId == null ? _subjectList() : _subjectContent()),
      ],
    );
  }

  Widget _restrictedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.lock_person_rounded, size: 64, color: AppColors.primary),
          const SizedBox(height: 24),
          Text(_selectedClassId == null ? 'Class Not Assigned' : 'Awaiting Approval', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800)),
          Text(_selectedClassId == null ? 'Contact admin to assign your class.' : 'Admin needs to approve your account to unlock curriculum.', textAlign: TextAlign.center, style: GoogleFonts.outfit(color: AppColors.textSecondary)),
        ]),
      ),
    );
  }

  Widget _crumb(String label, bool isSel, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Text(label, style: GoogleFonts.outfit(fontSize: 13, fontWeight: isSel ? FontWeight.w700 : FontWeight.w500, color: isSel ? AppColors.primary : AppColors.textMuted)),
    );
  }

  Widget _subjectList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('academic_classes').doc(_selectedClassId).collection('subjects').orderBy('createdAt').snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        if (snap.data!.docs.isEmpty) return _empty('No subjects assigned yet.');
        
        return GridView.builder(
          padding: const EdgeInsets.all(20),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 16, crossAxisSpacing: 16, childAspectRatio: 1.1),
          itemCount: snap.data!.docs.length,
          itemBuilder: (context, i) {
            final d = snap.data!.docs[i];
            return GestureDetector(
              onTap: () => setState(() {
                _selectedSubjectId = d.id;
                _selectedSubjectName = d['name'];
              }),
              child: Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.cardBorder), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const CircleAvatar(radius: 24, backgroundColor: Color(0xFFF3E8FF), child: Icon(Icons.auto_stories_rounded, color: AppColors.primary, size: 24)),
                  const SizedBox(height: 12),
                  Text(d['name'], style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textPrimary)),
                ]),
              ),
            );
          },
        );
      },
    );
  }

  Widget _subjectContent() {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textMuted,
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(text: 'Syllabus'),
              Tab(text: 'Videos'),
              Tab(text: 'Photos'),
              Tab(text: 'Study Material'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _contentList('syllabus'),
                _contentList('videos'),
                _contentList('photos'),
                _contentList('study_material'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _contentList(String type) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('academic_classes').doc(_selectedClassId).collection('subjects').doc(_selectedSubjectId).collection(type).orderBy('uploadedAt', descending: true).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        if (snap.data!.docs.isEmpty) return _empty('No $type yet.');
        
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: snap.data!.docs.length,
          itemBuilder: (context, i) {
            final d = snap.data!.docs[i];
            IconData icon = Icons.description_rounded;
            if (type == 'videos') icon = Icons.play_circle_fill_rounded;
            if (type == 'photos') icon = Icons.image_rounded;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.cardBorder)),
              child: ListTile(
                leading: CircleAvatar(backgroundColor: AppColors.cardLight, child: Icon(icon, color: AppColors.primary, size: 20)),
                title: Text(d['title'], style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 14)),
                subtitle: Text(d['description'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.file_download_rounded, color: AppColors.primary, size: 20),
                onTap: () => _handleContentAccess(d['url'], d['title'], type),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleContentAccess(String url, String title, String type) async {
    if (url.isEmpty) return;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(type == 'videos' ? 'Watch Video?' : 'Open/Download?', style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
        content: Text('Do you want to ${type == 'videos' ? "watch" : "open/download"} "$title"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(type == 'videos' ? 'Watch Now' : 'Open/Download', style: const TextStyle(fontWeight: FontWeight.w800))),
        ],
      )
    );
    
    if (confirm == true) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  Widget _empty(String msg) => Center(child: Text(msg, style: GoogleFonts.outfit(color: AppColors.textMuted)));
}
