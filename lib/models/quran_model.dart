import 'dart:convert';
import 'package:flutter/services.dart';

class QuranVerse {
  final int number;
  final String text;
  final int numberInSurah;
  final int juz;
  final int page;
  final int hizbQuarter;

  /// Which surah this verse belongs to (set during page building)
  int surahNumber;
  String surahName;

  QuranVerse({
    required this.number,
    required this.text,
    required this.numberInSurah,
    required this.juz,
    required this.page,
    required this.hizbQuarter,
    this.surahNumber = 0,
    this.surahName = '',
  });

  factory QuranVerse.fromJson(Map<String, dynamic> json) {
    return QuranVerse(
      number: json['number'] as int,
      text: json['text'] as String,
      numberInSurah: json['numberInSurah'] as int,
      juz: json['juz'] as int,
      page: json['page'] as int? ?? 1,
      hizbQuarter: json['hizbQuarter'] as int,
    );
  }
}

class QuranSurah {
  final int number;
  final String name;
  final String englishName;
  final String englishNameTranslation;
  final String revelationType;
  final List<QuranVerse> ayahs;

  QuranSurah({
    required this.number,
    required this.name,
    required this.englishName,
    required this.englishNameTranslation,
    required this.revelationType,
    required this.ayahs,
  });

  int get versesCount => ayahs.length;

  /// The juz number where this surah starts
  int get startJuz => ayahs.first.juz;

  /// All juz numbers this surah spans
  Set<int> get juzNumbers => ayahs.map((a) => a.juz).toSet();

  factory QuranSurah.fromJson(Map<String, dynamic> json) {
    return QuranSurah(
      number: json['number'] as int,
      name: json['name'] as String,
      englishName: json['englishName'] as String,
      englishNameTranslation: json['englishNameTranslation'] as String,
      revelationType: json['revelationType'] as String,
      ayahs: (json['ayahs'] as List)
          .map((a) => QuranVerse.fromJson(a as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// A group of verses from the same surah on a single page
class PageSurahGroup {
  final int surahNumber;
  final String surahName;
  final String revelationType;
  final bool isFirstVerseOfSurah; // true if this group starts at verse 1
  final List<QuranVerse> verses;

  PageSurahGroup({
    required this.surahNumber,
    required this.surahName,
    required this.revelationType,
    required this.isFirstVerseOfSurah,
    required this.verses,
  });
}

/// Represents a single page in the 604-page Mushaf
class QuranPage {
  final int pageNumber; // 1-604
  final int juz;
  final List<PageSurahGroup> surahGroups;

  QuranPage({
    required this.pageNumber,
    required this.juz,
    required this.surahGroups,
  });

  /// The first surah name on this page
  String get primarySurahName =>
      surahGroups.isNotEmpty ? surahGroups.first.surahName : '';

  /// Total verses on this page
  int get totalVerses =>
      surahGroups.fold(0, (sum, g) => sum + g.verses.length);
}

/// Strips Arabic diacritics (tashkeel) from text for search
String removeDiacritics(String text) {
  // Arabic diacritics Unicode range + common extra marks
  return text
      .replaceAll(
        RegExp(
          '[\u064B-\u065F\u0670\u06D6-\u06ED\uFE70-\uFE7F\u0610-\u061A\u06D6-\u06DC\u06DF-\u06E4\u06E7\u06E8\u06EA-\u06ED\uFEFF]',
        ),
        '',
      )
      .replaceAll('ٱ', 'ا');
}

class QuranData {
  static List<QuranSurah>? _cachedSurahs;
  static List<QuranPage>? _cachedPages;

  static Future<List<QuranSurah>> loadSurahs() async {
    if (_cachedSurahs != null) return _cachedSurahs!;

    final jsonString =
        await rootBundle.loadString('assets/database/quran_data.json');
    final Map<String, dynamic> jsonData = json.decode(jsonString);
    final List<dynamic> surahsJson = jsonData['data']['surahs'];

    _cachedSurahs = surahsJson
        .map((s) => QuranSurah.fromJson(s as Map<String, dynamic>))
        .toList();
    return _cachedSurahs!;
  }

  /// Build 604 pages from surah data
  static Future<List<QuranPage>> loadPages() async {
    if (_cachedPages != null) return _cachedPages!;

    final surahs = await loadSurahs();

    // Collect all verses with surah info, grouped by page
    final Map<int, List<_VerseWithSurah>> pageMap = {};

    for (final surah in surahs) {
      for (final verse in surah.ayahs) {
        verse.surahNumber = surah.number;
        verse.surahName = surah.name;
        final pg = verse.page;
        pageMap.putIfAbsent(pg, () => []);
        pageMap[pg]!.add(_VerseWithSurah(
          verse: verse,
          surahNumber: surah.number,
          surahName: surah.name,
          revelationType: surah.revelationType,
        ));
      }
    }

    // Build QuranPage objects
    final pages = <QuranPage>[];
    for (int p = 1; p <= 604; p++) {
      final verses = pageMap[p] ?? [];

      // Group consecutive verses by surah
      final groups = <PageSurahGroup>[];
      if (verses.isNotEmpty) {
        int currentSurah = verses.first.surahNumber;
        var currentVerses = <QuranVerse>[];
        String currentName = verses.first.surahName;
        String currentRevelation = verses.first.revelationType;

        for (final v in verses) {
          if (v.surahNumber != currentSurah) {
            // Flush previous group
            groups.add(PageSurahGroup(
              surahNumber: currentSurah,
              surahName: currentName,
              revelationType: currentRevelation,
              isFirstVerseOfSurah:
                  currentVerses.first.numberInSurah == 1,
              verses: currentVerses,
            ));
            currentSurah = v.surahNumber;
            currentName = v.surahName;
            currentRevelation = v.revelationType;
            currentVerses = [];
          }
          currentVerses.add(v.verse);
        }
        // Flush last group
        if (currentVerses.isNotEmpty) {
          groups.add(PageSurahGroup(
            surahNumber: currentSurah,
            surahName: currentName,
            revelationType: currentRevelation,
            isFirstVerseOfSurah:
                currentVerses.first.numberInSurah == 1,
            verses: currentVerses,
          ));
        }
      }

      pages.add(QuranPage(
        pageNumber: p,
        juz: verses.isNotEmpty ? verses.first.verse.juz : 1,
        surahGroups: groups,
      ));
    }

    _cachedPages = pages;
    return _cachedPages!;
  }
}

/// Internal helper for building pages
class _VerseWithSurah {
  final QuranVerse verse;
  final int surahNumber;
  final String surahName;
  final String revelationType;

  _VerseWithSurah({
    required this.verse,
    required this.surahNumber,
    required this.surahName,
    required this.revelationType,
  });
}
