import 'package:adhan/adhan.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class PrayerWidgetProvider {
  static const String androidWidgetName = 'PrayerWidgetProvider';
  static const String iOSWidgetName = 'PrayerWidget';

  static Future<void> initializeWidget() async {
    await HomeWidget.setAppGroupId('group.com.athkar.athkarcom');
    await updateWidget();
  }

  static String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'م' : 'ص';
    return '$hour:$minute $period';
  }

  static String _getPrayerNameInArabic(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr:
        return 'الفجر';
      case Prayer.sunrise:
        return 'الشروق';
      case Prayer.dhuhr:
        return 'الظهر';
      case Prayer.asr:
        return 'العصر';
      case Prayer.maghrib:
        return 'المغرب';
      case Prayer.isha:
        return 'العشاء';
      default:
        return '';
    }
  }

  static Future<void> updateWidget() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      double? lat = prefs.getDouble('prayer_latitude');
      double? lon = prefs.getDouble('prayer_longitude');
      String? city = prefs.getString('prayer_city') ?? 'موقعي';

      if (lat == null || lon == null) {
        return;
      }

      final coordinates = Coordinates(lat, lon);

      // Karachi method with offsets (synchronized globally)
      final params = CalculationMethod.karachi.getParameters();
      params.madhab = Madhab.shafi;
      params.adjustments.fajr = 0;
      params.adjustments.sunrise = -5;
      params.adjustments.dhuhr = -1;
      params.adjustments.asr = 0;
      params.adjustments.maghrib = 5;
      params.adjustments.isha = 0;

      final prayerTimes = PrayerTimes.today(coordinates, params);

      // Determine next prayer
      final now = DateTime.now();
      final prayerTimesList = {
        Prayer.fajr: prayerTimes.fajr,
        Prayer.sunrise: prayerTimes.sunrise,
        Prayer.dhuhr: prayerTimes.dhuhr,
        Prayer.asr: prayerTimes.asr,
        Prayer.maghrib: prayerTimes.maghrib,
        Prayer.isha: prayerTimes.isha,
      };

      Prayer nextPrayer = Prayer.fajr;
      DateTime nextPrayerTime = prayerTimesList[Prayer.fajr]!;
      bool found = false;

      for (var entry in prayerTimesList.entries) {
        if (entry.value.isAfter(now)) {
          nextPrayer = entry.key;
          nextPrayerTime = entry.value;
          found = true;
          break;
        }
      }

      if (!found) {
        // If all prayers today have passed, the next prayer is tomorrow's Fajr
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        final tomorrowPrayerTimes = PrayerTimes(
          coordinates,
          DateComponents(tomorrow.year, tomorrow.month, tomorrow.day),
          params,
        );
        nextPrayer = Prayer.fajr;
        nextPrayerTime = tomorrowPrayerTimes.fajr;
      }

      // Save fields to HomeWidget
      await HomeWidget.saveWidgetData<String>('prayer_date', DateFormat('dd/MM/yyyy').format(now));
      await HomeWidget.saveWidgetData<String>('prayer_city', city);
      await HomeWidget.saveWidgetData<String>('next_prayer_name', _getPrayerNameInArabic(nextPrayer));
      await HomeWidget.saveWidgetData<String>('next_prayer_time', _formatTime(nextPrayerTime));

      await HomeWidget.saveWidgetData<String>('fajr', _formatTime(prayerTimes.fajr));
      await HomeWidget.saveWidgetData<String>('sunrise', _formatTime(prayerTimes.sunrise));
      await HomeWidget.saveWidgetData<String>('dhuhr', _formatTime(prayerTimes.dhuhr));
      await HomeWidget.saveWidgetData<String>('asr', _formatTime(prayerTimes.asr));
      await HomeWidget.saveWidgetData<String>('maghrib', _formatTime(prayerTimes.maghrib));
      await HomeWidget.saveWidgetData<String>('isha', _formatTime(prayerTimes.isha));

      // Trigger update
      await HomeWidget.updateWidget(
        androidName: androidWidgetName,
        iOSName: iOSWidgetName,
      );
    } catch (e) {
      print('Error updating prayer times widget: $e');
    }
  }
}
