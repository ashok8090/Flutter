const _consonants = {
  "क": "k", "ख": "kh", "ग": "g", "घ": "gh", "ङ": "ng",
  "च": "ch", "छ": "chh", "ज": "j", "झ": "jh", "ञ": "ny",
  "ट": "t", "ठ": "th", "ड": "d", "ढ": "dh", "ण": "n",
  "त": "t", "थ": "th", "द": "d", "ध": "dh", "न": "n",
  "प": "p", "फ": "ph", "ब": "b", "भ": "bh", "म": "m",
  "य": "y", "र": "r", "ल": "l", "व": "v", "श": "sh",
  "ष": "sh", "स": "s", "ह": "h", "ळ": "l",
  "क़": "k", "ख़": "kh", "ग़": "g", "ज़": "z", "ड़": "d", "ढ़": "dh", "फ़": "f", "य़": "y",
};

const _independent = {
  "अ": "a", "आ": "aa", "इ": "i", "ई": "ee", "उ": "u", "ऊ": "oo",
  "ऋ": "ri", "ए": "e", "ऐ": "ai", "ओ": "o", "औ": "au", "ॐ": "om",
};

const _matras = {
  "ा": "aa", "ि": "i", "ी": "ee", "ु": "u", "ू": "oo",
  "ृ": "ri", "े": "e", "ै": "ai", "ो": "o", "ौ": "au",
};

String normalizeText(String input) {
  final lower = input.toLowerCase();
  final buf = StringBuffer();
  for (final rune in lower.runes) {
    final ch = String.fromCharCode(rune);
    if (ch == "\u200c" || ch == "\u200d") continue;
    if (ch == "।" || ch == "॥") {
      buf.write(" ");
      continue;
    }
    final isLetter = RegExp(r"\p{L}", unicode: true).hasMatch(ch);
    final isMark = RegExp(r"\p{M}", unicode: true).hasMatch(ch);
    final isNum = RegExp(r"\p{N}", unicode: true).hasMatch(ch);
    if (isLetter || isMark || isNum || ch.trim().isEmpty) {
      buf.write(ch);
    } else {
      buf.write(" ");
    }
  }
  return buf.toString().replaceAll(RegExp(r"\s+"), " ").trim();
}

String toRoman(String input) {
  final chars = input.charactersSafe();
  final out = StringBuffer();
  for (var i = 0; i < chars.length; i++) {
    final ch = chars[i];
    final base = _consonants[ch];
    if (base != null) {
      final next = i + 1 < chars.length ? chars[i + 1] : null;
      if (next == "्") {
        out.write(base);
        i += 1;
        continue;
      }
      final matra = next == null ? null : _matras[next];
      if (matra != null) {
        out.write(base);
        out.write(matra);
        i += 1;
        continue;
      }
      out.write(base);
      out.write("a");
      continue;
    }
    final vowel = _independent[ch];
    if (vowel != null) {
      out.write(vowel);
      continue;
    }
    final matra = _matras[ch];
    if (matra != null) {
      out.write(matra);
      continue;
    }
    if (ch == "ं" || ch == "ँ") {
      out.write("n");
      continue;
    }
    if (ch == "ः") {
      out.write("h");
      continue;
    }
    if (ch == "्" || ch == "़") continue;
    out.write(ch.toLowerCase());
  }
  return out.toString();
}

String phoneticKey(String input) {
  var s = toRoman(normalizeText(input))
      .replaceAll("aa", "a")
      .replaceAll("ee", "i")
      .replaceAll("oo", "u")
      .replaceAll("ai", "e")
      .replaceAll("au", "o")
      .replaceAll("chh", "ch")
      .replaceAll("kh", "k")
      .replaceAll("gh", "g")
      .replaceAll("jh", "j")
      .replaceAll("th", "t")
      .replaceAll("dh", "d")
      .replaceAll("ph", "f")
      .replaceAll("bh", "b")
      .replaceAll("sh", "s")
      .replaceAll("w", "v")
      .replaceAll("z", "j")
      .replaceAll("x", "ks");
  s = s.replaceAll(RegExp("[aeiou]"), "");
  s = s.replaceAllMapped(RegExp(r"(.)\1+"), (m) => m.group(1)!);
  return s;
}

