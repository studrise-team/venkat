import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../app_theme.dart';
import '../../services/cloudinary_service.dart';

class SAAnnouncementsTab extends StatefulWidget {
  const SAAnnouncementsTab({super.key});

  @override
  State<SAAnnouncementsTab> createState() => _SAAnnouncementsTabState();
}

class _SAAnnouncementsTabState extends State<SAAnnouncementsTab> {
  final List<String> _categories = ['Urgent', 'Event', 'News', 'Holiday', 'Exam'];
  String _selectedCategory = 'News';

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
                decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Broadcast Announcement', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700)),
                          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Category Selector
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _categories.map((cat) {
                            final isSel = _selectedCategory == cat;
                            return GestureDetector(
                              onTap: () => setModalState(() => _selectedCategory = cat),
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSel ? AppColors.primary : AppColors.cardLight,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: isSel ? AppColors.primary : AppColors.cardBorder),
                                ),
                                child: Text(cat, style: GoogleFonts.outfit(fontSize: 12, fontWeight: isSel ? FontWeight.w700 : FontWeight.w400, color: isSel ? Colors.white : AppColors.textSecondary)),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextField(
                        controller: titleCtrl,
                        decoration: InputDecoration(labelText: 'Title', filled: true, fillColor: AppColors.cardLight, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                      ),
                      const SizedBox(height: 12),
                      
                      TextField(
                        controller: bodyCtrl,
                        maxLines: 3,
                        decoration: InputDecoration(labelText: 'Message Body', alignLabelWithHint: true, filled: true, fillColor: AppColors.cardLight, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                      ),
                      const SizedBox(height: 16),

                      GestureDetector(
                        onTap: () async {
                          final picker = ImagePicker();
                          final picked = await picker.pickImage(source: ImageSource.gallery);
                          if (picked != null) setModalState(() => selectedImage = File(picked.path));
                        },
                        child: Container(
                          height: 120, width: double.infinity,
                          decoration: BoxDecoration(color: AppColors.cardLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.cardBorder)),
                          child: selectedImage != null
                              ? Stack(children: [
                                  ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(selectedImage!, width: double.infinity, height: 120, fit: BoxFit.cover)),
                                  Positioned(right: 4, top: 4, child: CircleAvatar(radius: 12, backgroundColor: Colors.black54, child: IconButton(icon: const Icon(Icons.close, size: 12, color: Colors.white), onPressed: () => setModalState(() => selectedImage = null)))),
                                ])
                              : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_photo_alternate_rounded, color: AppColors.textMuted), Text('Attach Media (Optional)')]),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      GestureDetector(
                        onTap: isUploading ? null : () async {
                          if (titleCtrl.text.isEmpty || bodyCtrl.text.isEmpty) return;
                          setModalState(() => isUploading = true);
                          
                          String? imageUrl;
                          if (selectedImage != null) {
                            imageUrl = await CloudinaryService().uploadFile(selectedImage!, folder: 'announcements');
                          }

                          await FirebaseFirestore.instance.collection('announcements').add({
                            'title': titleCtrl.text.trim(),
                            'body': bodyCtrl.text.trim(),
                            'category': _selectedCategory,
                            'imageUrl': imageUrl,
                            'createdAt': FieldValue.serverTimestamp(),
                            'author': 'Authority',
                          });
                          
                          if (context.mounted) Navigator.pop(context);
                        },
                        child: Container(
                          width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFF97316), Color(0xFFEA580C)]), borderRadius: BorderRadius.circular(14)),
                          alignment: Alignment.center,
                          child: isUploading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text('Publish Broadcast', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
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
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFF97316), Color(0xFFEA580C)]), borderRadius: BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28))),
              padding: const EdgeInsets.fromLTRB(24, 52, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Broadcast Hub', style: GoogleFonts.outfit(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                  Text('Official center announcements & alerts', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: _showCreateDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.4))),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.campaign_rounded, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text('Compose Message', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('announcements').orderBy('createdAt', descending: true).snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
              if (snap.data!.docs.isEmpty) return SliverFillRemaining(child: Center(child: Text('All quiet here.', style: GoogleFonts.outfit(color: AppColors.textMuted))));
              
              return SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final doc = snap.data!.docs[i];
                      final d = doc.data() as Map<String, dynamic>;
                      final createdAt = d['createdAt'] as Timestamp?;
                      final timeStr = createdAt != null ? DateFormat('MMM d, h:mm a').format(createdAt.toDate()) : 'Recent';
                      
                      Color catColor = const Color(0xFF64748B);
                      if (d['category'] == 'Urgent') catColor = const Color(0xFFEF4444);
                      if (d['category'] == 'Holiday') catColor = const Color(0xFF10B981);
                      if (d['category'] == 'Exam') catColor = const Color(0xFFF59E0B);
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.cardBorder)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: catColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                  child: Text((d['category'] ?? 'NEWS').toUpperCase(), style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w800, color: catColor)),
                                ),
                                Text(timeStr, style: GoogleFonts.outfit(fontSize: 10, color: AppColors.textMuted)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(d['title'] ?? '', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textPrimary)),
                            const SizedBox(height: 6),
                            Text(d['body'] ?? '', style: GoogleFonts.outfit(fontSize: 14, height: 1.4, color: AppColors.textSecondary)),
                            if (d['imageUrl'] != null) ...[
                              const SizedBox(height: 14),
                              ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(d['imageUrl'], width: double.infinity, fit: BoxFit.cover)),
                            ],
                            const SizedBox(height: 16),
                            Align(
                              alignment: Alignment.centerRight,
                              child: IconButton(icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 18), onPressed: () => doc.reference.delete()),
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
        ],
      ),
    );
  }
}
