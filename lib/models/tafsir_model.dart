import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class TafsirData {
  static Map<String, Map<String, String>>? _cache;

  /// Load tafsir data from bundled JSON
  static Future<void> _ensureLoaded() async {
    if (_cache != null) return;
    try {
      final jsonStr =
          await rootBundle.loadString('assets/database/tafsir_data.json');
      final Map<String, dynamic> raw = json.decode(jsonStr);
      _cache = {};
      for (final surahKey in raw.keys) {
        final Map<String, dynamic> versesMap =
            raw[surahKey] as Map<String, dynamic>;
        _cache![surahKey] = versesMap.map((k, v) => MapEntry(k, v as String));
      }
    } catch (e) {
      _cache = {};
    }
  }

  /// Get tafsir for a specific verse
  static Future<String?> getTafsir(int surahNumber, int verseNumber) async {
    await _ensureLoaded();
    final surahMap = _cache?[surahNumber.toString()];
    // Try local cache first
    if (surahMap != null && surahMap.containsKey(verseNumber.toString())) {
      return surahMap[verseNumber.toString()];
    }
    // Fallback: fetch from API if local data is missing
    return _fetchFromApi(surahNumber, verseNumber);
  }

  /// Fetch tafsir for a whole surah from API and cache it
  static Future<String?> _fetchFromApi(
      int surahNumber, int verseNumber) async {
    try {
      final surahKey = surahNumber.toString();
      _cache ??= {};
      _cache![surahKey] ??= {};

      int currentPage = 1;
      int totalPages = 1;

      while (currentPage <= totalPages) {
        // Use Tafsir Al-Muyassar (id=16) from api.quran.com
        final url = Uri.parse(
            'https://api.quran.com/api/v4/tafsirs/16/by_chapter/$surahNumber'
            '?language=ar&per_page=50&page=$currentPage');
        final response = await http.get(url).timeout(
              const Duration(seconds: 15),
            );
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final tafsirs = data['tafsirs'] as List?;
          final pagination = data['pagination'] as Map<String, dynamic>?;

          if (pagination != null) {
            totalPages = pagination['total_pages'] ?? 1;
          }

          if (tafsirs != null) {
            for (final t in tafsirs) {
              final verseKey = t['verse_key'] as String?;
              final text = t['text'] as String?;
              if (verseKey != null && text != null) {
                final parts = verseKey.split(':');
                if (parts.length == 2) {
                  // Strip HTML tags from API response
                  final cleanText =
                      text.replaceAll(RegExp(r'<[^>]*>'), '');
                  _cache![surahKey]![parts[1]] = cleanText;
                }
              }
            }
          }
        } else {
          break;
        }
        currentPage++;
      }

      return _cache![surahKey]?[verseNumber.toString()];
    } catch (_) {
      // Network error — return null
    }
    return null;
  }

  /// Get all tafsir for a surah (for full surah tafsir screen)
  static Future<Map<int, String>> getSurahTafsir(int surahNumber) async {
    await _ensureLoaded();
    final surahKey = surahNumber.toString();
    final surahMap = _cache?[surahKey];

    // If local data exists and is non-empty, use it
    if (surahMap != null && surahMap.isNotEmpty) {
      return surahMap.map((k, v) => MapEntry(int.parse(k), v));
    }

    // Otherwise fetch from API (this caches the results)
    await _fetchFromApi(surahNumber, 1);
    final updatedMap = _cache?[surahKey];
    if (updatedMap != null && updatedMap.isNotEmpty) {
      return updatedMap.map((k, v) => MapEntry(int.parse(k), v));
    }
    return {};
  }

  /// Check if tafsir data is available
  static Future<bool> isAvailable() async {
    await _ensureLoaded();
    return _cache != null && _cache!.isNotEmpty;
  }
}
