import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';

class VideoNotificationHandler extends BaseAudioHandler {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Function(bool) onPlayPause;
  final Function() onNext;
  final Function() onPrevious;
  final Function(Duration) onSeek;
  bool _initialized = false;

  VideoNotificationHandler({
    required this.onPlayPause,
    required this.onNext,
    required this.onPrevious,
    required this.onSeek,
  }) {
    // Initialize playback state immediately
    _initializePlaybackState();
    // Initialize with silent audio to keep notification alive
    _initSilentAudio();
  }

  void _initializePlaybackState() {
    playbackState.add(PlaybackState(
      playing: false,
      controls: [
        MediaControl.skipToPrevious,
        MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: AudioProcessingState.ready,
      updatePosition: Duration.zero,
      bufferedPosition: Duration.zero,
      speed: 1.0,
    ));
  }

  Future<void> _initSilentAudio() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());

      // Set to silent
      await _audioPlayer.setVolume(0.0);
      
      // Use a looping silent source
      // This is a base64 encoded silent 1-second WAV file
      await _audioPlayer.setAudioSource(
        AudioSource.uri(Uri.parse('data:audio/wav;base64,UklGRiQAAABXQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YQAAAAA=')),
        preload: true,
      );
      await _audioPlayer.setLoopMode(LoopMode.all);
      _initialized = true;
      print('Silent audio initialized successfully');
    } catch (e) {
      print('Error initializing silent audio: $e');
    }
  }

  @override
  Future<void> play() async {
    print('VideoNotificationHandler: play() called');
    // Start silent audio to trigger notification
    try {
      if (_initialized && !_audioPlayer.playing) {
        await _audioPlayer.play();
      }
    } catch (e) {
      print('Error starting silent audio: $e');
    }
    
    onPlayPause(true);
    playbackState.add(playbackState.value.copyWith(
      playing: true,
      controls: [
        MediaControl.skipToPrevious,
        MediaControl.pause,
        MediaControl.skipToNext,
      ],
      processingState: AudioProcessingState.ready,
    ));
  }

  @override
  Future<void> pause() async {
    print('VideoNotificationHandler: pause() called');
    onPlayPause(false);
    playbackState.add(playbackState.value.copyWith(
      playing: false,
      controls: [
        MediaControl.skipToPrevious,
        MediaControl.play,
        MediaControl.skipToNext,
      ],
      processingState: AudioProcessingState.ready,
    ));
  }

  @override
  Future<void> skipToNext() async {
    print('VideoNotificationHandler: skipToNext() called');
    onNext();
  }

  @override
  Future<void> skipToPrevious() async {
    print('VideoNotificationHandler: skipToPrevious() called');
    onPrevious();
  }

  @override
  Future<void> seek(Duration position) async {
    print('VideoNotificationHandler: seek($position) called');
    onSeek(position);
    playbackState.add(playbackState.value.copyWith(
      updatePosition: position,
    ));
  }

  Future<void> updateMediaItem(MediaItem mediaItem) async {
    print('VideoNotificationHandler: updating media item - ${mediaItem.title}');
    this.mediaItem.add(mediaItem);
  }

  void updatePlaybackState({
    required bool playing,
    required Duration position,
    required Duration duration,
  }) {
    playbackState.add(PlaybackState(
      playing: playing,
      controls: playing
          ? [
              MediaControl.skipToPrevious,
              MediaControl.pause,
              MediaControl.skipToNext,
            ]
          : [
              MediaControl.skipToPrevious,
              MediaControl.play,
              MediaControl.skipToNext,
            ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: AudioProcessingState.ready,
      updatePosition: position,
      bufferedPosition: duration,
      speed: 1.0,
    ));
  }

  @override
  Future<void> stop() async {
    print('VideoNotificationHandler: stop() called');
    await _audioPlayer.dispose();
    await super.stop();
  }
}
