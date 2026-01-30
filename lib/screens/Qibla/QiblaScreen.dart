import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
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

  // Camera (للهواتف فقط)
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _useARMode = false;

  // Compass
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
    if (!kIsWeb) {
      _initializeCamera();
    }
  }

  @override
  void dispose() {
    _compassSubscription?.cancel();
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras![0],
          ResolutionPreset.medium,
          enableAudio: false,
        );

        await _cameraController!.initialize();

        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      }
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  Future<void> _initializeLocation() async {
    if (widget.latitude != null && widget.longitude != null) {
      _latitude = widget.latitude;
      _longitude = widget.longitude;
      _cityName = widget.cityName ?? '';
      _calculateQiblaDirection();
      _checkPermissionAndStartCompass();
    } else {
      await _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _latitude = position.latitude;
      _longitude = position.longitude;

      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          _latitude!,
          _longitude!,
        );

        if (placemarks.isNotEmpty) {
          _cityName = placemarks.first.locality ??
              placemarks.first.administrativeArea ??
              'موقعك الحالي';
        } else {
          _cityName = 'موقعك الحالي';
        }
      } catch (e) {
        _cityName = 'موقعك الحالي';
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
    if (kIsWeb) {
      setState(() {
        _hasPermission = true;
        _heading = 0;
      });
    } else {
      var status = await Permission.location.status;
      if (!status.isGranted) {
        status = await Permission.location.request();
      }

      if (status.isGranted) {
        setState(() {
          _hasPermission = true;
        });
        _startMobileCompass();
      } else {
        setState(() {
          _hasPermission = false;
        });
      }
    }
  }

  void _startMobileCompass() {
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

  void _toggleARMode() {
    setState(() {
      _useARMode = !_useARMode;
    });
  }

  // حساب المسافة إلى الكعبة
  double _calculateDistance() {
    if (_latitude == null || _longitude == null) return 0;

    const R = 6371; // نصف قطر الأرض بالكيلومتر
    final lat1 = _latitude! * math.pi / 180;
    final lat2 = kaabaLatitude * math.pi / 180;
    final dLat = (kaabaLatitude - _latitude!) * math.pi / 180;
    final dLon = (kaabaLongitude - _longitude!) * math.pi / 180;

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return R * c;
  }

  @override
  Widget build(BuildContext context) {
    final isPointing = _isPointingToKaaba();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: _useARMode && !kIsWeb
              ? null
              : LinearGradient(
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
              : Stack(
            children: [
              // AR Camera View (للهواتف فقط)
              if (_useARMode &&
                  !kIsWeb &&
                  _isCameraInitialized &&
                  _cameraController != null)
                Positioned.fill(
                  child: CameraPreview(_cameraController!),
                ),

              // Normal View
              if (!_useARMode || kIsWeb)
                Positioned.fill(
                  child: _buildNormalView(isPointing),
                ),

              // AR Overlay (للهواتف فقط)
              if (_useARMode && !kIsWeb && _qiblaDirection != null)
                Positioned.fill(
                  child: _buildAROverlay(isPointing),
                ),

              // Top Bar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildTopBar(),
              ),

              // AR Toggle Button (للهواتف فقط)
              if (!kIsWeb && _isCameraInitialized)
                Positioned(
                  top: 60,
                  left: 10,
                  child: FloatingActionButton.extended(
                    onPressed: _toggleARMode,
                    backgroundColor: Colors.teal,
                    icon: Icon(
                      _useARMode ? Icons.map : Icons.camera_alt,
                      color: Colors.white,
                    ),
                    label: Text(
                      _useARMode ? 'عرض عادي' : 'واقع معزز',
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withOpacity(0.7),
            Colors.black.withOpacity(0.3),
            Colors.transparent,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
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
                  icon: const Icon(Icons.my_location, color: Colors.white),
                  tooltip: 'تحديث الموقع',
                  onPressed: _getCurrentLocation,
                ),
              ],
            ),
            if (_cityName.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on,
                        color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _cityName,
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 14,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNormalView(bool isPointing) {
    return Column(
      children: [
        const SizedBox(height: 120),

        // Web-specific notice
        if (kIsWeb)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Column(
              children: [
                Icon(Icons.web, color: Colors.white, size: 30),
                SizedBox(height: 10),
                Text(
                  'وضع الويب',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'استخدم هاتفك للحصول على تجربة البوصلة والواقع المعزز',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

        // Status Message (للهواتف فقط)
        if (!_hasPermission && !kIsWeb)
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
                  icon: const Icon(Icons.refresh, color: Colors.teal),
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
        else if (isPointing && !kIsWeb)
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
                Icon(Icons.check_circle, color: Colors.white, size: 24),
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

        const SizedBox(height: 20),

        // Compass
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_qiblaDirection != null)
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 280,
                            height: 280,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                          ),
                          if (_heading != null && !kIsWeb)
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
                          if (kIsWeb)
                            SizedBox(
                              width: 280,
                              height: 280,
                              child: CustomPaint(
                                painter: CompassPainter(),
                              ),
                            ),
                          Transform.rotate(
                            angle: _heading != null && !kIsWeb
                                ? _getRotationAngle() * math.pi / 180
                                : _qiblaDirection! * math.pi / 180,
                            child: Icon(
                              Icons.navigation,
                              size: 100,
                              color: isPointing && !kIsWeb
                                  ? Colors.green
                                  : Colors.teal,
                            ),
                          ),
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

                  // Instructions for web/static view
                  if (kIsWeb && _qiblaDirection != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          const Text(
                            'أدِر جسمك باتجاه السهم الأزرق ☝️',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 15),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Column(
                              children: [
                                const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.mosque,
                                        color: Colors.white, size: 24),
                                    SizedBox(width: 10),
                                    Text(
                                      'الكعبة المشرفة',
                                      style: TextStyle(
                                        fontFamily: 'Tajawal',
                                        fontSize: 16,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'الاتجاه: ${_qiblaDirection!.toStringAsFixed(0)}° من الشمال',
                                  style: const TextStyle(
                                    fontFamily: 'Tajawal',
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  'المسافة: ${_calculateDistance().toStringAsFixed(0)} كم',
                                  style: const TextStyle(
                                    fontFamily: 'Tajawal',
                                    fontSize: 16,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
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

        // Info Card
        if (_qiblaDirection != null)
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
                    if (_heading != null && !kIsWeb) ...[
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
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildAROverlay(bool isPointing) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withOpacity(0.3),
            Colors.transparent,
            Colors.black.withOpacity(0.3),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 120),

          if (isPointing)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.9),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 24),
                  SizedBox(width: 10),
                  Text(
                    'أنت تتجه نحو القبلة ✨',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

          const Spacer(),

          if (_heading != null && _qiblaDirection != null)
            Transform.rotate(
              angle: _getRotationAngle() * math.pi / 180,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.arrow_upward,
                    size: 100,
                    color: isPointing ? Colors.green : Colors.teal,
                    shadows: const [
                      Shadow(
                        blurRadius: 10,
                        color: Colors.black,
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: (isPointing ? Colors.green : Colors.teal)
                          .withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.mosque, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'اتجاه القبلة',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          const Spacer(),

          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'اتجاه القبلة',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${_qiblaDirection!.toStringAsFixed(0)}°',
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 2,
                  height: 40,
                  color: Colors.white30,
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'اتجاهك',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${_heading!.toStringAsFixed(0)}°',
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 80),
        ],
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