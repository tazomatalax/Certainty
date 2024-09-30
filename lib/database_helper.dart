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
      version: 2,
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
        isFavorite INTEGER DEFAULT 0
      )
    ''');
    
    // Insert initial truths
    for (String truth in initialTruths) {
      await db.insert('truths', {'text': truth, 'isUserGenerated': 0, 'isFavorite': 0});
    }
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add the isFavorite column if it doesn't exist
      await db.execute('ALTER TABLE truths ADD COLUMN isFavorite INTEGER DEFAULT 0');
    }
  }

  Future<List<Map<String, dynamic>>> getTruths() async {
    Database db = await database;
    return await db.query('truths');
  }

  Future<List<Map<String, dynamic>>> getFavoriteTruths() async {
    Database db = await database;
    return await db.query('truths', where: 'isFavorite = ?', whereArgs: [1]);
  }

  Future<int> insertTruth(String text) async {
    Database db = await database;
    return await db.insert('truths', {'text': text, 'isUserGenerated': 1, 'isFavorite': 0});
  }

  Future<int> toggleFavorite(int id) async {
    Database db = await database;
    var truth = await db.query('truths', where: 'id = ?', whereArgs: [id]);
    int newFavoriteStatus = (truth.first['isFavorite'] as int? ?? 0) == 1 ? 0 : 1;
    return await db.update('truths', {'isFavorite': newFavoriteStatus}, where: 'id = ?', whereArgs: [id]);
  }
}

// Initial truths list
const List<String> initialTruths = [
  "You are breathing. Your body knows how to do this automatically.",
  "Gravity is holding you in place, wherever you are.",
  "Your body is constantly working to maintain balance and health.",
  "You have the ability to focus your attention on different things.",
  "Your breath can be a powerful tool for calming your mind.",
  "You are resilient. You've overcome challenges before.",
  "Your feelings are valid, even if they're uncomfortable.",
  "You are more than just your thoughts and emotions.",
  "This moment is unique. It has never happened before and never will again.",
  "You have control over your actions, even if you can't control your thoughts.",
  "Your body responds to your mind, and your mind responds to your body.",
  "You are always changing and growing, even when you can't see it.",
  "Your presence matters. You impact the world around you.",
  "You have the capacity to learn and adapt to new situations.",
  "Your experiences are uniquely yours. No one else sees the world exactly as you do.",
  "You have survived 100% of your worst days so far.",
  "Your body is always trying to communicate with you through sensations.",
  "You have the power to choose your response to any situation.",
  "Your mind is capable of incredible things, including overcoming this moment.",
  "You are connected to the world around you, even when you feel alone.",
  "Your past does not define your future. You can always take a new path.",
  "You have inner strength that you can draw upon in difficult times.",
  "Your feelings are like weather - they pass and change over time.",
  "You are worthy of compassion, especially from yourself.",
  "Your brain is plastic, meaning it can change and adapt throughout your life.",
  "You have the ability to create meaning in your life.",
  "Your attention is yours to direct. You can choose what to focus on.",
  "You are separate from your anxiety. It is something you experience, not who you are.",
  "Your body is always in the present moment, even when your mind wanders.",
  "You have overcome every obstacle life has thrown at you so far.",
  "Your experience is valid, even if others don't understand it.",
  "You have the capacity for joy and peace, even if you don't feel it right now.",
  "Your thoughts are not facts. They are mental events that come and go.",
  "You are more than the sum of your experiences.",
  "Your breath is a constant companion, always there to ground you.",
  "You have the ability to grow from difficult experiences.",
  "Your perception shapes your reality, and you can work on changing your perceptions.",
  "You are not alone in your struggles. Many others have felt similar things.",
  "Your body has innate wisdom. It knows how to heal and repair itself.",
  "You have the power to set boundaries and protect your well-being.",
  "Your mind can be a powerful ally when you learn to work with it.",
  "You are capable of change and growth at any age.",
  "Your feelings are information, not commands. You can acknowledge them without being controlled by them.",
  "You have survived every panic attack or anxious moment you've ever had.",
  "Your breath is always with you, a tool you can use anytime, anywhere.",
  "You are more than your achievements or failures.",
  "Your nervous system is adaptable and can learn to be calmer over time.",
  "You have the right to take up space in the world.",
  "Your ability to be aware of your thoughts and feelings is a powerful tool.",
  "You are constantly supported by the world around you, from the air you breathe to the ground beneath you.",
  "Your future is not predetermined. You have the power to shape it.",
  "You are deserving of patience and understanding, especially from yourself.",
  // ... add all your initial truths here
];

DatabaseHelper getDatabaseHelper() {
  return DatabaseHelper();
}
