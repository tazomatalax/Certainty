import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui'; // Add this import for ImageFilter
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/animation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:audioplayers/audioplayers.dart';

// Use WebDatabaseHelper for web, and DatabaseHelper for other platforms
import 'database_helper.dart' if (dart.library.html) 'web_database_helper.dart' as db_helper;

void main() {
  runApp(const CertaintyApp());
}

class CertaintyApp extends StatelessWidget {
  const CertaintyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Certainty',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7A9E9F), // Soft teal
          brightness: Brightness.dark,
          // background: const Color(0xFF1E2A2A), // Removed deprecated property
          surface: const Color(0xFF1E2A2A), // Dark teal (moved from background)
          surfaceTint: const Color(0xFF2C3B3B), // Slightly lighter dark teal
          primary: const Color(0xFF7A9E9F), // Soft teal
          secondary: const Color(0xFFB8D8D8), // Light grayish cyan
          onSurface: const Color(0xFFE0E0E0), // Light gray
          onPrimary: Colors.white,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const TruthsHomePage(),
    );
  }
}

class TruthsHomePage extends StatefulWidget {
  const TruthsHomePage({super.key});

  @override
  _TruthsHomePageState createState() => _TruthsHomePageState();
}

class _TruthsHomePageState extends State<TruthsHomePage> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  List<Map<String, dynamic>> truths = [];
  int _currentTruthIndex = 0;
  final _databaseHelper = db_helper.getDatabaseHelper();
  bool _showingFavorites = false;
  late AnimationController _grassAnimationController;
  late AnimationController _breathingController;
  late Animation<double> _breathingAnimation;
  late MusicPlayer _musicPlayer;

  @override
  void initState() {
    super.initState();
    _loadTruths();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _controller.forward();
    
    _grassAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _breathingController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);
    
    _breathingAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );
    
    _musicPlayer = MusicPlayer();
  }

  void _toggleShowFavorites() {
    setState(() {
      _showingFavorites = !_showingFavorites;
    });
    _loadTruths();
  }

  Future<void> _loadTruths() async {
    List<Map<String, dynamic>> loadedTruths = _showingFavorites
        ? await _databaseHelper.getFavoriteTruths()
        : await _databaseHelper.getTruths();
    setState(() {
      truths = loadedTruths;
      _currentTruthIndex = 0;
    });
    _controller.forward(from: 0.0);
  }

  Future<void> _toggleFavorite() async {
    if (truths.isNotEmpty) {
      int currentId = truths[_currentTruthIndex]['id'];
      await _databaseHelper.toggleFavorite(currentId);
      
      // Reload the truths to get the updated favorite status
      List<Map<String, dynamic>> updatedTruths = _showingFavorites
          ? await _databaseHelper.getFavoriteTruths()
          : await _databaseHelper.getTruths();
      
      setState(() {
        truths = updatedTruths;
        // Find the index of the current truth in the updated list
        _currentTruthIndex = truths.indexWhere((truth) => truth['id'] == currentId);
        if (_currentTruthIndex == -1) {
          // If the current truth is not in the updated list (e.g., when toggling off a favorite in favorites view),
          // set the index to 0 or keep it at the last valid index
          _currentTruthIndex = truths.isEmpty ? 0 : truths.length - 1;
        }
      });
    }
  }

  void _changeTruth() {
    if (truths.isEmpty) return;
    _controller.reverse().then((_) {
      setState(() {
        _currentTruthIndex = (_currentTruthIndex + 1) % truths.length;
      });
      _controller.forward();
    });
  }

  Future<void> _addNewTruth() async {
    String? newTruth = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        String inputText = '';
        return AlertDialog(
          title: Text('Add New Truth'),
          content: TextField(
            onChanged: (value) {
              inputText = value;
            },
            decoration: InputDecoration(hintText: "Enter your truth"),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Add'),
              onPressed: () => Navigator.of(context).pop(inputText),
            ),
          ],
        );
      },
    );

    if (newTruth != null && newTruth.isNotEmpty) {
      await _databaseHelper.insertTruth(newTruth);
      _loadTruths();
    }
  }

  void _shareTruth() {
    if (truths.isNotEmpty) {
      String truthText = truths[_currentTruthIndex]['text'];
      Share.share('Hey, I saw this and wanted to share with you. "$truthText" \n\nCheck out Certainty on the App/Play Store');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        centerTitle: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Image.asset(
              'assets/certainty_logo_512.png',
              height: 40,
              width: 40,
            ),
            SizedBox(width: 10),
            Text(
              'Certainty',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 24,
                fontWeight: FontWeight.w300,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showingFavorites ? Icons.favorite : Icons.favorite_border,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: _toggleShowFavorites,
          ),
          IconButton(
            icon: Icon(
              Icons.add,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: _addNewTruth,
          ),
          Builder(
            builder: (BuildContext context) {
              return IconButton(
                icon: Icon(
                  Icons.music_note,
                  color: Theme.of(context).colorScheme.primary,
                ),
                onPressed: () {
                  Scaffold.of(context).openEndDrawer();
                },
              );
            },
          ),
        ],
      ),
      endDrawer: MusicSidebar(musicPlayer: _musicPlayer),
      body: Stack(
        children: [
          BreathingBackground(animation: _breathingAnimation),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Center(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        truths.isNotEmpty ? truths[_currentTruthIndex]['text'] : '',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onBackground,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      truths.isNotEmpty && truths[_currentTruthIndex]['isFavorite'] == 1
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    onPressed: _toggleFavorite,
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.share,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    onPressed: _shareTruth,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton(
                      onPressed: _changeTruth,
                      child: const Text('Next', style: TextStyle(fontSize: 20)),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(200, 60),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _grassAnimationController.dispose();
    _breathingController.dispose();
    _musicPlayer.dispose();
    super.dispose();
  }
}

class ForestBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/forest_background.jpg'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.3),
            BlendMode.darken,
          ),
        ),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          color: Colors.black.withOpacity(0.1),
        ),
      ),
    );
  }
}

