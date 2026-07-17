import 'package:flutter/material.dart';

import '../../models/AnalyticsMixin.dart';
import '../../models/quran_bookmark_service.dart';
import '../../models/quran_model.dart';
import '../../models/tafsir_model.dart';

class QuranPageTafsirScreen extends StatefulWidget {
  final List<QuranPage> pages;
  final int initialPageNumber;

  const QuranPageTafsirScreen({
    super.key, 
    required this.pages,
    required this.initialPageNumber,
  });

  @override
  State<QuranPageTafsirScreen> createState() =>
      _QuranPageTafsirScreenState();
}

class _QuranPageTafsirScreenState extends State<QuranPageTafsirScreen>
    with AnalyticsMixin {
  @override
  String get screenName => 'QuranPageTafsirScreen';

  Map<String, String> _tafsirMap = {}; // Key format: "surahNumber:verseNumber"
  bool _isLoading = true;
  double _fontSize = 24.0;
  String? _errorMessage;
  late List<({int surahNumber, String surahName, QuranVerse verse})> _flatVerses;
  late int _currentPageNumber;
  late QuranPage _currentPageData;

  String _toArabicNumber(int number) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number
        .toString()
        .split('')
        .map((d) => arabicDigits[int.parse(d)])
        .join();
  }

  @override
  void initState() {
    super.initState();
    _currentPageNumber = widget.initialPageNumber;
    _currentPageData = widget.pages[_currentPageNumber - 1];
    _initPageData();
    _loadFontSize();
  }

  void _initPageData() {
    _flatVerses = [];
    for (final group in _currentPageData.surahGroups) {
      for (final v in group.verses) {
        _flatVerses.add((surahNumber: group.surahNumber, surahName: group.surahName, verse: v));
      }
    }
    _loadAllTafsir();
  }

  Future<void> _loadFontSize() async {
    final size = await QuranBookmarkService.getFontSize();
    if (mounted) setState(() => _fontSize = size);
  }

  Future<void> _loadAllTafsir() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final map = <String, String>{};
      final surahsOnPage = _currentPageData.surahGroups.map((g) => g.surahNumber).toSet();
      
      for (final sNum in surahsOnPage) {
        final surahMap = await TafsirData.getSurahTafsir(sNum);
        for (final entry in surahMap.entries) {
          map['$sNum:${entry.key}'] = entry.value;
        }
      }

      if (mounted) {
        setState(() {
          _tafsirMap = map;
          _isLoading = false;
          if (map.isEmpty) {
            _errorMessage =
                'لم يتم العثور على التفسير. تأكد من الاتصال بالإنترنت.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'حدث خطأ أثناء تحميل التفسير. تأكد من الاتصال بالإنترنت.';
        });
      }
    }
  }

  void _showFontSizeSlider(Color primaryGreen, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        double tempSize = _fontSize;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF252525) : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Text(
                    'حجم الخط',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: primaryGreen.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: tempSize,
                        height: 1.8,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('أ',
                          style: TextStyle(fontFamily: 'Amiri', fontSize: 14)),
                      Expanded(
                        child: SliderTheme(
                          data: SliderThemeData(
                            activeTrackColor: primaryGreen,
                            inactiveTrackColor:
                                isDark ? Colors.grey[700] : Colors.grey[300],
                            thumbColor: primaryGreen,
                          ),
                          child: Slider(
                            value: tempSize,
                            min: 16.0,
                            max: 40.0,
                            divisions: 12,
                            onChanged: (val) {
                              setModalState(() => tempSize = val);
                            },
                          ),
                        ),
                      ),
                      const Text('أ',
                          style: TextStyle(fontFamily: 'Amiri', fontSize: 32)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        setState(() => _fontSize = tempSize);
                        QuranBookmarkService.saveFontSize(tempSize);
                        Navigator.pop(ctx);
                      },
                      child: const Text(
                        'تطبيق',
                        style: TextStyle(fontFamily: 'Tajawal', fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryGreen =
        isDark ? const Color(0xFF1B5E20) : const Color(0xFF00695C);
    final accentGold =
        isDark ? const Color(0xFFFFD54F) : const Color(0xFFBF8C2C);
    final bgColor = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFFF8F0);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pop(context, _currentPageNumber);
      },
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: primaryGreen,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context, _currentPageNumber),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'تفسير صفحة ${_toArabicNumber(_currentPageNumber)}',
                style: const TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
              Text(
                ' الجزء ${_toArabicNumber(_currentPageData.juz)}',
                style: const TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          centerTitle: true,
          actions: [
            if (_currentPageNumber > 1)
              IconButton(
                icon: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
                tooltip: 'الصفحة السابقة',
                onPressed: () {
                  if (_isLoading) return;
                  setState(() {
                    _currentPageNumber--;
                    _currentPageData = widget.pages[_currentPageNumber - 1];
                    _initPageData();
                  });
                },
              ),
            if (_currentPageNumber < widget.pages.length)
              IconButton(
                icon: const Icon(Icons.chevron_right, color: Colors.white, size: 28),
                tooltip: 'الصفحة التالية',
                onPressed: () {
                  if (_isLoading) return;
                  setState(() {
                    _currentPageNumber++;
                    _currentPageData = widget.pages[_currentPageNumber - 1];
                    _initPageData();
                  });
                },
              ),
            IconButton(
              icon: const Icon(Icons.text_fields, color: Colors.white, size: 22),
              tooltip: 'حجم الخط',
              onPressed: () => _showFontSizeSlider(primaryGreen, isDark),
            ),
          ],
        ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: primaryGreen),
                  const SizedBox(height: 16),
                  Text(
                    'جاري تحميل التفسير...',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 16,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_off,
                            size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 16,
                            color:
                                isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _loadAllTafsir,
                          icon: const Icon(Icons.refresh),
                          label: const Text('إعادة المحاولة',
                              style: TextStyle(fontFamily: 'Tajawal')),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryGreen,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: _flatVerses.length,
                  itemBuilder: (context, index) {
                    final item = _flatVerses[index];
                    final tafsir = _tafsirMap['${item.surahNumber}:${item.verse.numberInSurah}'];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color:
                            isDark ? const Color(0xFF252525) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? Colors.grey[800]!
                              : Colors.grey[200]!,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withOpacity(isDark ? 0.15 : 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Verse header
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: primaryGreen.withOpacity(0.06),
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(16)),
                            ),
                            child: Row(
                              textDirection: TextDirection.rtl,
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: primaryGreen,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        _toArabicNumber(item.verse.numberInSurah),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontFamily: 'Tajawal',
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        item.surahName,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontFamily: 'Amiri',
                                          fontSize: 8,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    item.verse.text,
                                    textDirection: TextDirection.rtl,
                                    style: TextStyle(
                                      fontFamily: 'Amiri',
                                      fontSize: _fontSize,
                                      height: 1.8,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF2C2C2C),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Tafsir content
                          Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Row(
                                  textDirection: TextDirection.rtl,
                                  children: [
                                    Icon(Icons.auto_stories,
                                        size: 16, color: accentGold),
                                    const SizedBox(width: 6),
                                    Text(
                                      'التفسير الميسر',
                                      style: TextStyle(
                                        fontFamily: 'Tajawal',
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: accentGold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  tafsir ?? 'التفسير غير متوفر',
                                  textDirection: TextDirection.rtl,
                                  style: TextStyle(
                                    fontFamily: 'Tajawal',
                                    fontSize: _fontSize - 6,
                                    height: 1.8,
                                    color: isDark
                                        ? Colors.grey[300]
                                        : Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
      ),
    );
  }
}
