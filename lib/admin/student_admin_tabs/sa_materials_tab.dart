import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../../app_theme.dart';
import '../../services/cloudinary_service.dart';

class SAMaterialsTab extends StatefulWidget {
  const SAMaterialsTab({super.key});

  @override
  State<SAMaterialsTab> createState() => _SAMaterialsTabState();
}

class _SAMaterialsTabState extends State<SAMaterialsTab> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _linkCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  String _query = '';
  String _selectedCategory = 'Notes';
  final List<String> _categories = ['Notes', 'Previous Papers', 'Assignments', 'Videos'];
  File? _selectedFile;
  String? _selectedFileName;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _linkCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile(StateSetter setModalState) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'jpg', 'png'],
    );

    if (result != null && result.files.single.path != null) {
      setModalState(() {
        _selectedFile = File(result.files.single.path!);
        _selectedFileName = result.files.single.name;
        // Auto-fill title if empty
        if (_titleCtrl.text.isEmpty) {
          _titleCtrl.text = _selectedFileName!.split('.').first;
        }
      });
    }
  }

  void _showAddDialog() {
    _selectedFile = null;
    _selectedFileName = null;
    _titleCtrl.clear();
    _descCtrl.clear();
    _linkCtrl.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Add Study Material', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700)),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
                  ],
                ),
                const SizedBox(height: 16),
                
                GestureDetector(
                  onTap: () => _pickFile(setModalState),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary.withOpacity(0.2), style: BorderStyle.solid),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _selectedFile != null ? Icons.insert_drive_file_rounded : Icons.cloud_upload_outlined,
                          color: AppColors.primary,
                          size: 32,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _selectedFileName ?? 'Tap to select PDF or Document',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            color: _selectedFile != null ? AppColors.textPrimary : AppColors.textSecondary,
                            fontWeight: _selectedFile != null ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                TextField(
                  controller: _titleCtrl,
                  decoration: InputDecoration(
                    labelText: 'Material Title',
                    prefixIcon: const Icon(Icons.title_rounded, size: 20),
                    filled: true,
                    fillColor: AppColors.cardLight,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                
                TextField(
                  controller: _descCtrl,
                  decoration: InputDecoration(
                    labelText: 'Description (Optional)',
                    prefixIcon: const Icon(Icons.description_rounded, size: 20),
                    filled: true,
                    fillColor: AppColors.cardLight,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setModalState(() => _selectedCategory = v!),
                  decoration: InputDecoration(
                    labelText: 'Category',
                    prefixIcon: const Icon(Icons.category_rounded, size: 20),
                    filled: true,
                    fillColor: AppColors.cardLight,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 24),
                
                GestureDetector(
                  onTap: _isSaving ? null : () => _saveMaterial(setModalState),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    alignment: Alignment.center,
                    child: _isSaving 
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                            const SizedBox(width: 12),
                            Text('Uploading...', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700)),
                          ],
                        )
                      : Text('Upload Material', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveMaterial(StateSetter setModalState) async {
    if (_titleCtrl.text.isEmpty) return;
    if (_selectedFile == null && _linkCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a file or provide a link')));
      return;
    }

    setModalState(() => _isSaving = true);
    
    String? finalLink = _linkCtrl.text.trim();

    if (_selectedFile != null) {
      finalLink = await CloudinaryService().uploadFile(_selectedFile!, folder: 'study_materials');
    }

    if (finalLink == null) {
      if (mounted) {
        setModalState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to upload file. Please try again.'), backgroundColor: AppColors.error));
      }
      return;
    }
    
    await FirebaseFirestore.instance.collection('study_materials').add({
      'title': _titleCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'link': finalLink,
      'category': _selectedCategory,
      'fileName': _selectedFileName,
      'fileType': _selectedFileName?.split('.').last ?? 'link',
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (mounted) {
      _titleCtrl.clear();
      _descCtrl.clear();
      _linkCtrl.clear();
      _selectedFile = null;
      _selectedFileName = null;
      Navigator.pop(context);
      setModalState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Material uploaded successfully!'), backgroundColor: AppColors.success),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 28),
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Study Materials', style: GoogleFonts.outfit(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  Text('Upload documents for your students', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _query = v.toLowerCase()),
                      decoration: InputDecoration(
                        hintText: 'Search materials...',
                        border: InputBorder.none,
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        hintStyle: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('study_materials').orderBy('createdAt', descending: true).snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
              var docs = snap.data!.docs;
              if (_query.isNotEmpty) {
                docs = docs.where((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  return (d['title'] ?? '').toString().toLowerCase().contains(_query) ||
                         (d['category'] ?? '').toString().toLowerCase().contains(_query);
                }).toList();
              }
              if (docs.isEmpty) return SliverFillRemaining(child: Center(child: Text(_query.isEmpty ? 'No materials uploaded yet.' : 'No materials match your search.')));
              
              return SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final d = snap.data!.docs[i].data() as Map<String, dynamic>;
                      final id = snap.data!.docs[i].id;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                              child: const Icon(Icons.description_rounded, color: AppColors.primary),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(d['title'] ?? '', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
                                  Text(d['category'] ?? '', style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textMuted)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                              onPressed: () => FirebaseFirestore.instance.collection('study_materials').doc(id).delete(),
                            ),
                          ],
                        ),
                      );
                    },
                    childCount: docs.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
