import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/AnalyticsMixin.dart';
import '../models/AthkarWidgetProvider.dart';
import 'AthkarWidgetSetup.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  ReportsScreenState createState() => ReportsScreenState();
}

class ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin, AnalyticsMixin {
  @override
  String get screenName => 'ReportsScreen';

  late TabController _tabController;
  Map<String, dynamic> completionData = {};
  bool isLoading = true;
  bool isDarkTheme = false;
  String? _userName; // CHANGE: To store the current user's name
  DateTime _selectedDailyDate = DateTime.now();
  DateTime _selectedWeeklyEndDate = DateTime.now();
  DateTime _selectedMonthlyDate = DateTime.now();

  // Section definitions
  final Map<int, String> sections = {
    1: "أذكار الصباح",
    2: "أذكار المساء"
  };

  final Map<int, IconData> sectionIcons = {
    1: Icons.wb_sunny,
    2: Icons.nights_stay
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeData();
  }

  // NEW: Method to handle data loading sequence
  Future<void> _initializeData() async {
    await getCurrentTheme();
    await _loadUserDataAndReports();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> getCurrentTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkTheme = prefs.getBool('theme') ?? false;
    });
  }

  // CHANGED: This method now loads data for the specific logged-in user
  Future<void> _loadUserDataAndReports() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName');
      isLoading = true; // Set loading state before fetching data
    });

    if (_userName != null && _userName!.isNotEmpty) {
      // Use a user-specific key to get the report
      String? data = prefs.getString('athkar_completion_data_${_userName!}');
      if (data != null) {
        setState(() {
          completionData = json.decode(data);
        });
      } else {
        // No data found for this user, so we show an empty report
        setState(() {
          completionData = {};
        });
      }
    } else {
      // No user is logged in, show an empty report
      setState(() {
        completionData = {};
      });
    }

    setState(() {
      isLoading = false;
    });

    // Update home widget when data changes
    await _updateHomeWidget();
  }

  // Get theme colors
  Color get backgroundColor =>
      isDarkTheme ? const Color(0xFF1A1A1A) : const Color(0xFFF5F7FA);

  Color get cardColor => isDarkTheme ? const Color(0xFF2C2C2C) : Colors.white;

  Color get textColor => isDarkTheme ? Colors.white : const Color(0xFF2C3E50);

  Color get secondaryTextColor =>
      isDarkTheme ? Colors.white70 : const Color(0xFF5D6D7E);

  Color get primaryColor =>
      isDarkTheme ? const Color(0xFF66BBB1) : const Color(0xFF4CAF95);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text(
          'تقارير الأذكار',
          style: TextStyle(
            fontFamily: 'Amiri',
            fontSize: 22.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AthkarWidgetSetup(),
                  ),
                );
              },
              icon: const Icon(Icons.add_home_outlined))
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'اليوم'),
            Tab(text: 'الأسبوع'),
            Tab(text: 'الشهر'),
            Tab(text: 'الإنجازات'),
          ],
        ),
      ),
      body: isLoading
          ? Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
        ),
      )
          : TabBarView(
        controller: _tabController,
        children: [
          _buildDailyView(),
          _buildWeeklyView(),
          _buildMonthlyView(),
          _buildAchievementsView(),
        ],
      ),
    );
  }

  Widget _buildDailyView() {
    String dayKey = DateFormat('yyyy-MM-dd').format(_selectedDailyDate);
    Map<String, dynamic> dayData = completionData[dayKey] ?? {};

    bool isToday = DateFormat('yyyy-MM-dd').format(_selectedDailyDate) ==
        DateFormat('yyyy-MM-dd').format(DateTime.now());

    String label = "${_getArabicDayNameFull(_selectedDailyDate.weekday)}، ${_selectedDailyDate.day} ${_getArabicMonthName(_selectedDailyDate.month)} ${_selectedDailyDate.year}";

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildNavigationHeader(
            label: label,
            onPrevious: () {
              setState(() {
                _selectedDailyDate = _selectedDailyDate.subtract(const Duration(days: 1));
              });
            },
            onNext: isToday ? null : () {
              setState(() {
                _selectedDailyDate = _selectedDailyDate.add(const Duration(days: 1));
              });
            },
          ),
          const SizedBox(height: 16),
          _buildTodayOverview(dayData),
          const SizedBox(height: 20),
          _buildSectionsList(dayData),
          const SizedBox(height: 20),
          _buildStreakCard(),
        ],
      ),
    );
  }

  Widget _buildTodayOverview(Map<String, dynamic> todayData) {
    int completedCount = _getCompletedCountForDay(todayData);
    int totalCount = sections.length;
    double percentage = totalCount > 0 ? (completedCount / totalCount) : 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'إنجاز اليوم',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  fontFamily: 'Amiri',
                ),
              ),
              Text(
                DateFormat('dd/MM/yyyy').format(DateTime.now()),
                style: TextStyle(
                  fontSize: 14,
                  color: secondaryTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            width: 120,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    color: primaryColor,
                    value: completedCount.toDouble(),
                    title: '$completedCount',
                    radius: 40,
                    titleStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    color: Colors.grey.withOpacity(0.3),
                    value: (totalCount - completedCount).toDouble(),
                    title: '${totalCount - completedCount}',
                    radius: 35,
                    titleStyle: TextStyle(
                      fontSize: 14,
                      color: secondaryTextColor,
                    ),
                  ),
                ],
                sectionsSpace: 2,
                centerSpaceRadius: 30,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${(percentage * 100).toInt()}% مكتمل',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          Text(
            '$completedCount من $totalCount أذكار',
            style: TextStyle(
              fontSize: 14,
              color: secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionsList(Map<String, dynamic> todayData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'تفاصيل الأذكار',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textColor,
            fontFamily: 'Amiri',
          ),
        ),
        const SizedBox(height: 12),
        ...sections.entries.map((entry) {
          bool isCompleted = todayData.containsKey(entry.key.toString());
          return _buildSectionCard(entry.key, entry.value, isCompleted);
        }).toList(),
      ],
    );
  }

  Widget _buildSectionCard(
      int sectionId, String sectionName, bool isCompleted) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted ? primaryColor : Colors.grey.withOpacity(0.2),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            sectionIcons[sectionId] ?? Icons.book,
            color: isCompleted ? primaryColor : secondaryTextColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              sectionName,
              style: TextStyle(
                fontSize: 16,
                color: textColor,
                fontFamily: 'Amiri',
              ),
            ),
          ),
          Icon(
            isCompleted ? Icons.check_circle : Icons.circle_outlined,
            color: isCompleted ? primaryColor : Colors.grey,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCard() {
    int streak = _calculateStreak();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.local_fire_department,
            color: Colors.orange,
            size: 30,
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'سلسلة الأيام',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  fontFamily: 'Amiri',
                ),
              ),
              Text(
                '$streak أيام متتالية',
                style: TextStyle(
                  fontSize: 14,
                  color: secondaryTextColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyView() {
    DateTime startDate = _selectedWeeklyEndDate.subtract(const Duration(days: 6));
    String label = "${startDate.day} ${_getArabicMonthName(startDate.month)} - ${_selectedWeeklyEndDate.day} ${_getArabicMonthName(_selectedWeeklyEndDate.month)} ${_selectedWeeklyEndDate.year}";

    bool isCurrentWeek = _selectedWeeklyEndDate.isAfter(DateTime.now().subtract(const Duration(days: 1)));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildNavigationHeader(
            label: label,
            onPrevious: () {
              setState(() {
                _selectedWeeklyEndDate = _selectedWeeklyEndDate.subtract(const Duration(days: 7));
              });
            },
            onNext: isCurrentWeek ? null : () {
              setState(() {
                DateTime newDate = _selectedWeeklyEndDate.add(const Duration(days: 7));
                if (newDate.isAfter(DateTime.now())) {
                  _selectedWeeklyEndDate = DateTime.now();
                } else {
                  _selectedWeeklyEndDate = newDate;
                }
              });
            },
          ),
          const SizedBox(height: 16),
          _buildWeeklyChart(),
          const SizedBox(height: 20),
          _buildWeeklyStats(),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart() {
    List<FlSpot> spots = [];
    List<String> weekDays = [];

    for (int i = 6; i >= 0; i--) {
      DateTime day = _selectedWeeklyEndDate.subtract(Duration(days: i));
      String dayKey = DateFormat('yyyy-MM-dd').format(day);

      // Arabic day names - each day will have unique weekday
      String arabicDayName = _getArabicDayName(day.weekday);
      weekDays.add(arabicDayName);

      Map<String, dynamic> dayData = completionData[dayKey] ?? {};
      double completionRate =
      sections.length > 0 ? _getCompletedCountForDay(dayData) / sections.length : 0;
      double percentage = completionRate * 100;
      double formattedPercentage = double.parse(percentage.toStringAsFixed(1));
      spots.add(FlSpot(6 - i.toDouble(), formattedPercentage));
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'أداء الأسبوع',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
              fontFamily: 'Amiri',
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}%',
                          style: TextStyle(
                            color: secondaryTextColor,
                            fontSize: 12,
                          ),
                        );
                      },
                      reservedSize: 40,
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() < weekDays.length) {
                          return Text(
                            weekDays[value.toInt()],
                            style: TextStyle(
                              color: secondaryTextColor,
                              fontSize: 12,
                              fontFamily: 'Amiri', // Added for Arabic text
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: primaryColor,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: primaryColor.withOpacity(0.1),
                    ),
                    preventCurveOverShooting:
                    true, // Prevents the curve from going outside bounds
                  ),
                ],
                minY: 0,
                maxY: 100,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to get Arabic day names (abbreviated)
  String _getArabicDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'الإثنين';
      case 2:
        return 'الثلاثاء';
      case 3:
        return 'الأربعاء';
      case 4:
        return 'الخميس';
      case 5:
        return 'الجمعة';
      case 6:
        return 'السبت';
      case 7:
        return 'الأحد';
      default:
        return '';
    }
  }

  Widget _buildWeeklyStats() {
    int totalDays = 7;
    int completedDays = 0;
    int totalSections = 0;
    int completedSections = 0;

    for (int i = 0; i < 7; i++) {
      DateTime day = _selectedWeeklyEndDate.subtract(Duration(days: i));
      String dayKey = DateFormat('yyyy-MM-dd').format(day);
      Map<String, dynamic> dayData = completionData[dayKey] ?? {};

      int completedCount = _getCompletedCountForDay(dayData);
      if (completedCount > 0) {
        completedDays++;
      }

      totalSections += sections.length;
      completedSections += completedCount;
    }

    return Column(
      children: [
        _buildStatCard('الأيام النشطة', '$completedDays من $totalDays',
            Icons.calendar_today),
        _buildStatCard('إجمالي الأذكار', '$completedSections من $totalSections',
            Icons.bookmark),
        _buildStatCard(
            'معدل الإنجاز',
            '${totalSections > 0 ? ((completedSections / totalSections) * 100).toInt() : 0}%',
            Icons.trending_up),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: primaryColor, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: secondaryTextColor,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyView() {
    String label = "${_getArabicMonthName(_selectedMonthlyDate.month)} ${_selectedMonthlyDate.year}";
    bool isCurrentMonth = _selectedMonthlyDate.year == DateTime.now().year &&
        _selectedMonthlyDate.month == DateTime.now().month;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildNavigationHeader(
            label: label,
            onPrevious: () {
              setState(() {
                _selectedMonthlyDate = DateTime(_selectedMonthlyDate.year, _selectedMonthlyDate.month - 1);
              });
            },
            onNext: isCurrentMonth ? null : () {
              setState(() {
                _selectedMonthlyDate = DateTime(_selectedMonthlyDate.year, _selectedMonthlyDate.month + 1);
              });
            },
          ),
          const SizedBox(height: 16),
          _buildMonthlyChart(),
          const SizedBox(height: 20),
          _buildMonthlyCalendar(),
        ],
      ),
    );
  }

  Widget _buildMonthlyChart() {
    Map<int, int> sectionCompletions = {};

    for (int sectionId in sections.keys) {
      sectionCompletions[sectionId] = 0;
    }

    String currentMonth = DateFormat('yyyy-MM').format(_selectedMonthlyDate);

    completionData.forEach((dateKey, dayData) {
      if (dateKey.startsWith(currentMonth)) {
        dayData.forEach((sectionIdStr, completed) {
          int sectionId = int.parse(sectionIdStr);
          if (completed && sectionCompletions.containsKey(sectionId)) {
            sectionCompletions[sectionId] = sectionCompletions[sectionId]! + 1;
          }
        });
      }
    });

    List<BarChartGroupData> barGroups = [];
    int index = 0;

    sectionCompletions.forEach((sectionId, count) {
      barGroups.add(
        BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: count.toDouble(),
              color: primaryColor,
              width: 20,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
      index++;
    });

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'إحصائيات الشهر الحالي',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
              fontFamily: 'Amiri',
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 31,
                barGroups: barGroups,
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            color: secondaryTextColor,
                            fontSize: 12,
                          ),
                        );
                      },
                      reservedSize: 30,
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        List<String> labels = ['صباح', 'مساء', 'نوم'];
                        if (value.toInt() < labels.length) {
                          return Text(
                            labels[value.toInt()],
                            style: TextStyle(
                              color: secondaryTextColor,
                              fontSize: 12,
                              fontFamily: 'Amiri',
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyCalendar() {
    DateTime now = _selectedMonthlyDate;
    DateTime lastDayOfMonth = DateTime(now.year, now.month + 1, 0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'تقويم الشهر',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
              fontFamily: 'Amiri',
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: lastDayOfMonth.day,
            itemBuilder: (context, index) {
              DateTime day = DateTime(now.year, now.month, index + 1);
              String dayKey = DateFormat('yyyy-MM-dd').format(day);
              Map<String, dynamic> dayData = completionData[dayKey] ?? {};

              double completionRate =
              sections.isNotEmpty ? _getCompletedCountForDay(dayData) / sections.length : 0.0;
              Color dayColor = completionRate == 1.0
                  ? primaryColor
                  : completionRate > 0
                  ? primaryColor.withOpacity(0.5)
                  : Colors.grey.withOpacity(0.3);

              return Container(
                decoration: BoxDecoration(
                  color: dayColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: completionRate > 0
                          ? Colors.white
                          : secondaryTextColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildLegendItem('مكتمل', primaryColor),
              _buildLegendItem('جزئي', primaryColor.withOpacity(0.5)),
              _buildLegendItem('لم يكتمل', Colors.grey.withOpacity(0.3)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: secondaryTextColor,
          ),
        ),
      ],
    );
  }

  int _getCompletedCountForDay(Map<String, dynamic> dayData) {
    return dayData.entries
        .where((e) => sections.containsKey(int.tryParse(e.key) ?? 0) && e.value == true)
        .length;
  }

  int _calculateStreak() {
    int streak = 0;
    if (sections.isEmpty) return 0;
    DateTime checkDate = DateTime.now();

    // Step 1: If today is not complete, skip it
    String todayKey = DateFormat('yyyy-MM-dd').format(checkDate);
    Map<String, dynamic> todayData = completionData[todayKey] ?? {};
    if (_getCompletedCountForDay(todayData) != sections.length) {
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    // Step 2: Count streak from most recent fully completed day
    while (true) {
      String dateKey = DateFormat('yyyy-MM-dd').format(checkDate);
      Map<String, dynamic> dayData = completionData[dateKey] ?? {};

      if (_getCompletedCountForDay(dayData) == sections.length) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  Future<void> _updateHomeWidget() async {
    await AthkarWidgetProvider.updateWidget();
  }

  int _calculateMaxStreak() {
    if (completionData.isEmpty) return 0;

    List<String> sortedDates = completionData.keys.toList()..sort();
    if (sortedDates.isEmpty) return 0;

    int maxStreak = 0;
    int currentStreak = 0;
    DateTime? prevDate;

    for (String dateStr in sortedDates) {
      try {
        DateTime date = DateFormat('yyyy-MM-dd').parse(dateStr);
        Map<String, dynamic> dayData = completionData[dateStr] ?? {};
        bool isDayComplete = _getCompletedCountForDay(dayData) == sections.length;

        if (isDayComplete) {
          if (prevDate == null) {
            currentStreak = 1;
          } else {
            int diff = date.difference(prevDate).inDays;
            if (diff == 1) {
              currentStreak++;
            } else if (diff > 1) {
              if (currentStreak > maxStreak) {
                maxStreak = currentStreak;
              }
              currentStreak = 1;
            }
          }
          prevDate = date;
        }
      } catch (e) {
        print("Error parsing date in max streak: $e");
      }
    }

    if (currentStreak > maxStreak) {
      maxStreak = currentStreak;
    }

    return maxStreak;
  }

  int _calculateTotalCompleted() {
    int total = 0;
    completionData.forEach((dateKey, dayData) {
      total += _getCompletedCountForDay(dayData);
    });
    return total;
  }

  bool _hasFullyCompletedDay() {
    bool found = false;
    completionData.forEach((dateKey, dayData) {
      if (_getCompletedCountForDay(dayData) == sections.length) {
        found = true;
      }
    });
    return found;
  }

  Widget _buildAchievementsView() {
    int totalCompleted = _calculateTotalCompleted();
    int maxStreak = _calculateMaxStreak();
    bool hasFullyCompletedDay = _hasFullyCompletedDay();

    int totalPoints = totalCompleted * 50;
    int level = (totalPoints / 500).floor() + 1;
    int pointsInCurrentLevel = totalPoints % 500;
    double levelProgress = pointsInCurrentLevel / 500.0;

    final List<Map<String, dynamic>> achievements = [
      {
        'title': 'أول خطوة',
        'desc': 'أكملت ورداً واحداً للأذكار لأول مرة',
        'icon': '🎯',
        'isUnlocked': totalCompleted >= 1,
        'current': totalCompleted.clamp(0, 1),
        'target': 1,
      },
      {
        'title': 'بداية الرحلة',
        'desc': 'أكملت الورد اليومي بالكامل (الصباح والمساء) ليوم واحد',
        'icon': '🚀',
        'isUnlocked': hasFullyCompletedDay,
        'current': hasFullyCompletedDay ? 1 : 0,
        'target': 1,
      },
      {
        'title': 'المثابرة الأسبوعية',
        'desc': 'حافظت على وردك اليومي لمدة 7 أيام متتالية',
        'icon': '🔥',
        'isUnlocked': maxStreak >= 7,
        'current': maxStreak.clamp(0, 7),
        'target': 7,
      },
      {
        'title': 'المداوم المخلص',
        'desc': 'أكملت 50 ورداً من الأذكار في مجموع قراءاتك',
        'icon': '✨',
        'isUnlocked': totalCompleted >= 50,
        'current': totalCompleted.clamp(0, 50),
        'target': 50,
      },
      {
        'title': 'العزم القوي',
        'desc': 'حافظت على وردك اليومي لمدة 30 يوماً متتالية',
        'icon': '📅',
        'isUnlocked': maxStreak >= 30,
        'current': maxStreak.clamp(0, 30),
        'target': 30,
      },
      {
        'title': 'فارس الأذكار',
        'desc': 'أكملت 150 ورداً من الأذكار في مجموع قراءاتك',
        'icon': '👑',
        'isUnlocked': totalCompleted >= 150,
        'current': totalCompleted.clamp(0, 150),
        'target': 150,
      },
      {
        'title': 'بطل الأذكار',
        'desc': 'حافظت على وردك اليومي لمدة 100 يوم متتالي',
        'icon': '🏆',
        'isUnlocked': maxStreak >= 100,
        'current': maxStreak.clamp(0, 100),
        'target': 100,
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Level Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$level',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                            fontFamily: 'Tajawal',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'المستوى الحالي',
                            style: TextStyle(
                              fontSize: 14,
                              color: secondaryTextColor,
                              fontFamily: 'Tajawal',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'نقاط الذكر: $totalPoints نقطة',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                              fontFamily: 'Tajawal',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: levelProgress,
                    minHeight: 10,
                    backgroundColor: isDarkTheme ? Colors.white10 : Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$pointsInCurrentLevel / 500 نقطة للمستوى التالي',
                      style: TextStyle(
                        fontSize: 12,
                        color: secondaryTextColor,
                        fontFamily: 'Tajawal',
                      ),
                    ),
                    Text(
                      '${(levelProgress * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                        fontFamily: 'Tajawal',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Stats Row
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        '📝 أوراد مقروءة',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Tajawal',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$totalCompleted',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                          fontFamily: 'Tajawal',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        '⚡ أطول سلسلة',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Tajawal',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$maxStreak يوم',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                          fontFamily: 'Tajawal',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Section Title
          Text(
            'الأوسمة والإنجازات',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
              fontFamily: 'Tajawal',
            ),
          ),
          const SizedBox(height: 12),

          // Achievements List
          ...achievements.map((ach) {
            bool unlocked = ach['isUnlocked'];
            double progress = ach['current'] / ach['target'];

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: unlocked ? primaryColor.withOpacity(0.3) : Colors.transparent,
                    width: unlocked ? 1.5 : 0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Icon Container
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: unlocked
                            ? primaryColor.withOpacity(0.1)
                            : (isDarkTheme ? Colors.white10 : Colors.grey.shade100),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          ach['icon'],
                          style: TextStyle(
                            fontSize: 26,
                            color: unlocked ? null : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                ach['title'],
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: unlocked ? textColor : textColor.withOpacity(0.5),
                                  fontFamily: 'Tajawal',
                                ),
                              ),
                              if (unlocked)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text(
                                    'مكتمل ✔',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.teal,
                                      fontFamily: 'Tajawal',
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            ach['desc'],
                            style: TextStyle(
                              fontSize: 12,
                              color: unlocked ? secondaryTextColor : secondaryTextColor.withOpacity(0.5),
                              fontFamily: 'Tajawal',
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Mini Progress Bar
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(5),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    minHeight: 6,
                                    backgroundColor: isDarkTheme ? Colors.white10 : Colors.grey.shade200,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      unlocked ? primaryColor : Colors.grey.shade400,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${ach['current']}/${ach['target']}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: unlocked ? primaryColor : Colors.grey,
                                  fontFamily: 'Tajawal',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }


  String _getArabicMonthName(int month) {
    const months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    if (month >= 1 && month <= 12) {
      return months[month - 1];
    }
    return '';
  }

  String _getArabicDayNameFull(int weekday) {
    switch (weekday) {
      case 1: return 'الإثنين';
      case 2: return 'الثلاثاء';
      case 3: return 'الأربعاء';
      case 4: return 'الخميس';
      case 5: return 'الجمعة';
      case 6: return 'السبت';
      case 7: return 'الأحد';
      default: return '';
    }
  }

  Widget _buildNavigationHeader({
    required String label,
    required VoidCallback onPrevious,
    required VoidCallback? onNext,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Next/Newer button (pointing Left in RTL / chronological forward)
          IconButton(
            icon: Icon(
              Icons.chevron_left,
              color: onNext != null ? primaryColor : Colors.grey.shade400,
            ),
            onPressed: onNext,
          ),
          Expanded(
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  fontFamily: 'Tajawal',
                ),
              ),
            ),
          ),
          // Previous/Older button (pointing Right in RTL / chronological backward)
          IconButton(
            icon: Icon(
              Icons.chevron_right,
              color: primaryColor,
            ),
            onPressed: onPrevious,
          ),
        ],
      ),
    );
  }
}
