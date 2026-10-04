import "dart:async";
import "dart:io";

import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:http/http.dart" as http;
import "package:path/path.dart" as p;
import "package:path_provider/path_provider.dart";
import "package:pdf/pdf.dart";
import "package:pdf/widgets.dart" as pw;
import "package:share_plus/share_plus.dart";

import "models.dart";

enum PdfScale { ninety, mool }

enum PdfJobStatus { queued, running, completed, failed, cancelled }

class PdfJob {
  PdfJob({
    required this.id,
    required this.name,
    required this.scale,
    required this.status,
    required this.stage,
    required this.pagesDone,
    required this.pagesTotal,
    required this.updatedAt,
    this.startedAt,
    this.filePath,
    this.error,
  });

  final String id;
  final String name;
  final PdfScale scale;
  final PdfJobStatus status;
  final String stage;
  final int pagesDone;
  final int pagesTotal;
  final DateTime updatedAt;
  final DateTime? startedAt;
  final String? filePath;
  final String? error;

  double get fraction => pagesTotal == 0 ? 0 : pagesDone / pagesTotal;

  String get eta {
    if (status == PdfJobStatus.completed) return "पूर्ण";
    if (status == PdfJobStatus.failed) return "असफल";
    if (status == PdfJobStatus.cancelled) return "रद्द";
    final start = startedAt;
    if (start == null || pagesDone < 1) return "Calculating...";
    final elapsed = DateTime.now().difference(start).inMilliseconds;
    final leftMs = ((pagesTotal - pagesDone) * elapsed / pagesDone).round();
    final sec = (leftMs / 1000).round();
    if (sec < 60) return "${sec}s";
    return "${sec ~/ 60}m ${sec % 60}s";
  }

  PdfJob copyWith({
    PdfJobStatus? status,
    String? stage,
    int? pagesDone,
    int? pagesTotal,
    DateTime? startedAt,
    String? filePath,
    String? error,
  }) {
    return PdfJob(
      id: id,
      name: name,
      scale: scale,
      status: status ?? this.status,
      stage: stage ?? this.stage,
      pagesDone: pagesDone ?? this.pagesDone,
      pagesTotal: pagesTotal ?? this.pagesTotal,
      updatedAt: DateTime.now(),
      startedAt: startedAt ?? this.startedAt,
      filePath: filePath ?? this.filePath,
      error: error,
    );
  }
}

final pdfJobsProvider = NotifierProvider<PdfJobs, List<PdfJob>>(PdfJobs.new);

class PdfJobs extends Notifier<List<PdfJob>> {
  final _cancel = <String, bool>{};

  @override
  List<PdfJob> build() => [];

  void cancel(String id) => _cancel[id] = true;

  Future<void> enqueue({
    required String name,
    required PdfScale scale,
    required List<Pramaan> pramaans,
    Granth? granth,
    String? description,
  }) async {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final job = PdfJob(
      id: id,
      name: name,
      scale: scale,
      status: PdfJobStatus.queued,
      stage: "Queued",
      pagesDone: 0,
      pagesTotal: pramaans.length,
      updatedAt: DateTime.now(),
    );
    state = [job, ...state];
    unawaited(_run(job, pramaans, granth, description));
  }

  void _update(PdfJob job) {
    state = [for (final item in state) item.id == job.id ? job : item];
  }

  Future<void> _run(PdfJob job, List<Pramaan> pramaans, Granth? granth, String? description) async {
    var current = job.copyWith(status: PdfJobStatus.running, stage: "Preparing", startedAt: DateTime.now());
    _update(current);
    try {
      final font = pw.Font.ttf(await rootBundle.load("assets/fonts/NotoSansDevanagari-Regular.ttf"));
      final doc = pw.Document();
      final margin = job.scale == PdfScale.ninety ? 46.0 : 36.0;
      final titleSize = job.scale == PdfScale.ninety ? 16.0 : 18.0;
      final bodySize = job.scale == PdfScale.ninety ? 13.0 : 15.0;

      Future<pw.MemoryImage?> load(String? path) async {
        final url = remoteMediaUrl(path);
        if (url == null) return null;
        final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 40));
        if (res.statusCode != 200 || res.bodyBytes.isEmpty) return null;
        return pw.MemoryImage(res.bodyBytes);
      }

