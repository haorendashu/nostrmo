import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:nostrmo/util/string_util.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../../util/platform_util.dart';
import '../event.dart';

class RelayLocalDB {
  static const _VERSION = 1;

  static const _dbName = "local_relay.db";

  late Database _database;

  // a eventId map in mem, to avoid alway insert event.
  Map<String, int> _memEventIdMap = {};

  RelayLocalDB._(Database database) {
    _database = database;
  }

  static Future<RelayLocalDB?> init() async {
    var path = await getFilepath();

    var database =
        await openDatabase(path, version: _VERSION, onCreate: _onCreate);

    return RelayLocalDB._(database);
  }

  static Future<String> getFilepath() async {
    String path = _dbName;

    if (!PlatformUtil.isWeb()) {
      var databasesPath = await getDatabasesPath();
      path = join(databasesPath, _dbName);
    }

    return path;
  }

  static Future<int> getDBFileSize() async {
    var path = await getFilepath();
    var file = File(path);
    return await file.length();
  }

  static Future<void> _onCreate(Database db, int version) async {
    // init db
    db.execute(
        "CREATE TABLE IF NOT EXISTS event (id text NOT NULL, pubkey text NOT NULL, created_at integer NOT NULL, kind integer NOT NULL, tags jsonb NOT NULL, content text NOT NULL, sig text NOT NULL, sources text);");
    db.execute("CREATE UNIQUE INDEX IF NOT EXISTS ididx ON event(id)");
    db.execute("CREATE INDEX IF NOT EXISTS pubkeyprefix ON event(pubkey)");
    db.execute("CREATE INDEX IF NOT EXISTS timeidx ON event(created_at DESC)");
    db.execute("CREATE INDEX IF NOT EXISTS kindidx ON event(kind)");
    db.execute(
        "CREATE INDEX IF NOT EXISTS kindtimeidx ON event(kind,created_at DESC)");
  }

  Future<Event?> queryById(String id) async {
    var sql =
        "SELECT id, pubkey, created_at, kind, tags, content, sig, sources FROM event WHERE id = ?";
    List<dynamic> params = [id];
    var rawEvents = await _database.rawQuery(sql, params);
    var events = _loadEventFromRawEvents(rawEvents);
    if (events.isNotEmpty) {
      return events.first;
    }
    return null;
  }

  List<Event> _loadEventFromRawEvents(List<Map<String, Object?>> rawEvents) {
    rawEvents = _handleEventMaps(rawEvents);
    return loadEventFromMaps(rawEvents);
  }

  List<Event> loadEventFromMaps(List<Map<String, Object?>> rawEvents) {
    List<Event> events = [];
    for (var rawEvent in rawEvents) {
      var event = Event.fromJson(rawEvent);
      var sources = rawEvent["sources"];
      if (sources != null && sources is List) {
        for (var source in sources) {
          event.sources.add(source);
        }
      }
      events.add(event);
    }
    return events;
  }

  bool checkAndSetEventFromMem(Map<String, dynamic> event) {
    var id = event["id"];
    var value = _memEventIdMap[id];
    _memEventIdMap[id] = 1;
    return value != null;
  }

  Future<void> deleteEvent(String pubkey, String id) async {
    var sql = "delete from event where id = ? and pubkey = ?";
    await _database.execute(sql, [id, pubkey]);
  }

  Future<int> addEvent(Map<String, dynamic> event) async {
    if (checkAndSetEventFromMem(event)) {
      return 0;
    }

    event = Map.from(event);
    var tags = event["tags"];
    if (tags != null) {
      var tagsStr = jsonEncode(tags);
      event["tags"] = tagsStr;
    }
    var sources = event["sources"];
    if (sources != null) {
      var sourcesStr = jsonEncode(sources);
      event["sources"] = sourcesStr;
    }
    try {
      return await _database.insert("event", event);
    } catch (e) {
      // print(e);
      return 0;
    }
  }

  String makePlaceHolders(int n) {
    if (n == 1) {
      return "?";
    }

    return "${List.filled(n - 1, "?").join(",")},?";
  }

  Future<List<Map<String, Object?>>> doQueryEvent(
      Map<String, dynamic> filter) async {
    List<dynamic> params = [];
    var sql = queryEventsSql(filter, false, params);
    var rawEvents = await _database.rawQuery(sql, params);
    var events = _handleEventMaps(rawEvents);
    return events;
  }

  Future<int?> doQueryCount(Map<String, dynamic> filter) async {
    List<dynamic> params = [];
    var sql = queryEventsSql(filter, true, params);
    return Sqflite.firstIntValue(await _database.rawQuery(sql, params));
  }

