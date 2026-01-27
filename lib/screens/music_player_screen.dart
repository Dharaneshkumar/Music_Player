import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'dart:async';
import '../main.dart';
import '../services/notification_service.dart';

class MusicPlayerScreen extends StatefulWidget {
  const MusicPlayerScreen({super.key});

  @override
  State<MusicPlayerScreen> createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends State<MusicPlayerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late AudioPlayer _audioPlayer;
  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _playbackStateSubscription;


  // Sample playlist
  final List<Map<String, String>> _playlist = [
    {
      'title': 'Midnight Dreams',
      'artist': 'The Synthwave',
      'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
    },
    {
      'title': 'Electric Sunset',
      'artist': 'Neon Lights',
      'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
    },
    {
      'title': 'Cosmic Journey',
      'artist': 'Space Explorers',
      'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
    },
    {
      'title': 'Digital Rain',
      'artist': 'Cyber Dreams',
      'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3',
    },
  ];

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _initWithJustAudio();
    
    // Request notification permission after a short delay
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        NotificationService().requestPermission();
      }
    });

    // Send an automatic notification after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        NotificationService().showPlaybackNotification(
          title: 'Welcome Back! 🎵',
          message: 'Your playlist is ready. Tap to start listening!',
        );
      }
    });

    // Scheduled notifications
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        NotificationService().showPlaybackNotification(
          title: 'S! 🎵',
          message: 'Add new songs to your playlist!',
        );
      }
    });

    Future.delayed(const Duration(seconds: 50), () {
      if (mounted) {
        NotificationService().showPlaybackNotification(
          title: 'S! 🎵',
          message: 'Listen new songs of Jana nayagan!',
        );
      }
    });
  }

  Future<void> _initWithJustAudio() async {
    debugPrint('Initializing with just_audio');
    
    try {
      // Create playlist
      final playlist = ConcatenatingAudioSource(
        children: _playlist.map((song) {
          return AudioSource.uri(
            Uri.parse(song['url']!),
            tag: MediaItem(
              id: song['url']!,
              album: "Music Player",
              title: song['title']!,
              artist: song['artist']!,
            ),
          );
        }).toList(),
      );

      await _audioPlayer.setAudioSource(playlist);

      // Listen to player state
      _playerStateSubscription = _audioPlayer.playerStateStream.listen((state) {
        if (!mounted) return;
        final provider = Provider.of<MusicPlayerProvider>(context, listen: false);
        // MusicPlayerProvider updates
        final isPlaying = state.playing;
        provider.setPlaying(isPlaying);

        if (isPlaying) {
          _animationController.repeat();
        } else {
          _animationController.stop();
        }
      });

      // Listen to position
      _positionSubscription = _audioPlayer.positionStream.listen((position) {
        if (!mounted) return;
        final provider = Provider.of<MusicPlayerProvider>(context, listen: false);
        provider.setPosition(position);
      });

      // Listen to duration
      _durationSubscription = _audioPlayer.durationStream.listen((duration) {
        if (!mounted) return;
        if (duration != null) {
          final provider = Provider.of<MusicPlayerProvider>(context, listen: false);
          provider.setDuration(duration);
        }
      });

      // Listen to current index changes
      _playbackStateSubscription = _audioPlayer.currentIndexStream.listen((index) {
        if (!mounted || index == null) return;
        final provider = Provider.of<MusicPlayerProvider>(context, listen: false);
        provider.setCurrentSongIndex(index);
      });
    } catch (e) {
      debugPrint('Error initializing audio: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _playerStateSubscription?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _playbackStateSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _playPause() {
    final provider = Provider.of<MusicPlayerProvider>(context, listen: false);
    if (provider.isPlaying) {
      _audioPlayer.pause();
    } else {
      _audioPlayer.play();
    }
  }

  void _skipNext() async {
    if (_audioPlayer.hasNext) {
      await _audioPlayer.seekToNext();
    }
  }

  void _skipPrevious() async {
    if (_audioPlayer.hasPrevious) {
      await _audioPlayer.seekToPrevious();
    }
  }

  void _seek(Duration position) {
    _audioPlayer.seek(position);
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
                          onPressed: () {
                            // Immediate notification
                            NotificationService().showPlaybackNotification(
                              title: 'Music Player Demo',
                              message: 'Immediate notification sent! 🎵',
                            );

                            // Delayed notification (after 10 seconds)
                            Future.delayed(const Duration(seconds: 10), () {
                              NotificationService().showPlaybackNotification(
                                title: 'Reminder ⏰',
                                message: 'You have been listening for a while! Keep it up! 🎧',
                              );
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Immediate notification sent! Reminder scheduled for 10s.'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Album Art with Animation
                  RotationTransition(
                    turns: _animationController,
                    child: Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Container(
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
                          child: Icon(
                            Icons.music_note,
                            size: 120,
                            color: Colors.white.withValues(alpha: 0.8),
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
                            await _audioPlayer.seek(Duration.zero, index: index);
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
                                Icons.music_note,
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
