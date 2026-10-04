import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "package:share_plus/share_plus.dart";
import "package:url_launcher/url_launcher.dart";

import "../core/models.dart";
import "../core/pdf_service.dart";
import "../core/repository.dart";
import "../core/search.dart";

const saffron = Color(0xFFE8821A);
const maroon = Color(0xFF7B1F2E);
const gold = Color(0xFFC9A84C);
const cream = Color(0xFFFDF6E3);
const brown = Color(0xFF4A2C0A);

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    routes: [
      ShellRoute(
        builder: (context, state, child) => GranthShell(child: child),
        routes: [
          GoRoute(path: "/", builder: (_, __) => const DashboardPage()),
          GoRoute(path: "/topics", builder: (_, __) => const TopicsPage()),
          GoRoute(path: "/granths", builder: (_, __) => const GranthsPage()),
          GoRoute(path: "/pramaans", builder: (_, __) => const PramaansPage()),
          GoRoute(
            path: "/granth/:id",
            builder: (_, state) => PramaansPage(granthId: state.pathParameters["id"]),
          ),
          GoRoute(
            path: "/topic/:id",
            builder: (_, state) => PramaansPage(topicId: state.pathParameters["id"]),
          ),
          GoRoute(
            path: "/pramaan/:id",
            builder: (_, state) => PramaansPage(pramaanId: state.pathParameters["id"]),
          ),
        ],
      ),
    ],
  );
});

class GranthApp extends ConsumerWidget {
  const GranthApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: "ग्रंथ",
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: saffron, primary: maroon, surface: cream),
        scaffoldBackgroundColor: cream,
        fontFamily: "Roboto",
        scrollbarTheme: ScrollbarThemeData(
          thumbVisibility: const WidgetStatePropertyAll(true),
          thickness: const WidgetStatePropertyAll(10),
          radius: const Radius.circular(8),
          thumbColor: WidgetStatePropertyAll(maroon.withValues(alpha: 0.45)),
        ),
      ),
    );
  }
}

class GranthShell extends ConsumerWidget {
  const GranthShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = GoRouterState.of(context).uri.path;
    final jobs = ref.watch(pdfJobsProvider);
    final running = jobs.where((j) => j.status == PdfJobStatus.running || j.status == PdfJobStatus.queued).length;
    int index = 0;
    if (loc.startsWith("/topic")) index = 1;
    if (loc.startsWith("/granths") || loc.startsWith("/granth/")) index = 2;
    if (loc.startsWith("/pramaan")) index = 3;
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        backgroundColor: brown,
        indicatorColor: saffron,
        selectedIndex: index,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined, color: gold), label: "Dashboard"),
          NavigationDestination(icon: Icon(Icons.list_alt, color: gold), label: "Topics"),
          NavigationDestination(icon: Icon(Icons.menu_book, color: gold), label: "Granths"),
          NavigationDestination(icon: Icon(Icons.image_outlined, color: gold), label: "प्रमाण"),
        ],
        onDestinationSelected: (i) {
          const paths = ["/", "/topics", "/granths", "/pramaans"];
          context.go(paths[i]);
        },
      ),
      floatingActionButton: running == 0
          ? null
          : FloatingActionButton(
              backgroundColor: brown,
              onPressed: () => showPdfProgress(context),
              child: const Icon(Icons.arrow_downward, color: gold),
            ),
    );
  }
}

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(catalogProvider);
    return catalog.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text("सिंक नहीं हो सका\n$e", textAlign: TextAlign.center)),
      data: (data) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text("ग्रंथ", style: TextStyle(fontSize: 32, color: maroon, fontWeight: FontWeight.w700)),
          Text(data.offline ? "ऑफलाइन — पिछला डेटा" : "सिंक ${data.syncedAt ?? "हो रहा है"}", style: const TextStyle(color: brown)),
          const SizedBox(height: 12),
          _DashCard(label: "Topics", count: data.topics.length, onTap: () => context.go("/topics")),
          _DashCard(label: "Granths", count: data.granths.length, onTap: () => context.go("/granths")),
          _DashCard(label: "प्रमाण", count: null, onTap: () => context.go("/pramaans")),
          const SizedBox(height: 8),
          const Text("सत साहेब जी", style: TextStyle(fontWeight: FontWeight.w700)),
          const Text("यह ऐप granth.wnmsolutions.com का मूल डेटा रखता है। एक बार सिंक के बाद विषय, ग्रंथ और प्रमाण बिना इंटरनेट खुलते हैं। YouTube प्रमाण नहीं दिखाए जाते।"),
        ],
      ),
    );
  }
}

