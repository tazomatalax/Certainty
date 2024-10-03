import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'widgets/breathing_background.dart';
import 'widgets/music_sidebar.dart';
import 'services/music_player.dart';
import 'database_helper.dart' if (dart.library.html) 'web_database_helper.dart' as db_helper;
import 'widgets/settings_sidebar.dart'; // Add this import

void main() {
  runApp(const CertaintyApp());
}

class CertaintyApp extends StatefulWidget {
  const CertaintyApp({super.key});

  @override
  _CertaintyAppState createState() => _CertaintyAppState();
}

class _CertaintyAppState extends State<CertaintyApp> {
  String _currentSeason = 'Default';

final Map<String, ColorScheme> _seasonColorSchemes = {
  'Default': ColorScheme.fromSeed(
    seedColor: const Color.fromARGB(255, 42, 155, 159), // Soft teal
    brightness: Brightness.dark,
    surface: const Color.fromARGB(255, 70, 155, 155), // Dark teal
    surfaceTint: const Color.fromARGB(255, 80, 108, 108), // Slightly lighter dark teal
    primary: const Color(0xFF7A9E9F), // Soft teal
    secondary: const Color(0xFFB8D8D8), // Light grayish cyan
    onSurface: const Color.fromARGB(255, 255, 255, 255), // Light gray
    onPrimary: Colors.white,
  ),
  'Spring': ColorScheme.fromSeed(
    seedColor: const Color(0xFF5A7E7F),
    brightness: Brightness.light,
    surface: const Color(0xFFD0E4E4),
    surfaceTint: const Color(0xFFC0CECE),
    primary: const Color(0xFF5A7E7F),
    secondary: const Color(0xFF98B8B8),
    onSurface: const Color(0xFF1C2B2B),
    onPrimary: Colors.white,
  ),
  'Summer': ColorScheme.fromSeed(
    seedColor: const Color(0xFFF4A460),
    brightness: Brightness.light,
    surface: const Color(0xFFFFF5E6),
    surfaceTint: const Color(0xFFFFE4B5),
    primary: const Color(0xFFF4A460),
    secondary: const Color(0xFFFFD700),
    onSurface: const Color(0xFF4A3C31),
    onPrimary: Colors.white,
  ),
  'Autumn': ColorScheme.fromSeed(
    seedColor: const Color.fromARGB(255, 124, 63, 23), // Darker
    brightness: Brightness.light,
    surface: const Color(0xFFEFD0B6), // Darker
    surfaceTint: const Color(0xFFDFC495), // Darker
    primary: const Color(0xFFB2591E), // Darker
    secondary: const Color(0xFFAD651F), // Darker
    onSurface: const Color(0xFF3A2C21), // Darker
    onPrimary: Colors.white,
  ),
  'Winter': ColorScheme.fromSeed(
    seedColor: const Color(0xFF366294), // Darker
    brightness: Brightness.light,
    surface: const Color(0xFFC6D0E0), // Darker
    surfaceTint: const Color(0xFF90A4BE), // Darker
    primary: const Color(0xFF366294), // Darker
    secondary: const Color(0xFF90A4BE), // Darker
    onSurface: const Color(0xFF0E1A2A), // Darker
    onPrimary: Colors.white,
  ),
};

  void _changeSeason(String season) {
    setState(() {
      _currentSeason = season;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Certainty',
      theme: ThemeData(
        colorScheme: _seasonColorSchemes[_currentSeason],
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: TruthsHomePage(
        currentSeason: _currentSeason,
        onChangeSeason: _changeSeason,
      ),
    );
  }
}

class TruthsHomePage extends StatefulWidget {
  final String currentSeason;
  final Function(String) onChangeSeason;

  const TruthsHomePage({
    super.key,
    required this.currentSeason,
    required this.onChangeSeason,
  });

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
  String _shareMessage = 'Hey, I saw this and wanted to share with you. "{truth}" \n\nCheck out Certainty on the App/Play Store';
  bool _showingCustomTruths = false;
  List<String> _categories = ['All'];
  String _currentCategory = 'All';

  @override
  void initState() {
    super.initState();
    _upgradeDatabase();
    _loadTruths();
    _loadCategories();
    _databaseHelper.printAllTruths(); // Add this line for debugging
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _controller.forward();
    
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8), // 4 seconds in, 4 seconds out
    )..repeat(reverse: true);
    
    _breathingAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );
    
