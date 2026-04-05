import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../app_theme.dart';
import '../../services/cloudinary_service.dart';
import '../../widgets/image_viewer.dart';

class CertificatesTab extends StatefulWidget {
  const CertificatesTab({super.key});

  @override
  State<CertificatesTab> createState() => _CertificatesTabState();
}

class _CertificatesTabState extends State<CertificatesTab> {
  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';
  XFile? _image;
  bool _isUploading = false;

  Future<void> _pickImage(StateSetter modalState) async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery);
    if (img != null) {
      modalState(() => _image = img);
    }
  }

  void _showAddDialog() {
    final titleCtrl = TextEditingController();
    final issuerCtrl = TextEditingController();
    final dateCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (context, modalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Upload New Achievement', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700)),
                      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  GestureDetector(
                    onTap: () => _pickImage(modalState),
                    child: Container(
                      height: 160,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
                      ),
                      child: _image != null 
                        ? ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.file(File(_image!.path), fit: BoxFit.cover))
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_photo_alternate_rounded, color: AppColors.primary, size: 40),
                              const SizedBox(height: 12),
                              Text('Tap to select certificate image', style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textSecondary)),
                            ],
                          ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  _sheet_field(titleCtrl, 'Certificate Title', Icons.workspace_premium_rounded),
                  const SizedBox(height: 12),
                  _sheet_field(issuerCtrl, 'Issued By', Icons.business_rounded),
                  const SizedBox(height: 12),
                  _sheet_field(dateCtrl, 'Date of Achievement', Icons.calendar_today_rounded),
                  const SizedBox(height: 24),
                  
                  GestureDetector(
                    onTap: _isUploading ? null : () async {
                      if (titleCtrl.text.isEmpty || _image == null) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please provide title and image')));
                        return;
                      }
                      
                      modalState(() => _isUploading = true);
                      
                      try {
                        final imageUrl = await CloudinaryService().uploadFile(File(_image!.path), folder: 'certificates');
                        
                        if (imageUrl != null) {
                          await FirebaseFirestore.instance
                              .collection('certificates')
                              .doc(_uid)
                              .collection('items')
                              .add({
                            'title': titleCtrl.text.trim(),
                            'issuer': issuerCtrl.text.trim(),
                            'date': dateCtrl.text.trim(),
                            'imageUrl': imageUrl,
                            'verified': false,
                            'addedAt': FieldValue.serverTimestamp(),
                          });
                          if (context.mounted) Navigator.pop(context);
                        }
                      } catch (e) {
                         debugPrint('Upload error: $e');
                      } finally {
                        modalState(() => _isUploading = false);
                        _image = null; 
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      alignment: Alignment.center,
                      child: _isUploading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text('Save Achievement', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sheet_field(TextEditingController ctrl, String label, IconData icon) {
    return TextField(
      controller: ctrl,
      style: GoogleFonts.outfit(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.textMuted, size: 18),
        filled: true,
        fillColor: AppColors.cardLight,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)]),
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 64, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Certificate Vault 🏆', style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                Text('Manage and store your personal achievements', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: _showAddDialog,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text('Add New Certificate', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('certificates').doc(_uid).collection('items').orderBy('addedAt', descending: true).snapshots(),
          builder: (context, snap) {
            if (!snap.hasData || snap.data!.docs.isEmpty) {
              return SliverFillRemaining(child: _empty());
            }
            final docs = snap.data!.docs;
            return SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.85,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final d = docs[i].data() as Map<String, dynamic>;
                    return _CertCard(data: d, docId: docs[i].id, uid: _uid);
                  },
                  childCount: docs.length,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _empty() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.workspace_premium_rounded, size: 56, color: AppColors.textMuted.withValues(alpha: 0.2)),
        const SizedBox(height: 16),
        Text('No Certificates Uploaded', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        Text('Store your achievements in the vault', style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textSecondary)),
      ],
    ),
  );
}

class _CertCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId, uid;
  const _CertCard({required this.data, required this.docId, required this.uid});

  @override
  Widget build(BuildContext context) {
    final verified = data['verified'] ?? false;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                       if (data['imageUrl'] != null) {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => FullScreenImageViewer(imageUrl: data['imageUrl'], title: data['title'] ?? 'Certificate')
                        ));
                       }
                    },
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.cardLight,
                        borderRadius: BorderRadius.circular(14),
                        image: data['imageUrl'] != null ? DecorationImage(image: NetworkImage(data['imageUrl']), fit: BoxFit.cover) : null,
                      ),
                      child: data['imageUrl'] == null ? const Icon(Icons.image_not_supported_rounded, color: AppColors.textMuted) : null,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(data['title'] ?? 'Certificate', maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13)),
                Text(data['issuer'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          if (verified)
            Positioned(
              top: 8, right: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                child: const Icon(Icons.verified_rounded, color: Colors.white, size: 14),
              ),
            ),
          Positioned(
            top: 6, left: 6,
            child: GestureDetector(
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Certificate?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Yes')),
                    ],
                  )
                );
                if (confirm == true) {
                  await FirebaseFirestore.instance.collection('certificates').doc(uid).collection('items').doc(docId).delete();
                }
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), shape: BoxShape.circle),
                child: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
