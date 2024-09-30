import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui'; // Add this import for ImageFilter
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/animation.dart';

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
  }

  Future<void> _loadTruths() async {
    List<Map<String, dynamic>> loadedTruths = _showingFavorites
        ? await _databaseHelper.getFavoriteTruths()
        : await _databaseHelper.getTruths();
    setState(() {
      truths = loadedTruths;
      _currentTruthIndex = 0;
    });
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

  Future<void> _toggleFavorite() async {
    if (truths.isNotEmpty) {
      await _databaseHelper.toggleFavorite(truths[_currentTruthIndex]['id']);
      _loadTruths();
    }
  }

  void _toggleShowFavorites() {
    setState(() {
      _showingFavorites = !_showingFavorites;
    });
    _loadTruths();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Make scaffold background transparent
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        centerTitle: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.spa_outlined,
              color: Theme.of(context).colorScheme.primary,
              size: 30,
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
        ],
      ),
      body: Stack(
        children: [
          GrassBackground(animation: _grassAnimationController),
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
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton(
                      onPressed: _changeTruth,
                      child: const Text('Next Fact', style: TextStyle(fontSize: 20)),
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
      ..color = Colors.green[700]!
      ..style = PaintingStyle.fill;

    final darkPaint = Paint()
      ..color = Colors.green[900]!
      ..style = PaintingStyle.fill;

    final skyPaint = Paint()
      ..color = Colors.lightBlue[200]!
      ..style = PaintingStyle.fill;

    // Draw sky (full screen)
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), skyPaint);

    // Draw grass blades (bottom third of the screen)
    for (int i = 0; i < size.width; i += 10) {
      final path = Path();
      path.moveTo(i.toDouble(), size.height);
      
      final waveOffset = math.sin((animationValue * 2 * math.pi) + (i / size.width) * 4 * math.pi) * 5;
      final height = size.height * 0.1 + waveOffset; // Reduced grass height
      
      path.quadraticBezierTo(
        i.toDouble() + 5, 
        size.height - height, 
        i.toDouble() + 10, 
        size.height
      );

      canvas.drawPath(path, i % 20 == 0 ? darkPaint : paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
