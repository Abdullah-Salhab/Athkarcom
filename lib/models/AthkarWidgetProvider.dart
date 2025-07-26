import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AthkarWidgetProvider {
  static const String androidWidgetName = 'AthkarWidgetProvider';
  static const String iOSWidgetName = 'AthkarWidget';

  // Section definitions (same as in your ReportsScreen)
  static final Map<int, String> sections = {
    1: "أذكار الصباح",
    2: "أذكار المساء",
    6: "أذكار النوم"
  };

  static Future<void> initializeWidget() async {
    await HomeWidget.setAppGroupId('group.com.athkar.athkarcom');
    await updateWidget();
  }

  static Future<void> updateWidget() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? data = prefs.getString('athkar_completion_data');

      Map<String, dynamic> completionData = {};
      if (data != null) {
        completionData = json.decode(data);
      }

      // Get today's data
      String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      Map<String, dynamic> todayData = completionData[today] ?? {};

      int completedCount = todayData.length;
      int totalCount = sections.length;
      double percentage =
          totalCount > 0 ? (completedCount / totalCount) * 100 : 0;

      // Calculate streak
      int streak = _calculateStreak(completionData);

      // Get completed sections names
      List<String> completedSections = [];
      todayData.forEach((sectionIdStr, completed) {
        if (completed) {
          int sectionId = int.parse(sectionIdStr);
          if (sections.containsKey(sectionId)) {
            completedSections.add(sections[sectionId]!);
          }
        }
      });

      // Update widget data - Save percentage as String to avoid casting issues
      await HomeWidget.saveWidgetData<String>(
          'date', DateFormat('dd/MM/yyyy').format(DateTime.now()));
      await HomeWidget.saveWidgetData<int>('completed_count', completedCount);
      await HomeWidget.saveWidgetData<int>('total_count', totalCount);

      // Save percentage as String to avoid Long/Float casting issues
      await HomeWidget.saveWidgetData<String>(
          'percentage', percentage.toStringAsFixed(1));
      // Also save as int if you need it for progress bars
      await HomeWidget.saveWidgetData<int>(
          'percentage_int', percentage.round());

      await HomeWidget.saveWidgetData<int>('streak', streak);
      await HomeWidget.saveWidgetData<String>(
          'completed_sections', completedSections.join('، '));

      // Update the actual widget
      await HomeWidget.updateWidget(
        androidName: androidWidgetName,
        iOSName: iOSWidgetName,
      );

      print('Widget updated successfully');
    } catch (e) {
      print('Error updating widget: $e');
      // Optionally, you can try to clear problematic data and retry
      await _clearAndRetryUpdate();
    }
  }

  static Future<void> _clearAndRetryUpdate() async {
    try {
      // Clear potentially problematic data
      await HomeWidget.saveWidgetData<String>('percentage', '0.0');
      await HomeWidget.saveWidgetData<int>('percentage_int', 0);
      await HomeWidget.saveWidgetData<int>('completed_count', 0);
      await HomeWidget.saveWidgetData<int>('total_count', sections.length);
      await HomeWidget.saveWidgetData<int>('streak', 0);
      await HomeWidget.saveWidgetData<String>('completed_sections', '');
      await HomeWidget.saveWidgetData<String>(
          'date', DateFormat('dd/MM/yyyy').format(DateTime.now()));

      await HomeWidget.updateWidget(
        androidName: androidWidgetName,
        iOSName: iOSWidgetName,
      );

      print('Widget cleared and updated with default values');
    } catch (e) {
      print('Error in clear and retry: $e');
    }
  }

  static int _calculateStreak(Map<String, dynamic> completionData) {
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
