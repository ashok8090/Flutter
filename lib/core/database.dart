import "package:path/path.dart" as p;
import "package:sqflite/sqflite.dart";

class AppDatabase {
  AppDatabase(this.db);
  final Database db;

  static Future<AppDatabase> open() async {
    final dir = await getDatabasesPath();
    final db = await openDatabase(
      p.join(dir, "granth.db"),
      version: 1,
      onCreate: (db, version) async {
        await db.execute("""
          CREATE TABLE topics (
            id TEXT PRIMARY KEY,
            title TEXT,
            description TEXT,
            position INTEGER,
            praman_count INTEGER,
            granth_count INTEGER,
            created_at TEXT
          )
        """);
        await db.execute("""
          CREATE TABLE granths (
            id TEXT PRIMARY KEY,
            title TEXT,
            author TEXT,
            granth_url TEXT,
            description TEXT,
            image_path TEXT,
            editor_image_path TEXT,
            position INTEGER,
            praman_count INTEGER,
            created_at TEXT
          )
        """);
        await db.execute("""
          CREATE TABLE pramaans (
            id TEXT PRIMARY KEY,
            title TEXT,
            description TEXT,
            topic_id TEXT,
            granth_id TEXT,
            page_number INTEGER,
            chapter_number INTEGER,
            image_path TEXT,
            topic_title TEXT,
            granth_title TEXT,
            granth_image TEXT,
            editor_image_path TEXT,
            granth_author TEXT,
            created_at TEXT
          )
        """);
        await db.execute("CREATE INDEX idx_pramaan_granth ON pramaans(granth_id, page_number)");
        await db.execute("CREATE INDEX idx_pramaan_topic ON pramaans(topic_id, page_number)");
        await db.execute("CREATE TABLE sync_meta (key TEXT PRIMARY KEY, value TEXT)");
        await db.execute("""
          CREATE TABLE files (
            remote_url TEXT PRIMARY KEY,
            local_path TEXT,
            bytes INTEGER,
            updated_at TEXT
          )
        """);
        await db.execute("""
          CREATE TABLE pdf_jobs (
            id TEXT PRIMARY KEY,
            name TEXT,
            status TEXT,
            pages_done INTEGER,
            pages_total INTEGER,
            file_path TEXT,
            error TEXT,
            updated_at TEXT
          )
        """);
      },
    );
    return AppDatabase(db);
  }

  Future<void> replaceAll({
    required List<Map<String, Object?>> topics,
    required List<Map<String, Object?>> granths,
    required List<Map<String, Object?>> pramaans,
    required String fetchedAt,
  }) async {
    await db.transaction((txn) async {
      final batch = txn.batch();
      batch.delete("topics");
      batch.delete("granths");
      batch.delete("pramaans");
      for (final row in topics) {
        batch.insert("topics", row);
      }
      for (final row in granths) {
        batch.insert("granths", row);
      }
      for (final row in pramaans) {
        batch.insert("pramaans", row);
      }
      batch.insert("sync_meta", {"key": "fetched_at", "value": fetchedAt}, conflictAlgorithm: ConflictAlgorithm.replace);
      await batch.commit(noResult: true);
    });
  }

  Future<String?> meta(String key) async {
    final rows = await db.query("sync_meta", where: "key = ?", whereArgs: [key], limit: 1);
    if (rows.isEmpty) return null;
    return rows.first["value"] as String?;
  }
}
