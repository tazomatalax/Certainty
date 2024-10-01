import 'package:flutter/material.dart';
import '../services/music_player.dart';
import 'package:audioplayers/audioplayers.dart';

class MusicSidebar extends StatefulWidget {
  final MusicPlayer musicPlayer;

  const MusicSidebar({super.key, required this.musicPlayer});

  @override
  MusicSidebarState createState() => MusicSidebarState();
}

class MusicSidebarState extends State<MusicSidebar> {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Theme.of(context).colorScheme.surface,
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: Center(
                child: Text(
                  'Music Player',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 24,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  ListTile(
                    title: Text('Ocean Waves'),
                    onTap: () => _playTrack(0),
                  ),
                  ListTile(
                    title: Text('Charmed Meditation'),
                    onTap: () => _playTrack(1),
                  ),
                  ListTile(
                    title: Text('Moonlight Meditation'),
                    onTap: () => _playTrack(2),
                  ),
                ],
              ),
            ),
            _buildMusicControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildMusicControls() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          StreamBuilder<Duration>(
            stream: widget.musicPlayer.onPositionChanged,
            builder: (context, positionSnapshot) {
              return StreamBuilder<Duration>(
                stream: widget.musicPlayer.onDurationChanged,
                builder: (context, durationSnapshot) {
                  final position = positionSnapshot.data ?? Duration.zero;
                  final duration = durationSnapshot.data ?? Duration.zero;
                  return Slider(
                    value: position.inSeconds.toDouble(),
                    max: duration.inSeconds.toDouble(),
                    onChanged: (value) {
                      widget.musicPlayer.audioPlayer.seek(Duration(seconds: value.toInt()));
                    },
                  );
                },
              );
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: Icon(Icons.skip_previous),
                onPressed: widget.musicPlayer.playPrevious,
              ),
              StreamBuilder<PlayerState>(
                stream: widget.musicPlayer.audioPlayer.onPlayerStateChanged,
                builder: (context, snapshot) {
                  final playerState = snapshot.data;
                  final isPlaying = playerState == PlayerState.playing;
                  return IconButton(
                    icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                    onPressed: widget.musicPlayer.togglePlayPause,
                  );
                },
              ),
              IconButton(
                icon: Icon(Icons.skip_next),
                onPressed: widget.musicPlayer.playNext,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _playTrack(int index) {
    widget.musicPlayer.selectTrack(index);
    setState(() {});
  }

  void _togglePlayPause() {
    widget.musicPlayer.togglePlayPause();
    setState(() {});
  }
}