      pw.Widget bordered(pw.MemoryImage image) {
        return pw.Container(
          alignment: pw.Alignment.center,
          decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black, width: 1)),
          child: pw.Image(image, fit: pw.BoxFit.contain),
        );
      }

      if (granth != null) {
        current = current.copyWith(stage: "Starting images");
        _update(current);
        final cover = await load(granth.imagePath);
        if (cover != null) {
          doc.addPage(pw.Page(
            margin: pw.EdgeInsets.all(margin),
            build: (_) => bordered(cover),
          ));
        }
        final editor = await load(granth.editorImagePath);
        if (editor != null) {
          doc.addPage(pw.Page(
            margin: pw.EdgeInsets.all(margin),
            build: (_) => bordered(editor),
          ));
        }
      }

      if (_cancel[job.id] == true) throw const _Cancelled();

      for (var i = 0; i < pramaans.length; i++) {
        if (_cancel[job.id] == true) throw const _Cancelled();
        final item = pramaans[i];
        current = current.copyWith(stage: "प्रमाण ${i + 1} / ${pramaans.length}", pagesDone: i);
        _update(current);
        final image = await load(item.imagePath);
        final header = job.name;
        doc.addPage(pw.MultiPage(
          margin: pw.EdgeInsets.all(margin),
          maxPages: 8,
          build: (context) => [
            pw.Text(header, style: pw.TextStyle(font: font, fontSize: 11, color: PdfColors.brown)),
            pw.SizedBox(height: 8),
            pw.Text(item.title.isEmpty ? "प्रमाण" : item.title, style: pw.TextStyle(font: font, fontSize: titleSize, color: PdfColor.fromInt(0xFF7B1F2E))),
            if (i == 0 && (description ?? "").trim().isNotEmpty) ...[
              pw.SizedBox(height: 8),
              pw.Text(description!.trim(), style: pw.TextStyle(font: font, fontSize: bodySize)),
            ],
            if (item.description.trim().isNotEmpty) ...[
              pw.SizedBox(height: 8),
              pw.Text(item.description.trim(), style: pw.TextStyle(font: font, fontSize: bodySize)),
            ],
            if (image != null) ...[
              pw.SizedBox(height: 10),
              pw.Container(height: job.scale == PdfScale.mool ? 460 : 400, child: bordered(image)),
            ],
            pw.SizedBox(height: 12),
            pw.Text(
              [
                "पृष्ठ ${item.pageNumber}",
                if (item.chapterNumber > 0) "अध्याय ${item.chapterNumber}",
                if (item.granthTitle.isNotEmpty) "ग्रंथ ${item.granthTitle}",
                if (item.topicTitle.isNotEmpty) "विषय ${item.topicTitle}",
                "प्रमाण ${i + 1} / ${pramaans.length}",
              ].join("   ·   "),
              style: pw.TextStyle(font: font, fontSize: 11, color: PdfColors.grey700),
            ),
          ],
        ));
        await Future<void>.delayed(Duration.zero);
      }

      current = current.copyWith(stage: "Saving PDF", pagesDone: pramaans.length);
      _update(current);
      final bytes = await doc.save();
      final suffix = job.scale == PdfScale.ninety ? "90" : "Mool_Aakar";
      final fileName = "${safeFileBase(job.name)}_$suffix.pdf";
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, fileName));
      await file.writeAsBytes(bytes, flush: true);
      current = current.copyWith(status: PdfJobStatus.completed, stage: "Completed", pagesDone: pramaans.length, filePath: file.path);
      _update(current);
    } on _Cancelled {
      _update(current.copyWith(status: PdfJobStatus.cancelled, stage: "Cancelled"));
    } catch (error) {
      _update(current.copyWith(status: PdfJobStatus.failed, stage: "Failed", error: "$error"));
    }
  }
}

class _Cancelled implements Exception {
  const _Cancelled();
}

Future<void> sharePdf(String path) async {
  await Share.shareXFiles([XFile(path)]);
}

Future<String> copyPdfToDownloads(String path) async {
  final source = File(path);
  final bytes = await source.readAsBytes();
  Directory? downloads;
  try {
    downloads = await getDownloadsDirectory();
  } catch (_) {
    downloads = null;
  }
  downloads ??= await getApplicationDocumentsDirectory();
  final dest = File(p.join(downloads.path, p.basename(path)));
  await dest.writeAsBytes(bytes, flush: true);
  return dest.path;
}
