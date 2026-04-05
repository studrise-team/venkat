import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../app_theme.dart';
import 'subject_content_management_screen.dart';

class SubjectManagementScreen extends StatefulWidget {
  final String classId;
  final String className;

  const SubjectManagementScreen({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  State<SubjectManagementScreen> createState() => _SubjectManagementScreenState();
}

class _SubjectManagementScreenState extends State<SubjectManagementScreen> {
  final _firestore = FirebaseFirestore.instance;

  void _addSubject() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add Subject to ${widget.className}',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(
            hintText: 'e.g. Mathematics, English, Science',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.trim().isNotEmpty) {
                await _firestore
                    .collection('academic_classes')
                    .doc(widget.classId)
                    .collection('subjects')
                    .add({
                  'name': ctrl.text.trim(),
                  'createdAt': FieldValue.serverTimestamp(),
                });
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _editSubject(String id, String currentName) {
    final ctrl = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit Subject', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(
            hintText: 'e.g. Mathematics',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.trim().isNotEmpty) {
                await _firestore
                    .collection('academic_classes')
                    .doc(widget.classId)
                    .collection('subjects')
                    .doc(id)
                    .update({
                  'name': ctrl.text.trim(),
                });
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Update', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _deleteSubject(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Subject?'),
        content: const Text('This will permanently delete this subject and all its related syllabus, chapters, and video links.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('No')),
          TextButton(
            onPressed: () async {
              await _firestore
                  .collection('academic_classes')
                  .doc(widget.classId)
                  .collection('subjects')
                  .doc(id)
                  .delete();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Yes, Delete', style: TextStyle(color: AppColors.error)),
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
            Text('Subjects Management', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 16)),
            Text(widget.className, style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('academic_classes')
              .doc(widget.classId)
              .collection('subjects')
              .orderBy('createdAt')
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final docs = snapshot.data!.docs;
            if (docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.library_books_outlined, size: 60, color: AppColors.textMuted.withOpacity(0.5)),
                    const SizedBox(height: 16),
                    Text('No subjects for this class', style: GoogleFonts.outfit(color: AppColors.textMuted)),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _addSubject,
                      icon: const Icon(Icons.add),
                      label: const Text('Add First Subject'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              );
            }
            return LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 600 ? 5 : 2;
                return GridView.builder(
                  padding: const EdgeInsets.all(24),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: constraints.maxWidth > 600 ? 1.2 : 0.82,
                  ),
                  itemCount: docs.length + 1,
                  itemBuilder: (context, index) {
                    if (index == docs.length) {
                      return InkWell(
                        onTap: _addSubject,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.card.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.primary.withOpacity(0.3), style: BorderStyle.none),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary, size: 36),
                              const SizedBox(height: 8),
                              Text('Add Subject', style: GoogleFonts.outfit(color: AppColors.primary, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      );
                    }
                    final doc = docs[index];
                    final name = doc['name'] as String;
                    return _SubjectCard(
                      name: name,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SubjectContentManagementScreen(
                            classId: widget.classId,
                            className: widget.className,
                            subjectId: doc.id,
                            subjectName: name,
                          ),
                        ),
                      ),
                      onEdit: () => _editSubject(doc.id, name),
                      onDelete: () => _deleteSubject(doc.id),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  final String name;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SubjectCard({
    required this.name,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.book_rounded, color: AppColors.accent, size: 24),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      name,
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textMuted), onPressed: onEdit),
                IconButton(icon: Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error.withOpacity(0.7)), onPressed: onDelete),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
