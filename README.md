# Music Player App

A beautiful single-page music player Flutter application with background playback support, push notifications, and media controls.

## Features

### 🎵 Core Features
- **Single Page Music Player UI** - Beautiful, modern interface with gradient backgrounds
- **Background Audio Playback** - Music continues playing when app is in background
- **Media Notification Controls** - Control playback from notification bar
- **Push Notifications** - Get notified when tracks change
- **Playlist Support** - Browse and select from multiple tracks
- **Animated Album Art** - Rotating album art animation during playback

### 🎨 UI Features
- **Dark Theme** - Sleek dark mode design with vibrant gradients
- **Animated Controls** - Smooth animations for play/pause and track changes
- **Progress Slider** - Seek through tracks with visual feedback
- **Playlist Preview** - Horizontal scrollable playlist at the bottom
- **Responsive Design** - Adapts to different screen sizes

### 🔔 Notification Features
- **Now Playing Notification** - Shows current track in notification bar
- **Media Controls** - Play, pause, skip next/previous from notification
- **Track Change Alerts** - Push notification when track changes
- **Background Persistence** - Notification stays active during playback

## Technical Stack

- **Flutter SDK**: ^3.9.2
- **just_audio**: Audio playback engine
- **audio_service**: Background audio service
- **flutter_local_notifications**: Push notifications
- **permission_handler**: Runtime permissions
- **provider**: State management

## Setup Instructions

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Android Configuration
The app is already configured with necessary permissions in `AndroidManifest.xml`:
- Internet access
- Foreground service
- Wake lock
- Post notifications
- Media playback service

### 3. iOS Configuration
Background modes are configured in `Info.plist`:
- Audio background mode
- Processing background mode

### 4. Run the App
```bash
# For Android
flutter run

# For iOS
flutter run -d ios

# For a specific device
flutter devices
flutter run -d <device-id>
```

## Project Structure

```
lib/
├── main.dart                          # App entry point and provider setup
├── screens/
│   └── music_player_screen.dart      # Main music player UI
└── services/
    ├── audio_handler.dart             # Background audio service handler
    └── notification_service.dart      # Push notification service
```

## How It Works

### Background Playback
The app uses `audio_service` package to create a background service that continues playing music even when the app is minimized. The `MyAudioHandler` class manages the audio player and communicates with the system media controls.

### Notifications
Two types of notifications are implemented:
1. **Now Playing Notification**: Persistent notification showing current track with media controls
2. **Track Change Notification**: Push notification when user skips to next/previous track

### State Management
The app uses Provider for state management to handle:
- Play/pause state
- Current track position
- Track duration
- Current song index

## Customization

### Adding Your Own Music
Edit the `_playlist` array in `music_player_screen.dart`:

```dart
final List<Map<String, String>> _playlist = [
  {
    'title': 'Your Song Title',
    'artist': 'Artist Name',
    'url': 'https://your-audio-url.mp3',
    'artUri': 'https://your-album-art-url.jpg',
  },
  // Add more tracks...
];
```

### Changing Theme Colors
Modify the theme in `main.dart`:

```dart
colorScheme: ColorScheme.dark(
  primary: const Color(0xFF6C63FF),      // Primary color
  secondary: const Color(0xFFFF6584),    // Secondary color
  surface: const Color(0xFF1D1E33),      // Card color
  background: const Color(0xFF0A0E21),   // Background color
),
```

## Permissions

### Android
- `INTERNET` - Stream audio from URLs
- `FOREGROUND_SERVICE` - Run background audio service
- `WAKE_LOCK` - Keep device awake during playback
- `POST_NOTIFICATIONS` - Show push notifications
- `FOREGROUND_SERVICE_MEDIA_PLAYBACK` - Media playback service type

### iOS
- Background Modes: Audio
- Background Modes: Processing

## Troubleshooting

### Audio Not Playing
1. Check internet connection
2. Verify audio URLs are accessible
3. Check device volume settings

### Notifications Not Showing
1. Grant notification permissions when prompted
2. Check device notification settings
3. Ensure app has notification permission in system settings

### Background Playback Not Working
1. Verify background modes are enabled (iOS)
2. Check foreground service permission (Android)
3. Ensure audio service is properly initialized

## Future Enhancements

- [ ] Add favorite tracks feature
- [ ] Implement shuffle and repeat modes
- [ ] Add equalizer controls
- [ ] Support for local audio files
- [ ] Create custom playlists
- [ ] Add lyrics display
- [ ] Implement sleep timer
- [ ] Add audio visualization

## License

This project is open source and available under the MIT License.

## Support

For issues and questions, please create an issue in the repository.
