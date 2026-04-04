import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../app_theme.dart';
import '../../services/storage_service.dart';

/// Admin tab: Create and manage announcements.
class SAAnnouncementsTab extends StatefulWidget {
  const SAAnnouncementsTab({super.key});

  @override
  State<SAAnnouncementsTab> createState() => _SAAnnouncementsTabState();
}

class _SAAnnouncementsTabState extends State<SAAnnouncementsTab> {
  void _showCreateDialog() {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    File? selectedImage;
    bool isUploading = false;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
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
                        Text('New Announcement', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700)),
                        IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    TextField(
                      controller: titleCtrl,
                      style: GoogleFonts.outfit(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Main Title',
                        prefixIcon: const Icon(Icons.campaign_rounded, color: AppColors.textMuted, size: 18),
                        filled: true,
                        fillColor: AppColors.cardLight,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    TextField(
                      controller: bodyCtrl,
                      maxLines: 3,
                      style: GoogleFonts.outfit(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Announcement Details',
                        alignLabelWithHint: true,
                        filled: true,
                        fillColor: AppColors.cardLight,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Image Picker
                    GestureDetector(
                      onTap: () async {
                        final picker = ImagePicker();
                        final picked = await picker.pickImage(source: ImageSource.gallery);
                        if (picked != null) {
                          setModalState(() => selectedImage = File(picked.path));
                        }
                      },
                      child: Container(
                        height: 100,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.cardLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: selectedImage != null
                            ? Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(selectedImage!, width: double.infinity, height: 100, fit: BoxFit.cover),
                                  ),
                                  Positioned(
                                    right: 4, top: 4,
                                    child: GestureDetector(
                                      onTap: () => setModalState(() => selectedImage = null),
                                      child: const CircleAvatar(radius: 12, backgroundColor: Colors.black54, child: Icon(Icons.close, size: 14, color: Colors.white)),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.add_photo_alternate_outlined, color: AppColors.textMuted),
                                  const SizedBox(height: 4),
                                  Text('Add Photo (Optional)', style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textMuted)),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    GestureDetector(
                      onTap: isUploading ? null : () async {
                        if (titleCtrl.text.isEmpty || bodyCtrl.text.isEmpty) return;
                        
                        setModalState(() => isUploading = true);
                        
                        String? imageUrl;
                        if (selectedImage != null) {
                          imageUrl = await StorageService().uploadFile(selectedImage!, 'announcements');
                        }

                        await FirebaseFirestore.instance.collection('announcements').add({
                          'title': titleCtrl.text.trim(),
                          'body': bodyCtrl.text.trim(),
                          'imageUrl': imageUrl,
                          'createdAt': FieldValue.serverTimestamp(),
                          'author': 'Admin',
                        });
                        
                        if (context.mounted) Navigator.pop(context);
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)]),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [BoxShadow(color: const Color(0xFF8B5CF6).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
                        ),
                        alignment: Alignment.center,
                        child: isUploading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text('Post Announcement', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        );
      },
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
                Text('Announcements',
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('Broadcast messages to students & parents',
                    style: GoogleFonts.outfit(
                        color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: _showCreateDialog,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add_alert_rounded,
                            color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text('New Announcement',
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

        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('announcements')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
            }
            if (snap.data!.docs.isEmpty) {
              return const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: Text('No announcements placed.', style: TextStyle(color: AppColors.textMuted))),
                ),
              );
            }
            
            return SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final doc = snap.data!.docs[i];
                    final d = doc.data() as Map<String, dynamic>;
                    
                    String formattedDate = '';
                    if (d['createdAt'] != null) {
                      final timestamp = d['createdAt'] as Timestamp;
                      formattedDate = DateFormat('dd MMM, hh:mm a').format(timestamp.toDate());
                    } else {
                      formattedDate = 'Just now';
                    }
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: AppColors.cardBorder),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF8B5CF6).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('BROADCAST', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF8B5CF6))),
                              ),
                              if (formattedDate.isNotEmpty)
                                Text(formattedDate, style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textMuted)),
                            ],
                          ),
                          const SizedBox(height: 12),
                           Text(d['title'] ?? 'Announcement', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 17, color: AppColors.textPrimary)),
                           const SizedBox(height: 6),
                           Text(d['body'] ?? '', style: GoogleFonts.outfit(fontSize: 14, height: 1.5, color: AppColors.textSecondary)),
                           if (d['imageUrl'] != null) ...[
                             const SizedBox(height: 12),
                             ClipRRect(
                               borderRadius: BorderRadius.circular(12),
                               child: Image.network(d['imageUrl'], width: double.infinity, fit: BoxFit.fitWidth),
                             ),
                           ],
                           const SizedBox(height: 16),
                           Row(
                             mainAxisAlignment: MainAxisAlignment.end,
                             children: [
                               GestureDetector(
                                 onTap: () => FirebaseFirestore.instance.collection('announcements').doc(doc.id).delete(),
                                 child: Container(
                                   padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                   decoration: BoxDecoration(
                                     color: AppColors.error.withOpacity(0.08),
                                     borderRadius: BorderRadius.circular(8),
                                   ),
                                   child: Row(
                                     children: [
                                       const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 16),
                                       const SizedBox(width: 4),
                                       Text('Delete', style: GoogleFonts.outfit(color: AppColors.error, fontSize: 11, fontWeight: FontWeight.w600)),
                                     ],
                                   ),
                                 ),
                               ),
                             ],
                           ),
                        ],
                      ),
                    );
                  },
                  childCount: snap.data!.docs.length,
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
