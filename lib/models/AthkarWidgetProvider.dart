import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AthkarWidgetProvider {
  static const String androidWidgetName = 'AthkarWidgetProvider';
  static const String iOSWidgetName = 'AthkarWidget';

  // Section definitions (same as in your ReportsScreen)
  static final Map<int, String> sections = {
    1: "أذكار الصباح",
    2: "أذكار المساء"
  };

  static Future<void> initializeWidget() async {
    await HomeWidget.setAppGroupId('group.com.athkar.athkarcom');
    await updateWidget();
  }

  static Future<void> updateWidget() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      // First, get the current user.
      String? userName = prefs.getString('userName');

      // If no user is logged in, show a default/empty state for the widget.
      if (userName == null || userName.isEmpty) {
        await _clearAndRetryUpdate();
        return;
      }

      // Use the user-specific key to get the correct report data.
      final String dataKey = 'athkar_completion_data_$userName';
      String? data = prefs.getString(dataKey);

      Map<String, dynamic> completionData = {};
      if (data != null) {
        completionData = json.decode(data);
      }

      // Get today's data
      String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      Map<String, dynamic> todayData = completionData[today] ?? {};

      int completedCount = todayData.entries
          .where((e) => sections.containsKey(int.tryParse(e.key) ?? 0) && e.value == true)
          .length;
      int totalCount = sections.length;
      double percentage =
      totalCount > 0 ? (completedCount / totalCount) * 100 : 0;

      // Calculate streak from the user's report
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

      if (kDebugMode) {
        print('Widget updated successfully for user: $userName');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating widget: $e');
      }
      // Optionally, you can try to clear problematic data and retry
      await _clearAndRetryUpdate();
    }
  }

  static Future<void> _clearAndRetryUpdate() async {
    try {
      // Clear potentially problematic data and set to default
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

      if (kDebugMode) {
        print('Widget cleared and updated with default values.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in clear and retry: $e');
      }
    }
  }

  // This function correctly calculates the streak from the provided data map.
  static int _calculateStreak(Map<String, dynamic> completionData) {
    if (sections.isEmpty) return 0;
    int streak = 0;
    DateTime checkDate = DateTime.now();

    // First, check if today is fully complete. If not, start checking from yesterday.
    String todayKey = DateFormat('yyyy-MM-dd').format(checkDate);
    Map<String, dynamic> todayData = completionData[todayKey] ?? {};
    int todayCompleted = todayData.entries
        .where((e) => sections.containsKey(int.tryParse(e.key) ?? 0) && e.value == true)
        .length;
    if (todayCompleted != sections.length) {
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    // Now, count backwards from the last fully completed day.
    while (true) {
      String dateKey = DateFormat('yyyy-MM-dd').format(checkDate);
      Map<String, dynamic> dayData = completionData[dateKey] ?? {};
      int dayCompleted = dayData.entries
          .where((e) => sections.containsKey(int.tryParse(e.key) ?? 0) && e.value == true)
          .length;

      if (dayCompleted == sections.length) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        // Stop when a day is not fully completed.
        break;
      }
    }

    return streak;
  }
}
