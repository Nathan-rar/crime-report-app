import 'dart:typed_data';

import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

class LocalImageStore {
  LocalImageStore._();

  static final LocalImageStore instance = LocalImageStore._();
  static const scheme = 'sqlite-image';

  Database? _database;

  Future<String> saveImage({
    required String ownerType,
    required String ownerId,
    required String fileName,
    required String contentType,
    required Uint8List bytes,
  }) async {
    final db = await _openDatabase();
    final id = '$scheme://$ownerType/$ownerId';
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.insert('images', {
      'id': id,
      'ownerType': ownerType,
      'ownerId': ownerId,
      'fileName': fileName,
      'contentType': contentType,
      'bytes': bytes,
      'updatedAt': now,
      'createdAt': now,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    return id;
  }

  Future<Uint8List?> readImage(String? id) async {
    if (!isLocalImageRef(id)) {
      return null;
    }

    final db = await _openDatabase();
    final rows = await db.query(
      'images',
      columns: ['bytes'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return rows.first['bytes'] as Uint8List?;
  }

  Future<void> deleteImage(String? id) async {
    if (!isLocalImageRef(id)) {
      return;
    }

    final db = await _openDatabase();
    await db.delete('images', where: 'id = ?', whereArgs: [id]);
  }

  bool isLocalImageRef(String? value) {
    return value != null && value.startsWith('$scheme://');
  }

  Future<Database> _openDatabase() async {
    final database = _database;
    if (database != null) {
      return database;
    }

    final databasesPath = await getDatabasesPath();
    final databasePath = path.join(databasesPath, 'crime_report_images.db');
    return _database = await openDatabase(
      databasePath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE images (
            id TEXT PRIMARY KEY,
            ownerType TEXT NOT NULL,
            ownerId TEXT NOT NULL,
            fileName TEXT NOT NULL,
            contentType TEXT NOT NULL,
            bytes BLOB NOT NULL,
            createdAt INTEGER NOT NULL,
            updatedAt INTEGER NOT NULL
          )
        ''');
        await db.execute(
          'CREATE INDEX images_owner_idx ON images(ownerType, ownerId)',
        );
      },
    );
  }
}
