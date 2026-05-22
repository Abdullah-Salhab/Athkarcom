import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';

import '../../models/AnalyticsMixin.dart';
import '../../models/quran_bookmark_service.dart';
import '../../models/quran_model.dart';
import 'QuranPageReadingScreen.dart';
import 'QuranProgressScreen.dart';
import 'QuranSearchScreen.dart';

class QuranSurahListScreen extends StatefulWidget {
  const QuranSurahListScreen({super.key});

  @override
  State<QuranSurahListScreen> createState() => _QuranSurahListScreenState();
}

class _QuranSurahListScreenState extends State<QuranSurahListScreen>
    with AnalyticsMixin {
  @override
  String get screenName => 'QuranSurahListScreen';

  List<QuranSurah> _allSurahs = [];
  List<QuranSurah> _filteredSurahs = [];
  List<QuranPage> _allPages = [];
  List<QuranPage> _filteredPages = [];
  List<QuranPage> _bookmarkedPages = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  int _selectedJuz = 0;
  int? _lastReadPage;


  // Mode: 0 = Surah, 1 = Page
  int _viewMode = 0;

  @override
  void initState() {
    super.initState();
    _loadSurahs();
  }

  Future<void> _loadSurahs() async {
    final surahs = await QuranData.loadSurahs();
    final pages = await QuranData.loadPages();
    final lastReadPage = await QuranBookmarkService.getLastReadPage();
    final bookmarks = await QuranBookmarkService.getBookmarks();

    setState(() {
      _allSurahs = surahs;
      _filteredSurahs = surahs;
      _allPages = pages;
      _filteredPages = pages;
      _lastReadPage = lastReadPage;
      _bookmarkedPages = pages.where((p) => bookmarks.any((b) => b.pageNumber == p.pageNumber)).toList();
      _isLoading = false;
    });
  }

  void _refreshState() async {
    final lastReadPage = await QuranBookmarkService.getLastReadPage();
    final bookmarks = await QuranBookmarkService.getBookmarks();
    if (mounted) {
      setState(() {
        _lastReadPage = lastReadPage;
        if (_allPages.isNotEmpty) {
           _bookmarkedPages = _allPages.where((p) => bookmarks.any((b) => b.pageNumber == p.pageNumber)).toList();
        }
      });
    }
  }

  void _applyFilters() {
    final query = _searchController.text;
    setState(() {
      // Filter surahs
      List<QuranSurah> surahResult = _allSurahs;
      if (_selectedJuz > 0) {
        surahResult = surahResult
            .where((s) => s.juzNumbers.contains(_selectedJuz))
            .toList();
      }
      if (query.isNotEmpty) {
        final cleanQuery = removeDiacritics(query);
        surahResult = surahResult.where((s) {
          final cleanName = removeDiacritics(s.name);
          return cleanName.contains(cleanQuery) ||
              s.englishName.toLowerCase().contains(query.toLowerCase()) ||
              s.number.toString() == query;
        }).toList();
      }
      _filteredSurahs = surahResult;

      // Filter pages (by surah name or page number)
      List<QuranPage> pageResult = _allPages;
      if (_selectedJuz > 0) {
        pageResult =
            pageResult.where((p) => p.juz == _selectedJuz).toList();
      }
      if (query.isNotEmpty) {
        final cleanQuery = removeDiacritics(query);
        final pageNum = int.tryParse(query);
        pageResult = pageResult.where((p) {
          // Match by page number
          if (pageNum != null && p.pageNumber == pageNum) return true;
          // Match by any surah name on the page
          return p.surahGroups.any((g) {
            final cleanName = removeDiacritics(g.surahName);
            return cleanName.contains(cleanQuery);
          });
        }).toList();
      }
      _filteredPages = pageResult;
    });
  }

  String _toArabicNumber(int number) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number
        .toString()
        .split('')
        .map((d) => arabicDigits[int.parse(d)])
        .join();
  }

  @override
  void dispose() {
    _searchController.dispose();
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
      body: CustomScrollView(
        slivers: [
          // ── Gradient AppBar ──
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            backgroundColor: primaryGreen,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              // Verse search
              IconButton(
                icon: const Icon(Icons.search, color: Colors.white, size: 22),
                tooltip: 'بحث في الآيات',
                onPressed: () async {
                  if (_allSurahs.isNotEmpty) {
                    await Navigator.push(
                      context,
                      PageTransition(
                        type: PageTransitionType.rightToLeftWithFade,
                        duration: const Duration(milliseconds: 400),
                        reverseDuration: const Duration(milliseconds: 400),
                        child: QuranSearchScreen(surahs: _allSurahs, pages: _allPages),
                      ),
                    );
                    _refreshState();
                  }
                },
              ),
              // Progress
              IconButton(
                icon: const Icon(Icons.bar_chart_rounded,
                    color: Colors.white, size: 22),
                tooltip: 'تقدم القراءة',
                onPressed: () async {
                  if (_allPages.isNotEmpty) {
                    await Navigator.push(
                      context,
                      PageTransition(
                        type: PageTransitionType.rightToLeftWithFade,
                        duration: const Duration(milliseconds: 400),
                        reverseDuration: const Duration(milliseconds: 400),
                        child: QuranProgressScreen(pages: _allPages),
                      ),
                    );
                    _refreshState();
                  }
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      primaryGreen,
                      primaryGreen.withOpacity(0.7),
                      const Color(0xFF004D40),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(
                        top: 10, left: 20, right: 20, bottom: 50),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'القرآن الكريم',
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _viewMode == 0 ? '١١٤ سورة' : _viewMode == 1 ? '٦٠٤ صفحات' : '${_bookmarkedPages.length} علامة مرجعية',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(52),
              child: Container(
                height: 44,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => _applyFilters(),
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 14,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    hintText: 'ابحث عن سورة...',
                    hintStyle: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[500],
                    ),
                    prefixIcon:
                        Icon(Icons.search, size: 20, color: primaryGreen),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                  ),
                ),
              ),
            ),
          ),

          // ── Mode Toggle (سور / صفحات) ──
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.grey[100],
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  _buildModeTab(
                    label: 'سور',
                    icon: Icons.menu_book_rounded,
                    isSelected: _viewMode == 0,
                    primaryGreen: primaryGreen,
                    isDark: isDark,
                    onTap: () => setState(() => _viewMode = 0),
                  ),
                  _buildModeTab(
                    label: 'صفحات',
                    icon: Icons.auto_stories_rounded,
                    isSelected: _viewMode == 1,
                    primaryGreen: primaryGreen,
                    isDark: isDark,
                    onTap: () => setState(() => _viewMode = 1),
                  ),
                  _buildModeTab(
                    label: 'مرجعيات',
                    icon: Icons.bookmark_rounded,
                    isSelected: _viewMode == 2,
                    primaryGreen: primaryGreen,
                    isDark: isDark,
                    onTap: () => setState(() => _viewMode = 2),
                  ),
                ],
              ),
            ),
          ),

          // ── Last Read Banner (Unified Page-Based) ──
          if (_lastReadPage != null && _allPages.isNotEmpty)
            SliverToBoxAdapter(
              child: GestureDetector(
                onTap: () async {
                  await Navigator.push(
                    context,
                    PageTransition(
                      type: PageTransitionType.rightToLeftWithFade,
                      duration: const Duration(milliseconds: 400),
                      reverseDuration: const Duration(milliseconds: 400),
                      child: QuranPageReadingScreen(
                        pages: _allPages,
                        surahs: _allSurahs,
                        initialPage: _lastReadPage!,
                      ),
                    ),
                  );
                  _refreshState();
                },
                child: _buildLastReadBanner(
                  accentGold: accentGold,
                  isDark: isDark,
                  label: '${_allPages[_lastReadPage! - 1].surahGroups.first.surahName} • صفحة ${_toArabicNumber(_lastReadPage!)}',
                  subtitle: 'متابعة القراءة',
                ),
              ),
            ),

          // ── Juz Filter Chips ──
            SliverToBoxAdapter(
              child: SizedBox(
                height: 48,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  itemCount: 31,
                  itemBuilder: (context, index) {
                    final juzNum = index;
                    final isSelected = _selectedJuz == juzNum;
                    return Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: ChoiceChip(
                        label: Text(
                          juzNum == 0
                              ? 'الكل'
                              : 'الجزء ${_toArabicNumber(juzNum)}',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 12,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? Colors.white70 : Colors.black87),
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: primaryGreen,
                        backgroundColor:
                            isDark ? Colors.grey[800] : Colors.grey[100],
                        onSelected: (_) {
                          setState(() => _selectedJuz = juzNum);
                          _applyFilters();
                        },
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                      ),
                    );
                  },
                ),
              ),
            ),

          // ── Content ──
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_viewMode == 0)
            _buildSurahList(primaryGreen, accentGold, isDark)
          else
            _buildPageGrid(primaryGreen, accentGold, isDark),
        ],
      ),
    );
  }

  Widget _buildModeTab({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color primaryGreen,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? primaryGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.grey[400] : Colors.grey[600]),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 14,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.grey[400] : Colors.grey[600]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLastReadBanner({
    required Color accentGold,
    required bool isDark,
    required String label,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accentGold.withOpacity(0.15),
            accentGold.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: accentGold.withOpacity(0.3), width: 0.5),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Icon(Icons.history, color: accentGold, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_left,
              color: accentGold.withOpacity(0.7)),
        ],
      ),
    );
  }

  Widget _buildSurahList(
      Color primaryGreen, Color accentGold, bool isDark) {
    if (_filteredSurahs.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Text(
            'لا توجد نتائج',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 16,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final surah = _filteredSurahs[index];
            return _SurahCard(
              surah: surah,
              accentGold: accentGold,
              primaryGreen: primaryGreen,
              isDark: isDark,
              toArabicNumber: _toArabicNumber,
              isBookmarked: false, // Surah cards don't show bookmarks natively anymore
              isRead: false,
              onTap: () async {
                await Navigator.push(
                  context,
                  PageTransition(
                    type: PageTransitionType.rightToLeftWithFade,
                    duration: const Duration(milliseconds: 400),
                    reverseDuration: const Duration(milliseconds: 400),
                    child: QuranPageReadingScreen(
                      pages: _allPages,
                      surahs: _allSurahs,
                      initialPage: surah.ayahs.first.page,
                    ),
                  ),
                );
                _refreshState();
              },
            );
          },
          childCount: _filteredSurahs.length,
        ),
      ),
    );
  }

  Widget _buildPageGrid(
      Color primaryGreen, Color accentGold, bool isDark) {
    final filteredPages = _viewMode == 2 ? _bookmarkedPages : _filteredPages;

    if (filteredPages.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Text(
            _viewMode == 2 ? 'لا توجد علامات مرجعية' : 'لا توجد نتائج',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 16,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ),
      );
    }

    // Juz Filter Chips for page mode
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 0.85,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final page = filteredPages[index];
            return _PageCard(
              page: page,
              primaryGreen: primaryGreen,
              accentGold: accentGold,
              isDark: isDark,
              toArabicNumber: _toArabicNumber,
              onTap: () async {
                await Navigator.push(
                  context,
                  PageTransition(
                    type: PageTransitionType.rightToLeftWithFade,
                    duration: const Duration(milliseconds: 400),
                    reverseDuration: const Duration(milliseconds: 400),
                    child: QuranPageReadingScreen(
                      pages: _allPages,
                      surahs: _allSurahs,
                      initialPage: page.pageNumber,
                    ),
                  ),
                );
                _refreshState();
              },
            );
          },
          childCount: filteredPages.length,
        ),
      ),
    );
  }
}

