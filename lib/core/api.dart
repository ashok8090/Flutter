import "dart:convert";

import "package:http/http.dart" as http;

import "models.dart";

class ApiService {
  static const origin = "https://granth.wnmsolutions.com";
  static const _api = "$origin/api/index.php?request=";

  Future<Map<String, dynamic>> _get(String request) async {
    final res = await http.get(Uri.parse("$_api$request")).timeout(const Duration(seconds: 60));
    if (res.statusCode != 200) {
      throw Exception("API $request failed (${res.statusCode})");
    }
    final body = jsonDecode(res.body);
    if (body is! Map<String, dynamic>) throw Exception("Unexpected API body");
    return body;
  }

  Future<List<Topic>> topics() async {
    final json = await _get("getTopics");
    return _list(json).map(Topic.fromApi).where((t) => t.id.isNotEmpty).toList();
  }

  Future<List<Granth>> granths() async {
    final json = await _get("getGranths");
    return _list(json).map(Granth.fromApi).where((g) => g.id.isNotEmpty).toList();
  }

  Future<List<Pramaan>> pramaans() async {
    final json = await _get("getPramans");
    return _list(json).map(Pramaan.fromApi).where((p) => p.id.isNotEmpty).toList();
  }

  List<Map<String, dynamic>> _list(Map<String, dynamic> json) {
    final data = json["data"];
    if (data is! List) return const [];
    return data.whereType<Map>().map((row) => Map<String, dynamic>.from(row)).toList();
  }
}