class _DashCard extends StatelessWidget {
  const _DashCard({required this.label, required this.count, required this.onTap});
  final String label;
  final int? count;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(count == null ? label : "$count", style: const TextStyle(fontSize: 28, color: maroon)),
        subtitle: Text(label),
        onTap: onTap,
      ),
    );
  }
}

class TopicsPage extends ConsumerStatefulWidget {
  const TopicsPage({super.key});
  @override
  ConsumerState<TopicsPage> createState() => _TopicsPageState();
}

class _TopicsPageState extends ConsumerState<TopicsPage> {
  String q = "";
  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(catalogProvider);
    return catalog.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text("$e"),
      data: (data) {
        final shown = rankSearch(q, data.topics, (t) => SearchDoc(id: t.id, title: t.title, extra: t.description));
        return Column(children: [
          _SearchBar(hint: "विषय खोजें — हिंदी, English, Hinglish", onChanged: (v) => setState(() => q = v)),
          Expanded(
            child: Scrollbar(
              child: shown.isEmpty
                  ? const Center(child: Text("No Topic found"))
                  : ListView.builder(
                      itemCount: shown.length,
                      itemBuilder: (_, i) {
                        final t = shown[i];
                        return Card(
                          margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                          child: InkWell(
                            onTap: () => context.push("/topic/${t.id}"),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text("${t.position}. ${t.title}", style: const TextStyle(color: maroon, fontSize: 16)),
                                if (t.description.isNotEmpty) Text(t.description, maxLines: 4, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 8),
                                Wrap(spacing: 8, children: [
                                  ActionChip(label: Text("प्रमाण ${t.pramanCount}"), onPressed: () => context.push("/topic/${t.id}")),
                                  ActionChip(label: const Text("Share"), onPressed: () => shareText("https://granth.wnmsolutions.com/topic/${t.id}")),
                                  FilledButton(onPressed: () => _pdfTopic(context, ref, t), child: const Text("PDF")),
                                ]),
                              ]),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ]);
      },
    );
  }

  Future<void> _pdfTopic(BuildContext context, WidgetRef ref, Topic topic) async {
    final scale = await pickPdfScale(context);
    if (scale == null) return;
    final list = await ref.read(repoProvider).pramaans(topicId: topic.id);
    await ref.read(pdfJobsProvider.notifier).enqueue(name: topic.title, scale: scale, pramaans: list, description: topic.description);
    if (context.mounted) showPdfProgress(context);
  }
}

class GranthsPage extends ConsumerStatefulWidget {
  const GranthsPage({super.key});
  @override
  ConsumerState<GranthsPage> createState() => _GranthsPageState();
}

class _GranthsPageState extends ConsumerState<GranthsPage> {
  String q = "";
  int grid = 2;
  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(catalogProvider);
    return catalog.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text("$e"),
      data: (data) {
        final shown = rankSearch(q, data.granths, (g) => SearchDoc(id: g.id, title: g.title, extra: "${g.author}\n${g.description}"));
        return Column(children: [
          _SearchBar(hint: "ग्रंथ खोजें — हिंदी, English, Hinglish", onChanged: (v) => setState(() => q = v)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 1, label: Text("1×1")),
                ButtonSegment(value: 2, label: Text("2×2")),
                ButtonSegment(value: 3, label: Text("3×3")),
              ],
              selected: {grid},
              onSelectionChanged: (s) => setState(() => grid = s.first),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: shown.isEmpty
                ? const Center(child: Text("No Granth found"))
                : Scrollbar(
                    child: GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: grid,
                        mainAxisExtent: grid == 3 ? 250 : 340,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: shown.length,
                      itemBuilder: (_, i) => _GranthCard(granth: shown[i], index: i + 1, total: shown.length),
                    ),
                  ),
          ),
        ]);
      },
    );
  }
}

