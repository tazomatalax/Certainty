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
                    title: Text('Calm Music 1'),
                    onTap: () => _playTrack(0),
                  ),
                  ListTile(
                    title: Text('Calm Music 2'),
                    onTap: () => _playTrack(1),
                  ),
                  ListTile(
                    title: Text('Calm Music 3'),
                    onTap: () => _playTrack(2),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _togglePlayPause,
                child: StreamBuilder<PlayerState>(
                  stream: widget.musicPlayer.audioPlayer.onPlayerStateChanged,
                  builder: (context, snapshot) {
                    final playerState = snapshot.data;
                    final isPlaying = playerState == PlayerState.playing;
                    return Text(isPlaying ? 'Pause' : 'Play');
                  },
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                ),
              ),
            ),
          ],
        ),
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