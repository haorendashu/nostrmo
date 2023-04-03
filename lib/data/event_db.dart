import 'dart:convert';

import 'package:nostr_dart/nostr_dart.dart';
import 'package:nostrmo/util/string_util.dart';
import 'package:sqflite/sqflite.dart';

import 'db.dart';

class EventDB {
  static Future<List<Event>> list(int kind, int skip, limit,
      {DatabaseExecutor? db, String? pubkey}) async {
    db = await DB.getDB(db);
    List<Event> l = [];
    List<dynamic> args = [];

    var sql = "select * from event where kind = ? ";
    args.add(kind);
    if (StringUtil.isNotBlank(pubkey)) {
      sql += " and pubkey = ? ";
      args.add(pubkey);
    }
    sql += " order by created_at desc limit ?, ?";
    args.add(skip);
    args.add(limit);

    List<Map<String, dynamic>> list = await db.rawQuery(sql, args);
    for (var listObj in list) {
      l.add(loadFromJson(listObj));
    }
    return l;
  }

  static Future<int> insert(Event o, {DatabaseExecutor? db}) async {
    db = await DB.getDB(db);
    var jsonObj = o.toJson();
    var tags = jsonEncode(o.tags);
    jsonObj["tags"] = tags;
    jsonObj.remove("sig");
    return await db.insert("event", jsonObj);
  }

  static Future<Event?> get(String id, {DatabaseExecutor? db}) async {
    db = await DB.getDB(db);
    var list = await db.query("event", where: "id = ?", whereArgs: [id]);
    if (list.isNotEmpty) {
      return Event.fromJson(list[0]);
    }
  }

  static Future<void> deleteAll({DatabaseExecutor? db}) async {
    db = await DB.getDB(db);
    db.execute("delete from event");
  }

  static Event loadFromJson(Map<String, dynamic> data) {
    Map<String, dynamic> m = {};
    m.addAll(data);

    var tagsStr = data["tags"];
    var tagsObj = jsonDecode(tagsStr);
    m["tags"] = tagsObj;
    m["sig"] = "";
    return Event.fromJson(m);
  }
}