class GrassBackground extends StatelessWidget {
  final Animation<double> animation;

  const GrassBackground({Key? key, required this.animation}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return CustomPaint(
          painter: GrassPainter(animation.value),
          child: Container(),
        );
      },
    );
  }
}

class GrassPainter extends CustomPainter {
  final double animationValue;

  GrassPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green[600]!
      ..style = PaintingStyle.fill;

    final skyPaint = Paint()
      ..color = Colors.lightBlue[200]!
      ..style = PaintingStyle.fill;

    // Draw sky (full screen)
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), skyPaint);

    // Draw grass blades (bottom half of the screen)
    for (int i = 0; i < size.width; i += 20) {
      final path = Path();
      path.moveTo(i.toDouble(), size.height);
      
      final waveOffset = math.sin((animationValue * 2 * math.pi) + (i / size.width) * 2 * math.pi) * 20;
      final height = size.height * 0.5 + waveOffset; // Increased grass height
      
      path.quadraticBezierTo(
        i.toDouble() + 10, 
        size.height - height, 
        i.toDouble() + 20, 
        size.height
      );

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class BreathingBackground extends StatelessWidget {
  final Animation<double> animation;

  const BreathingBackground({Key? key, required this.animation}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 0.8 * animation.value,
              colors: [
                Theme.of(context).colorScheme.surface.withOpacity(0.6),
                Theme.of(context).colorScheme.background.withOpacity(0.9),
              ],
            ),
          ),
        );
      },
    );
  }
}

class MusicPlayer {
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<String> _playlist = [
    'calm_music_1.mp3',
    'calm_music_2.mp3',
    'calm_music_3.mp3',
  ];
  int _currentIndex = 0;

  MusicPlayer() {
    _audioPlayer.onPlayerComplete.listen((_) {
      _playNext();
    });
  }

  Future<void> play() async {
    await _audioPlayer.play(AssetSource(_playlist[_currentIndex]));
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
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
    _audioPlayer.dispose();
  }

  bool get isPlaying => _audioPlayer.state == PlayerState.playing;

  Future<void> togglePlayPause() async {
    if (isPlaying) {
      await pause();
    } else {
      await play();
    }
  }
}

class MusicSidebar extends StatefulWidget {
  final MusicPlayer musicPlayer;

  const MusicSidebar({Key? key, required this.musicPlayer}) : super(key: key);

  @override
  _MusicSidebarState createState() => _MusicSidebarState();
}

class _MusicSidebarState extends State<MusicSidebar> {
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
                  stream: widget.musicPlayer._audioPlayer.onPlayerStateChanged,
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
    setState(() {}); // This line is correct now
  }

  void _togglePlayPause() {
    widget.musicPlayer.togglePlayPause();
    setState(() {}); // This line is correct now
  }
}