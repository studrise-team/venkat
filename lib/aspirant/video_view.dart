import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app_theme.dart';
import '../services/firebase_service.dart';

class VideoView extends StatelessWidget {
  final String exam;
  const VideoView({super.key, required this.exam});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 24, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Video Classes', style: GoogleFonts.outfit(
                            color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
                        Text(exam, style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder(
                  stream: FirebaseService().getDocumentsByExam('video_classes', exam),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                    }
                    final docs = snapshot.data ?? [];
                    if (docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.play_circle_rounded, color: AppColors.textMuted, size: 60),
                            const SizedBox(height: 16),
                            Text('No Videos available yet',
                                style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 16)),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      itemCount: docs.length,
                      itemBuilder: (_, i) {
                        final data = docs[i].data();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _VideoCard(doc: data),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VideoCard extends StatelessWidget {
  final Map<String, dynamic> doc;
  const _VideoCard({required this.doc});

  @override
  Widget build(BuildContext context) {
    final isYouTube = doc['type'] == 'YouTube';
    final color = isYouTube ? Colors.red : AppColors.primary;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          // Thumbnail area
          GestureDetector(
            onTap: () => _launchUrl(doc['link'] ?? ''),
            child: Container(
              height: 160,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
                  ),
                  child: Icon(Icons.play_arrow_rounded, color: color, size: 36),
                ),
              ),
            ),
          ),
          // Info
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(doc['type'] ?? 'YouTube', style: GoogleFonts.outfit(
                        color: color, fontSize: 9, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 6),
                  if ((doc['subject'] ?? '').isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(doc['subject'], style: GoogleFonts.outfit(
                          color: AppColors.textSecondary, fontSize: 9, fontWeight: FontWeight.w600)),
                    ),
                ]),
                const SizedBox(height: 6),
                Text(doc['topic'] ?? '', style: GoogleFonts.outfit(
                    color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
                if ((doc['description'] ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(doc['description'], style: GoogleFonts.outfit(
                      color: AppColors.textSecondary, fontSize: 12),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => _launchUrl(doc['link'] ?? ''),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: color.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(isYouTube ? Icons.smart_display_rounded : Icons.open_in_new_rounded,
                            color: color, size: 18),
                        const SizedBox(width: 8),
                        Text(isYouTube ? 'Watch on YouTube' : 'Open in Drive',
                            style: GoogleFonts.outfit(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _launchUrl(String url) async {
  final uri = Uri.tryParse(url);
  if (uri != null && await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
