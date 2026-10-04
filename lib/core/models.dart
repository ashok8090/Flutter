class Topic {
  Topic({
    required this.id,
    required this.title,
    required this.description,
    required this.position,
    required this.pramanCount,
    required this.granthCount,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String description;
  final int position;
  final int pramanCount;
  final int granthCount;
  final String createdAt;

  factory Topic.fromApi(Map<String, dynamic> raw) => Topic(
        id: "${raw["id"] ?? ""}",
        title: "${raw["title"] ?? ""}",
        description: "${raw["description"] ?? ""}",
        position: int.tryParse("${raw["position"]}") ?? 0,
        pramanCount: int.tryParse("${raw["praman_count"]}") ?? 0,
        granthCount: int.tryParse("${raw["granth_count"]}") ?? 0,
        createdAt: "${raw["created_at"] ?? ""}",
      );

  Map<String, Object?> toRow() => {
        "id": id,
        "title": title,
        "description": description,
        "position": position,
        "praman_count": pramanCount,
        "granth_count": granthCount,
        "created_at": createdAt,
      };

  factory Topic.fromRow(Map<String, Object?> row) => Topic(
        id: "${row["id"]}",
        title: "${row["title"] ?? ""}",
        description: "${row["description"] ?? ""}",
        position: (row["position"] as int?) ?? 0,
        pramanCount: (row["praman_count"] as int?) ?? 0,
        granthCount: (row["granth_count"] as int?) ?? 0,
        createdAt: "${row["created_at"] ?? ""}",
      );
}

class Granth {
  Granth({
    required this.id,
    required this.title,
    required this.author,
    required this.granthUrl,
    required this.description,
    required this.imagePath,
    required this.editorImagePath,
    required this.position,
    required this.pramanCount,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String author;
  final String granthUrl;
  final String description;
  final String imagePath;
  final String editorImagePath;
  final int position;
  final int pramanCount;
  final String createdAt;

  bool get hasRemotePdf => granthUrl.startsWith("http://") || granthUrl.startsWith("https://");

  factory Granth.fromApi(Map<String, dynamic> raw) => Granth(
        id: "${raw["id"] ?? ""}",
        title: "${raw["title"] ?? ""}",
        author: "${raw["author"] ?? ""}",
        granthUrl: "${raw["granthURL"] ?? ""}",
        description: "${raw["description"] ?? ""}",
        imagePath: "${raw["imagePath"] ?? ""}",
        editorImagePath: "${raw["editorImagePath"] ?? ""}",
        position: int.tryParse("${raw["position"]}") ?? 0,
        pramanCount: int.tryParse("${raw["pramanCount"]}") ?? 0,
        createdAt: "${raw["created_at"] ?? ""}",
      );

  Map<String, Object?> toRow() => {
        "id": id,
        "title": title,
        "author": author,
        "granth_url": granthUrl,
        "description": description,
        "image_path": imagePath,
        "editor_image_path": editorImagePath,
        "position": position,
        "praman_count": pramanCount,
        "created_at": createdAt,
      };

  factory Granth.fromRow(Map<String, Object?> row) => Granth(
        id: "${row["id"]}",
        title: "${row["title"] ?? ""}",
        author: "${row["author"] ?? ""}",
        granthUrl: "${row["granth_url"] ?? ""}",
        description: "${row["description"] ?? ""}",
        imagePath: "${row["image_path"] ?? ""}",
        editorImagePath: "${row["editor_image_path"] ?? ""}",
        position: (row["position"] as int?) ?? 0,
        pramanCount: (row["praman_count"] as int?) ?? 0,
        createdAt: "${row["created_at"] ?? ""}",
      );
}

class Pramaan {
  Pramaan({
    required this.id,
    required this.title,
    required this.description,
    required this.topicId,
    required this.granthId,
    required this.pageNumber,
    required this.chapterNumber,
    required this.imagePath,
    required this.topicTitle,
    required this.granthTitle,
    required this.granthImage,
    required this.editorImagePath,
    required this.granthAuthor,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String description;
  final String topicId;
  final String granthId;
  final int pageNumber;
  final int chapterNumber;
  final String imagePath;
  final String topicTitle;
  final String granthTitle;
  final String granthImage;
  final String editorImagePath;
  final String granthAuthor;
  final String createdAt;

  factory Pramaan.fromApi(Map<String, dynamic> raw) {
    final youtube = "${raw["youtube_url"] ?? ""}".trim();
    if (youtube.isNotEmpty) return Pramaan.empty();
    return Pramaan(
      id: "${raw["id"] ?? ""}",
      title: "${raw["title"] ?? ""}",
      description: "${raw["description"] ?? ""}",
      topicId: "${raw["topic_id"] ?? ""}",
      granthId: "${raw["granth_id"] ?? ""}",
      pageNumber: int.tryParse("${raw["pageNumber"]}") ?? 0,
      chapterNumber: int.tryParse("${raw["chapterNumber"]}") ?? 0,
      imagePath: "${raw["image_path"] ?? ""}",
      topicTitle: "${raw["topic_title"] ?? ""}",
      granthTitle: "${raw["granth_title"] ?? ""}",
      granthImage: "${raw["granth_image"] ?? ""}",
      editorImagePath: "${raw["editorImagePath"] ?? ""}",
      granthAuthor: "${raw["granth_auther"] ?? raw["granth_author"] ?? ""}",
      createdAt: "${raw["created_at"] ?? ""}",
    );
  }

  factory Pramaan.empty() => Pramaan(
        id: "",
        title: "",
        description: "",
        topicId: "",
        granthId: "",
        pageNumber: 0,
        chapterNumber: 0,
        imagePath: "",
        topicTitle: "",
        granthTitle: "",
        granthImage: "",
        editorImagePath: "",
        granthAuthor: "",
        createdAt: "",
      );

  Map<String, Object?> toRow() => {
        "id": id,
        "title": title,
        "description": description,
        "topic_id": topicId,
        "granth_id": granthId,
        "page_number": pageNumber,
        "chapter_number": chapterNumber,
        "image_path": imagePath,
        "topic_title": topicTitle,
        "granth_title": granthTitle,
        "granth_image": granthImage,
        "editor_image_path": editorImagePath,
        "granth_author": granthAuthor,
        "created_at": createdAt,
      };

  factory Pramaan.fromRow(Map<String, Object?> row) => Pramaan(
        id: "${row["id"]}",
        title: "${row["title"] ?? ""}",
        description: "${row["description"] ?? ""}",
        topicId: "${row["topic_id"] ?? ""}",
        granthId: "${row["granth_id"] ?? ""}",
        pageNumber: (row["page_number"] as int?) ?? 0,
        chapterNumber: (row["chapter_number"] as int?) ?? 0,
        imagePath: "${row["image_path"] ?? ""}",
        topicTitle: "${row["topic_title"] ?? ""}",
        granthTitle: "${row["granth_title"] ?? ""}",
        granthImage: "${row["granth_image"] ?? ""}",
        editorImagePath: "${row["editor_image_path"] ?? ""}",
        granthAuthor: "${row["granth_author"] ?? ""}",
        createdAt: "${row["created_at"] ?? ""}",
      );
}

bool isKabirSagar(String title, [String? id]) {
  if (id == "7") return true;
  return title.contains("कबीर सागर");
}

List<Pramaan> sortPramaans(List<Pramaan> list, {String? granthId, String? granthTitle}) {
  final kabir = (granthId != null && isKabirSagar("", granthId)) ||
      (granthTitle != null && isKabirSagar(granthTitle)) ||
      (list.isNotEmpty && list.every((p) => isKabirSagar(p.granthTitle, p.granthId)));
  final copy = [...list];
  copy.sort((a, b) {
    if (kabir && a.chapterNumber != b.chapterNumber) return a.chapterNumber.compareTo(b.chapterNumber);
    if (a.pageNumber != b.pageNumber) return a.pageNumber.compareTo(b.pageNumber);
    return (int.tryParse(a.id) ?? 0).compareTo(int.tryParse(b.id) ?? 0);
  });
  return copy;
}

String safeFileBase(String title) {
  final cleaned = title.replaceAll(RegExp(r"[^\p{L}\p{N}]+", unicode: true), "_").replaceAll(RegExp(r"^_+|_+$"), "");
  final cut = cleaned.length > 80 ? cleaned.substring(0, 80) : cleaned;
  return cut.isEmpty ? "Granth" : cut;
}

String? safeMediaPath(String? raw) {
  if (raw == null) return null;
  var path = raw.trim();
  if (path.isEmpty) return null;
  if (path.startsWith("http://") || path.startsWith("https://")) {
    final uri = Uri.tryParse(path);
    if (uri == null) return null;
    path = uri.path.replaceFirst(RegExp(r"^/+"), "");
  }
  path = path.replaceFirst(RegExp(r"^/+"), "");
  if (path.contains("..") || path.contains("\\")) return null;
  if (!path.startsWith("granths/") && !path.startsWith("uploads/")) return null;
  return path;
}

String? remoteMediaUrl(String? raw) {
  final path = safeMediaPath(raw);
  if (path == null) return null;
  return "https://granth.wnmsolutions.com/$path";
}