// ── Individual Surah Card ──────────────────────────────────────────────────
class _SurahCard extends StatelessWidget {
  final QuranSurah surah;
  final Color accentGold;
  final Color primaryGreen;
  final bool isDark;
  final String Function(int) toArabicNumber;
  final bool isBookmarked;
  final bool isRead;
  final VoidCallback onTap;

  const _SurahCard({
    required this.surah,
    required this.accentGold,
    required this.primaryGreen,
    required this.isDark,
    required this.toArabicNumber,
    required this.isBookmarked,
    required this.isRead,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isMeccan = surah.revelationType == 'Meccan';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Surah number badge
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        primaryGreen,
                        primaryGreen.withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      toArabicNumber(surah.number),
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Tajawal',
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Surah info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        surah.name,
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            isMeccan
                                ? Icons.mosque_outlined
                                : Icons.location_city_outlined,
                            size: 12,
                            color: accentGold,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isMeccan ? 'مكية' : 'مدنية',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 11,
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${toArabicNumber(surah.versesCount)} آية',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 11,
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'جزء ${toArabicNumber(surah.startJuz)}',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 11,
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Status icons
                if (isRead)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Icon(Icons.check_circle,
                        size: 18, color: primaryGreen),
                  ),
                if (isBookmarked)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child:
                        Icon(Icons.bookmark, size: 18, color: accentGold),
                  ),

                Icon(
                  Icons.chevron_left,
                  color: isDark ? Colors.grey[500] : Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Page Card (Grid item for 604-page mode) ────────────────────────────────
class _PageCard extends StatelessWidget {
  final QuranPage page;
  final Color primaryGreen;
  final Color accentGold;
  final bool isDark;
  final String Function(int) toArabicNumber;
  final VoidCallback onTap;

  const _PageCard({
    required this.page,
    required this.primaryGreen,
    required this.accentGold,
    required this.isDark,
    required this.toArabicNumber,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[850] : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Page number
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      primaryGreen,
                      primaryGreen.withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    toArabicNumber(page.pageNumber),
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Tajawal',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              // Surah name (primary)
              Text(
                page.primarySurahName,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              // Juz
              Text(
                'جزء ${toArabicNumber(page.juz)}',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 10,
                  color: isDark ? Colors.grey[500] : Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