    _musicPlayer = MusicPlayer();
  }

  Future<void> _upgradeDatabase() async {
    print("Starting database upgrade");
    await _databaseHelper.deleteDatabase(); // Add this line
    await _databaseHelper.forceUpgrade();
    print("Database upgrade completed");
    await _loadTruths();
    await _loadCategories();
    print("Truths and categories loaded");
  }

  Future<void> _loadCategories() async {
    List<String> dbCategories = await _databaseHelper.getCategories();
    print("Loaded categories from DB: $dbCategories");
    setState(() {
      _categories = ['All', ...dbCategories];
    });
    print("Final categories list: $_categories");
  }

  void _toggleShowFavorites() {
    setState(() {
      _showingFavorites = !_showingFavorites;
    });
    _loadTruths().then((_) {
      if (_filteredTruths.isEmpty && _showingFavorites) {
        // If there are no favorites, show a message and revert the toggle
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No favorite truths found.'),
            duration: Duration(seconds: 2),
          ),
        );
        setState(() {
          _showingFavorites = false;
        });
      }
    });
  }

  void _toggleShowCustomTruths() async {
    if (!_showingCustomTruths) {
      List<Map<String, dynamic>> customTruths = await _databaseHelper.getCustomTruths();
      print("Custom truths loaded: $customTruths");
      setState(() {
        truths = customTruths;
      });
    }
    setState(() {
      _showingCustomTruths = !_showingCustomTruths;
      _showingFavorites = false;
      _currentIndex = 0;
      if (_showingCustomTruths) {
        _randomOrder = List<int>.generate(truths.length, (i) => i);
      } else {
        _loadTruths();
      }
    });
    _controller.forward(from: 0.0);
  }

  List<Map<String, dynamic>> get _filteredTruths {
    if (_showingFavorites) {
      return truths.where((truth) => truth['isFavorite'] == 1).toList();
    } else if (_showingCustomTruths) {
      List<Map<String, dynamic>> customTruths = truths.where((truth) => truth['isCustom'] == 1).toList();
      print("Filtered custom truths: $customTruths"); // Add this line
      return customTruths;
    } else {
      return truths;
    }
  }

  Future<void> _loadTruths() async {
    List<Map<String, dynamic>> loadedTruths;
    if (_currentCategory == 'All' || !_categories.contains(_currentCategory)) {
      loadedTruths = await _databaseHelper.getTruths();
    } else {
      loadedTruths = await _databaseHelper.getTruthsByCategory(_currentCategory);
    }
    setState(() {
      truths = loadedTruths;
      _randomOrder = List<int>.generate(truths.length, (i) => i)..shuffle();
      _currentIndex = _randomOrder.first; // Start with the first shuffled index
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

  void _addNewTruth(BuildContext context) {
    String newTruth = '';
    String category = 'General';
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Truth'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                autofocus: true,
                decoration: const InputDecoration(hintText: 'Enter your truth'),
                onChanged: (value) {
                  newTruth = value;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: ['General', 'Motivation', 'Self-care', 'Mindfulness'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    category = newValue;
                  }
                },
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () async {
                if (newTruth.isNotEmpty) {
                  await _databaseHelper.insertTruth(newTruth, category);
                  await _loadTruths();
                  await _loadCategories(); // Add this line
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _openSettingsSidebar() {
    Scaffold.of(context).openDrawer();
  }

  void _updateShareMessage(String newMessage) {
    setState(() {
      _shareMessage = newMessage;
    });
  }

  void _shareTruth() {
    if (truths.isNotEmpty) {
      String truthText = truths[_currentIndex]['text'];
      String formattedMessage = _shareMessage.replaceAll('{truth}', '"$truthText"');
      Share.share(formattedMessage);
    }
  }

  void _editOrDeleteTruth(Map<String, dynamic> truth) {
    String updatedText = truth['text'];
    String category = truth['category'] ?? 'General'; // Provide a default value if category is null

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit or Delete Truth'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                autofocus: true,
                decoration: const InputDecoration(hintText: 'Edit your truth'),
                controller: TextEditingController(text: updatedText),
                onChanged: (value) {
                  updatedText = value;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: ['General', 'Motivation', 'Self-care', 'Mindfulness'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    category = newValue;
                  }
                },
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Delete'),
              onPressed: () async {
                await _databaseHelper.deleteTruth(truth['id']);
                await _loadTruths();
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () async {
                if (updatedText.isNotEmpty) {
                  await _databaseHelper.updateTruth(truth['id'], updatedText, category);
                  await _loadTruths();
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showCategoryDialog() {
    print("Categories in dialog: $_categories"); // Add this line
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Category'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _categories.length,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  title: Text(_categories[index]),
                  onTap: () {
                    setState(() {
                      _currentCategory = _categories[index];
                    });
                    _loadTruths();
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showSeasonDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Theme'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: ['Default', 'Spring', 'Summer', 'Autumn', 'Winter'].map((String season) {
                return ListTile(
                  title: Text(season),
                  onTap: () {
                    widget.onChangeSeason(season);
                    Navigator.of(context).pop();
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: GestureDetector(
          onTap: _showCategoryDialog,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Image.asset(
              //   'assets/certainty_logo_512.png',
              //   height: 40,
              //   width: 40,
              // ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  _currentCategory == 'All' ? 'Certainty' : _currentCategory,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 24,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 1.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.palette,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: _showSeasonDialog,
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
      drawer: SettingsSidebar(
        currentShareMessage: _shareMessage,
        onUpdateShareMessage: _updateShareMessage,
        onToggleFavorites: _toggleShowFavorites,
        onToggleCustomTruths: _toggleShowCustomTruths,
        onAddNewTruth: _addNewTruth,
        showingFavorites: _showingFavorites,
        showingCustomTruths: _showingCustomTruths,
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
                      child: GestureDetector(
                        onLongPress: () {
                          if (truths[_currentIndex]['isCustom'] == 1) {
                            _editOrDeleteTruth(truths[_currentIndex]);
                          }
                        },
                        child: Text(
                          truths.isNotEmpty ? truths[_currentIndex]['text'] : '',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
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
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(200, 60),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      ),
                      child: const Text('Next', style: TextStyle(fontSize: 20)),
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