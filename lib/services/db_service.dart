import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/tag.dart';
import '../models/location_record.dart';

class DbService {
  static final DbService _instance = DbService._internal();
  factory DbService() => _instance;
  DbService._internal();

  static Database?_database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'tailtag.db');

    return await openDatabase(
      path,
      version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE tags (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              deviceId TEXT NOT NULL UNIQUE,
              registeredAt TEXT NOT NULL
            )
          ''');

          await db.execute('''
            CREATE TABLE location_records (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              tagDeviceId TEXT NOT NULL,
              latitude REAL NOT NULL,
              longitude REAL NOT NULL,
              rssi INTEGER NOT NULL,
              detectedAt TEXT NOT NULL
            )
          ''');
      },
    );
  }

  Future<int> insertTag(Tag tag) async {
    final db = await database;
    return await db.insert(
      'tags',
      tag.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Tag>> getAllTags() async {
    final db = await database;
    final maps = await db.query('tags', orderBy: 'registeredAt DESC');
    return maps.map((m) => Tag.fromMap(m)).toList();
  }

  Future<int> deleteTag(String deviceId) async {
    final db = await database;
    return await db.delete('tags', where: 'deviceId = ?', whereArgs: [deviceId]);
  }

  Future<int> insertLocationRecord(LocationRecord record) async {
    final db = await database;
    return await db.insert('location_records', record.toMap());
  }

  // 특정 태그의 마지막 (가장 최근) 위치 기록 조회
  Future<LocationRecord?> getLastLocation(String tagDeviceId) async {
    final db = await database;
    final maps = await db.query(
      'location_records',
      where: 'tagDeviceId = ?',
      whereArgs: [tagDeviceId],
      orderBy: 'detectedAt DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return LocationRecord.fromMap(maps.first);
  }

  // 특정 태그의 전체 위치 기 히스토리 조회 (선택 가능)
  Future<List<LocationRecord>> getLocationHistory(String tagDeviceId) async {
    final db = await database;
    final maps = await db.query(
      'location_records',
      where: 'tagDeviceId = ?',
      whereArgs: [tagDeviceId],
      orderBy: 'detectedAt DESC',
    );
    return maps.map((m) => LocationRecord.fromMap(m)).toList();
  }
}