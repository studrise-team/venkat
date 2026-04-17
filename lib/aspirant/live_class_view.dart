import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../app_theme.dart';
import '../services/firebase_service.dart';
import '../screens/video_class_player_page.dart';

class LiveClassView extends StatelessWidget {
  final String exam;
  final String? subject;
  const LiveClassView({super.key, required this.exam, this.subject});

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
                        Text('Live Classes', style: GoogleFonts.outfit(
                            color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
                        Text(subject != null ? '$exam • $subject' : exam, 
                            style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder(
                  stream: FirebaseService().getDocumentsByExam('live_classes', exam, subject: subject),
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
                            const Icon(Icons.live_tv, color: AppColors.textMuted, size: 60),
                            const SizedBox(height: 16),
                            Text('No Live Classes scheduled',
                                style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 16)),
                            const SizedBox(height: 8),
                            Text('Check back soon!',
                                style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 13)),
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
                          child: _LiveCard(doc: data, exam: exam),
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

class _LiveCard extends StatelessWidget {
  final Map<String, dynamic> doc;
  final String exam;
  const _LiveCard({required this.doc, required this.exam});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFe040fb).withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Live banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFe040fb), Color(0xFF7c4dff)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(children: [
              const Icon(Icons.circle, color: Colors.white, size: 8),
              const SizedBox(width: 6),
              Text('LIVE CLASS', style: GoogleFonts.outfit(
                  color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
              const Spacer(),
              Text('${doc['date'] ?? ''} • ${doc['time'] ?? ''}',
                  style: GoogleFonts.outfit(color: Colors.white70, fontSize: 11)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(doc['title'] ?? '', style: GoogleFonts.outfit(
                    color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
                if ((doc['description'] ?? '').isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(doc['description'], style: GoogleFonts.outfit(
                      color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                      maxLines: 3, overflow: TextOverflow.ellipsis),
                ],
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: () => _handleTap(context, doc, doc['youtubeLink'] ?? ''),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFFe040fb), Color(0xFF7c4dff)],
                          begin: Alignment.centerLeft, end: Alignment.centerRight),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.smart_display_rounded, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text('Join Live Class', style: GoogleFonts.outfit(
                            color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
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
  void _handleTap(BuildContext context, Map<String, dynamic> doc, String url) {
    if (url.isEmpty) return;
    final videoId = YoutubePlayer.convertUrlToId(url);
    if (videoId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VideoClassPlayerPage(
            activeVideo: doc,
            collection: 'live_classes',
            exam: exam,
          ),
        ),
      );
      return;
    }
    _launchUrl(url);
  }
}

Future<void> _launchUrl(String url) async {
  final uri = Uri.tryParse(url);
  if (uri != null && await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
