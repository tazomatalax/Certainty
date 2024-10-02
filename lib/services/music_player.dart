import 'package:audioplayers/audioplayers.dart';
import 'dart:async';

class MusicPlayer {
  final AudioPlayer audioPlayer = AudioPlayer();
  final List<String> _playlist = [
    'calm_music_1.mp3',
    'calm_music_2.mp3',
    'calm_music_3.mp3',
  ];
  int _currentIndex = 0;
  final _currentIndexController = StreamController<int>.broadcast();

  MusicPlayer() {
    audioPlayer.onPlayerComplete.listen((_) {
      playNext();
    });
  }

  Stream<int> get currentIndexStream => _currentIndexController.stream;

  Future<void> play() async {
    await audioPlayer.play(AssetSource(_playlist[_currentIndex]));
    _currentIndexController.add(_currentIndex);
  }

  Future<void> pause() async {
    await audioPlayer.pause();
  }

  Future<void> stop() async {
    await audioPlayer.stop();
  }

  void _playNext() {
    _currentIndex = (_currentIndex + 1) % _playlist.length;
    play();
  }

  void selectTrack(int index) {
    if (index >= 0 && index < _playlist.length) {
      _currentIndex = index;
      play();
    }
  }

  void dispose() {
    audioPlayer.dispose();
    _currentIndexController.close();
  }

  bool get isPlaying => audioPlayer.state == PlayerState.playing;

  Future<void> togglePlayPause() async {
    if (isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  void playNext() {
    _currentIndex = (_currentIndex + 1) % _playlist.length;
    play();
  }

  void playPrevious() {
    _currentIndex = (_currentIndex - 1 + _playlist.length) % _playlist.length;
    play();
  }

  Stream<Duration> get onDurationChanged => audioPlayer.onDurationChanged;
  Stream<Duration> get onPositionChanged => audioPlayer.onPositionChanged;

  PlayerState get playerState => audioPlayer.state;

  Stream<PlayerState> get playerStateStream => audioPlayer.onPlayerStateChanged;
}