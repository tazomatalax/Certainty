import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'truths_database.db');
    return await openDatabase(
      path, 
      version: 4,  // Increase this to 4
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE truths(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        text TEXT,
        isUserGenerated INTEGER,
        isFavorite INTEGER DEFAULT 0,
        isCustom INTEGER DEFAULT 0,
        category TEXT
      )
    ''');
    
    // Insert initial truths with categories
    for (Map<String, String> truth in initialTruths) {
      await db.insert('truths', {
        'text': truth['text'], 
        'isUserGenerated': 0, 
        'isFavorite': 0,
        'isCustom': 0,
        'category': truth['category']
      });
    }
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add the isFavorite column if it doesn't exist
      await db.execute('ALTER TABLE truths ADD COLUMN isFavorite INTEGER DEFAULT 0');
    }
    if (oldVersion < 3) {
      // Add the isCustom column
      await db.execute('ALTER TABLE truths ADD COLUMN isCustom INTEGER DEFAULT 0');
      // Update existing user-generated truths to be marked as custom
      await db.execute('UPDATE truths SET isCustom = 1 WHERE isUserGenerated = 1');
    }
    if (oldVersion < 4) {
      // Add the category column if it doesn't exist
      await db.execute('ALTER TABLE truths ADD COLUMN category TEXT DEFAULT "General"');
      // Update existing truths to have a category
      await db.execute('UPDATE truths SET category = "General" WHERE category IS NULL');
    }
  }

  Future<List<Map<String, dynamic>>> getTruths() async {
    Database db = await database;
    List<Map<String, dynamic>> truths = await db.query('truths');
    print("All truths from database: $truths");
    return truths;
  }

  Future<List<Map<String, dynamic>>> getFavoriteTruths() async {
    Database db = await database;
    return await db.query('truths', where: 'isFavorite = ?', whereArgs: [1]);
  }

  Future<int> insertTruth(String text, String category) async {
    Database db = await database;
    return await db.insert('truths', {
      'text': text, 
      'isUserGenerated': 1, 
      'isFavorite': 0,
      'isCustom': 1,
      'category': category.isNotEmpty ? category : 'General' // Provide a default category if empty
    });
  }

  Future<List<String>> getCategories() async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query('truths', distinct: true, columns: ['category']);
    return result.map((row) => row['category'] as String).toList();
  }

  Future<List<Map<String, dynamic>>> getTruthsByCategory(String category) async {
    Database db = await database;
    return await db.query('truths', where: 'category = ?', whereArgs: [category]);
  }

  Future<int> toggleFavorite(int id) async {
    Database db = await database;
    var truth = await db.query('truths', where: 'id = ?', whereArgs: [id]);
    int newFavoriteStatus = (truth.first['isFavorite'] as int? ?? 0) == 1 ? 0 : 1;
    return await db.update('truths', {'isFavorite': newFavoriteStatus}, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getCustomTruths() async {
    Database db = await database;
    List<Map<String, dynamic>> customTruths = await db.query('truths', where: 'isCustom = ?', whereArgs: [1]);
    print("Custom truths: $customTruths"); // Add this line
    return customTruths;
  }

  Future<int> updateTruth(int id, String text, String category) async {
    Database db = await database;
    return await db.update(
      'truths',
      {'text': text, 'category': category},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteTruth(int id) async {
    Database db = await database;
    return await db.delete('truths', where: 'id = ?', whereArgs: [id]);
  }
}

// Initial truths list
const List<Map<String, String>> initialTruths = [
  {"text": "You are breathing. Your body knows how to do this automatically.", "category": "Mindfulness"},
  {"text": "Gravity is holding you in place, wherever you are.", "category": "Mindfulness"},
  {"text": "Your body is constantly working to maintain balance and health.", "category": "Self-care"},
  {"text": "You have the ability to focus your attention on different things.", "category": "Mindfulness"},
  {"text": "Your breath can be a powerful tool for calming your mind.", "category": "Mindfulness"},
  {"text": "You are resilient. You've overcome challenges before.", "category": "Motivation"},
  {"text": "Your feelings are valid, even if they're uncomfortable.", "category": "Self-care"},
  {"text": "You are more than just your thoughts and emotions.", "category": "Mindfulness"},
  {"text": "This moment is unique. It has never happened before and never will again.", "category": "Mindfulness"},
  {"text": "You have control over your actions, even if you can't control your thoughts.", "category": "Motivation"},
  {"text": "Your body responds to your mind, and your mind responds to your body.", "category": "Mindfulness"},
  {"text": "You are always changing and growing, even when you can't see it.", "category": "Motivation"},
  {"text": "Your presence matters. You impact the world around you.", "category": "Motivation"},
  {"text": "You have the capacity to learn and adapt to new situations.", "category": "Motivation"},
  {"text": "Your experiences are uniquely yours. No one else sees the world exactly as you do.", "category": "Mindfulness"},
  {"text": "You have survived 100% of your worst days so far.", "category": "Motivation"},
  {"text": "Your body is always trying to communicate with you through sensations.", "category": "Self-care"},
  {"text": "You have the power to choose your response to any situation.", "category": "Motivation"},
  {"text": "Your mind is capable of incredible things, including overcoming this moment.", "category": "Motivation"},
  {"text": "You are connected to the world around you, even when you feel alone.", "category": "Mindfulness"},
  {"text": "Your past does not define your future. You can always take a new path.", "category": "Motivation"},
  {"text": "You have inner strength that you can draw upon in difficult times.", "category": "Motivation"},
  {"text": "Your feelings are like weather - they pass and change over time.", "category": "Mindfulness"},
  {"text": "You are worthy of compassion, especially from yourself.", "category": "Self-care"},
  {"text": "Your brain is plastic, meaning it can change and adapt throughout your life.", "category": "Motivation"},
  {"text": "You have the ability to create meaning in your life.", "category": "Motivation"},
  {"text": "Your attention is yours to direct. You can choose what to focus on.", "category": "Mindfulness"},
  {"text": "You are separate from your anxiety. It is something you experience, not who you are.", "category": "Mindfulness"},
  {"text": "Your body is always in the present moment, even when your mind wanders.", "category": "Mindfulness"},
  {"text": "You have overcome every obstacle life has thrown at you so far.", "category": "Motivation"},
  {"text": "Your experience is valid, even if others don't understand it.", "category": "Self-care"},
  {"text": "You have the capacity for joy and peace, even if you don't feel it right now.", "category": "Motivation"},
  {"text": "Your thoughts are not facts. They are mental events that come and go.", "category": "Mindfulness"},
  {"text": "You are more than the sum of your experiences.", "category": "Motivation"},
  {"text": "Your breath is a constant companion, always there to ground you.", "category": "Mindfulness"},
  {"text": "You have the ability to grow from difficult experiences.", "category": "Motivation"},
  {"text": "Your perception shapes your reality, and you can work on changing your perceptions.", "category": "Mindfulness"},
  {"text": "You are not alone in your struggles. Many others have felt similar things.", "category": "Self-care"},
  {"text": "Your body has innate wisdom. It knows how to heal and repair itself.", "category": "Self-care"},
  {"text": "You have the power to set boundaries and protect your well-being.", "category": "Self-care"},
  {"text": "Your mind can be a powerful ally when you learn to work with it.", "category": "Mindfulness"},
  {"text": "You are capable of change and growth at any age.", "category": "Motivation"},
  {"text": "Your feelings are information, not commands. You can acknowledge them without being controlled by them.", "category": "Mindfulness"},
  {"text": "You have survived every panic attack or anxious moment you've ever had.", "category": "Motivation"},
  {"text": "Your breath is always with you, a tool you can use anytime, anywhere.", "category": "Mindfulness"},
  {"text": "You are more than your achievements or failures.", "category": "Self-care"},
  {"text": "Your nervous system is adaptable and can learn to be calmer over time.", "category": "Self-care"},
  {"text": "You have the right to take up space in the world.", "category": "Self-care"},
  {"text": "Your ability to be aware of your thoughts and feelings is a powerful tool.", "category": "Mindfulness"},
  {"text": "You are constantly supported by the world around you, from the air you breathe to the ground beneath you.", "category": "Mindfulness"},
  {"text": "Your future is not predetermined. You have the power to shape it.", "category": "Motivation"},
  {"text": "You are deserving of patience and understanding, especially from yourself.", "category": "Self-care"},
];

DatabaseHelper getDatabaseHelper() {
  return DatabaseHelper();
}