class SearchDoc {
  SearchDoc({required this.id, required this.title, this.extra = ""});
  final String id;
  final String title;
  final String extra;
  late final String norm = normalizeText("$title\n$extra");
  late final String roman = toRoman(norm);
  late final List<String> tokens = norm.split(" ").where((t) => t.isNotEmpty).toList();
}

int levenshtein(String a, String b) {
  if (a == b) return 0;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;
  if ((a.length - b.length).abs() > 3) return 9;
  var prev = List<int>.generate(b.length + 1, (j) => j);
  var cur = List<int>.filled(b.length + 1, 0);
  for (var i = 1; i <= a.length; i++) {
    cur[0] = i;
    for (var j = 1; j <= b.length; j++) {
      final cost = a[i - 1] == b[j - 1] ? 0 : 1;
      final del = prev[j] + 1;
      final ins = cur[j - 1] + 1;
      final sub = prev[j - 1] + cost;
      cur[j] = del < ins ? (del < sub ? del : sub) : (ins < sub ? ins : sub);
    }
    final swap = prev;
    prev = cur;
    cur = swap;
  }
  return prev[b.length];
}

int? scoreText(String query, SearchDoc item) {
  final qNorm = normalizeText(query);
  if (qNorm.isEmpty) return 0;
  final qRoman = toRoman(qNorm);
  final qPhon = phoneticKey(query);
  final titleNorm = normalizeText(item.title);
  if (titleNorm == qNorm) return 0;
  if (item.norm == qNorm || item.roman == qRoman) return 1;
  if (titleNorm.startsWith(qNorm) || item.roman.startsWith(qRoman)) return 2;
  if (item.tokens.any((t) => t == qNorm || toRoman(t) == qRoman)) return 3;
  if (item.norm.contains(qNorm) || item.roman.contains(qRoman)) return 4;
  final phonTokens = titleNorm.split(" ").where((t) => t.isNotEmpty).map(phoneticKey).toList();
  if (qPhon.isNotEmpty && phonTokens.any((p) => p == qPhon)) return 5;
  if (qPhon.length >= 2 && phonTokens.any((p) => p.startsWith(qPhon) || (p.length >= 2 && qPhon.startsWith(p)))) {
    return 6;
  }
  if (qPhon.length >= 3 && phonTokens.any((p) => (p.length - qPhon.length).abs() <= 1 && levenshtein(qPhon, p) <= 1)) {
    return 7;
  }
  if (qPhon.length >= 4 && phonTokens.any((p) => (p.length - qPhon.length).abs() <= 1 && levenshtein(qPhon, p) <= 2)) {
    return 8;
  }
  if (qPhon.length == 2 && phonTokens.any((p) => p.length == 3 && levenshtein(qPhon, p) <= 1)) return 7;
  final qTokens = qNorm.split(" ").where((t) => t.length >= 2);
  if (qTokens.isNotEmpty &&
      qTokens.every((tok) {
        final tp = phoneticKey(tok);
        return item.norm.contains(normalizeText(tok)) || item.roman.contains(toRoman(tok)) || (tp.length >= 2 && phoneticKey(item.norm).contains(tp));
      })) {
    return 6;
  }
  return null;
}

List<T> rankSearch<T>(String query, List<T> items, SearchDoc Function(T) docOf) {
  final q = query.trim();
  if (q.isEmpty) return items;
  final scored = <({T item, int score})>[];
  for (final item in items) {
    final score = scoreText(q, docOf(item));
    if (score != null) scored.add((item: item, score: score));
  }
  scored.sort((a, b) => a.score.compareTo(b.score));
  return scored.map((s) => s.item).toList();
}

extension on String {
  List<String> charactersSafe() => runes.map(String.fromCharCode).toList();
}
