import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../app_theme.dart';

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

  // Simulated add certificate dialog (admin would normally assign them)
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
                  Text('Upload Certificate',
                      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),
                  
                  // Image Picker
                  GestureDetector(
                    onTap: () => _pickImage(modalState),
                    child: Container(
                      height: 140,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.cardLight,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.cardBorder, style: BorderStyle.solid),
                      ),
                      child: _image != null 
                        ? ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.file(File(_image!.path), fit: BoxFit.cover))
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_a_photo_rounded, color: AppColors.primary, size: 32),
                              const SizedBox(height: 8),
                              Text('Tap to pick certificate image', style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textSecondary)),
                            ],
                          ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _sheet_field(titleCtrl, 'Certificate Title', Icons.workspace_premium_rounded),
                  const SizedBox(height: 12),
                  _sheet_field(issuerCtrl, 'Issued By', Icons.business_rounded),
                  const SizedBox(height: 12),
                  _sheet_field(dateCtrl, 'Date', Icons.calendar_today_rounded),
                  const SizedBox(height: 24),
                  
                  _isUploading 
                    ? const Center(child: CircularProgressIndicator())
                    : GestureDetector(
                        onTap: () async {
                          if (titleCtrl.text.isEmpty) return;
                          
                          modalState(() => _isUploading = true);
                          String imageUrl = '';
                          
                          try {
                            if (_image != null) {
                              final ref = FirebaseStorage.instance
                                  .ref()
                                  .child('certificates')
                                  .child(_uid)
                                  .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
                              await ref.putFile(File(_image!.path));
                              imageUrl = await ref.getDownloadURL();
                            }

                            await FirebaseFirestore.instance
                                .collection('certificates')
                                .doc(_uid)
                                .collection('items')
                                .add({
                              'title': titleCtrl.text.trim(),
                              'issuer': issuerCtrl.text.trim(),
                              'date': dateCtrl.text.trim(),
                              'imageUrl': imageUrl,
                              'addedAt': FieldValue.serverTimestamp(),
                            });
                            
                            if (context.mounted) Navigator.pop(context);
                          } catch (e) {
                            debugPrint('Upload error: $e');
                          } finally {
                            modalState(() => _isUploading = false);
                            _image = null; 
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text('Save & Upload',
                              style: GoogleFonts.outfit(
                                  color: Colors.white, fontWeight: FontWeight.w700)),
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

  Widget _sheet_field(
      TextEditingController ctrl, String label, IconData icon) {
    return TextField(
      controller: ctrl,
      style: GoogleFonts.outfit(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.textMuted, size: 18),
        filled: true,
        fillColor: AppColors.cardLight,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Header
        SliverToBoxAdapter(
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(24, 52, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Certificate Vault 🏆',
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('Store all your achievements here',
                    style:
                        GoogleFonts.outfit(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: _showAddDialog,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add_rounded,
                            color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text('Add Certificate',
                            style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 20)),

        // Certificates Grid
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('certificates')
              .doc(_uid)
              .collection('items')
              .orderBy('addedAt', descending: true)
              .snapshots(),
          builder: (context, snap) {
            if (!snap.hasData || snap.data!.docs.isEmpty) {
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.workspace_premium_rounded,
                            size: 40, color: Color(0xFF8B5CF6)),
                      ),
                      const SizedBox(height: 16),
                      Text('No certificates yet',
                          style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 4),
                      Text('Tap "Add Certificate" to store your achievements',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                              fontSize: 13, color: AppColors.textMuted)),
                    ],
                  ),
                ),
              );
            }
            final docs = snap.data!.docs;
            return SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.9,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final d = docs[i].data() as Map<String, dynamic>;
                    final docId = docs[i].id;
                    return _CertCard(
                      data: d,
                      onDelete: () async {
                        await FirebaseFirestore.instance
                            .collection('certificates')
                            .doc(_uid)
                            .collection('items')
                            .doc(docId)
                            .delete();
                      },
                    );
                  },
                  childCount: docs.length,
                ),
              ),
            );
          },
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 30)),
      ],
    );
  }
}

class _CertCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onDelete;

  const _CertCard({required this.data, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final colors = [
      [const Color(0xFF8B5CF6), const Color(0xFF6D28D9)],
      [const Color(0xFF06B6D4), const Color(0xFF0284C7)],
      [const Color(0xFF10B981), const Color(0xFF047857)],
      [const Color(0xFFF97316), const Color(0xFFEA580C)],
    ];
    final colorIdx =
        (data['title'] as String? ?? '').length % colors.length;
    final c1 = colors[colorIdx][0];
    final c2 = colors[colorIdx][1];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [c1.withValues(alpha: 0.08), c2.withValues(alpha: 0.04)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c1.withValues(alpha: 0.2)),
      ),
      padding: const EdgeInsets.all(16),
      child: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [c1, c2]),
                  borderRadius: BorderRadius.circular(12),
                  image: data['imageUrl'] != null && data['imageUrl'].isNotEmpty
                    ? DecorationImage(image: NetworkImage(data['imageUrl']), fit: BoxFit.cover, opacity: 0.3)
                    : null,
                ),
                child: Icon(
                  data['imageUrl'] != null && data['imageUrl'].isNotEmpty ? Icons.image_rounded : Icons.workspace_premium_rounded,
                  color: Colors.white, 
                  size: 22
                ),
              ),
              const SizedBox(height: 12),
              Text(data['title'] ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              if ((data['issuer'] ?? '').isNotEmpty)
                Text(data['issuer'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                        fontSize: 11, color: AppColors.textSecondary)),
              if ((data['date'] ?? '').isNotEmpty)
                Text(data['date'] ?? '',
                    style: GoogleFonts.outfit(
                        fontSize: 11, color: AppColors.textMuted)),
            ],
          ),
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              onTap: onDelete,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.delete_outline_rounded,
                    size: 16, color: AppColors.error),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
