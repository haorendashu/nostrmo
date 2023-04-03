import 'package:nostrmo/data/metadata.dart';
import 'package:sqflite/sqflite.dart';

import 'db.dart';

class MetadataDB {
  static Future<List<Metadata>> all({DatabaseExecutor? db}) async {
    List<Metadata> objs = [];
    Database db = await DB.getCurrentDatabase();
    List<Map<String, dynamic>> list =
        await db.rawQuery("select * from metadata");
    for (var i = 0; i < list.length; i++) {
      var json = list[i];
      objs.add(Metadata.fromJson(json));
    }
    return objs;
  }

  static Future<Metadata?> get(String pubKey, {DatabaseExecutor? db}) async {
    db = await DB.getDB(db);
    var list =
        await db.query("metadata", where: "pub_key = ?", whereArgs: [pubKey]);
    if (list.isNotEmpty) {
      return Metadata.fromJson(list[0]);
    }
  }

  static Future<int> insert(Metadata o, {DatabaseExecutor? db}) async {
    db = await DB.getDB(db);
    return await db.insert("metadata", o.toFullJson());
  }

  static Future update(Metadata o, {DatabaseExecutor? db}) async {
    db = await DB.getDB(db);
    await db.update("metadata", o.toJson(),
        where: "pub_key = ?", whereArgs: [o.pubKey]);
  }

  static Future<void> deleteAll({DatabaseExecutor? db}) async {
    db = await DB.getDB(db);
    db.execute("delete from metadata");
  }
}
