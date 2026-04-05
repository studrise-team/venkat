import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../app_theme.dart';
import 'package:flutter/services.dart';
import '../services/firebase_service.dart';

class VideoClassPlayerPage extends StatefulWidget {
  final Map<String, dynamic> activeVideo;
  final String collection;
  final String exam;

  const VideoClassPlayerPage({
    super.key,
    required this.activeVideo,
    required this.collection,
    required this.exam,
  });

  @override
  State<VideoClassPlayerPage> createState() => _VideoClassPlayerPageState();
}

class _VideoClassPlayerPageState extends State<VideoClassPlayerPage> {
  late YoutubePlayerController _controller;
  late Map<String, dynamic> _currentVideo;
  List<Map<String, dynamic>> _playlist = [];

  @override
  void initState() {
    super.initState();
    _currentVideo = widget.activeVideo;
    _initPlayer(_getVideoId(_currentVideo));
  }

  String _getVideoId(Map<String, dynamic> doc) {
    final url = doc['link'] ?? doc['youtubeLink'] ?? '';
    return YoutubePlayer.convertUrlToId(url) ?? '';
  }

  void _initPlayer(String videoId) {
    _controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: false,
        hideControls: false,
        controlsVisibleAtStart: true,
        hideThumbnail: true,
      ),
    );
    _controller.addListener(_onPlayerStateChange);
  }

  void _onPlayerStateChange() {
    if (_controller.value.playerState == PlayerState.ended) {
      _playNext();
    }
  }

  void _playNext() {
    if (_playlist.isEmpty) return;
    final currentUrl = _currentVideo['link'] ?? _currentVideo['youtubeLink'] ?? '';
    final currentIndex = _playlist.indexWhere((doc) =>
        (doc['link'] ?? doc['youtubeLink'] ?? '') == currentUrl);

    if (currentIndex != -1 && currentIndex + 1 < _playlist.length) {
      _changeVideo(_playlist[currentIndex + 1]);
    }
  }

  void _changeVideo(Map<String, dynamic> nextVideo) {
    setState(() {
      _currentVideo = nextVideo;
    });
    final newId = _getVideoId(nextVideo);
    if (newId.isNotEmpty) {
      _controller.load(newId);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final titleInfo = _currentVideo['title'] ?? _currentVideo['topic'] ?? _currentVideo['subject'] ?? 'Recorded Class';
    final descInfo = _currentVideo['description'] ?? '${widget.exam} Recorded Class';

    return YoutubePlayerBuilder(
      onEnterFullScreen: () {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      },
      onExitFullScreen: () {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
        ]);
      },
      player: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
        progressIndicatorColor: const Color(0xFF7C4DFF),
        progressColors: const ProgressBarColors(
          playedColor: Color(0xFF7C4DFF),
          handleColor: Color(0xFF7C4DFF),
        ),
        topActions: const [],
        bottomActions: [
          const SizedBox(width: 14),
          CurrentPosition(),
          const SizedBox(width: 8),
          ProgressBar(
            isExpanded: true,
            colors: const ProgressBarColors(
              playedColor: Color(0xFF7C4DFF),
              handleColor: Color(0xFF7C4DFF),
            ),
          ),
          RemainingDuration(),
          const PlaybackSpeedButton(),
          FullScreenButton(),
        ],
      ),
      builder: (context, player) {
        return Scaffold(
          backgroundColor: AppColors.bg,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Recorded Classes',
              style: GoogleFonts.outfit(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            centerTitle: true,
          ),
          body: Column(
            children: [
              // 1. Fixed Video Player at Top
              AspectRatio(
                aspectRatio: 16 / 9,
                child: player,
              ),

              // 2. Dark Navy Info Strip
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                color: const Color(0xFF1F213A),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titleInfo,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      descInfo,
                      style: GoogleFonts.outfit(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // 3. Playlist
              Expanded(
                child: StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
                  stream: FirebaseService().getDocumentsByExam(widget.collection, widget.exam),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    // Filter out any non-YouTube links
                    final validDocs = snapshot.data!.where((doc) {
                      final url = doc.data()['link'] ?? doc.data()['youtubeLink'] ?? '';
                      return YoutubePlayer.convertUrlToId(url) != null;
                    }).toList();

                    _playlist = validDocs.map((e) => e.data()).toList();

                    return ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _playlist.length,
                      itemBuilder: (context, index) {
                        final doc = _playlist[index];
                        final url = doc['link'] ?? doc['youtubeLink'] ?? '';
                        final videoId = YoutubePlayer.convertUrlToId(url) ?? '';
                        final thumbnailUrl = 'https://img.youtube.com/vi/$videoId/mqdefault.jpg';
                        
                        final currentUrl = _currentVideo['link'] ?? _currentVideo['youtubeLink'] ?? '';
                        final isSelected = url == currentUrl;

                        final itemTitle = doc['title'] ?? doc['topic'] ?? doc['subject'] ?? 'Recorded Class';
                        final itemDate = doc['date'] ?? doc['time'] ?? 'Available Now';

                        return GestureDetector(
                          onTap: () {
                            if (!isSelected) {
                              _changeVideo(doc);
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFEDEEFC) : AppColors.card,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF7C4DFF).withOpacity(0.5) : AppColors.cardBorder,
                                width: isSelected ? 1.5 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                // Thumbnail
                                ClipRRect(
                                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(15)),
                                  child: SizedBox(
                                    width: 120,
                                    height: 70,
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        Image.network(thumbnailUrl, fit: BoxFit.cover),
                                        if (isSelected)
                                          Container(
                                            color: Colors.black45,
                                            child: const Center(
                                              child: Icon(Icons.play_circle_fill_rounded, color: Color(0xFF7C4DFF), size: 36),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Text Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        itemTitle,
                                        style: GoogleFonts.outfit(
                                          color: isSelected ? const Color(0xFF7C4DFF) : AppColors.textPrimary,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        itemDate,
                                        style: GoogleFonts.outfit(
                                          color: AppColors.textSecondary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
