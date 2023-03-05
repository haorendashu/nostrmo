import 'package:nostrmo/data/metadata.dart';
import 'package:sqflite/sqflite.dart';

import 'db.dart';

class MetadataDB {
  static Future<Metadata?> get(int pubKey, {DatabaseExecutor? db}) async {
    db = await DB.getDB(db);
    var list =
        await db.query("metadata", where: "pub_key = ?", whereArgs: [pubKey]);
    if (list.isNotEmpty) {
      return Metadata.fromJson(list[0]);
    }
  }

  static Future<int> insert(Metadata o, {DatabaseExecutor? db}) async {
    db = await DB.getDB(db);
    return await db.insert("metadata", o.toJson());
  }

  static Future update(Metadata o, {DatabaseExecutor? db}) async {
    db = await DB.getDB(db);
    await db.update("metadata", o.toJson(),
        where: "pub_key = ?", whereArgs: [o.pubKey]);
  }
}
