import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart' as yt;
import 'package:audio_service/audio_service.dart';
import 'package:permission_handler/permission_handler.dart';
import '../main.dart';
import '../services/video_notification_handler.dart';

class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({super.key});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  VideoPlayerController? _videoController;
  yt.YoutubePlayerController? _youtubeController;
  Timer? _progressTimer;
  VideoNotificationHandler? _notificationHandler;

  // Sample playlist with YouTube and direct video URLs
  final List<Map<String, String>> _playlist = [
    {
      'title': 'Faded',
      'artist': 'Alan Walker',
      'youtubeId': '60ItHLz5WEA',
      'videoUrl': '',
    },
    {
      'title': 'Stay',
      'artist': 'The Kid LAROI & Justin Bieber',
      'youtubeId': 'kTJczUoc26U',
      'videoUrl': '',
    },
    {
      'title': 'Blinding Lights',
      'artist': 'The Weeknd',
      'youtubeId': '4NRXx6U8ABQ',
      'videoUrl': '',
    },
    {
      'title': 'Big Buck Bunny',
      'artist': 'Blender Foundation',
      'videoUrl': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
      'youtubeId': '',
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _requestPermissions();
    await _initNotificationService();
    await _initVideoPlayer(0); // Initialize with first video
    _startProgressTimer();
  }

  Future<void> _requestPermissions() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  }

  Future<void> _initNotificationService() async {
    try {
      print('Initializing AudioService...');
      final handler = await AudioService.init(
        builder: () => VideoNotificationHandler(
          onPlayPause: (playing) {
            print('onPlayPause callback: playing=$playing');
            if (!mounted) return;
            if (playing) {
              if (_youtubeController != null) {
                _youtubeController!.play();
              } else if (_videoController != null) {
                _videoController!.play();
              }
            } else {
              if (_youtubeController != null) {
                _youtubeController!.pause();
              } else if (_videoController != null) {
                _videoController!.pause();
              }
            }
          },
          onNext: () {
            print('onNext callback');
            if (mounted) _skipNext();
          },
          onPrevious: () {
            print('onPrevious callback');
            if (mounted) _skipPrevious();
          },
          onSeek: (position) {
            print('onSeek callback: position=$position');
            if (mounted) _seek(position);
          },
        ),
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'com.example.music_player.channel.audio',
          androidNotificationChannelName: 'Video Playback',
          androidNotificationOngoing: true,
          androidStopForegroundOnPause: true,
        ),
      );
      
      _notificationHandler = handler as VideoNotificationHandler;
      print('AudioService initialized successfully');
      
      // Wait a bit for the service to fully initialize
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Initialize notification with first track
      if (_notificationHandler != null) {
        final firstSong = _playlist[0];
        final isYoutube = (firstSong['youtubeId'] ?? '').isNotEmpty;
        
        await _notificationHandler!.updateMediaItem(MediaItem(
          id: '0',
          title: firstSong['title']!,
          artist: firstSong['artist']!,
          album: isYoutube ? 'YouTube' : 'Video',
          artUri: isYoutube 
              ? Uri.parse('https://img.youtube.com/vi/${firstSong['youtubeId']}/hqdefault.jpg')
              : null,
          duration: Duration.zero,
        ));
        
        _notificationHandler!.updatePlaybackState(
          playing: false,
          position: Duration.zero,
          duration: Duration.zero,
        );
        print('Initial media item set');
      }
    } catch (e) {
      print('Error initializing AudioService: $e');
    }
  }

  void _startProgressTimer() {
    _progressTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!mounted) return;
      final provider = Provider.of<MusicPlayerProvider>(context, listen: false);
      
      if (_youtubeController != null) {
        provider.setPosition(_youtubeController!.value.position);
        provider.setDuration(_youtubeController!.value.metaData.duration);
        provider.setPlaying(_youtubeController!.value.isPlaying);
        
        // Update notification
        _updateNotification(
          playing: _youtubeController!.value.isPlaying,
          position: _youtubeController!.value.position,
          duration: _youtubeController!.value.metaData.duration,
        );
        
        if (_youtubeController!.value.isPlaying) {
          _animationController.repeat();
        } else {
          _animationController.stop();
        }
        
        // Auto-skip when video ends
        if (_youtubeController!.value.playerState == yt.PlayerState.ended) {
          _skipNext();
        }
      } else if (_videoController != null && _videoController!.value.isInitialized) {
        provider.setPosition(_videoController!.value.position);
        provider.setDuration(_videoController!.value.duration);
        provider.setPlaying(_videoController!.value.isPlaying);
        
        // Update notification
        _updateNotification(
          playing: _videoController!.value.isPlaying,
          position: _videoController!.value.position,
          duration: _videoController!.value.duration,
        );
        
        if (_videoController!.value.isPlaying) {
          _animationController.repeat();
        } else {
          _animationController.stop();
        }
        
        // Auto-skip when video ends
        if (_videoController!.value.position >= _videoController!.value.duration) {
          _skipNext();
        }
      }
    });
  }

  void _updateNotification({required bool playing, required Duration position, required Duration duration}) {
    final provider = Provider.of<MusicPlayerProvider>(context, listen: false);
    final currentSong = _playlist[provider.currentSongIndex];
    final isYoutube = (currentSong['youtubeId'] ?? '').isNotEmpty;
    
    _notificationHandler?.updateMediaItem(MediaItem(
      id: provider.currentSongIndex.toString(),
      title: currentSong['title']!,
      artist: currentSong['artist']!,
      album: isYoutube ? 'YouTube' : 'Video',
      artUri: isYoutube 
          ? Uri.parse('https://img.youtube.com/vi/${currentSong['youtubeId']}/hqdefault.jpg')
          : null,
      duration: duration,
    ));
    
    _notificationHandler?.updatePlaybackState(
      playing: playing,
      position: position,
      duration: duration,
    );
  }

  Future<void> _initVideoPlayer(int index) async {
    // Dispose previous controllers
    await _videoController?.dispose();
    _youtubeController?.dispose();
    _videoController = null;
    _youtubeController = null;
    
    final youtubeId = _playlist[index]['youtubeId'];
    final videoUrl = _playlist[index]['videoUrl'];

    if (youtubeId != null && youtubeId.isNotEmpty) {
      _youtubeController = yt.YoutubePlayerController(
        initialVideoId: youtubeId,
        flags: const yt.YoutubePlayerFlags(
          autoPlay: false,
          mute: false,
          disableDragSeek: false,
          loop: false,
          isLive: false,
          forceHD: false,
          enableCaption: true,
        ),
      );
      if (mounted) setState(() {});
    } else if (videoUrl != null && videoUrl.isNotEmpty) {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      try {
        await _videoController!.initialize();
        _videoController!.setLooping(false);
        if (mounted) setState(() {});
      } catch (e) {
        debugPrint('Error initializing video: $e');
      }
    }
    
    // Update notification with new track info
    if (mounted) {
      final currentSong = _playlist[index];
      final isYoutube = (currentSong['youtubeId'] ?? '').isNotEmpty;
      
      _notificationHandler?.updateMediaItem(MediaItem(
        id: index.toString(),
        title: currentSong['title']!,
        artist: currentSong['artist']!,
        album: isYoutube ? 'YouTube' : 'Video',
        artUri: isYoutube 
            ? Uri.parse('https://img.youtube.com/vi/${currentSong['youtubeId']}/hqdefault.jpg')
            : null,
      ));
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _progressTimer?.cancel();
    _videoController?.dispose();
    _youtubeController?.dispose();
    super.dispose();
  }

  void _playPause() {
    print('_playPause called');
    if (_youtubeController != null) {
      if (_youtubeController!.value.isPlaying) {
        _youtubeController!.pause();
        _notificationHandler?.pause();
      } else {
        _youtubeController!.play();
        _notificationHandler?.play();
      }
    } else if (_videoController != null && _videoController!.value.isInitialized) {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
        _notificationHandler?.pause();
      } else {
        _videoController!.play();
        _notificationHandler?.play();
      }
    }
  }

  void _skipNext() async {
    final provider = Provider.of<MusicPlayerProvider>(context, listen: false);
    final nextIndex = (provider.currentSongIndex + 1) % _playlist.length;
    provider.setCurrentSongIndex(nextIndex);
    await _initVideoPlayer(nextIndex);
    
    // Auto-play next video
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_youtubeController != null) {
        _youtubeController!.play();
      } else if (_videoController != null) {
        _videoController!.play();
      }
      _notificationHandler?.play();
    });
  }

  void _skipPrevious() async {
    final provider = Provider.of<MusicPlayerProvider>(context, listen: false);
    final prevIndex = provider.currentSongIndex > 0 
        ? provider.currentSongIndex - 1 
        : _playlist.length - 1;
    provider.setCurrentSongIndex(prevIndex);
    await _initVideoPlayer(prevIndex);
    
    // Auto-play previous video
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_youtubeController != null) {
        _youtubeController!.play();
      } else if (_videoController != null) {
        _videoController!.play();
      }
      _notificationHandler?.play();
    });
  }

  void _seek(Duration position) {
    _youtubeController?.seekTo(position);
    _videoController?.seekTo(position);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0A0E21),
              const Color(0xFF1D1E33),
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
            ],
          ),
        ),
        child: SafeArea(
          child: Consumer<MusicPlayerProvider>(
            builder: (context, provider, child) {
              final currentSong = _playlist[provider.currentSongIndex];
              
              return Column(
                children: [
                  // App Bar
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.menu, color: Colors.white),
                          onPressed: () {},
                        ),
                        Text(
                          'Now Playing',
                          style: Theme.of(context).textTheme.displayMedium,
                        ),
                        IconButton(
                          icon: const Icon(Icons.more_vert, color: Colors.white),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Video Player
                  Container(
                    width: MediaQuery.of(context).size.width * 0.9,
                    height: 280,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: _youtubeController != null
                          ? yt.YoutubePlayer(
                              controller: _youtubeController!,
                              showVideoProgressIndicator: true,
                              progressIndicatorColor: Theme.of(context).colorScheme.primary,
                              onReady: () {
                                debugPrint('Youtube Player is ready.');
                              },
                            )
                          : _videoController != null && _videoController!.value.isInitialized
                              ? AspectRatio(
                                  aspectRatio: _videoController!.value.aspectRatio,
                                  child: VideoPlayer(_videoController!),
                                )
                              : Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Theme.of(context).colorScheme.primary,
                                        Theme.of(context).colorScheme.secondary,
                                      ],
                                    ),
                                  ),
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Song Info
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: Column(
                      children: [
                        Text(
                          currentSong['title']!,
                          style: Theme.of(context).textTheme.displayLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          currentSong['artist']!,
                          style: Theme.of(context).textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Progress Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: Column(
                      children: [
                        SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 8,
                            ),
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 16,
                            ),
                            activeTrackColor: Theme.of(context).colorScheme.primary,
                            inactiveTrackColor: Colors.white24,
                            thumbColor: Colors.white,
                            overlayColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                          ),
                          child: Slider(
                            value: provider.position.inSeconds.toDouble().clamp(
                              0.0,
                              provider.duration.inSeconds.toDouble().clamp(0.1, double.infinity),
                            ),
                            max: provider.duration.inSeconds.toDouble().clamp(0.1, double.infinity),
                            onChanged: (value) {
                              _seek(Duration(seconds: value.toInt()));
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(provider.position),
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              Text(
                                _formatDuration(provider.duration),
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Control Buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Previous Button
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.skip_previous, size: 36),
                            color: Colors.white,
                            onPressed: _skipPrevious,
                          ),
                        ),

                        // Play/Pause Button
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Theme.of(context).colorScheme.primary,
                                Theme.of(context).colorScheme.secondary,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: Icon(
                              provider.isPlaying ? Icons.pause : Icons.play_arrow,
                              size: 40,
                            ),
                            color: Colors.white,
                            onPressed: _playPause,
                          ),
                        ),

                        // Next Button
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.skip_next, size: 36),
                            color: Colors.white,
                            onPressed: _skipNext,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Playlist Preview
                  Container(
                    height: 120,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _playlist.length,
                      itemBuilder: (context, index) {
                        final isSelected = index == provider.currentSongIndex;
                        return GestureDetector(
                          onTap: () async {
                            provider.setCurrentSongIndex(index);
                            await _initVideoPlayer(index);
                            // Auto-play selected video
                            Future.delayed(const Duration(milliseconds: 500), () {
                              if (_youtubeController != null) {
                                _youtubeController!.play();
                              } else if (_videoController != null) {
                                _videoController!.play();
                              }
                              _notificationHandler?.play();
                            });
                          },
                          child: Container(
                            width: 80,
                            margin: const EdgeInsets.only(right: 16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.transparent,
                                width: 2,
                              ),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: isSelected
                                    ? [
                                        Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                                        Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3),
                                      ]
                                    : [
                                        Colors.white.withValues(alpha: 0.1),
                                        Colors.white.withValues(alpha: 0.05),
                                      ],
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.play_circle_outline,
                                color: isSelected ? Colors.white : Colors.white54,
                                size: 32,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