  String queryEventsSql(
      Map<String, dynamic> filter, bool doCount, List<dynamic> params) {
    List<String> conditions = [];

    // clone filter, due to filter will be change download.
    filter = Map<String, dynamic>.from(filter);

    var key = "ids";
    if (filter[key] != null && filter[key] is List && filter[key].isNotEmpty) {
      for (var id in filter[key]) {
        params.add(id);
      }

      conditions.add("id IN(${makePlaceHolders(filter[key]!.length)})");

      filter.remove(key);
    }

    key = "authors";
    if (filter[key] != null && filter[key] is List && filter[key]!.isNotEmpty) {
      for (var author in filter[key]!) {
        params.add(author);
      }

      conditions.add("pubkey IN(${makePlaceHolders(filter[key]!.length)})");

      filter.remove(key);
    }

    key = "kinds";
    if (filter[key] != null && filter[key] is List && filter[key]!.isNotEmpty) {
      for (var kind in filter[key]!) {
        params.add(kind);
      }

      conditions.add("kind IN(${makePlaceHolders(filter[key]!.length)})");

      filter.remove(key);
    }

    var since = filter.remove("since");
    if (since != null) {
      conditions.add("created_at >= ?");
      params.add(since);
    }

    var until = filter.remove("until");
    if (until != null) {
      conditions.add("created_at <= ?");
      params.add(until);
    }

    var search = filter.remove("search");
    if (search != null && search is String) {
      conditions.add("content LIKE ? ESCAPE '\\'");
      params.add("%${search.replaceAll("%", "\%")}%");
    }

    List<String> tagQuery = [];
    for (var entry in filter.entries) {
      var k = entry.key;
      var v = entry.value;

      if (k != "limit") {
        for (var vItem in v) {
          tagQuery.add("\"${k.replaceFirst("#", "")}\",\"${vItem}");
        }
      }
    }
    for (var tagValue in tagQuery) {
      conditions.add("tags LIKE ? ESCAPE '\\'");
      params.add("%${tagValue.replaceAll("%", "\%")}%");
    }

    if (conditions.isEmpty) {
      // fallback
      conditions.add("true");
    }

    var limit = filter["limit"];
    if (limit != null && limit > 0) {
      params.add(limit);
    } else {
      params.add(100); // This is a default num.
    }

    late String query;
    if (doCount) {
      query =
          " SELECT COUNT(*) FROM event WHERE ${conditions.join(" AND ")} ORDER BY created_at DESC LIMIT ?";
    } else {
      query =
          " SELECT id, pubkey, created_at, kind, tags, content, sig, sources FROM event WHERE ${conditions.join(" AND ")} ORDER BY created_at DESC LIMIT ?";
    }

    // log("sql ${query}");
    // log("params ${jsonEncode(params)}");

    return query;
  }

  Future<List<Map<String, Object?>>> queryEventByPubkey(String pubkey) async {
    var sql =
        "SELECT id, pubkey, created_at, kind, tags, content, sig, sources FROM event WHERE pubkey = ? ORDER BY created_at DESC";
    List<dynamic> params = [pubkey];
    var rawEvents = await _database.rawQuery(sql, params);
    var events = _handleEventMaps(rawEvents);
    return events;
  }

  List<Map<String, Object?>> _handleEventMaps(
      List<Map<String, Object?>> rawEvents) {
    var length = rawEvents.length;
    List<Map<String, Object?>> events = List.filled(length, {});
    for (var i = 0; i < length; i++) {
      var rawEvent = rawEvents[i];
      var event = Map<String, Object?>.from(rawEvent);
      var tagsStr = rawEvent["tags"];
      if (tagsStr is String) {
        event["tags"] = jsonDecode(tagsStr);
      }
      var sourcesStr = rawEvent["sources"];
      if (sourcesStr != null) {
        event["sources"] = jsonDecode(sourcesStr as String);
      }

      events[i] = event;
    }

    return events;
  }

  Map<String, Object?> _handleEventMap(Map<String, Object?> rawEvent) {
    var event = Map<String, Object?>.from(rawEvent);
    var tagsStr = rawEvent["tags"];
    if (tagsStr is String) {
      event["tags"] = jsonDecode(tagsStr);
    }
    var sourcesStr = rawEvent["sources"];
    if (sourcesStr != null) {
      event["sources"] = jsonDecode(sourcesStr as String);
    }

    return event;
  }

  Future<int?> allDataCount() async {
    var sql = "select count(1) from event";
    return Sqflite.firstIntValue(await _database.rawQuery(sql, []));
  }

  Future<void> deleteData({String? pubkey}) async {
    List params = [];
    var sql = "delete from event where 1 = 1";
    if (StringUtil.isNotBlank(pubkey)) {
      sql += " and pubkey <> ?";
      params.add(pubkey);
    }
    await _database.execute(sql, params);
  }
}
