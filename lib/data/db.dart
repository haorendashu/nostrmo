import 'dart:io';

import 'package:nostrmo/util/platform_util.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:process_run/shell_run.dart';

class DB {
  static const _VERSION = 1;

  static const _dbName = "nostrmo.db";

  static Database? _database;

  static init() async {
    String path = _dbName;

    if (!PlatformUtil.isWeb()) {
      var databasesPath = await getDatabasesPath();
      path = join(databasesPath, _dbName);
    }

    try {
      _database = await openDatabase(path, version: _VERSION,
        onCreate: _onCreate);
    } catch (e) {
      if (Platform.isLinux) {
        // maybe it need install sqlite first, but this command need run by root.
        await run('sudo apt-get -y install libsqlite3-0 libsqlite3-dev');
        _database = await openDatabase(path, version: _VERSION,
          onCreate: _onCreate);
      }
    }
  }
  
   static Future<void> _onCreate(Database db, int version) async {
      // init db
      db.execute(
          "create table metadata(pub_key      TEXT not null primary key,banner       TEXT,website      TEXT,lud16        TEXT,lud06        TEXT,nip05        TEXT,picture      TEXT,display_name TEXT,about        TEXT,name         TEXT,updated_at   datetime, valid  INTEGER);");
      db.execute(
          "create table event(key_index  INTEGER, id         text,pubkey     text,created_at integer,kind       integer,tags       text,content    text);");
      db.execute(
          "create unique index event_key_index_id_uindex on event (key_index, id);");
      db.execute(
          "create index event_date_index    on event (key_index, kind, created_at);");
      db.execute(
          "create index event_pubkey_index    on event (key_index, kind, pubkey, created_at);");
      db.execute(
          "create table dm_session_info(key_index  INTEGER, pubkey      text    not null,readed_time integer not null,value1      text,value2      text,value3      text);");
      db.execute(
          "create unique index dm_session_info_uindex on dm_session_info (key_index, pubkey);");
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
