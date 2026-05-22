import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class QuranBookmark {
  final int pageNumber;
  final String surahName;
  final DateTime timestamp;

  QuranBookmark({
    required this.pageNumber,
    required this.surahName,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'pageNumber': pageNumber,
        'surahName': surahName,
        'timestamp': timestamp.toIso8601String(),
      };

  factory QuranBookmark.fromJson(Map<String, dynamic> json) => QuranBookmark(
        pageNumber: json['pageNumber'] as int? ?? json['surahNumber'] as int,
        surahName: json['surahName'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}

class QuranBookmarkService {
  static const _lastReadSurahKey = 'quran_last_read_surah'; // Used for old fallback
  static const _lastReadPageKey = 'quran_last_read_page';
  static const _bookmarksKey = 'quran_page_bookmarks'; // Changed key to reset
  static const _readPagesKey = 'quran_read_pages';
  static const _readTimestampsKey = 'quran_page_read_timestamps';

  // ── Last Read (Surah mode) ─────────────────────────────────────────────

  static Future<void> saveLastRead(int surahIndex) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastReadSurahKey, surahIndex);
  }

  static Future<int?> getLastRead() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_lastReadSurahKey);
  }

  // ── Last Read (Page mode) ──────────────────────────────────────────────

  static Future<void> saveLastReadPage(int pageNumber) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastReadPageKey, pageNumber);
  }

  static Future<int?> getLastReadPage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_lastReadPageKey);
  }

  // ── Bookmarks ──────────────────────────────────────────────────────────

  static Future<List<QuranBookmark>> getBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_bookmarksKey);
    if (raw == null || raw.isEmpty) return [];
    final List<dynamic> list = json.decode(raw);
    return list
        .map((e) => QuranBookmark.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> addBookmark(int pageNumber, String surahName) async {
    final bookmarks = await getBookmarks();
    // Don't duplicate
    if (bookmarks.any((b) => b.pageNumber == pageNumber)) return;
    bookmarks.add(QuranBookmark(
      pageNumber: pageNumber,
      surahName: surahName,
      timestamp: DateTime.now(),
    ));
    await _saveBookmarks(bookmarks);
  }

  static Future<void> removeBookmark(int pageNumber) async {
    final bookmarks = await getBookmarks();
    bookmarks.removeWhere((b) => b.pageNumber == pageNumber);
    await _saveBookmarks(bookmarks);
  }

  static Future<bool> isBookmarked(int pageNumber) async {
    final bookmarks = await getBookmarks();
    return bookmarks.any((b) => b.pageNumber == pageNumber);
  }

  static Future<void> _saveBookmarks(List<QuranBookmark> bookmarks) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _bookmarksKey, json.encode(bookmarks.map((b) => b.toJson()).toList()));
  }

  // ── Reading Progress ───────────────────────────────────────────────────

  static Future<void> markPageRead(int pageNumber) async {
    final prefs = await SharedPreferences.getInstance();
    final readSet = await getReadPages();
    readSet.add(pageNumber);
    await prefs.setStringList(
        _readPagesKey, readSet.map((e) => e.toString()).toList());

    // Save timestamp
    final timestamps = await _getReadTimestamps();
    timestamps[pageNumber.toString()] = DateTime.now().toIso8601String();
    await prefs.setString(_readTimestampsKey, json.encode(timestamps));
  }

  static Future<void> unmarkPageRead(int pageNumber) async {
    final prefs = await SharedPreferences.getInstance();
    final readSet = await getReadPages();
    readSet.remove(pageNumber);
    await prefs.setStringList(
        _readPagesKey, readSet.map((e) => e.toString()).toList());

    final timestamps = await _getReadTimestamps();
    timestamps.remove(pageNumber.toString());
    await prefs.setString(_readTimestampsKey, json.encode(timestamps));
  }

  static Future<bool> isPageRead(int pageNumber) async {
    final readSet = await getReadPages();
    return readSet.contains(pageNumber);
  }

  static Future<Set<int>> getReadPages() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_readPagesKey);
    if (list == null) return {};
    return list.map((e) => int.parse(e)).toSet();
  }

  static Future<double> getProgressPercentage() async {
    final read = await getReadPages();
    return read.length / 604.0;
  }

  static Future<Map<String, String>> _getReadTimestamps() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_readTimestampsKey);
    if (raw == null) return {};
    final Map<String, dynamic> decoded = json.decode(raw);
    return decoded.map((k, v) => MapEntry(k, v as String));
  }

  static Future<List<MapEntry<int, DateTime>>> getRecentlyRead() async {
    final timestamps = await _getReadTimestamps();
    final entries = timestamps.entries
        .map((e) => MapEntry(int.parse(e.key), DateTime.parse(e.value)))
        .toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries.take(10).toList();
  }

  /// Get read count per juz (for progress chart)
  static Future<Map<int, int>> getReadCountPerJuz(
      Map<int, Set<int>> juzPageMap) async {
    final read = await getReadPages();
    final Map<int, int> result = {};
    for (final entry in juzPageMap.entries) {
      result[entry.key] = entry.value.intersection(read).length;
    }
    return result;
  }

  // ── Scroll Position (for long surahs) ──────────────────────────────────

  static const _scrollPositionsKey = 'quran_scroll_positions';

  static Future<void> saveScrollPosition(
      int surahNumber, double offset) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_scrollPositionsKey);
    final Map<String, dynamic> positions =
        raw != null ? json.decode(raw) : {};
    positions[surahNumber.toString()] = offset;
    await prefs.setString(_scrollPositionsKey, json.encode(positions));
  }

  static Future<double> getScrollPosition(int surahNumber) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_scrollPositionsKey);
    if (raw == null) return 0.0;
    final Map<String, dynamic> positions = json.decode(raw);
    return (positions[surahNumber.toString()] ?? 0.0).toDouble();
  }

  // ── Font Size Preference ───────────────────────────────────────────────

  static const _fontSizeKey = 'quran_font_size';

  static Future<void> saveFontSize(double size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontSizeKey, size);
  }

  static Future<double> getFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_fontSizeKey) ?? 24.0;
  }
}
