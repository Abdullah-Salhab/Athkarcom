import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';

import '../../models/AnalyticsMixin.dart';
import '../../models/quran_model.dart';
import 'QuranPageReadingScreen.dart';

class QuranSearchScreen extends StatefulWidget {
  final List<QuranSurah> surahs;
  final List<QuranPage> pages;

  const QuranSearchScreen({super.key, required this.surahs, required this.pages});

  @override
  State<QuranSearchScreen> createState() => _QuranSearchScreenState();
}

class _QuranSearchScreenState extends State<QuranSearchScreen>
    with AnalyticsMixin {
  @override
  String get screenName => 'QuranSearchScreen';

  final TextEditingController _controller = TextEditingController();
  List<_SearchResult> _results = [];
  bool _hasSearched = false;

  String _toArabicNumber(int number) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number
        .toString()
        .split('')
        .map((d) => arabicDigits[int.parse(d)])
        .join();
  }

  void _search(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _hasSearched = false;
      });
      return;
    }

    final cleanQuery = removeDiacritics(query.trim());
    final List<_SearchResult> results = [];

    for (final surah in widget.surahs) {
      for (final ayah in surah.ayahs) {
        final cleanText = removeDiacritics(ayah.text);
        if (cleanText.contains(cleanQuery)) {
          results.add(_SearchResult(
            surah: surah,
            verse: ayah,
            surahIndex: widget.surahs.indexOf(surah),
          ));
        }
        if (results.length >= 100) break; // Cap results
      }
      if (results.length >= 100) break;
    }

    setState(() {
      _results = results;
      _hasSearched = true;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryGreen =
        isDark ? const Color(0xFF1B5E20) : const Color(0xFF00695C);
    final accentGold =
        isDark ? const Color(0xFFFFD54F) : const Color(0xFFBF8C2C);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryGreen,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'بحث في القرآن',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _controller,
              onChanged: _search,
              textDirection: TextDirection.rtl,
              autofocus: true,
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 18,
                color: isDark ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: 'ابحث عن آية أو كلمة...',
                hintStyle: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 16,
                  color: isDark ? Colors.grey[400] : Colors.grey[500],
                ),
                prefixIcon: Icon(Icons.search, color: primaryGreen),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear,
                            color:
                                isDark ? Colors.grey[400] : Colors.grey[500]),
                        onPressed: () {
                          _controller.clear();
                          _search('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
            ),
          ),

          // Results count
          if (_hasSearched)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                textDirection: TextDirection.rtl,
                children: [
                  Text(
                    _results.isEmpty
                        ? 'لا توجد نتائج'
                        : '${_toArabicNumber(_results.length)} نتيجة${_results.length >= 100 ? ' (أول ١٠٠)' : ''}',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 13,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // Results list
          Expanded(
            child: _hasSearched && _results.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off,
                            size: 64,
                            color:
                                isDark ? Colors.grey[700] : Colors.grey[300]),
                        const SizedBox(height: 12),
                        Text(
                          'لا توجد نتائج',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 16,
                            color:
                                isDark ? Colors.grey[500] : Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  )
                : !_hasSearched
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.menu_book_outlined,
                                size: 64,
                                color: isDark
                                    ? Colors.grey[700]
                                    : Colors.grey[300]),
                            const SizedBox(height: 12),
                            Text(
                              'ابحث في القرآن الكريم',
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 16,
                                color: isDark
                                    ? Colors.grey[500]
                                    : Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: _results.length,
                        itemBuilder: (context, index) {
                          final r = _results[index];
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.grey[850] : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isDark
                                    ? Colors.grey[700]!
                                    : Colors.grey[200]!,
                                width: 0.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black
                                      .withOpacity(isDark ? 0.15 : 0.04),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    PageTransition(
                                      type: PageTransitionType
                                          .rightToLeftWithFade,
                                      duration:
                                          const Duration(milliseconds: 400),
                                      reverseDuration:
                                          const Duration(milliseconds: 400),
                                      child: QuranPageReadingScreen(
                                        pages: widget.pages,
                                        surahs: widget.surahs,
                                        initialPage: r.verse.page,
                                      ),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.end,
                                    children: [
                                      // Surah name + verse number
                                      Row(
                                        textDirection: TextDirection.rtl,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 3),
                                            decoration: BoxDecoration(
                                              color:
                                                  primaryGreen.withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              r.surah.name,
                                              style: TextStyle(
                                                fontFamily: 'Amiri',
                                                fontSize: 13,
                                                color: primaryGreen,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'آية ${_toArabicNumber(r.verse.numberInSurah)}',
                                            style: TextStyle(
                                              fontFamily: 'Tajawal',
                                              fontSize: 12,
                                              color: accentGold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      // Verse text
                                      Text(
                                        r.verse.text,
                                        textDirection: TextDirection.rtl,
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontFamily: 'Amiri',
                                          fontSize: 18,
                                          height: 1.8,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _SearchResult {
  final QuranSurah surah;
  final QuranVerse verse;
  final int surahIndex;

  _SearchResult({
    required this.surah,
    required this.verse,
    required this.surahIndex,
  });
}
