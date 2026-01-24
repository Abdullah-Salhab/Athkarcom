import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:math' as math;
import 'dart:async';

import '../../models/AnalyticsMixin.dart';
import '../ExceptionDialog.dart';

class QiblaScreen extends StatefulWidget {
  final double? latitude;
  final double? longitude;
  final String? cityName;

  const QiblaScreen({
    super.key,
    this.latitude,
    this.longitude,
    this.cityName,
  });

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> with AnalyticsMixin {
  @override
  String get screenName => 'QiblaScreen';

  double? _heading;
  double? _qiblaDirection;
  StreamSubscription<CompassEvent>? _compassSubscription;
  bool _hasPermission = false;
  bool _isLoadingLocation = false;

  // Location data
  double? _latitude;
  double? _longitude;
  String _cityName = '';

  // إحداثيات الكعبة المشرفة
  static const double kaabaLatitude = 21.4225;
  static const double kaabaLongitude = 39.8262;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  @override
  void dispose() {
    _compassSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    // Check if location was passed as parameter
    if (widget.latitude != null && widget.longitude != null) {
      _latitude = widget.latitude;
      _longitude = widget.longitude;
      _cityName = widget.cityName ?? '';
      _calculateQiblaDirection();
      _checkPermissionAndStartCompass();
    } else {
      // Get location from GPS
      await _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
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

      _latitude = position.latitude;
      _longitude = position.longitude;

      // Get city name
      List<Placemark> placemarks = await placemarkFromCoordinates(
        _latitude!,
        _longitude!,
      );

      if (placemarks.isNotEmpty) {
        _cityName = placemarks.first.locality ??
            placemarks.first.administrativeArea ??
            'موقعك الحالي';
      }

      _calculateQiblaDirection();
      _checkPermissionAndStartCompass();

      setState(() {
        _isLoadingLocation = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text(
              'تم تحديد الموقع: $_cityName',
              style: const TextStyle(fontFamily: 'Tajawal'),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoadingLocation = false;
      });
      if (mounted) {
        showExceptionPopup(context, 'خطأ في تحديد الموقع: ${e.toString()}');
      }
    }
  }

  void _calculateQiblaDirection() {
    if (_latitude == null || _longitude == null) return;

    final lat1 = _latitude! * math.pi / 180;
    final lon1 = _longitude! * math.pi / 180;
    final lat2 = kaabaLatitude * math.pi / 180;
    final lon2 = kaabaLongitude * math.pi / 180;

    final dLon = lon2 - lon1;

    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

    var bearing = math.atan2(y, x);
    bearing = bearing * 180 / math.pi;
    bearing = (bearing + 360) % 360;

    setState(() {
      _qiblaDirection = bearing;
    });
  }

  Future<void> _checkPermissionAndStartCompass() async {
    var status = await Permission.location.status;
    if (!status.isGranted) {
      status = await Permission.location.request();
    }

    if (status.isGranted) {
      setState(() {
        _hasPermission = true;
      });
      _startCompass();
    } else {
      setState(() {
        _hasPermission = false;
      });
    }
  }

  void _startCompass() {
    _compassSubscription = FlutterCompass.events?.listen((CompassEvent event) {
      if (mounted && event.heading != null) {
        setState(() {
          _heading = event.heading;
        });
      }
    });
  }

  double _getRotationAngle() {
    if (_heading == null || _qiblaDirection == null) return 0;
    return (_qiblaDirection! - _heading!);
  }

  bool _isPointingToKaaba() {
    if (_heading == null || _qiblaDirection == null) return false;
    final diff = (_qiblaDirection! - _heading!).abs() % 360;
    return diff < 2 || diff > 350;
  }

  @override
  Widget build(BuildContext context) {
    final isPointing = _isPointingToKaaba();

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
          child: _isLoadingLocation
              ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(height: 20),
                Text(
                  'جاري تحديد موقعك...',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          )
              : Column(
            children: [
              // App Bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back,
                          color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'اتجاه القبلة',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.my_location,
                          color: Colors.white),
                      tooltip: 'تحديث الموقع',
                      onPressed: _getCurrentLocation,
                    ),
                  ],
                ),
              ),

              // Location Info
              if (_cityName.isNotEmpty)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_on, color: Colors.white),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          _cityName,
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              // Status Message
              if (!_hasPermission)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.warning, color: Colors.white),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'يرجى السماح بالوصول إلى الموقع',
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: _checkPermissionAndStartCompass,
                        icon:
                        const Icon(Icons.refresh, color: Colors.teal),
                        label: const Text(
                          'إعادة المحاولة',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            color: Colors.teal,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              else if (_heading == null)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                      SizedBox(width: 15),
                      Text(
                        'جاري تحديد الاتجاه...',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              else if (isPointing)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle,
                            color: Colors.white, size: 24),
                        SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            'أنت تتجه نحو القبلة ✨',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

              // Spacer
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Compass
                        if (_hasPermission &&
                            _heading != null &&
                            _qiblaDirection != null)
                          Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Outer Circle
                                Container(
                                  width: 280,
                                  height: 280,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                        Colors.black.withOpacity(0.2),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                ),

                                // Direction Markers
                                Transform.rotate(
                                  angle: -_heading! * math.pi / 180,
                                  child: SizedBox(
                                    width: 280,
                                    height: 280,
                                    child: CustomPaint(
                                      painter: CompassPainter(),
                                    ),
                                  ),
                                ),

                                // Qibla Arrow
                                Transform.rotate(
                                  angle:
                                  _getRotationAngle() * math.pi / 180,
                                  child: Icon(
                                    Icons.navigation,
                                    size: 100,
                                    color: isPointing
                                        ? Colors.green
                                        : Colors.teal,
                                  ),
                                ),

                                // Kaaba Icon at center
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.mosque,
                                    size: 30,
                                    color: Colors.teal,
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

              // Distance Info
              if (_qiblaDirection != null && _heading != null)
                Container(
                  margin: const EdgeInsets.all(16),
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.explore, color: Colors.teal),
                          SizedBox(width: 10),
                          Text(
                            'معلومات الاتجاه',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                const Text(
                                  'اتجاه القبلة',
                                  style: TextStyle(
                                    fontFamily: 'Tajawal',
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  '${_qiblaDirection!.toStringAsFixed(1)}°',
                                  style: const TextStyle(
                                    fontFamily: 'Tajawal',
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 2,
                            height: 40,
                            color: Colors.grey.shade300,
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                const Text(
                                  'اتجاهك الحالي',
                                  style: TextStyle(
                                    fontFamily: 'Tajawal',
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  '${_heading!.toStringAsFixed(1)}°',
                                  style: const TextStyle(
                                    fontFamily: 'Tajawal',
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
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
      ),
    );
  }
}

class CompassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Draw direction markers
    for (int i = 0; i < 360; i += 30) {
      final angle = i * math.pi / 180;
      final x1 = center.dx + (radius - 20) * math.cos(angle);
      final y1 = center.dy + (radius - 20) * math.sin(angle);
      final x2 = center.dx + (radius - 5) * math.cos(angle);
      final y2 = center.dy + (radius - 5) * math.sin(angle);

      paint.color = i == 0 ? Colors.red : Colors.grey.shade400;
      paint.strokeWidth = i == 0 ? 3 : 2;

      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
    }

    // Draw N marker
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'N',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.red,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, 10),
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}