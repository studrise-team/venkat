import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app_theme.dart';
import '../services/firebase_service.dart';

class NotesView extends StatelessWidget {
  final String exam;
  final String? subject;
  const NotesView({super.key, required this.exam, this.subject});

  @override
  Widget build(BuildContext context) {
    return _ContentListView(
      exam: exam,
      subject: subject,
      title: 'Notes',
      collection: 'notes',
      icon: Icons.note_rounded,
      accentColor: const Color(0xFF38ef7d),
      cardBuilder: (doc) => _NoteCard(doc: doc),
    );
  }
}

class PaperView extends StatelessWidget {
  final String exam;
  final String? subject;
  const PaperView({super.key, required this.exam, this.subject});

  @override
  Widget build(BuildContext context) {
    return _ContentListView(
      exam: exam,
      subject: subject,
      title: 'Previous Papers',
      collection: 'previous_papers',
      icon: Icons.description_rounded,
      accentColor: AppColors.accent,
      cardBuilder: (doc) => _PaperCard(doc: doc),
    );
  }
}

class CurrentAffairsView extends StatelessWidget {
  final String exam;
  final String? subject;
  const CurrentAffairsView({super.key, required this.exam, this.subject});

  @override
  Widget build(BuildContext context) {
    return _ContentListView(
      exam: exam,
      subject: subject,
      title: 'Current Affairs',
      collection: 'current_affairs',
      icon: Icons.newspaper_rounded,
      accentColor: const Color(0xFFFF6B6B),
      cardBuilder: (doc) => _CACard(doc: doc),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Generic list scaffold for aspirant
// ─────────────────────────────────────────────────────────────────────────────
class _ContentListView extends StatelessWidget {
  final String exam;
  final String? subject;
  final String title;
  final String collection;
  final IconData icon;
  final Color accentColor;
  final Widget Function(Map<String, dynamic>) cardBuilder;

  const _ContentListView({
    required this.exam,
    this.subject,
    required this.title,
    required this.collection,
    required this.icon,
    required this.accentColor,
    required this.cardBuilder,
  });

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
                        Text(title, style: GoogleFonts.outfit(
                            color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
                        Text(subject != null ? '$exam • $subject' : exam, style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder(
                  stream: FirebaseService().getDocumentsByExam(collection, exam, subject: subject),
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
                            Icon(icon, color: AppColors.textMuted, size: 60),
                            const SizedBox(height: 16),
                            Text('No $title available yet',
                                style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 16)),
                            const SizedBox(height: 8),
                            Text('Check back later',
                                style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 13)),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      itemCount: docs.length,
                      itemBuilder: (_, i) {
                        final data = {...docs[i].data(), 'id': docs[i].id};
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: cardBuilder(data),
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

// ─────────────────────────────────────────────────────────────────────────────
// Cards
// ─────────────────────────────────────────────────────────────────────────────
class _NoteCard extends StatelessWidget {
  final Map<String, dynamic> doc;
  const _NoteCard({required this.doc});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF38ef7d).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(doc['subject'] ?? '', style: GoogleFonts.outfit(
                  color: const Color(0xFF38ef7d), fontSize: 10, fontWeight: FontWeight.w600)),
            ),
          ]),
          const SizedBox(height: 8),
          Text(doc['topic'] ?? '', style: GoogleFonts.outfit(
              color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
          if ((doc['description'] ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(doc['description'], style: GoogleFonts.outfit(
                color: AppColors.textSecondary, fontSize: 12, height: 1.4),
                maxLines: 3, overflow: TextOverflow.ellipsis),
          ],
          if ((doc['driveLink'] ?? '').isNotEmpty) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _launchUrl(doc['driveLink']),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.open_in_new_rounded, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text('Open Notes', style: GoogleFonts.outfit(
                      color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PaperCard extends StatelessWidget {
  final Map<String, dynamic> doc;
  const _PaperCard({required this.doc});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                gradient: AppColors.accentGradient,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(doc['year']?.toString() ?? '', style: GoogleFonts.outfit(
                  color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(doc['subject'] ?? '', style: GoogleFonts.outfit(
                  color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w600)),
            ),
          ]),
          const SizedBox(height: 8),
          Text(doc['topic'] ?? '', style: GoogleFonts.outfit(
              color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
          if ((doc['description'] ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(doc['description'], style: GoogleFonts.outfit(
                color: AppColors.textSecondary, fontSize: 12, height: 1.4),
                maxLines: 3, overflow: TextOverflow.ellipsis),
          ],
          if ((doc['driveLink'] ?? '').isNotEmpty) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _launchUrl(doc['driveLink']),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: AppColors.accentGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.download_rounded, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text('Open Paper', style: GoogleFonts.outfit(
                      color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CACard extends StatelessWidget {
  final Map<String, dynamic> doc;
  const _CACard({required this.doc});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.calendar_month_rounded, color: AppColors.accentOrange, size: 14),
            const SizedBox(width: 4),
            Text(doc['date'] ?? '', style: GoogleFonts.outfit(
                color: AppColors.accentOrange, fontSize: 12, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 6),
          Text(doc['title'] ?? '', style: GoogleFonts.outfit(
              color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
          if ((doc['description'] ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(doc['description'], style: GoogleFonts.outfit(
                color: AppColors.textSecondary, fontSize: 12, height: 1.4),
                maxLines: 3, overflow: TextOverflow.ellipsis),
          ],
          if ((doc['link'] ?? '').isNotEmpty) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _launchUrl(doc['link']),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.accentOrange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.accentOrange.withValues(alpha: 0.4)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.open_in_new_rounded, color: AppColors.accentOrange, size: 16),
                  const SizedBox(width: 6),
                  Text('View PDF', style: GoogleFonts.outfit(
                      color: AppColors.accentOrange, fontSize: 13, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          ],
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