class _GranthCard extends ConsumerWidget {
  const _GranthCard({required this.granth, required this.index, required this.total});
  final Granth granth;
  final int index;
  final int total;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final image = remoteMediaUrl(granth.imagePath);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push("/granth/${granth.id}"),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Stack(children: [
              Positioned.fill(
                child: image == null
                    ? const ColoredBox(color: Color(0xFFF5E6C8))
                    : Image.network(image, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox()),
              ),
              if (image != null)
                Positioned(
                  right: 6,
                  bottom: 6,
                  child: _GlassButton(
                    icon: Icons.image_outlined,
                    onTap: () => showDialog<void>(
                      context: context,
                      builder: (ctx) => Dialog(
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Image.network(image),
                          if (remoteMediaUrl(granth.editorImagePath) != null) Image.network(remoteMediaUrl(granth.editorImagePath)!),
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Close")),
                        ]),
                      ),
                    ),
                  ),
                ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(granth.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: maroon, fontWeight: FontWeight.w600)),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Row(children: [
              ActionChip(label: const Text("Share"), onPressed: () => shareText("https://granth.wnmsolutions.com/granth/${granth.id}")),
              const SizedBox(width: 6),
              ActionChip(label: Text("प्रमाण ${granth.pramanCount}"), onPressed: () => context.push("/granth/${granth.id}")),
              const SizedBox(width: 6),
              Text("$index/$total"),
              const SizedBox(width: 6),
              FilledButton(
                onPressed: () async {
                  final scale = await pickPdfScale(context);
                  if (scale == null || !context.mounted) return;
                  final list = await ref.read(repoProvider).pramaans(granthId: granth.id);
                  await ref.read(pdfJobsProvider.notifier).enqueue(name: granth.title, scale: scale, pramaans: list, granth: granth, description: granth.description);
                  if (context.mounted) showPdfProgress(context);
                },
                child: const Text("PDF"),
              ),
              if (granth.hasRemotePdf)
                IconButton(
                  tooltip: "Granth PDF",
                  onPressed: () => launchUrl(Uri.parse(granth.granthUrl), mode: LaunchMode.externalApplication),
                  icon: const Icon(Icons.remove_red_eye_outlined),
                ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  const _GlassButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black45,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(onTap: onTap, child: Padding(padding: const EdgeInsets.all(10), child: Icon(icon, color: Colors.white))),
    );
  }
}

class PramaansPage extends ConsumerStatefulWidget {
  const PramaansPage({super.key, this.granthId, this.topicId, this.pramaanId});
  final String? granthId;
  final String? topicId;
  final String? pramaanId;
  @override
  ConsumerState<PramaansPage> createState() => _PramaansPageState();
}

class _PramaansPageState extends ConsumerState<PramaansPage> {
  String q = "";
  late Future<List<Pramaan>> future;

  @override
  void initState() {
    super.initState();
    future = _load();
  }

