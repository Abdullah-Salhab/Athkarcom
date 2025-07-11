import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  ReportsScreenState createState() => ReportsScreenState();
}

class ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic> completionData = {};
  bool isLoading = true;
  bool isDarkTheme = false;

  // Section definitions
  final Map<int, String> sections = {
    1: "أذكار الصباح",
    2: "أذكار المساء",
    5: "الأذكار بعد السلام من الصلاة",
    6: "أذكار النوم"
  };

  final Map<int, IconData> sectionIcons = {
    1: Icons.wb_sunny,
    2: Icons.nights_stay,
    5: Icons.mosque,
    6: Icons.bedtime
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    loadCompletionData();
    getCurrentTheme();
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

  Future<void> loadCompletionData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString('athkar_completion_data');

    if (data != null) {
      setState(() {
        completionData = json.decode(data);
        isLoading = false;
      });
    } else {
      setState(() {
        completionData = {};
        isLoading = false;
      });
    }
  }

  // Get theme colors
  Color get backgroundColor =>
      isDarkTheme ? const Color(0xFF1A1A1A) : const Color(0xFFF5F7FA);

  Color get cardColor => isDarkTheme ? const Color(0xFF2C2C2C) : Colors.white;

  Color get textColor => isDarkTheme ? Colors.white : const Color(0xFF2C3E50);

  Color get secondaryTextColor =>
      isDarkTheme ? Colors.white70 : const Color(0xFF5D6D7E);

  Color get primaryColor =>
      isDarkTheme ? const Color(0xFF66BB6A) : const Color(0xFF4CAF50);

  Color get appBarColor =>
      isDarkTheme ? const Color(0xFF2C2C2C) : const Color(0xFF4CAF50);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: appBarColor,
        foregroundColor: Colors.white,
        title: const Text(
          'تقارير الأذكار',
          style: TextStyle(
            fontFamily: 'Amiri',
            fontSize: 22.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'اليوم'),
            Tab(text: 'الأسبوع'),
            Tab(text: 'الشهر'),
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
              ],
            ),
    );
  }

  Widget _buildDailyView() {
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    Map<String, dynamic> todayData = completionData[today] ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTodayOverview(todayData),
          const SizedBox(height: 20),
          _buildSectionsList(todayData),
          const SizedBox(height: 20),
          _buildStreakCard(),
        ],
      ),
    );
  }

  Widget _buildTodayOverview(Map<String, dynamic> todayData) {
    int completedCount = todayData.length;
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
      DateTime day = DateTime.now().subtract(Duration(days: i));
      String dayKey = DateFormat('yyyy-MM-dd').format(day);

      // Arabic day names - each day will have unique weekday
      String arabicDayName = _getArabicDayName(day.weekday);
      weekDays.add(arabicDayName);

      Map<String, dynamic> dayData = completionData[dayKey] ?? {};
      double completionRate =
          sections.length > 0 ? dayData.length / sections.length : 0;
      spots.add(FlSpot(6 - i.toDouble(), completionRate * 100));
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
      DateTime day = DateTime.now().subtract(Duration(days: i));
      String dayKey = DateFormat('yyyy-MM-dd').format(day);
      Map<String, dynamic> dayData = completionData[dayKey] ?? {};

      if (dayData.isNotEmpty) {
        completedDays++;
      }

      totalSections += sections.length;
      completedSections += dayData.length;
    }

    return Column(
      children: [
        _buildStatCard('الأيام النشطة', '$completedDays من $totalDays',
            Icons.calendar_today),
        _buildStatCard('إجمالي الأذكار', '$completedSections من $totalSections',
            Icons.bookmark),
        _buildStatCard(
            'معدل الإنجاز',
            '${((completedSections / totalSections) * 100).toInt()}%',
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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

    String currentMonth = DateFormat('yyyy-MM').format(DateTime.now());

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
                        List<String> labels = ['صباح', 'مساء', 'صلاة', 'نوم'];
                        if (value.toInt() < labels.length) {
                          return Text(
                            labels[value.toInt()],
                            style: TextStyle(
                              color: secondaryTextColor,
                              fontSize: 12,
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
    DateTime now = DateTime.now();
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

              double completionRate = dayData.length / sections.length;
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

  int _calculateStreak() {
    int streak = 0;
    DateTime checkDate = DateTime.now();

    while (true) {
      String dateKey = DateFormat('yyyy-MM-dd').format(checkDate);
      Map<String, dynamic> dayData = completionData[dateKey] ?? {};

      if (dayData.length == sections.length) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }
}
