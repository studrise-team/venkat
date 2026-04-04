import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app_theme.dart';

class MaterialsTab extends StatefulWidget {
  const MaterialsTab({super.key});

  @override
  State<MaterialsTab> createState() => _MaterialsTabState();
}

class _MaterialsTabState extends State<MaterialsTab> {
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'Notes', 'Previous Papers', 'Assignments', 'Videos'];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Header ──────────────────────────────────────────────────
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(28),
              bottomRight: Radius.circular(28),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 52, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Study Materials',
                  style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('Access notes, papers, and more',
                  style: GoogleFonts.outfit(
                      color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 16),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final isSelected = _selectedCategory == _categories[i];
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategory = _categories[i]),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : Colors.white24,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        alignment: Alignment.center,
                        child: Text(_categories[i],
                            style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? AppColors.primary : Colors.white)),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // ── Content ──────────────────────────────────────────────────
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _selectedCategory == 'All'
                ? FirebaseFirestore.instance.collection('study_materials').orderBy('createdAt', descending: true).snapshots()
                : FirebaseFirestore.instance.collection('study_materials').where('category', isEqualTo: _selectedCategory).orderBy('createdAt', descending: true).snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snap.hasData || snap.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.description_outlined, size: 48, color: AppColors.textMuted),
                      const SizedBox(height: 12),
                      Text('No material found for $_selectedCategory',
                          style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 14)),
                    ],
                  ),
                );
              }
              final docs = snap.data!.docs;
              return ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final d = docs[i].data() as Map<String, dynamic>;
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            d['category'] == 'Videos' 
                                ? Icons.play_circle_outline_rounded 
                                : Icons.description_rounded,
                            color: AppColors.primary, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(d['title'] ?? '',
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
                              if (d['description'] != null && d['description'].toString().isNotEmpty)
                                Text(d['description'],
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary)),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.bg,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(d['category'] ?? '', 
                                  style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.open_in_new_rounded, color: AppColors.primary, size: 20),
                          onPressed: () async {
                            final url = Uri.parse(d['link'] ?? '');
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url);
                            }
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
