import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'widgets/breathing_background.dart';
import 'widgets/music_sidebar.dart';
import 'services/music_player.dart';
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
  List<int> _randomOrder = [];
  int _currentIndex = 0;
  final _databaseHelper = db_helper.getDatabaseHelper();
  bool _showingFavorites = false;
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
      _currentIndex = 0;
      if (!_showingFavorites) {
        _randomOrder = List<int>.generate(truths.length, (i) => i)..shuffle();
      }
    });
    _controller.forward(from: 0.0);
  }

  Future<void> _toggleFavorite() async {
    if (truths.isNotEmpty) {
      int currentId = truths[_currentIndex]['id'];
      await _databaseHelper.toggleFavorite(currentId);
      
      List<Map<String, dynamic>> updatedTruths = _showingFavorites
          ? await _databaseHelper.getFavoriteTruths()
          : await _databaseHelper.getTruths();
      
      setState(() {
        truths = updatedTruths;
        _currentIndex = truths.indexWhere((truth) => truth['id'] == currentId);
        if (_currentIndex == -1) {
          _currentIndex = truths.isEmpty ? 0 : truths.length - 1;
        }
      });
    }
  }

  void _changeTruth() {
    if (truths.isEmpty) return;
    _controller.reverse().then((_) {
      setState(() {
        if (_showingFavorites) {
          _currentIndex = (_currentIndex + 1) % truths.length;
        } else {
          int currentRandomIndex = _randomOrder.indexOf(_currentIndex);
          int nextRandomIndex = (currentRandomIndex + 1) % _randomOrder.length;
          _currentIndex = _randomOrder[nextRandomIndex];
        }
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
      String truthText = truths[_currentIndex]['text'];
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
                        truths.isNotEmpty ? truths[_currentIndex]['text'] : '',
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
                      truths.isNotEmpty && truths[_currentIndex]['isFavorite'] == 1
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    onPressed: _toggleFavorite,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                  IconButton(
                    icon: Icon(
                      Icons.share,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    onPressed: _shareTruth,
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
    _breathingController.dispose();
    _musicPlayer.dispose();
    super.dispose();
  }
}