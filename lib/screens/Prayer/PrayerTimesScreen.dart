import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:adhan/adhan.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:async';
import 'package:page_transition/page_transition.dart';

import '../../models/AnalyticsMixin.dart';
import '../ExceptionDialog.dart';
import '../../models/PrayerWidgetProvider.dart';
import '../Qibla/QiblaScreen.dart';
import 'ManualLocationScreen.dart';

class PrayerTimesScreen extends StatefulWidget {
  const PrayerTimesScreen({super.key});

  @override
  State<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen>
    with AnalyticsMixin, TickerProviderStateMixin {
  @override
  String get screenName => 'PrayerTimesScreen';

  bool isLoading = true;
  bool isLocaleInitialized = false;
  String cityName = '';
  String countryName = '';
  double latitude = 0.0;
  double longitude = 0.0;

  PrayerTimes? prayerTimes;
  Prayer? nextPrayer;
  Prayer? previousPrayer;
  Duration? timeUntilNextPrayer;
  Duration? timeSincePreviousPrayer;
  Timer? countdownTimer;

  Map<Prayer, DateTime> prayerTimesList = {};
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _initializeLocale();
  }

  Future<void> _initializeLocale() async {
    await initializeDateFormatting('ar', null);
    setState(() {
      isLocaleInitialized = true;
    });
    _loadLocation();
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLat = prefs.getDouble('prayer_latitude');
      final savedLon = prefs.getDouble('prayer_longitude');
      final savedCity = prefs.getString('prayer_city');
      final savedCountry = prefs.getString('prayer_country');

      if (savedLat != null && savedLon != null) {
        latitude = savedLat;
        longitude = savedLon;
        cityName = savedCity ?? '';
        countryName = savedCountry ?? '';
        await _calculatePrayerTimes();
        setState(() {
          isLoading = false;
        });
      } else {
        // للويب: اذهب مباشرة إلى الإدخال اليدوي
        if (kIsWeb) {
          setState(() {
            isLoading = false;
          });
          // انتظر حتى يتم بناء الواجهة ثم افتح شاشة الإدخال اليدوي
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showWebLocationDialog();
          });
        } else {
          // للهواتف: جرب GPS
          await _getCurrentLocation();
        }
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        showExceptionPopup(context, e.toString());
      }
    }
  }

  // دالة خاصة للويب لإظهار رسالة ثم فتح الإدخال اليدوي
  void _showWebLocationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text(
          'تحديد الموقع',
          style: TextStyle(fontFamily: 'Tajawal'),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_on, size: 60, color: Colors.teal),
            const SizedBox(height: 20),
            const Text(
              'يرجى تحديد موقعك لحساب مواقيت الصلاة',
              style: TextStyle(fontFamily: 'Tajawal', fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                await _tryGPSLocation();
              },
              icon: const Icon(Icons.gps_fixed),
              label: const Text(
                'تحديد تلقائي (GPS)',
                style: TextStyle(fontFamily: 'Tajawal'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                await _openManualLocationScreen();
              },
              icon: const Icon(Icons.edit_location),
              label: const Text(
                'إدخال يدوي',
                style: TextStyle(fontFamily: 'Tajawal'),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.teal,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _tryGPSLocation() async {
    setState(() {
      isLoading = true;
    });

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      latitude = position.latitude;
      longitude = position.longitude;

      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          latitude,
          longitude,
        );

        if (placemarks.isNotEmpty) {
          cityName = placemarks.first.locality ??
              placemarks.first.administrativeArea ??
              'موقعك الحالي';
          countryName = placemarks.first.country ?? '';
        }
      } catch (e) {
        cityName = 'موقعك الحالي';
        countryName = '';
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('prayer_latitude', latitude);
      await prefs.setDouble('prayer_longitude', longitude);
      await prefs.setString('prayer_city', cityName);
      await prefs.setString('prayer_country', countryName);

      await _calculatePrayerTimes();

      setState(() {
        isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text(
              'تم تحديد الموقع: $cityName',
              style: const TextStyle(fontFamily: 'Tajawal'),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        // إذا فشل GPS، افتح الإدخال اليدوي
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text(
              'خطأ في تحديد الموقع',
              style: TextStyle(fontFamily: 'Tajawal'),
              textAlign: TextAlign.center,
            ),
            content: Text(
              'لم نتمكن من تحديد موقعك تلقائياً.\n${e.toString()}',
              style: const TextStyle(fontFamily: 'Tajawal'),
              textAlign: TextAlign.center,
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _openManualLocationScreen();
                },
                child: const Text(
                  'إدخال يدوي',
                  style: TextStyle(fontFamily: 'Tajawal'),
                ),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    if (kIsWeb) {
      // للويب: جرب GPS مباشرة
      await _tryGPSLocation();
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      var status = await Permission.location.status;
      if (!status.isGranted) {
        status = await Permission.location.request();
        if (!status.isGranted) {
          throw Exception('يجب السماح بالوصول إلى الموقع');
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      latitude = position.latitude;
      longitude = position.longitude;

      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isNotEmpty) {
        cityName = placemarks.first.locality ??
            placemarks.first.administrativeArea ??
            'غير معروف';
        countryName = placemarks.first.country ?? '';
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('prayer_latitude', latitude);
      await prefs.setDouble('prayer_longitude', longitude);
      await prefs.setString('prayer_city', cityName);
      await prefs.setString('prayer_country', countryName);

      await _calculatePrayerTimes();

      setState(() {
        isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text(
              'تم تحديد الموقع: $cityName',
              style: const TextStyle(fontFamily: 'Tajawal'),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        showExceptionPopup(context, 'خطأ في تحديد الموقع: ${e.toString()}');
      }
    }
  }

  Future<void> _calculatePrayerTimes() async {
    try {
      final coordinates = Coordinates(latitude, longitude);

      final params = CalculationMethod.karachi.getParameters();
      params.madhab = Madhab.shafi;
      params.adjustments.fajr = 0;
      params.adjustments.sunrise = -5;
      params.adjustments.dhuhr = -1;
      params.adjustments.asr = 0;
      params.adjustments.maghrib = 5;
      params.adjustments.isha = 0;

      prayerTimes = PrayerTimes.today(coordinates, params);

      prayerTimesList = {
        Prayer.fajr: prayerTimes!.fajr,
        Prayer.sunrise: prayerTimes!.sunrise,
        Prayer.dhuhr: prayerTimes!.dhuhr,
        Prayer.asr: prayerTimes!.asr,
        Prayer.maghrib: prayerTimes!.maghrib,
        Prayer.isha: prayerTimes!.isha,
      };

      _updateNextPrayer();

      countdownTimer?.cancel();
      countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _updateNextPrayer();
      });

      // Update the home screen widget
      await PrayerWidgetProvider.updateWidget();
    } catch (e) {
      if (mounted) {
        showExceptionPopup(context, e.toString());
      }
    }
  }

  void _updateNextPrayer() {
    final now = DateTime.now();
    Prayer? found;
    Prayer? previous;
    Duration? duration;
    Duration? previousDuration;

    final prayerEntries = prayerTimesList.entries.toList();

    for (int i = 0; i < prayerEntries.length; i++) {
      if (prayerEntries[i].value.isAfter(now)) {
        found = prayerEntries[i].key;
        duration = prayerEntries[i].value.difference(now);

        if (i > 0) {
          previous = prayerEntries[i - 1].key;
          previousDuration = now.difference(prayerEntries[i - 1].value);
        }
        break;
      }
    }

    if (found == null) {
      final coordinates = Coordinates(latitude, longitude);
      final params = CalculationMethod.karachi.getParameters();
      params.madhab = Madhab.shafi;
      params.adjustments.fajr = 0;
      params.adjustments.sunrise = -5;
      params.adjustments.dhuhr = -1;
      params.adjustments.asr = 0;
      params.adjustments.maghrib = 5;
      params.adjustments.isha = 0;

      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final tomorrowPrayers = PrayerTimes(
        coordinates,
        DateComponents.from(tomorrow),
        params,
      );
      found = Prayer.fajr;
      duration = tomorrowPrayers.fajr.difference(now);

      previous = Prayer.isha;
      previousDuration = now.difference(prayerTimesList[Prayer.isha]!);
    }

    if (mounted) {
      setState(() {
        nextPrayer = found;
        timeUntilNextPrayer = duration;
        previousPrayer = previous;
        timeSincePreviousPrayer = previousDuration;
      });
    }
  }

  Future<void> _openManualLocationScreen() async {
    final result = await Navigator.push(
      context,
      PageTransition(
        type: PageTransitionType.bottomToTop,
        duration: const Duration(milliseconds: 500),
        child: const ManualLocationScreen(),
      ),
    );

    if (result == true) {
      await _loadLocation();
    }
  }

  void _openQiblaScreen() {
    Navigator.push(
      context,
      PageTransition(
        type: PageTransitionType.rightToLeft,
        duration: const Duration(milliseconds: 500),
        child: QiblaScreen(
          latitude: latitude,
          longitude: longitude,
          cityName: cityName,
        ),
      ),
    );
  }

  String _getPrayerNameInArabic(Prayer prayer) {
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

  IconData _getPrayerIcon(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr:
        return Icons.wb_twilight;
      case Prayer.sunrise:
        return Icons.wb_sunny;
      case Prayer.dhuhr:
        return Icons.light_mode;
      case Prayer.asr:
        return Icons.wb_sunny_outlined;
      case Prayer.maghrib:
        return Icons.nights_stay;
      case Prayer.isha:
        return Icons.nightlight_round;
      default:
        return Icons.access_time;
    }
  }

  Color _getPrayerColor(Prayer prayer, {bool isUrgent = false}) {
    if (isUrgent) return Colors.red;

    switch (prayer) {
      case Prayer.fajr:
        return Colors.indigo;
      case Prayer.sunrise:
        return Colors.orange;
      case Prayer.dhuhr:
        return Colors.amber;
      case Prayer.asr:
        return Colors.deepOrange;
      case Prayer.maghrib:
        return Colors.purple;
      case Prayer.isha:
        return Colors.deepPurple;
      default:
        return Colors.teal;
    }
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'م' : 'ص';
    return '$hour:$minute $period';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours س $minutes د';
    } else if (minutes > 0) {
      return '$minutes د $seconds ث';
    } else {
      return '$seconds ث';
    }
  }

  String _getArabicDayName(DateTime date) {
    const days = ['الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];
    return days[date.weekday % 7];
  }

  String _getArabicMonthName(DateTime date) {
    const months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    return months[date.month - 1];
  }

  bool _isUrgent() {
    if (timeUntilNextPrayer == null) return false;
    return timeUntilNextPrayer!.inMinutes <= 30;
  }

  @override
  Widget build(BuildContext context) {
    if (!isLocaleInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // إذا لم يتم تحديد الموقع بعد
    if (latitude == 0.0 && longitude == 0.0 && !isLoading) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.teal.shade700,
                Colors.teal.shade400,
                Colors.white,
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.location_off,
                      size: 100,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'لم يتم تحديد الموقع',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'يرجى تحديد موقعك لعرض مواقيت الصلاة',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    if (!kIsWeb) ...[
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton.icon(
                          onPressed: _getCurrentLocation,
                          icon: const Icon(Icons.gps_fixed),
                          label: const Text(
                            'تحديد تلقائي (GPS)',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 18,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.teal,
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                    ],
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: OutlinedButton.icon(
                        onPressed: _openManualLocationScreen,
                        icon: const Icon(Icons.edit_location),
                        label: const Text(
                          'إدخال يدوي',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 18,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final isUrgent = _isUrgent();
    final showPreviousPrayer = timeSincePreviousPrayer != null &&
        timeSincePreviousPrayer!.inMinutes <= 30;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.teal.shade700,
              Colors.teal.shade300,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: isLoading
              ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(height: 20),
                Text(
                  'جاري تحديد الموقع...',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          )
              : CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                floating: false,
                pinned: true,
                backgroundColor: Colors.transparent,
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  titlePadding: const EdgeInsets.only(bottom: 16),
                  title: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'مواقيت الصلاة',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              blurRadius: 10.0,
                              color: Colors.black45,
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                      ),
                      if (cityName.isNotEmpty)
                        Text(
                          cityName,
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 13,
                            color: Colors.white70,
                          ),
                        ),
                    ],
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.teal.shade800,
                          Colors.teal.shade600,
                        ],
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.mosque,
                        size: 80,
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.explore, color: Colors.white),
                    tooltip: 'اتجاه القبلة',
                    onPressed: _openQiblaScreen,
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_location,
                        color: Colors.white),
                    tooltip: 'إدخال الموقع يدوياً',
                    onPressed: _openManualLocationScreen,
                  ),
                  if (!kIsWeb)
                    IconButton(
                      icon: const Icon(Icons.my_location,
                          color: Colors.white),
                      tooltip: 'تحديث الموقع',
                      onPressed: _getCurrentLocation,
                    ),
                ],
              ),

              // Next Prayer Card
              if (nextPrayer != null && timeUntilNextPrayer != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                        CurvedAnimation(
                          parent: _pulseController,
                          curve: Curves.easeInOut,
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                          gradient: LinearGradient(
                            colors: [
                              _getPrayerColor(nextPrayer!,
                                  isUrgent: isUrgent),
                              _getPrayerColor(nextPrayer!,
                                  isUrgent: isUrgent)
                                  .withOpacity(0.7),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _getPrayerColor(nextPrayer!,
                                  isUrgent: isUrgent)
                                  .withOpacity(0.5),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'الصلاة القادمة',
                                  style: TextStyle(
                                    fontFamily: 'Tajawal',
                                    fontSize: 18,
                                    color: Colors.white70,
                                  ),
                                ),
                                if (isUrgent) ...[
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.warning_amber_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _getPrayerIcon(nextPrayer!),
                                  color: Colors.white,
                                  size: 40,
                                ),
                                const SizedBox(width: 15),
                                Flexible(
                                  child: Text(
                                    _getPrayerNameInArabic(nextPrayer!),
                                    style: const TextStyle(
                                      fontFamily: 'Tajawal',
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 25,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    isUrgent
                                        ? 'اقترب الأذان!'
                                        : 'الوقت المتبقي',
                                    style: const TextStyle(
                                      fontFamily: 'Tajawal',
                                      fontSize: 16,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    _formatDuration(
                                        timeUntilNextPrayer!),
                                    style: const TextStyle(
                                      fontFamily: 'Tajawal',
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              // Previous Prayer Card
              if (showPreviousPrayer && previousPrayer != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _getPrayerIcon(previousPrayer!),
                            color: Colors.grey.shade600,
                            size: 24,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'مضى على ${_getPrayerNameInArabic(previousPrayer!)}: ${_formatDuration(timeSincePreviousPrayer!)}',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 16,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              if (showPreviousPrayer)
                const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // Date Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              const Icon(Icons.calendar_today,
                                  color: Colors.teal),
                              const SizedBox(height: 5),
                              Text(
                                _getArabicDayName(DateTime.now()),
                                style: const TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                '${DateTime.now().day} ${_getArabicMonthName(DateTime.now())} ${DateTime.now().year}',
                                style: const TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 2,
                          height: 50,
                          color: Colors.grey.shade300,
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              const Icon(Icons.location_on,
                                  color: Colors.teal),
                              const SizedBox(height: 5),
                              Text(
                                cityName,
                                style: const TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                countryName,
                                style: const TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // Prayer Times List
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final prayers = prayerTimesList.entries.toList();
                      final entry = prayers[index];
                      final prayer = entry.key;
                      final time = entry.value;
                      final isNext = prayer == nextPrayer;
                      final isPast = time.isBefore(DateTime.now());
                      final timeSince = isPast
                          ? DateTime.now().difference(time)
                          : null;
                      final showTimeSince = isPast &&
                          timeSince != null &&
                          timeSince.inMinutes <= 30;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isNext
                                ? _getPrayerColor(prayer,
                                isUrgent: isUrgent)
                                .withOpacity(0.1)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isNext
                                  ? _getPrayerColor(prayer,
                                  isUrgent: isUrgent)
                                  : Colors.transparent,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isNext
                                    ? _getPrayerColor(prayer,
                                    isUrgent: isUrgent)
                                    .withOpacity(0.3)
                                    : Colors.grey.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            leading: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _getPrayerColor(prayer,
                                    isUrgent: isNext && isUrgent)
                                    .withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _getPrayerIcon(prayer),
                                color: _getPrayerColor(prayer,
                                    isUrgent: isNext && isUrgent),
                                size: 28,
                              ),
                            ),
                            title: Text(
                              _getPrayerNameInArabic(prayer),
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 20,
                                fontWeight: isNext
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                color: isPast
                                    ? Colors.grey
                                    : Colors.black87,
                              ),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment:
                              CrossAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _formatTime(time),
                                  style: TextStyle(
                                    fontFamily: 'Tajawal',
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isNext
                                        ? _getPrayerColor(prayer,
                                        isUrgent: isUrgent)
                                        : isPast
                                        ? Colors.grey
                                        : Colors.black87,
                                  ),
                                ),
                                if (showTimeSince)
                                  Text(
                                    'مضى ${_formatDuration(timeSince)}',
                                    style: const TextStyle(
                                      fontFamily: 'Tajawal',
                                      fontSize: 12,
                                      color: Colors.orange,
                                    ),
                                  )
                                else if (isPast)
                                  const Text(
                                    'انتهى',
                                    style: TextStyle(
                                      fontFamily: 'Tajawal',
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: prayerTimesList.length,
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),
            ],
          ),
        ),
      ),
    );
  }
}