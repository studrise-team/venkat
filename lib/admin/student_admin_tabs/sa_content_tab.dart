import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../../app_theme.dart';
import '../../services/cloudinary_service.dart';

class SAContentTab extends StatefulWidget {
  const SAContentTab({super.key});

  @override
  State<SAContentTab> createState() => _SAContentTabState();
}

class _SAContentTabState extends State<SAContentTab> {
  String? _selectedClassId;
  String? _selectedClassName;
  String? _selectedSubjectId;
  String? _selectedSubjectName;

  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Header ────────────────────────────────────────────────────────
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF00B894), Color(0xFF00CEC9)]),
            borderRadius: BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 52, 20, 24),
          child: Column(
            children: [
              Text('Academic Flow',
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              Text('Think like a teacher. Organize your curriculum.',
                  style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13)),
            ],
          ),
        ),

        // ── Breadcrumbs ───────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.all(12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _breadcrumb('Classes', _selectedClassId == null, () {
                  setState(() {
                    _selectedClassId = null;
                    _selectedSubjectId = null;
                  });
                }),
                if (_selectedClassId != null) ...[
                  const Icon(Icons.chevron_right, size: 16, color: AppColors.textMuted),
                  _breadcrumb(_selectedClassName!, _selectedSubjectId == null, () {
                    setState(() => _selectedSubjectId = null);
                  }),
                ],
                if (_selectedSubjectId != null) ...[
                  const Icon(Icons.chevron_right, size: 16, color: AppColors.textMuted),
                  _breadcrumb(_selectedSubjectName!, true, () {}),
                ],
              ],
            ),
          ),
        ),

        // ── Main List ─────────────────────────────────────────────────────
        Expanded(child: _buildMainList()),
      ],
    );
  }

  Widget _breadcrumb(String label, bool isLast, VoidCallback onTap) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: isLast ? AppColors.primary : AppColors.textMuted,
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
      child: Text(label, style: GoogleFonts.outfit(fontWeight: isLast ? FontWeight.w700 : FontWeight.w400)),
    );
  }

  Widget _buildMainList() {
    if (_selectedClassId == null) return _classList();
    if (_selectedSubjectId == null) return _subjectList(_selectedClassId!);
    return _contentHub(_selectedClassId!, _selectedSubjectId!);
  }

  // ── Class Management ────────────────────────────────────────────────────
  Widget _classList() {
    return Column(
      children: [
        _addButton('new academic class', _addClassDialog),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('academic_classes').orderBy('createdAt', descending: true).snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              if (snap.data!.docs.isEmpty) return _emptyState('Classes');
              
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: snap.data!.docs.length,
                itemBuilder: (context, i) {
                  final d = snap.data!.docs[i];
                  return _itemTile(
                    title: d['name'],
                    icon: Icons.school_rounded,
                    onTap: () => setState(() {
                      _selectedClassId = d.id;
                      _selectedClassName = d['name'];
                    }),
                    onDelete: () => _deleteDoc('academic_classes', d.id),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Subject Management ──────────────────────────────────────────────────
  Widget _subjectList(String classId) {
    return Column(
      children: [
        _addButton('subject for $_selectedClassName', () => _addSubjectDialog(classId)),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('academic_classes').doc(classId).collection('subjects').orderBy('createdAt').snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              if (snap.data!.docs.isEmpty) return _emptyState('Subjects');
              
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: snap.data!.docs.length,
                itemBuilder: (context, i) {
                  final d = snap.data!.docs[i];
                  return _itemTile(
                    title: d['name'],
                    icon: Icons.book_rounded,
                    onTap: () => setState(() {
                      _selectedSubjectId = d.id;
                      _selectedSubjectName = d['name'];
                    }),
                    onDelete: () => _deleteDocDeep(classId, 'subjects', d.id),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Content Hub (Teacher Perspective) ──────────────────────────────────
  Widget _contentHub(String classId, String subjectId) {
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
              Tab(text: 'Syllabus/PDF'),
              Tab(text: 'Videos'),
              Tab(text: 'Photos'),
              Tab(text: 'Study Material'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _contentList(classId, subjectId, 'syllabus'),
                _contentList(classId, subjectId, 'videos'),
                _contentList(classId, subjectId, 'photos'),
                _contentList(classId, subjectId, 'study_material'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _contentList(String classId, String subjectId, String type) {
    return Column(
      children: [
        _addButton('new $type', () => _uploadContentDialog(classId, subjectId, type)),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('academic_classes')
                .doc(classId)
                .collection('subjects')
                .doc(subjectId)
                .collection(type)
                .orderBy('uploadedAt', descending: true)
                .snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              if (snap.data!.docs.isEmpty) return _emptyState(type);
              
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: snap.data!.docs.length,
                itemBuilder: (context, i) {
                  final d = snap.data!.docs[i];
                  IconData icon = Icons.description_rounded;
                  if (type == 'videos') icon = Icons.play_circle_fill_rounded;
                  if (type == 'photos') icon = Icons.image_rounded;
                  
                  return _itemTile(
                    title: d['title'],
                    subtitle: d['description'] ?? 'No description',
                    icon: icon,
                    onTap: () {},
                    onDelete: () => FirebaseFirestore.instance
                        .collection('academic_classes')
                        .doc(classId)
                        .collection('subjects')
                        .doc(subjectId)
                        .collection(type)
                        .doc(d.id)
                        .delete(),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Dialogs ─────────────────────────────────────────────────────────────
  
  Future<void> _addClassDialog() async {
    final ctrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('New Academic Class', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'e.g. Class 1, Level A')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () async {
            if (ctrl.text.isEmpty) return;
            await FirebaseFirestore.instance.collection('academic_classes').add({
              'name': ctrl.text.trim(),
              'createdAt': FieldValue.serverTimestamp(),
            });
            if (context.mounted) Navigator.pop(ctx);
          }, child: const Text('Create')),
        ],
      ),
    );
  }

  Future<void> _addSubjectDialog(String classId) async {
    final ctrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('New Subject', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'e.g. Science, Mathematics')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () async {
            if (ctrl.text.isEmpty) return;
            await FirebaseFirestore.instance.collection('academic_classes').doc(classId).collection('subjects').add({
              'name': ctrl.text.trim(),
              'createdAt': FieldValue.serverTimestamp(),
            });
            if (context.mounted) Navigator.pop(ctx);
          }, child: const Text('Add Subject')),
        ],
      ),
    );
  }

  Future<void> _uploadContentDialog(String classId, String subjectId, String type) async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    File? selectedFile;
    
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Upload to ${type.replaceAll("_", " ").toUpperCase()}', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 20),
                  TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Description (What is this about?)', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  if (type != 'videos') ...[
                    GestureDetector(
                      onTap: () async {
                        final result = await FilePicker.platform.pickFiles();
                        if (result != null) setModalState(() => selectedFile = File(result.files.single.path!));
                      },
                      child: Container(
                        height: 100, width: double.infinity,
                        decoration: BoxDecoration(color: AppColors.cardLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.cardBorder)),
                        child: selectedFile != null 
                          ? Center(child: Text(selectedFile!.path.split('/').last, style: const TextStyle(fontSize: 12)))
                          : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.upload_file_rounded, color: AppColors.primary), Text('Pick File')]),
                      ),
                    ),
                  ] else ...[
                    TextField(controller: urlCtrl, decoration: const InputDecoration(labelText: 'YouTube / Video Link', border: OutlineInputBorder())),
                  ],
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: _isUploading ? null : () async {
                      if (titleCtrl.text.isEmpty) return;
                      setModalState(() => _isUploading = true);
                      
                      String finalUrl = urlCtrl.text.trim();
                      if (selectedFile != null) {
                        finalUrl = await CloudinaryService().uploadFile(selectedFile!, folder: 'academic/$type') ?? '';
                      }
                      
                      if (finalUrl.isNotEmpty || type == 'study_material') {
                         await FirebaseFirestore.instance
                            .collection('academic_classes')
                            .doc(classId)
                            .collection('subjects')
                            .doc(subjectId)
                            .collection(type)
                            .add({
                          'title': titleCtrl.text.trim(),
                          'description': descCtrl.text.trim(),
                          'url': finalUrl,
                          'uploadedAt': FieldValue.serverTimestamp(),
                        });
                        if (mounted) Navigator.pop(ctx);
                      }
                      setModalState(() => _isUploading = false);
                    },
                    child: Container(
                      width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(14)),
                      alignment: Alignment.center,
                      child: _isUploading 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text('Broadcast to Students', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────
  
  Widget _itemTile({required String title, required IconData icon, required VoidCallback onTap, required VoidCallback onDelete, String? subtitle}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.cardBorder)),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(backgroundColor: AppColors.cardLight, child: Icon(icon, color: AppColors.primary, size: 20)),
        title: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 14)),
        subtitle: subtitle != null ? Text(subtitle, style: GoogleFonts.outfit(fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis) : null,
        trailing: IconButton(icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 18), onPressed: onDelete),
      ),
    );
  }

  Widget _addButton(String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.primary.withOpacity(0.1))),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary, size: 18),
            const SizedBox(width: 8),
            Text('Add $label', style: GoogleFonts.outfit(color: AppColors.primary, fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    );
  }

  Widget _emptyState(String label) => Center(child: Text('No $label yet.', style: GoogleFonts.outfit(color: AppColors.textMuted)));

  Future<void> _deleteDoc(String collection, String id) async {
    await FirebaseFirestore.instance.collection(collection).doc(id).delete();
  }

  Future<void> _deleteDocDeep(String parentId, String collection, String id) async {
    await FirebaseFirestore.instance.collection('academic_classes').doc(parentId).collection(collection).doc(id).delete();
  }
}
