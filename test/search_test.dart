import "package:flutter_test/flutter_test.dart";
import "package:granth/core/models.dart";
import "package:granth/core/search.dart";

void main() {
  final docs = [
    SearchDoc(id: "1", title: "मांस खाने वाले को नरक"),
    SearchDoc(id: "2", title: "गुरु की महिमा"),
    SearchDoc(id: "3", title: "गीता अध्याय 5"),
  ];

  List<String> ids(String q) => rankSearch(q, docs, (d) => d).map((d) => d.id).toList();

  test("hindi english hinglish meat and guru", () {
    expect(ids("मांस"), ["1"]);
    expect(ids("mans"), ["1"]);
    expect(ids("maans"), ["1"]);
    expect(ids("maas"), ["1"]);
    expect(ids("गुरु"), ["2"]);
    expect(ids("guru"), ["2"]);
    expect(ids("gur"), ["2"]);
  });

  test("kabir sagar sorts by chapter then page", () {
    final list = [
      Pramaan.fromRow({"id": "2", "title": "b", "page_number": 1, "chapter_number": 3, "granth_id": "7", "granth_title": "कबीर सागर"}),
      Pramaan.fromRow({"id": "1", "title": "a", "page_number": 9, "chapter_number": 1, "granth_id": "7", "granth_title": "कबीर सागर"}),
    ];
    final sorted = sortPramaans(list, granthId: "7");
    expect(sorted.map((p) => p.id).toList(), ["1", "2"]);
  });

  test("other granths sort by page", () {
    final list = [
      Pramaan.fromRow({"id": "2", "title": "b", "page_number": 4, "chapter_number": 1, "granth_id": "4", "granth_title": "गीता"}),
      Pramaan.fromRow({"id": "1", "title": "a", "page_number": 2, "chapter_number": 9, "granth_id": "4", "granth_title": "गीता"}),
    ];
    final sorted = sortPramaans(list, granthId: "4", granthTitle: "गीता");
    expect(sorted.first.id, "1");
  });
}
