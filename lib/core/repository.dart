import "package:connectivity_plus/connectivity_plus.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "api.dart";
import "database.dart";
import "models.dart";

final databaseProvider = Provider<AppDatabase>((ref) => throw UnimplementedError("database override"));

final repoProvider = Provider<CatalogRepository>((ref) => CatalogRepository(ref.watch(databaseProvider), ApiService()));

class CatalogRepository {
  CatalogRepository(this.database, this.api);
  final AppDatabase database;
  final ApiService api;

  Future<List<Topic>> topics() async {
    final rows = await database.db.query("topics", orderBy: "position ASC, CAST(id AS INTEGER) ASC");
    return rows.map(Topic.fromRow).toList();
  }

  Future<List<Granth>> granths() async {
    final rows = await database.db.query("granths", orderBy: "position ASC, CAST(id AS INTEGER) ASC");
    return rows.map(Granth.fromRow).toList();
  }

  Future<List<Pramaan>> pramaans({String? granthId, String? topicId, String? id}) async {
    String? where;
    List<Object?>? args;
    if (id != null) {
      where = "id = ?";
      args = [id];
    } else if (granthId != null) {
      where = "granth_id = ?";
      args = [granthId];
    } else if (topicId != null) {
      where = "topic_id = ?";
      args = [topicId];
    }
    final rows = await database.db.query("pramaans", where: where, whereArgs: args);
    return sortPramaans(rows.map(Pramaan.fromRow).toList(), granthId: granthId);
  }

  Future<Topic?> topic(String id) async {
    final rows = await database.db.query("topics", where: "id = ?", whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return Topic.fromRow(rows.first);
  }

  Future<Granth?> granth(String id) async {
    final rows = await database.db.query("granths", where: "id = ?", whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return Granth.fromRow(rows.first);
  }

  Future<String?> syncedAt() => database.meta("fetched_at");

  /// Keeps the previous local catalog if the network or API fails.
  Future<bool> sync() async {
    final link = await Connectivity().checkConnectivity();
    if (link.every((item) => item == ConnectivityResult.none)) return false;
    try {
      final results = await Future.wait([api.topics(), api.granths(), api.pramaans()]);
      final topics = results[0] as List<Topic>;
      final granths = results[1] as List<Granth>;
      final pramaans = results[2] as List<Pramaan>;
      await database.replaceAll(
        topics: topics.map((t) => t.toRow()).toList(),
        granths: granths.map((g) => g.toRow()).toList(),
        pramaans: pramaans.map((p) => p.toRow()).toList(),
        fetchedAt: DateTime.now().toIso8601String(),
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}

final catalogProvider = AsyncNotifierProvider<CatalogController, CatalogSnapshot>(CatalogController.new);

class CatalogSnapshot {
  const CatalogSnapshot({
    required this.topics,
    required this.granths,
    required this.offline,
    required this.syncedAt,
  });
  final List<Topic> topics;
  final List<Granth> granths;
  final bool offline;
  final String? syncedAt;
}

class CatalogController extends AsyncNotifier<CatalogSnapshot> {
  @override
  Future<CatalogSnapshot> build() async {
    final repo = ref.read(repoProvider);
    final local = await _read(repo, offline: false);
    Future<void>(() async {
      final ok = await repo.sync();
      final next = await _read(repo, offline: !ok && local.topics.isEmpty == false && (await repo.syncedAt()) != null && !ok);
      state = AsyncData(next);
    });
    return local;
  }

  Future<void> refresh() async {
    final repo = ref.read(repoProvider);
    final ok = await repo.sync();
    state = AsyncData(await _read(repo, offline: !ok));
  }

  Future<CatalogSnapshot> _read(CatalogRepository repo, {required bool offline}) async {
    return CatalogSnapshot(
      topics: await repo.topics(),
      granths: await repo.granths(),
      offline: offline,
      syncedAt: await repo.syncedAt(),
    );
  }
}
