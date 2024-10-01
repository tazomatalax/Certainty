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
      duration: const Duration(seconds: 4),
      vsync: this,
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
    _loadTruths();
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
      _currentIndex = 0;
      _randomOrder = List<int>.generate(truths.length, (i) => i)..shuffle();
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
          title: Text('Add New Truth'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                autofocus: true,
                decoration: InputDecoration(hintText: 'Enter your truth'),
                onChanged: (value) {
                  newTruth = value;
                },
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: category,
                decoration: InputDecoration(labelText: 'Category'),
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
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Add'),
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
          title: Text('Edit or Delete Truth'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                autofocus: true,
                decoration: InputDecoration(hintText: 'Edit your truth'),
                controller: TextEditingController(text: updatedText),
                onChanged: (value) {
                  updatedText = value;
                },
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: category,
                decoration: InputDecoration(labelText: 'Category'),
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
              child: Text('Delete'),
              onPressed: () async {
                await _databaseHelper.deleteTruth(truth['id']);
                await _loadTruths();
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Save'),
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
          title: Text('Select Category'),
          content: Container(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        centerTitle: true,
        title: GestureDetector(
          onTap: _showCategoryDialog,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/certainty_logo_512.png',
                height: 40,
                width: 40,
              ),
              SizedBox(width: 10),
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
                            color: Theme.of(context).colorScheme.onBackground,
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