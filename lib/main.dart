import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'widgets/breathing_background.dart';
import 'widgets/music_sidebar.dart';
import 'services/music_player.dart';
import 'database_helper.dart' if (dart.library.html) 'web_database_helper.dart' as db_helper;
import 'widgets/settings_sidebar.dart';

void main() {
  runApp(const CertaintyApp());
}

class CertaintyApp extends StatefulWidget {
  const CertaintyApp({super.key});

  @override
  State<CertaintyApp> createState() => _CertaintyAppState();
}

class _CertaintyAppState extends State<CertaintyApp> {
  static const String _prefSeasonKey = 'theme_season';
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

  @override
  void initState() {
    super.initState();
    _loadSavedSeason();
  }

  Future<void> _loadSavedSeason() async {
    final prefs = await SharedPreferences.getInstance();
    final savedSeason = prefs.getString(_prefSeasonKey);
    if (savedSeason != null && _seasonColorSchemes.containsKey(savedSeason)) {
      setState(() {
        _currentSeason = savedSeason;
      });
    }
  }

  void _changeSeason(String season) {
    setState(() {
      _currentSeason = season;
    });
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString(_prefSeasonKey, season);
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
  State<TruthsHomePage> createState() => _TruthsHomePageState();
}

class _TruthsHomePageState extends State<TruthsHomePage> with TickerProviderStateMixin {
  static const String _prefShareMessageKey = 'share_message';
  static const String _prefCategoryKey = 'selected_category';

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late AnimationController _breathingController;
  late Animation<double> _breathingAnimation;
  late MusicPlayer _musicPlayer;

  List<Map<String, dynamic>> truths = [];
  List<int> _randomOrder = [];
  int _currentIndex = 0;
  final _databaseHelper = db_helper.getDatabaseHelper();

  bool _showingFavorites = false;
  bool _showingCustomTruths = false;
  List<String> _categories = ['All'];
  String _currentCategory = 'All';
  String _shareMessage = 'Hey, I saw this and wanted to share with you. "{truth}"';

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _breathingAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );

