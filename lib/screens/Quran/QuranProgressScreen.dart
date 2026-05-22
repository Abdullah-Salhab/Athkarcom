import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../models/AnalyticsMixin.dart';
import '../../models/quran_bookmark_service.dart';
import '../../models/quran_model.dart';

class QuranProgressScreen extends StatefulWidget {
  final List<QuranPage> pages;

  const QuranProgressScreen({super.key, required this.pages});

  @override
  State<QuranProgressScreen> createState() => _QuranProgressScreenState();
}

class _QuranProgressScreenState extends State<QuranProgressScreen>
    with AnalyticsMixin {
  @override
  String get screenName => 'QuranProgressScreen';

  Set<int> _readPages = {};
  double _progress = 0.0;
  List<MapEntry<int, DateTime>> _recentlyRead = [];
  Map<int, int> _juzReadCount = {};
  Map<int, int> _juzTotalCount = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final read = await QuranBookmarkService.getReadPages();
    final progress = await QuranBookmarkService.getProgressPercentage();
    final recent = await QuranBookmarkService.getRecentlyRead();

    final Map<int, Set<int>> juzPageMap = {};
    for (final page in widget.pages) {
      juzPageMap.putIfAbsent(page.juz, () => {}).add(page.pageNumber);
    }

    final juzTotal = <int, int>{};
    for (final entry in juzPageMap.entries) {
      juzTotal[entry.key] = entry.value.length;
    }

    final juzRead =
        await QuranBookmarkService.getReadCountPerJuz(juzPageMap);

    setState(() {
      _readPages = read;
      _progress = progress;
      _recentlyRead = recent;
      _juzReadCount = juzRead;
      _juzTotalCount = juzTotal;
      _isLoading = false;
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

  String _getPageTitle(int number) {
    final page = widget.pages.firstWhere((p) => p.pageNumber == number,
        orElse: () => widget.pages.first);
    if (page.surahGroups.isEmpty) return 'صفحة ${_toArabicNumber(number)}';
    return '${page.surahGroups.first.surahName} • صفحة ${_toArabicNumber(number)}';
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) {
      return 'منذ ${_toArabicNumber(diff.inMinutes)} دقيقة';
    }
    if (diff.inHours < 24) {
      return 'منذ ${_toArabicNumber(diff.inHours)} ساعة';
    }
    if (diff.inDays < 7) return 'منذ ${_toArabicNumber(diff.inDays)} يوم';
    return '${_toArabicNumber(dt.day)}/${_toArabicNumber(dt.month)}/${_toArabicNumber(dt.year)}';
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
          'تقدم القراءة',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // ── Circular Progress ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          primaryGreen,
                          primaryGreen.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
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
                        SizedBox(
                          width: 140,
                          height: 140,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CircularProgressIndicator(
                                value: _progress,
                                strokeWidth: 10,
                                backgroundColor:
                                    Colors.white.withOpacity(0.2),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    accentGold),
                              ),
                              Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${(_progress * 100).toStringAsFixed(1)}%',
                                      style: const TextStyle(
                                        fontFamily: 'Tajawal',
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      '${_toArabicNumber(_readPages.length)} / ${_toArabicNumber(604)}',
                                      style: TextStyle(
                                        fontFamily: 'Tajawal',
                                        fontSize: 14,
                                        color: Colors.white.withOpacity(0.8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'صفحة مكتملة',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Juz Progress Chart (vertical bars, proportional fill) ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color:
                          isDark ? const Color(0xFF252525) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withOpacity(isDark ? 0.15 : 0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'التقدم حسب الجزء',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 220,
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: 1.0, // Normalized: 100%
                              barTouchData: BarTouchData(
                                touchTooltipData: BarTouchTooltipData(
                                  getTooltipItem: (group, groupIndex,
                                      rod, rodIndex) {
                                    final juz = group.x + 1;
                                    final read =
                                        _juzReadCount[juz] ?? 0;
                                    final total =
                                        _juzTotalCount[juz] ?? 0;
                                    return BarTooltipItem(
                                      'جزء ${_toArabicNumber(juz)}\n${_toArabicNumber(read)} / ${_toArabicNumber(total)}',
                                      const TextStyle(
                                        fontFamily: 'Tajawal',
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              titlesData: FlTitlesData(
                                show: true,
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      final juz = value.toInt() + 1;
                                      if (juz % 5 == 0 || juz == 1) {
                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(top: 4),
                                          child: Text(
                                            _toArabicNumber(juz),
                                            style: TextStyle(
                                              fontFamily: 'Tajawal',
                                              fontSize: 9,
                                              color: isDark
                                                  ? Colors.grey[400]
                                                  : Colors.grey[600],
                                            ),
                                          ),
                                        );
                                      }
                                      return const SizedBox.shrink();
                                    },
                                    reservedSize: 22,
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      if (value == 0 ||
                                          value == 0.5 ||
                                          value == 1.0) {
                                        return Text(
                                          '${(value * 100).toInt()}%',
                                          style: TextStyle(
                                            fontFamily: 'Tajawal',
                                            fontSize: 9,
                                            color: isDark
                                                ? Colors.grey[500]
                                                : Colors.grey[500],
                                          ),
                                        );
                                      }
                                      return const SizedBox.shrink();
                                    },
                                    reservedSize: 32,
                                  ),
                                ),
                                topTitles: const AxisTitles(
                                  sideTitles:
                                      SideTitles(showTitles: false),
                                ),
                                rightTitles: const AxisTitles(
                                  sideTitles:
                                      SideTitles(showTitles: false),
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                horizontalInterval: 0.5,
                                getDrawingHorizontalLine: (value) {
                                  return FlLine(
                                    color: isDark
                                        ? Colors.grey[800]!
                                        : Colors.grey[200]!,
                                    strokeWidth: 0.5,
                                  );
                                },
                              ),
                              barGroups: List.generate(30, (i) {
                                final juz = i + 1;
                                final read =
                                    (_juzReadCount[juz] ?? 0).toDouble();
                                final total =
                                    (_juzTotalCount[juz] ?? 1).toDouble();
                                final ratio = total > 0
                                    ? (read / total).clamp(0.0, 1.0)
                                    : 0.0;

                                return BarChartGroupData(
                                  x: i,
                                  barRods: [
                                    BarChartRodData(
                                      toY: 1.0, // Full height
                                      width: 7,
                                      borderRadius:
                                          BorderRadius.circular(3),
                                      color: isDark
                                          ? Colors.grey[800]!
                                          : Colors.grey[200]!,
                                      rodStackItems: [
                                        BarChartRodStackItem(
                                          0,
                                          ratio,
                                          primaryGreen,
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              }),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Recently Read ──
                  if (_recentlyRead.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF252525)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withOpacity(isDark ? 0.15 : 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'آخر ما قرأت',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color:
                                  isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...List.generate(
                            _recentlyRead.length,
                            (i) {
                              final entry = _recentlyRead[i];
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 6),
                                child: Row(
                                  textDirection: TextDirection.rtl,
                                  children: [
                                    Icon(Icons.check_circle,
                                        size: 18, color: primaryGreen),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _getPageTitle(entry.key),
                                        textDirection: TextDirection.rtl,
                                        style: TextStyle(
                                          fontFamily: 'Amiri',
                                          fontSize: 16,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      _formatDate(entry.value),
                                      style: TextStyle(
                                        fontFamily: 'Tajawal',
                                        fontSize: 11,
                                        color: isDark
                                            ? Colors.grey[400]
                                            : Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }
}
