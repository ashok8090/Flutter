import "package:app_links/app_links.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "core/database.dart";
import "core/repository.dart";
import "ui/granth_app.dart";

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = await AppDatabase.open();
  final container = ProviderContainer(overrides: [databaseProvider.overrideWithValue(database)]);
  final appLinks = AppLinks();
  final initial = await appLinks.getInitialLink();
  runApp(UncontrolledProviderScope(container: container, child: const GranthApp()));
  final router = container.read(routerProvider);
  final first = _routeFor(initial);
  if (first != null) router.go(first);
  appLinks.uriLinkStream.listen((uri) {
    final route = _routeFor(uri);
    if (route != null) router.go(route);
  });
}

/// https://granth.wnmsolutions.com/granth/{id}
/// https://granth.wnmsolutions.com/topic/{id}
/// https://granth.wnmsolutions.com/pramaan/{id}
/// Also the existing site query links: /praman.php?granth=&topic=&id=
String? _routeFor(Uri? uri) {
  if (uri == null) return null;
  if (uri.host.isNotEmpty && uri.host != "granth.wnmsolutions.com") return null;
  final parts = uri.pathSegments.where((s) => s.isNotEmpty).toList();
  if (parts.length >= 2 && (parts[0] == "granth" || parts[0] == "topic" || parts[0] == "pramaan")) {
    return "/${parts[0]}/${parts[1]}";
  }
  if (parts.isNotEmpty && parts.last == "praman.php") {
    final granth = uri.queryParameters["granth"];
    final topic = uri.queryParameters["topic"];
    final id = uri.queryParameters["id"];
    if (granth != null && granth.isNotEmpty) return "/granth/$granth";
    if (topic != null && topic.isNotEmpty) return "/topic/$topic";
    if (id != null && id.isNotEmpty) return "/pramaan/$id";
  }
  return null;
}
