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
      db.execute(
          "create table event(id         text constraint event_pk primary key,pubkey     text,created_at integer,kind       integer,tags       text,content    text);");
      db.execute(
          "create index event_date_index    on event (kind, created_at);");
      db.execute(
          "create index event_pubkey_index    on event (kind, pubkey, created_at);");
      db.execute(
          "create table dm_session_info(pubkey      text    not null constraint dm_session_info_pk primary key,readed_time integer not null,value1      text,value2      text,value3      text);");
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
