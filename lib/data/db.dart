import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DB {
  static const _VERSION = 1;

  static const _dbName = "nostrmo.db";

  static Database? _database;

  static init() async {
    var databasesPath = await getDatabasesPath();

    String path = join(databasesPath, _dbName);

    _database = await openDatabase(path, version: _VERSION,
        onCreate: (Database db, int version) async {
      // init db
      db.execute(
          "create table metadata(pub_key      TEXT not null primary key,banner       TEXT,website      TEXT,lud16        TEXT,lud06        TEXT,nip05        TEXT,picture      TEXT,display_name TEXT,about        TEXT,name         TEXT,updated_at   datetime);");
    });
  }

  static Future<Database> getCurrentDatabase() async {
    if (_database == null) {
      await init();
    }
    return _database!;
  }

  static Future<DatabaseExecutor> getDB(DatabaseExecutor? db) async {
    if (db != null) {
      return db;
    }
    return getCurrentDatabase();
  }

  static void close() {
    _database?.close();
    _database = null;
  }
}