  Future<List<Pramaan>> _load() {
    final repo = ref.read(repoProvider);
    return repo.pramaans(granthId: widget.granthId, topicId: widget.topicId, id: widget.pramaanId);
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _SearchBar(hint: "प्रमाण खोजें — मांस / mans / guru", onChanged: (v) => setState(() => q = v)),
      Expanded(
        child: FutureBuilder<List<Pramaan>>(
          future: future,
          builder: (context, snap) {
            if (!snap.hasData) {
              if (snap.hasError) return Center(child: Text("ऑफलाइन या नहीं मिला\n${snap.error}"));
              return const Center(child: CircularProgressIndicator());
            }
            final shown = rankSearch(q, snap.data!, (p) => SearchDoc(id: p.id, title: p.title, extra: "${p.description}\n${p.topicTitle}\n${p.granthTitle}"));
            if (shown.isEmpty) return const Center(child: Text("No Pramaan found"));
            return Scrollbar(
              child: ListView.builder(
                itemCount: shown.length,
                itemBuilder: (_, i) {
                  final p = shown[i];
                  final photo = remoteMediaUrl(p.imagePath);
                  return Card(
                    margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(p.title, style: const TextStyle(color: maroon, fontSize: 18)),
                        if (p.description.isNotEmpty) Text(p.description),
                        if (photo != null) Padding(padding: const EdgeInsets.only(top: 8), child: Image.network(photo)),
                        const SizedBox(height: 8),
                        Wrap(spacing: 6, children: [
                          if (p.topicTitle.isNotEmpty) ActionChip(label: Text(p.topicTitle), onPressed: () => context.push("/topic/${p.topicId}")),
                          if (p.granthTitle.isNotEmpty) ActionChip(label: Text(p.granthTitle), onPressed: () => context.push("/granth/${p.granthId}")),
                          Chip(label: Text("पृष्ठ ${p.pageNumber}")),
                          if (p.chapterNumber > 0) Chip(label: Text("अध्याय ${p.chapterNumber}")),
                          ActionChip(label: const Text("Share"), onPressed: () => shareText("https://granth.wnmsolutions.com/pramaan/${p.id}")),
                        ]),
                      ]),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    ]);
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.hint, required this.onChanged});
  final String hint;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: cream.withValues(alpha: 0.94),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: TextField(
          decoration: InputDecoration(hintText: hint, filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

Future<void> shareText(String url) async {
  await Share.share(url);
}

Future<PdfScale?> pickPdfScale(BuildContext context) {
  return showModalBottomSheet<PdfScale>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const ListTile(title: Text("PDF")),
        ListTile(title: const Text("90%"), onTap: () => Navigator.pop(ctx, PdfScale.ninety)),
        ListTile(title: const Text("मूल आकार"), onTap: () => Navigator.pop(ctx, PdfScale.mool)),
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
      ]),
    ),
  );
}

void showPdfProgress(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const PdfProgressSheet(),
  );
}

class PdfProgressSheet extends ConsumerWidget {
  const PdfProgressSheet({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobs = ref.watch(pdfJobsProvider);
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(16),
        children: [
          Text("PDF प्रगति  ${jobs.isEmpty ? "" : "1/${jobs.length}"}", style: const TextStyle(fontSize: 20, color: maroon)),
          for (final job in jobs)
            Card(
              child: ListTile(
                title: Text(job.name),
                subtitle: Text("${job.stage}\n${job.pagesDone} / ${job.pagesTotal} pages · ${(job.fraction * 100).round()}%\nTime left: ${job.eta}"),
                isThreeLine: true,
                trailing: job.status == PdfJobStatus.completed && job.filePath != null
                    ? Row(mainAxisSize: MainAxisSize.min, children: [
                        IconButton(onPressed: () => sharePdf(job.filePath!), icon: const Icon(Icons.share)),
                        IconButton(
                          onPressed: () async {
                            final saved = await copyPdfToDownloads(job.filePath!);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Saved $saved")));
                            }
                          },
                          icon: const Icon(Icons.download),
                        ),
                      ])
                    : job.status == PdfJobStatus.running
                        ? IconButton(onPressed: () => ref.read(pdfJobsProvider.notifier).cancel(job.id), icon: const Icon(Icons.close))
                        : null,
              ),
            ),
        ],
      ),
    );
  }
}