    _musicPlayer = MusicPlayer();
    _initAppData();
  }

  Future<void> _initAppData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedShareMsg = prefs.getString(_prefShareMessageKey);
    final savedCategory = prefs.getString(_prefCategoryKey);

    if (savedShareMsg != null && savedShareMsg.isNotEmpty) {
      _shareMessage = savedShareMsg;
    }

    await _loadCategories();

    if (savedCategory != null && _categories.contains(savedCategory)) {
      _currentCategory = savedCategory;
    }

    await _loadTruths();
  }

  Future<void> _loadCategories() async {
    List<String> dbCategories = await _databaseHelper.getCategories();
    if (!mounted) return;
    setState(() {
      _categories = ['All', ...dbCategories];
    });
  }

  Future<void> _loadTruths() async {
    List<Map<String, dynamic>> loadedTruths;
    if (_showingFavorites) {
      loadedTruths = await _databaseHelper.getFavoriteTruths();
    } else if (_showingCustomTruths) {
      loadedTruths = await _databaseHelper.getCustomTruths();
    } else if (_currentCategory == 'All' || !_categories.contains(_currentCategory)) {
      loadedTruths = await _databaseHelper.getTruths();
    } else {
      loadedTruths = await _databaseHelper.getTruthsByCategory(_currentCategory);
    }

    if (!mounted) return;
    setState(() {
      truths = loadedTruths;
      _randomOrder = List<int>.generate(truths.length, (i) => i);
      if (!_showingFavorites && !_showingCustomTruths) {
        _randomOrder.shuffle();
      }
      _currentIndex = _randomOrder.isNotEmpty ? _randomOrder.first : 0;
    });
    _controller.forward(from: 0.0);
  }

  void _toggleShowFavorites() {
    setState(() {
      _showingFavorites = !_showingFavorites;
      if (_showingFavorites) {
        _showingCustomTruths = false;
      }
    });
    _loadTruths();
  }

  void _toggleShowCustomTruths() {
    setState(() {
      _showingCustomTruths = !_showingCustomTruths;
      if (_showingCustomTruths) {
        _showingFavorites = false;
      }
    });
    _loadTruths();
  }

  Future<void> _toggleFavorite() async {
    if (truths.isEmpty) return;
    HapticFeedback.selectionClick();
    int currentId = truths[_currentIndex]['id'];
    await _databaseHelper.toggleFavorite(currentId);

    if (!mounted) return;
    if (_showingFavorites) {
      List<Map<String, dynamic>> updatedTruths = await _databaseHelper.getFavoriteTruths();
      if (!mounted) return;
      setState(() {
        truths = updatedTruths;
        if (_currentIndex >= truths.length) {
          _currentIndex = truths.isEmpty ? 0 : truths.length - 1;
        }
      });
    } else {
      List<Map<String, dynamic>> updatedTruths = _showingCustomTruths
          ? await _databaseHelper.getCustomTruths()
          : (_currentCategory == 'All' || !_categories.contains(_currentCategory))
              ? await _databaseHelper.getTruths()
              : await _databaseHelper.getTruthsByCategory(_currentCategory);

      if (!mounted) return;
      setState(() {
        truths = updatedTruths;
      });
    }
  }

  void _nextTruth() {
    if (truths.isEmpty) return;
    HapticFeedback.lightImpact();
    _controller.reverse().then((_) {
      if (!mounted) return;
      setState(() {
        if (_showingFavorites || _showingCustomTruths) {
          _currentIndex = (_currentIndex + 1) % truths.length;
        } else if (_randomOrder.isNotEmpty) {
          int currentPos = _randomOrder.indexOf(_currentIndex);
          int nextPos = (currentPos + 1) % _randomOrder.length;
          _currentIndex = _randomOrder[nextPos];
        } else {
          _currentIndex = (_currentIndex + 1) % truths.length;
        }
      });
      _controller.forward();
    });
  }

  void _previousTruth() {
    if (truths.isEmpty) return;
    HapticFeedback.lightImpact();
    _controller.reverse().then((_) {
      if (!mounted) return;
      setState(() {
        if (_showingFavorites || _showingCustomTruths) {
          _currentIndex = (_currentIndex - 1 + truths.length) % truths.length;
        } else if (_randomOrder.isNotEmpty) {
          int currentPos = _randomOrder.indexOf(_currentIndex);
          int prevPos = (currentPos - 1 + _randomOrder.length) % _randomOrder.length;
          _currentIndex = _randomOrder[prevPos];
        } else {
          _currentIndex = (_currentIndex - 1 + truths.length) % truths.length;
        }
      });
      _controller.forward();
    });
  }

  void _copyTruth() {
    if (truths.isEmpty) return;
    final truthText = truths[_currentIndex]['text'];
    Clipboard.setData(ClipboardData(text: truthText));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('Truth copied to clipboard'),
          ],
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  void _shareTruth() {
    if (truths.isNotEmpty) {
      String truthText = truths[_currentIndex]['text'];
      String formattedMessage = _shareMessage.replaceAll('{truth}', '"$truthText"');
      Share.share(formattedMessage);
    }
  }

  void _addNewTruth(BuildContext context) {
    String newTruth = '';
    String category = 'General';
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
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
                initialValue: category,
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
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () async {
                if (newTruth.trim().isNotEmpty) {
                  await _databaseHelper.insertTruth(newTruth.trim(), category);
                  if (!mounted) return;
                  await _loadTruths();
                  await _loadCategories();
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _updateShareMessage(String newMessage) {
    setState(() {
      _shareMessage = newMessage;
    });
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString(_prefShareMessageKey, newMessage);
    });
  }

  void _editOrDeleteTruth(Map<String, dynamic> truth) {
    String updatedText = truth['text'];
    String category = truth['category'] ?? 'General';

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
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
                initialValue: category,
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
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                await _databaseHelper.deleteTruth(truth['id']);
                if (!mounted) return;
                await _loadTruths();
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
            ),
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () async {
                if (updatedText.trim().isNotEmpty) {
                  await _databaseHelper.updateTruth(truth['id'], updatedText.trim(), category);
                  if (!mounted) return;
                  await _loadTruths();
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showCategoryDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Select Category'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _categories.length,
              itemBuilder: (BuildContext context, int index) {
                final categoryName = _categories[index];
                final isSelected = categoryName == _currentCategory && !_showingFavorites && !_showingCustomTruths;
                return ListTile(
                  title: Text(
                    categoryName,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: isSelected ? const Icon(Icons.check, size: 20) : null,
                  onTap: () {
                    setState(() {
                      _currentCategory = categoryName;
                      _showingFavorites = false;
                      _showingCustomTruths = false;
                    });
                    SharedPreferences.getInstance().then((prefs) {
                      prefs.setString(_prefCategoryKey, categoryName);
                    });
                    _loadTruths();
                    Navigator.of(dialogContext).pop();
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
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Select Theme'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: ['Default', 'Spring', 'Summer', 'Autumn', 'Winter'].map((String season) {
                final isSelected = season == widget.currentSeason;
                return ListTile(
                  title: Text(
                    season,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: isSelected ? const Icon(Icons.check, size: 20) : null,
                  onTap: () {
                    widget.onChangeSeason(season);
                    Navigator.of(dialogContext).pop();
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final IconData icon;
    final String title;
    final String message;
    final String actionLabel;
    final VoidCallback onAction;

    if (_showingFavorites) {
      icon = Icons.favorite_border;
      title = 'No Favorites Yet';
      message = 'Tap the heart icon on any truth to save it here.';
      actionLabel = 'Show All Truths';
      onAction = _toggleShowFavorites;
    } else if (_showingCustomTruths) {
      icon = Icons.person_outline;
      title = 'No Custom Truths Yet';
      message = 'Add your own personal truths to reflect on them anytime.';
      actionLabel = 'Add New Truth';
      onAction = () => _addNewTruth(context);
    } else {
      icon = Icons.spa_outlined;
      title = 'No Truths Found';
      message = 'No truths available in this category.';
      actionLabel = 'Show All Truths';
      onAction = () {
        setState(() {
          _currentCategory = 'All';
        });
        _loadTruths();
      };
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 56,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.85),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
                child: Text(actionLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getAppTitle() {
    if (_showingFavorites) return 'Favorites';
    if (_showingCustomTruths) return 'Custom Truths';
    return _currentCategory == 'All' ? 'Certainty' : _currentCategory;
  }

  @override
  Widget build(BuildContext context) {
    final hasTruths = truths.isNotEmpty;

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
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  _getAppTitle(),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 24,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 1.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_drop_down,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
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
            tooltip: 'Change Theme',
            onPressed: _showSeasonDialog,
          ),
          Builder(
            builder: (BuildContext context) {
              return IconButton(
                icon: Icon(
                  Icons.music_note,
                  color: Theme.of(context).colorScheme.primary,
                ),
                tooltip: 'Calm Music',
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
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragEnd: (DragEndDetails details) {
              final velocity = details.primaryVelocity ?? 0;
              if (velocity < -200) {
                _nextTruth();
              } else if (velocity > 200) {
                _previousTruth();
              }
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: hasTruths
                      ? Center(
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                              child: GestureDetector(
                                onLongPress: () {
                                  if (truths[_currentIndex]['isCustom'] == 1) {
                                    _editOrDeleteTruth(truths[_currentIndex]);
                                  }
                                },
                                child: Text(
                                  truths[_currentIndex]['text'],
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onSurface,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                      : _buildEmptyState(),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 32.0, left: 16.0, right: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(
                          hasTruths && truths[_currentIndex]['isFavorite'] == 1
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        tooltip: 'Favorite',
                        onPressed: hasTruths ? _toggleFavorite : null,
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back_ios_new,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        tooltip: 'Previous',
                        onPressed: hasTruths ? _previousTruth : null,
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: hasTruths ? _nextTruth : null,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(130, 56),
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: const Text('Next', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(
                          Icons.copy_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        tooltip: 'Copy',
                        onPressed: hasTruths ? _copyTruth : null,
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: Icon(
                          Icons.share,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        tooltip: 'Share',
                        onPressed: hasTruths ? _shareTruth : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
