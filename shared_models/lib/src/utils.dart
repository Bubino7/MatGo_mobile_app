/// Spoločné utility (čisto Dart, bez Flutter/Firebase).
abstract class MatGoUtils {
  MatGoUtils._();

  /// Parsuje dátum z Firestore (Timestamp) alebo DateTime. Bez závislosti na cloud_firestore.
  static DateTime? parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    try {
      final ms = (v as dynamic).millisecondsSinceEpoch;
      if (ms is int) return DateTime.fromMillisecondsSinceEpoch(ms);
    } catch (_) {}
    return null;
  }

  /// Formátuje DateTime na reťazec: DD.MM.YYYY HH:mm
  static String formatDateTime(dynamic v) {
    final d = parseDate(v);
    if (d == null) return '—';
    return '${d.day}.${d.month}.${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  static String formatItemsCount(int n) {
    if (n == 1) return '1 položka';
    if (n >= 2 && n <= 4) return '$n položky';
    return '$n položiek';
  }

  /// Vygeneruje kľúčové slová pre vyhľadávanie: prefixy celého názvu (d, dr, …, drevoskrutka 6x40)
  /// plus prefixy každého slova zvlášť (pre „Drevoskrutka 6x40“ aj 6, 6x, 6x4, 6x40), aby vyhľadávanie „6x“ alebo „6x40“ tiež našlo produkt.
  static List<String> searchKeywordsFromName(String name) {
    if (name.trim().isEmpty) return [];
    final full = name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    final out = <String>{};
    for (var len = 1; len <= full.length; len++) {
      out.add(full.substring(0, len));
    }
    final words = full.split(' ').where((s) => s.isNotEmpty);
    for (final word in words) {
      for (var len = 1; len <= word.length; len++) {
        out.add(word.substring(0, len));
      }
    }
    return out.toList()..sort();
  }
}
