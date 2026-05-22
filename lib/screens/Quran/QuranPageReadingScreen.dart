import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:just_audio/just_audio.dart';

import '../../models/AnalyticsMixin.dart';
import '../../models/quran_audio_service.dart';
import '../../models/quran_bookmark_service.dart';
import '../../models/quran_model.dart';
import '../../models/tafsir_model.dart';
import 'package:page_transition/page_transition.dart';
import 'package:flutter/services.dart';
import 'QuranSurahTafsirScreen.dart';

class QuranPageReadingScreen extends StatefulWidget {
  final List<QuranPage> pages;
  final List<QuranSurah> surahs;
  final int initialPage; // 1-indexed page number

  const QuranPageReadingScreen({
    super.key,
    required this.pages,
    required this.surahs,
    required this.initialPage,
  });

  @override
  State<QuranPageReadingScreen> createState() => _QuranPageReadingScreenState();
}

class _QuranPageReadingScreenState extends State<QuranPageReadingScreen>
    with AnalyticsMixin {
  @override
  String get screenName => 'QuranPageReadingScreen';

  late PageController _pageController;
  late int _currentPage; // 1-indexed
  double _fontSize = 24.0;
  bool _showBars = true;
  bool _showScrollControls = false;
  bool _isBookmarked = false;
  bool _isRead = false;
  bool _tafsirMode = false;
  bool _eachAyahPerLine = false;

  // Audio
  final QuranAudioService _audioService = QuranAudioService();
  bool _isAudioPlaying = false;
  bool _isAudioPaused = false;
  bool _isAudioLoading = false;
  int _currentVerseIndex = -1;
  int _longPressedVerseIndex = -1;
  int _audioPage = -1;
  bool _isAutoAdvancing = false;
  StreamSubscription? _playerStateSub;
  StreamSubscription? _indexSub;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _pageController = PageController(initialPage: _currentPage - 1);
    _loadFontSize();
    _saveLastReadPage();
    _checkPageData();
    _audioService.loadSavedReciter();
    _setupAudioListeners();
  }

  Future<void> _checkPageData() async {
    final page = widget.pages[_currentPage - 1];
    if (page.surahGroups.isEmpty) return;
    
    final isBookmarked = await QuranBookmarkService.isBookmarked(_currentPage);
    final isRead = await QuranBookmarkService.isPageRead(_currentPage);
    
    if (mounted) {
      setState(() {
        _isBookmarked = isBookmarked;
        _isRead = isRead;
      });
    }
  }

  Future<void> _toggleBookmark() async {
    final page = widget.pages[_currentPage - 1];
    if (page.surahGroups.isEmpty) return;
    final su = page.surahGroups.first;

    if (_isBookmarked) {
      await QuranBookmarkService.removeBookmark(_currentPage);
    } else {
      await QuranBookmarkService.addBookmark(_currentPage, su.surahName);
    }
    setState(() => _isBookmarked = !_isBookmarked);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isBookmarked ? 'تمت إضافة علامة مرجعية' : 'تم إزالة العلامة المرجعية',
            textDirection: TextDirection.rtl,
            style: const TextStyle(fontFamily: 'Tajawal'),
          ),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _toggleReadStatus() async {
    final page = widget.pages[_currentPage - 1];
    if (page.surahGroups.isEmpty) return;

    if (_isRead) {
      await QuranBookmarkService.unmarkPageRead(_currentPage);
    } else {
      await QuranBookmarkService.markPageRead(_currentPage);
    }
    setState(() => _isRead = !_isRead);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isRead ? 'تم تسجيل قراءة الصفحة ${_currentPage}' : 'تم إلغاء تسجيل قراءة الصفحة ${_currentPage}',
            textDirection: TextDirection.rtl,
            style: const TextStyle(fontFamily: 'Tajawal'),
          ),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _setupAudioListeners() {
    _playerStateSub = _audioService.playerStateStream.listen((state) {
      if (!mounted) return;
      final wasPlaying = _isAudioPlaying;
      final newPlaying = state.playing;
      final newLoading = state.processingState == ProcessingState.loading ||
          state.processingState == ProcessingState.buffering;
      final newPaused = !state.playing &&
          state.processingState == ProcessingState.ready &&
          _currentVerseIndex >= 0;

      if (newPlaying != _isAudioPlaying ||
          newLoading != _isAudioLoading ||
          newPaused != _isAudioPaused) {
        setState(() {
          _isAudioPlaying = newPlaying;
          _isAudioLoading = newLoading;
          _isAudioPaused = newPaused;
        });
      }

      // Auto-advance safely when playlist truly completes
      if (state.processingState == ProcessingState.completed &&
          wasPlaying &&
          !_isAutoAdvancing) {
        setState(() {
          _currentVerseIndex = -1;
          _isAudioPaused = false;
        });
        
        if (_audioPage > 0) {
          QuranBookmarkService.markPageRead(_audioPage);
          if (_currentPage == _audioPage) {
            setState(() => _isRead = true);
          }
        }

        if (_audioPage > 0 && _audioPage < 604 && mounted) {
          setState(() => _isAutoAdvancing = true);
          final nextAudioPage = _audioPage + 1;
          
          if (_pageController.hasClients) {
            _pageController.animateToPage(
              nextAudioPage - 1,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
            );
          }
          
          _playPage(nextAudioPage).then((_) {
            if (mounted) setState(() => _isAutoAdvancing = false);
          });
        }
      }
    });

    _indexSub = _audioService.currentIndexStream.listen((index) {
      if (!mounted) return;
      if (index == null) return;
      final newIndex = index;
      if (newIndex != _currentVerseIndex) {
        final oldIndex = _currentVerseIndex;
        setState(() => _currentVerseIndex = newIndex);
        // Handle repeat (logic is already safe in service)
        _audioService.handleVerseChange(oldIndex, newIndex);
      }
    });
  }

  Future<void> _loadFontSize() async {
    final size = await QuranBookmarkService.getFontSize();
    if (mounted) setState(() => _fontSize = size);
  }



  Future<void> _saveLastReadPage() async {
    await QuranBookmarkService.saveLastReadPage(_currentPage);
  }

  String _toArabicNumber(int number) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number
        .toString()
        .split('')
        .map((d) => arabicDigits[int.parse(d)])
        .join();
  }

  void _showVerseMenu(int surahNumber, int verseNumber, int verseIndex) {
    setState(() => _longPressedVerseIndex = verseIndex);
    final primaryGreen = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1B5E20)
        : const Color(0xFF00695C);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Option 1: Tafsir
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD54F).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_stories_rounded,
                    color: Color(0xFFFFD54F), size: 22),
              ),
              title: const Text(
                'عرض التفسير',
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _showTafsir(surahNumber, verseNumber);
              },
            ),
            const Divider(height: 1),
            // Option 2: Play from this verse
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.play_circle_outline_rounded,
                    color: primaryGreen, size: 22),
              ),
              title: const Text(
                'تشغيل من هذه الآية',
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _playPage(_currentPage, startIndex: verseIndex);
              },
            ),
          ],
        ),
      ),
    ).whenComplete(() {
      if (mounted) setState(() => _longPressedVerseIndex = -1);
    });
  }

  void _showTafsir(int surahNumber, int verseNumber) async {
    final tafsir = await TafsirData.getTafsir(surahNumber, verseNumber);
    if (!mounted) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryGreen =
        isDark ? const Color(0xFF2E7D32) : const Color(0xFF00695C);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Text(
                'تفسير الآية ${verseNumber}',
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  tafsir ?? 'لا يوجد تفسير متاح لهذه الآية.',
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 18,
                    height: 1.8,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    'إغلاق',
                    style: TextStyle(fontFamily: 'Tajawal', fontSize: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
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
                      borderRadius: BorderRadius.circular(14),
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
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
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

  void _showGoToPageDialog(Color primaryGreen, bool isDark) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'الانتقال إلى صفحة',
          textDirection: TextDirection.rtl,
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(3)
          ],
          textDirection: TextDirection.rtl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'أدخل رقم الصفحة (١ - ٦٠٤)',
            hintStyle: const TextStyle(fontFamily: 'Tajawal', fontSize: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: primaryGreen, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء',
                style:
                    TextStyle(fontFamily: 'Tajawal', color: Colors.grey[500])),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              final page = int.tryParse(controller.text);
              if (page != null && page >= 1 && page <= 604) {
                Navigator.pop(ctx);
                _pageController.jumpToPage(page - 1);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'الرجاء إدخال رقم صحيح بين ١ و ٦٠٤',
                      textDirection: TextDirection.rtl,
                      style: TextStyle(fontFamily: 'Tajawal'),
                    ),
                    duration: Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('انتقال',
                style: TextStyle(fontFamily: 'Tajawal')),
          ),
        ],
      ),
    );
  }

  void _showReadingOptions(Color primaryGreen, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'خيارات القراءة',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(Icons.auto_stories_rounded, color: primaryGreen),
                title: Text('الانتقال إلى صفحة', textDirection: TextDirection.rtl, style: TextStyle(fontFamily: 'Tajawal', color: isDark ? Colors.white : Colors.black87)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showGoToPageDialog(primaryGreen, isDark);
                },
              ),
              ListTile(
                leading: Icon(Icons.text_fields_rounded, color: primaryGreen),
                title: Text('حجم الخط', textDirection: TextDirection.rtl, style: TextStyle(fontFamily: 'Tajawal', color: isDark ? Colors.white : Colors.black87)),
                trailing: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                onTap: () {
                  Navigator.pop(ctx);
                  _showFontSizeSlider(primaryGreen, isDark);
                },
              ),
              ListTile(
                leading: Icon(_eachAyahPerLine ? Icons.wrap_text : Icons.format_list_bulleted, color: primaryGreen),
                title: Text(_eachAyahPerLine ? 'تفعيل وضع المصحف المتصل' : 'تفعيل وضع آية في كل سطر', textDirection: TextDirection.rtl, style: TextStyle(fontFamily: 'Tajawal', color: isDark ? Colors.white : Colors.black87)),
                onTap: () {
                  setState(() => _eachAyahPerLine = !_eachAyahPerLine);
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: Icon(_tafsirMode ? Icons.auto_stories : Icons.auto_stories_outlined, color: primaryGreen),
                title: Text(_tafsirMode ? 'إيقاف وضع التفسير (آية بآية)' : 'تفعيل وضع التفسير (آية بآية)', textDirection: TextDirection.rtl, style: TextStyle(fontFamily: 'Tajawal', color: isDark ? Colors.white : Colors.black87)),
                onTap: () {
                  setState(() => _tafsirMode = !_tafsirMode);
                  Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(_tafsirMode ? 'وضع التفسير مفعل: اضغط على الآية لعرض التفسير' : 'تم إيقاف وضع التفسير',
                          textDirection: TextDirection.rtl, style: const TextStyle(fontFamily: 'Tajawal')),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ));
                  }
                },
              ),
              ListTile(
                leading: Icon(_showScrollControls ? Icons.unfold_less_rounded : Icons.unfold_more_rounded, color: primaryGreen),
                title: Text(_showScrollControls ? 'إخفاء شريط التمرير التلقائي' : 'إظهار شريط التمرير التلقائي', textDirection: TextDirection.rtl, style: TextStyle(fontFamily: 'Tajawal', color: isDark ? Colors.white : Colors.black87)),
                onTap: () {
                  setState(() => _showScrollControls = !_showScrollControls);
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleBars() {
    setState(() {
      _showBars = !_showBars;
    });
    if (_showBars) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _pageController.dispose();
    _playerStateSub?.cancel();
    _indexSub?.cancel();
    _audioService.stop();
    super.dispose();
  }

  List<({int surah, int verse})> _getPageVerses(QuranPage page) {
    final verses = <({int surah, int verse})>[];
    for (final group in page.surahGroups) {
      for (final v in group.verses) {
        verses.add((surah: group.surahNumber, verse: v.numberInSurah));
      }
    }
    return verses;
  }

  Future<void> _playPage(int pageNum, {int startIndex = 0}) async {
    final page = widget.pages[pageNum - 1];
    final verses = _getPageVerses(page);
    if (verses.isEmpty) return;

    setState(() {
      _audioPage = pageNum;
      _isAudioLoading = true;
      _currentVerseIndex = startIndex;
    });

    try {
      await _audioService.playPageVerses(verses, startIndex: startIndex);
      if (mounted) setState(() => _isAudioLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAudioLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تعذر تشغيل الصوت: $e',
              textDirection: TextDirection.rtl,
              style: const TextStyle(fontFamily: 'Tajawal'),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _togglePlayPause() async {
    if (_isAudioLoading) return;
    if (_isAudioPlaying) {
      await _audioService.pause();
    } else if (_isAudioPaused) {
      await _audioService.resume();
    } else {
      await _playPage(_currentPage);
    }
  }

  void _stopAudio() {
    _audioService.stop();
    setState(() {
      _currentVerseIndex = -1;
      _isAudioPaused = false;
      _audioPage = -1;
    });
  }


  void _showReciterPicker(Color primaryGreen, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'اختر القارئ',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: QuranAudioService.reciters
                    .where((r) => r.verseAudioFolder != null)
                    .length,
                itemBuilder: (context, index) {
                  final reciter = QuranAudioService.reciters
                      .where((r) => r.verseAudioFolder != null)
                      .toList()[index];
                  final isSelected =
                      reciter.id == _audioService.currentReciterId;
                  return ListTile(
                    title: Text(
                      reciter.name,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 16,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? primaryGreen : null,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(Icons.check_circle, color: primaryGreen)
                        : null,
                    onTap: () {
                      _audioService.setReciter(reciter.id);
                      setState(() {});
                      Navigator.pop(ctx);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryGreen =
        isDark ? const Color(0xFF2E7D32) : const Color(0xFF00695C);
    final accentGold =
        isDark ? const Color.fromARGB(255, 255, 255, 255) : const Color.fromARGB(255, 0, 0, 0);
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFFFFBF5);
    final currentPageData = widget.pages[_currentPage - 1];

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          // ── Premium Top Header ──
          if (_showBars)
            Container(
              padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              bottom: 12,
              left: 16,
              right: 16,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primaryGreen,
                  isDark
                      ? const Color(0xFF1B5E20)
                      : const Color(0xFF004D40),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryGreen.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Top row: back + title
                Row(
                  textDirection: TextDirection.rtl,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Right Side: Title and Subtitles
                    Expanded(
                      child: Row(
                        textDirection: TextDirection.rtl,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              currentPageData.primarySurahName,
                              textDirection: TextDirection.rtl,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Amiri',
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'الجزء ${_toArabicNumber(currentPageData.juz)}',
                                textDirection: TextDirection.rtl,
                                style: TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 10,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                              Text(
                                'صفحة ${_toArabicNumber(_currentPage)}',
                                textDirection: TextDirection.rtl,
                                style: TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 10,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    
                    // Left Side: Action Icons
                    Row(
                      textDirection: TextDirection.rtl,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Tafsir
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          icon: const Icon(Icons.menu_book_outlined, color: Colors.white, size: 20),
                          onPressed: () {
                             if (currentPageData.surahGroups.isNotEmpty) {
                                Navigator.push(
                                  context,
                                  PageTransition(
                                    type: PageTransitionType.bottomToTop,
                                    child: QuranPageTafsirScreen(
                                      page: currentPageData,
                                      pageNumber: _currentPage,
                                    ),
                                  ),
                                );
                              }
                          },
                        ),
                        // Mark as read
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          icon: Icon(_isRead ? Icons.check_circle : Icons.check_circle_outline, 
                              color: _isRead ? Colors.lightGreenAccent : Colors.white, size: 20),
                          onPressed: _toggleReadStatus,
                        ),
                        // Bookmark
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          icon: Icon(_isBookmarked ? Icons.bookmark : Icons.bookmark_border, 
                              color: _isBookmarked ? const Color(0xFFFFD54F) : Colors.white, size: 20),
                          onPressed: _toggleBookmark,
                        ),
                        // More options
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          icon: const Icon(Icons.more_vert_rounded, color: Colors.white, size: 20),
                          onPressed: () => _showReadingOptions(primaryGreen, isDark),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          )
          else
            _buildMinimalHeader(isDark, currentPageData),

          // ── Main reading area ──
          Expanded(
            child: Stack(
              children: [
                GestureDetector(
                  onTap: _toggleBars,
                  child: PageView.builder(
                controller: _pageController,
                itemCount: 604,
              onPageChanged: (index) {
                setState(() => _currentPage = index + 1);
                QuranBookmarkService.saveLastReadPage(index + 1);
                _checkPageData();
              },
              itemBuilder: (context, index) {
                final page = widget.pages[index];
                return _MushafPageView(
                  page: page,
                  allSurahs: widget.surahs,
                  fontSize: _fontSize,
                  primaryGreen: primaryGreen,
                  accentGold: accentGold,
                  isDark: isDark,
                  toArabicNumber: _toArabicNumber,
                  highlightVerseIndex: (index == _audioPage - 1) ? _currentVerseIndex : -1,
                  longPressHighlightIndex: (index == _currentPage - 1) ? _longPressedVerseIndex : -1,
                  isAudioPlaying: _isAudioPlaying && (index == _audioPage - 1),
                  showScrollControls: _showScrollControls,
                  eachAyahPerLine: _eachAyahPerLine,
                  tafsirMode: _tafsirMode,
                  onPlayFromVerse: (vIdx) {
                    _playPage(index + 1, startIndex: vIdx);
                  },
                  onTapVerse: (surahIdx, verseNum, vIdx) {
                    if (_tafsirMode) {
                      _showTafsir(surahIdx, verseNum);
                    }
                  },
                  onLongPressVerse: (surahIdx, verseNum, vIdx) {
                    _showVerseMenu(surahIdx, verseNum, vIdx);
                  },
                );
              },
            ),
          ),
          if (_audioPage > 0 && _currentPage != _audioPage && (_isAudioPlaying || _isAudioPaused || _isAudioLoading))
            Positioned(
              bottom: 16,
              left: 16,
              child: FloatingActionButton.extended(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
                elevation: 4,
                icon: const Icon(Icons.my_location_rounded),
                label: const Text(
                  'التتبع مع القارئ',
                  style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  _pageController.animateToPage(
                    _audioPage - 1,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                  );
                },
              ),
            ),
        ],
      ),
    ),

        // ── Audio Player Bar ──
          if (_showBars)
            _buildAudioBar(primaryGreen, accentGold, isDark),
        ],
      ),
    );
  }

  Widget _buildMinimalHeader(bool isDark, QuranPage currentPageData) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 4,
        bottom: 8,
        left: 24,
        right: 24,
      ),
      color: Colors.transparent,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        textDirection: TextDirection.rtl,
        children: [
          Expanded(
            child: Text(
              currentPageData.primarySurahName,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
          ),
          Text(
            '${_toArabicNumber(_currentPage)}',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
          Expanded(
            child: Text(
              'الجزء ${_toArabicNumber(currentPageData.juz)}',
              textDirection: TextDirection.ltr,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 13,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioBar(Color primaryGreen, Color accentGold, bool isDark) {
    final iconColor = isDark ? Colors.grey[300]! : Colors.grey[700]!;
    final dimColor = isDark ? Colors.grey[600]! : Colors.grey[400]!;
    final isActive = _isAudioPlaying || _isAudioPaused || _isAudioLoading;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true, // Right-to-Left
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (!isActive) ...[
                    GestureDetector(
                      onTap: () => _showReciterPicker(primaryGreen, isDark),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person_rounded, size: 20, color: dimColor),
                          const SizedBox(width: 4),
                          Text(
                            _audioService.currentVerseReciter.name,
                            style: TextStyle(
                              fontFamily: 'Tajawal', fontSize: 18,
                              color: isDark ? Colors.grey[300] : Colors.grey[800],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Icon(Icons.arrow_drop_down, size: 20, color: dimColor),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: _togglePlayPause,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: primaryGreen,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
                            const SizedBox(width: 4),
                            const Text(
                              'بدء',
                              style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    _audioSpeedCycleBtn(primaryGreen, isDark),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      width: 1, height: 24,
                      color: isDark ? Colors.grey[700] : Colors.grey[300],
                    ),
                    _barIcon(Icons.skip_next_rounded, iconColor, 28, () {
                      _audioService.previousVerse();
                    }),
                    const SizedBox(width: 4),
                    (_isAudioLoading && !_isAudioPlaying)
                        ? SizedBox(
                            width: 44, height: 44,
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5, color: primaryGreen),
                            ),
                          )
                        : GestureDetector(
                            onTap: _togglePlayPause,
                            child: Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(
                                color: primaryGreen,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _isAudioPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                    const SizedBox(width: 4),
                    _barIcon(Icons.skip_previous_rounded, iconColor, 28, () {
                      _audioService.nextVerse();
                    }),
                    const SizedBox(width: 8),
                    _barIcon(
                      Icons.stop_rounded,
                      (_isAudioPlaying || _isAudioPaused) ? Colors.red[400]! : dimColor,
                      26,
                      _stopAudio,
                    ),
                    const SizedBox(width: 8),
                    _repeatButton(primaryGreen, isDark),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _barIcon(IconData icon, Color color, double size, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, color: color, size: size),
      ),
    );
  }

  Widget _repeatButton(Color primaryGreen, bool isDark) {
    final active = _audioService.repeatMode != VerseRepeatMode.none;
    final color = active
        ? primaryGreen
        : (isDark ? Colors.grey[500]! : Colors.grey[500]!);
    String label;
    switch (_audioService.repeatMode) {
      case VerseRepeatMode.none:
        label = '';
        break;
      case VerseRepeatMode.one:
        label = '1';
        break;
      case VerseRepeatMode.two:
        label = '2';
        break;
      case VerseRepeatMode.infinite:
        label = '∞';
        break;
    }
    return GestureDetector(
      onTap: () {
        _audioService.cycleRepeatMode();
        setState(() {});
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: active ? primaryGreen.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: active ? Border.all(color: primaryGreen, width: 1) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.repeat_rounded, size: 18, color: color),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 2),
              Text(label, style: TextStyle(
                fontFamily: 'Tajawal', fontSize: 11,
                fontWeight: FontWeight.bold, color: color,
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _audioSpeedCycleBtn(Color primaryGreen, bool isDark) {
    final speed = _audioService.playbackSpeed;
    final label = speed == 1.0 ? '1x' : '${speed}x';
    return GestureDetector(
      onTap: () {
        double nextSpeed;
        if (speed == 1.0) nextSpeed = 1.25;
        else if (speed == 1.25) nextSpeed = 1.5;
        else if (speed == 1.5) nextSpeed = 0.75;
        else nextSpeed = 1.0;
        
        _audioService.setSpeed(nextSpeed);
        setState(() {});
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[800] : Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.speed_rounded, size: 16, color: primaryGreen),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }


}

// ── Single Mushaf Page with Auto-Scroll ──────────────────────────────────
class _MushafPageView extends StatefulWidget {
  final QuranPage page;
  final List<QuranSurah> allSurahs;
  final double fontSize;
  final Color primaryGreen;
  final Color accentGold;
  final bool isDark;
  final String Function(int) toArabicNumber;
  final int highlightVerseIndex;
  final int longPressHighlightIndex;
  final bool isAudioPlaying;
  final bool showScrollControls;
  final bool eachAyahPerLine;
  final bool tafsirMode;
  final void Function(int verseIndex)? onPlayFromVerse;
  final void Function(int surahIdx, int verseNum, int vIdx)? onLongPressVerse;
  final void Function(int surahIdx, int verseNum, int vIdx)? onTapVerse;

  const _MushafPageView({
    required this.page,
    required this.allSurahs,
    required this.fontSize,
    required this.primaryGreen,
    required this.accentGold,
    required this.isDark,
    required this.toArabicNumber,
    this.highlightVerseIndex = -1,
    this.longPressHighlightIndex = -1,
    this.isAudioPlaying = false,
    required this.showScrollControls,
    this.eachAyahPerLine = false,
    this.tafsirMode = false,
    this.onPlayFromVerse,
    this.onLongPressVerse,
    this.onTapVerse,
  });

  @override
  State<_MushafPageView> createState() => _MushafPageViewState();
}

class _MushafPageViewState extends State<_MushafPageView>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  bool _isAutoScrolling = false;
  double _scrollSpeed = 0.8;
  late AnimationController _autoScrollController;

  @override
  void initState() {
    super.initState();
    _autoScrollController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_onAutoScrollTick);
  }

  void _onAutoScrollTick() {
    if (!_isAutoScrolling || !_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final current = _scrollController.offset;
    if (current >= maxScroll) {
      _stopAutoScroll();
      return;
    }
    _scrollController.jumpTo(current + _scrollSpeed * 0.5);
  }

  void _startAutoScroll() {
    setState(() => _isAutoScrolling = true);
    _autoScrollController.repeat();
  }

  void _stopAutoScroll() {
    setState(() => _isAutoScrolling = false);
    _autoScrollController.stop();
  }

  void _toggleAutoScroll() {
    if (_isAutoScrolling) {
      _stopAutoScroll();
    } else {
      _startAutoScroll();
    }
  }

  @override
  void dispose() {
    _autoScrollController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.page.surahGroups.isEmpty) return _buildEmptyPage();

    return Stack(
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is UserScrollNotification && _isAutoScrolling) {
              _stopAutoScroll();
            }
            return false;
          },
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: EdgeInsets.fromLTRB(
                16, 16, 16, widget.showScrollControls ? 90 : 16),
            child: Column(
              children: widget.eachAyahPerLine 
                  ? _buildAyahPerLineLayout() 
                  : _buildContinuousLayout(),
            ),
          ),
        ),
        if (widget.showScrollControls)
          Positioned(
            bottom: 12,
            left: 12,
            right: 12,
            child: _buildAutoScrollBar(),
          ),
      ],
    );
  }

  List<Widget> _buildContinuousLayout() {
    final List<Widget> children = [];
    int verseIndex = 0;
    for (int i = 0; i < widget.page.surahGroups.length; i++) {
        final group = widget.page.surahGroups[i];
        if (group.isFirstVerseOfSurah) {
            children.add(_buildSurahHeader(group));
        }
        children.add(_buildContinuousVerses(group, verseIndex));
        verseIndex += group.verses.length;
    }
    return children;
  }

  List<Widget> _buildAyahPerLineLayout() {
    final List<Widget> children = [];
    int verseIndex = 0;
    for (int i = 0; i < widget.page.surahGroups.length; i++) {
        final group = widget.page.surahGroups[i];
        if (group.isFirstVerseOfSurah) {
            children.add(_buildSurahHeader(group));
        }
        for (final verse in group.verses) {
            children.add(_buildTappableVerseBox(group, verse, verseIndex));
            verseIndex++;
        }
    }
    return children;
  }

  String _removeBasmalah(String text, bool isFirstOfSurah) {
    if (!isFirstOfSurah) return text;
    String cleanText = text;
    final variations = [
      'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
      'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
      'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
      'بسم الله الرحمن الرحيم'
    ];
    for (final v in variations) {
      if (cleanText.startsWith(v)) {
        cleanText = cleanText.substring(v.length).trim();
      }
    }
    return cleanText;
  }

  Widget _buildTappableVerseBox(PageSurahGroup group, QuranVerse verse, int vIdx) {
    final isAudioHighlighted = widget.isAudioPlaying && vIdx == widget.highlightVerseIndex;
    final isLongPressHighlighted = vIdx == widget.longPressHighlightIndex;
    final isHighlighted = isAudioHighlighted || isLongPressHighlighted;

    final bgColor = isHighlighted 
        ? (widget.isDark ? const Color(0xFF1B5E20) : const Color(0xFFC8E6C9))
        : (widget.isDark ? Colors.grey[850] : Colors.white);
        
    final borderColor = isHighlighted
        ? widget.primaryGreen
        : (widget.isDark ? Colors.grey[800]! : Colors.grey[200]!);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(widget.isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (widget.tafsirMode) {
              widget.onTapVerse?.call(group.surahNumber, verse.numberInSurah, vIdx);
            } else {
              widget.onPlayFromVerse?.call(vIdx);
            }
          },
          onLongPress: () => widget.onLongPressVerse?.call(group.surahNumber, verse.numberInSurah, vIdx),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Start audio button
                    IconButton(
                      icon: Icon(Icons.play_circle_filled_rounded, color: widget.primaryGreen),
                      onPressed: () => widget.onPlayFromVerse?.call(vIdx),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: widget.primaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'آية ${widget.toArabicNumber(verse.numberInSurah)}',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: widget.primaryGreen,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _removeBasmalah(verse.text, verse.numberInSurah == 1 && group.surahNumber != 1),
                  textAlign: TextAlign.justify,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: widget.fontSize,
                    height: 2.0,
                    color: widget.isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSurahHeader(PageSurahGroup group) {
    final fullSurah = widget.allSurahs.firstWhere(
      (s) => s.number == group.surahNumber,
      orElse: () => QuranSurah(number: group.surahNumber, name: group.surahName, englishName: '', englishNameTranslation: '', revelationType: group.revelationType, ayahs: []),
    );
    final totalVerses = fullSurah.ayahs.isNotEmpty ? fullSurah.ayahs.length : group.verses.length;
    final isMeccan = group.revelationType == 'Meccan';
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20, top: 12),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: widget.primaryGreen,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: widget.primaryGreen.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            group.surahName,
            style: const TextStyle(
              fontFamily: 'Amiri',
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isMeccan ? 'مكية • آياتها $totalVerses' : 'مدنية • آياتها $totalVerses',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          if (group.surahNumber != 9 && group.surahNumber != 1) ...[
            const SizedBox(height: 16),
            const Text(
              'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 22,
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContinuousVerses(PageSurahGroup group, int startVerseIndex) {
    final List<InlineSpan> allSpans = [];
    final textColor = widget.isDark ? Colors.white : const Color(0xFF2C2C2C);
    final verseNumColor = widget.accentGold;
    final highlightBg = widget.isDark
        ? const Color(0xFF1B5E20) // Deep dark green
        : const Color(0xFFC8E6C9); // Light green 100

    int verseIndex = startVerseIndex;
    for (final verse in group.verses) {
      final isAudioHighlighted =
            widget.isAudioPlaying && verseIndex == widget.highlightVerseIndex;
      final isLongPressHighlighted = verseIndex == widget.longPressHighlightIndex;
      final isHighlighted = isAudioHighlighted || isLongPressHighlighted;

      final highlightColor = isAudioHighlighted ? widget.accentGold : widget.primaryGreen;
      
      // Capture context for closures
      final int currentVIdx = verseIndex;

      allSpans.add(
        TextSpan(
          text: _removeBasmalah(verse.text, verse.numberInSurah == 1 && group.surahNumber != 1),
          style: TextStyle(
            fontFamily: 'Amiri',
            fontSize: widget.fontSize,
            height: 2.2,
            color: isHighlighted ? highlightColor : textColor,
            backgroundColor: isHighlighted ? highlightBg : null,
          ),
          recognizer: widget.tafsirMode
            ? (TapGestureRecognizer()
                ..onTap = () {
                  widget.onTapVerse?.call(
                      group.surahNumber, verse.numberInSurah, currentVIdx);
                })
            : (LongPressGestureRecognizer()
                ..onLongPress = () {
                  widget.onLongPressVerse?.call(
                      group.surahNumber, verse.numberInSurah, currentVIdx);
                }),
        ),
      );

      allSpans.add(
        TextSpan(
          text: ' ﴿${widget.toArabicNumber(verse.numberInSurah)}﴾ ',
          style: TextStyle(
            fontFamily: 'Amiri',
            fontSize: widget.fontSize * 0.8,
            color: verseNumColor,
            fontWeight: FontWeight.bold,
            backgroundColor: isHighlighted ? highlightBg : null,
          ),
          recognizer: widget.tafsirMode
            ? (TapGestureRecognizer()
                ..onTap = () {
                  widget.onTapVerse?.call(
                      group.surahNumber, verse.numberInSurah, currentVIdx);
                })
            : (LongPressGestureRecognizer()
                ..onLongPress = () {
                  widget.onLongPressVerse?.call(
                      group.surahNumber, verse.numberInSurah, currentVIdx);
                }),
        ),
      );
      verseIndex++;
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: RichText(
        textAlign: TextAlign.justify,
        text: TextSpan(children: allSpans),
      ),
    );
  }

  Widget _buildEmptyPage() {
    return Center(
      child: Text(
        'الصفحة غير متوفرة',
        style: TextStyle(
            fontFamily: 'Tajawal',
            color: widget.isDark ? Colors.white70 : Colors.black54),
      ),
    );
  }

  Widget _buildAutoScrollBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(_isAutoScrolling
                ? Icons.pause_circle_filled
                : Icons.play_circle_filled),
            color: widget.primaryGreen,
            iconSize: 32,
            onPressed: _toggleAutoScroll,
          ),
          const SizedBox(width: 8),
          const Icon(Icons.speed, size: 16, color: Colors.grey),
          Expanded(
            child: Slider(
              value: _scrollSpeed,
              min: 0.2,
              max: 3.0,
              activeColor: widget.primaryGreen,
              onChanged: (val) => setState(() => _scrollSpeed = val),
            ),
          ),
          Text(
            '${_scrollSpeed.toStringAsFixed(1)}x',
            style: const TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 12,
                fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
