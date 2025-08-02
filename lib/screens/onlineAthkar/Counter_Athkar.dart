import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:share/share.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:confetti/confetti.dart';

import '../../models/AnalyticsMixin.dart';
import '../ExceptionDialog.dart';

class CounterAthkarScreen extends StatefulWidget {
  final int count;
  final String content;
  final String value;
  final String id;
  final int index;
  final int currentCount;
  final String? userName;
  final String groupId;

  const CounterAthkarScreen({
    super.key,
    required this.count,
    required this.content,
    required this.value,
    required this.id,
    required this.index,
    required this.currentCount,
    this.userName,
    required this.groupId,
  });

  @override
  CounterAthkarScreenState createState() => CounterAthkarScreenState();
}

class CounterAthkarScreenState extends State<CounterAthkarScreen>
    with TickerProviderStateMixin , AnalyticsMixin {
  @override
  String get screenName => 'GroupsCounterScreen';

  int counter = 0;
  double fontSize = 18;
  bool isDarkTheme = false;
  bool vibrationActive = true;
  late ConfettiController _confettiController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  Future<void> _updateUsers() async {
    final objectRef = FirebaseFirestore.instance
        .collection('Groups')
        .doc(widget.groupId)
        .collection("Athkars")
        .doc(widget.id);

    DocumentSnapshot docSnapshot = await objectRef.get();

    if (docSnapshot.exists) {
      List<dynamic> users =
          (docSnapshot.data() as Map<String, dynamic>)['users'] ?? [];

      if (!users.contains(widget.userName)) {
        users.add(widget.userName);
        await objectRef.update({'users': users});
      }
    }
  }

  Future<void> _updateUserPoints() async {
    var userQuerySnapshot = await FirebaseFirestore.instance
        .collection('Users')
        .where("name", isEqualTo: widget.userName)
        .where('groupId', isEqualTo: widget.groupId)
        .get();

    if (userQuerySnapshot.docs.isNotEmpty) {
      var userDocument = userQuerySnapshot.docs.first;
      int currentPoints = userDocument.get('points');
      await userDocument.reference.update({
        'points': currentPoints + 10,
        'last_update': DateTime.now().toIso8601String(),
      });
    }
  }

  @override
  void initState() {
    super.initState();
    setState(() {
      counter = widget.currentCount;
    });
    _confettiController = ConfettiController(duration: const Duration(seconds: 5));
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    getFontSize();
    getCurrentTheme();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _triggerConfetti() {
    _confettiController.play();
  }

  void _animateCounterTap() {
    _pulseController.forward().then((_) {
      _pulseController.reverse();
    });
  }

  Future getFontSize() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    double? fontSizeSaved = sharedPreferences.getDouble('fontSize');
    if (fontSizeSaved != null) {
      setState(() {
        fontSize = fontSizeSaved;
      });
    }
  }

  Future setNewFontSize() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    sharedPreferences.setDouble('fontSize', fontSize);
  }

  Future getCurrentTheme() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    setState(() {
      if (sharedPreferences.containsKey('theme')) {
        isDarkTheme = sharedPreferences.getBool('theme')!;
      }
    });
  }

  // Theme colors
  Color get backgroundColor => isDarkTheme ? const Color(0xFF1A1A1A) : const Color(0xFFF5F7FA);
  Color get gradientStart => isDarkTheme ? const Color(0xFF1A1A1A) : const Color(0xFFF5F7FA);
  Color get gradientEnd => isDarkTheme ? const Color(0xFF2C2C2C) : const Color(0xFFE8F5E8);
  Color get cardColor => isDarkTheme ? const Color(0xFF2C2C2C) : Colors.white;
  Color get textColor => isDarkTheme ? Colors.white : const Color(0xFF2C3E50);
  Color get secondaryTextColor => isDarkTheme ? Colors.white70 : const Color(0xFF5D6D7E);
  Color get primaryColor => isDarkTheme ? const Color(0xFF66BBB1) : const Color(0xFF4CAF95);
  Color get shadowColor => isDarkTheme ? Colors.black26 : Colors.black.withOpacity(0.05);

  void _showCustomSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        backgroundColor: Colors.black87,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [primaryColor, primaryColor.withOpacity(0.8)],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
                const Icon(
                  Icons.check_circle_outline,
                  size: 80,
                  color: Colors.white,
                ),
                const SizedBox(height: 16),
                const Text(
                  'تم إكمال الذكر',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    color: Colors.white,
                    fontFamily: 'Amiri',
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'هنيئاً لك',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white70,
                    fontFamily: 'Amiri',
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                  child: const Text(
                    'حسناً',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildAppBar(),
      body: GestureDetector(
        onTap: () => decreaseCounter(),
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [gradientStart, gradientEnd],
                ),
              ),
              child: Column(
                children: [
                  _buildTopSection(),
                  Expanded(child: _buildContentSection()),
                  _buildCounterSection(),
                  _buildBottomSection(),
                ],
              ),
            ),
            _buildConfettiWidget(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      foregroundColor: Colors.white,
      title: const Text(
        'الذكر',
        style: TextStyle(
          fontFamily: 'Amiri',
          fontSize: 22.0,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        if (!kIsWeb) _buildVibrationButton(),
        _buildFontSizeButton(),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildVibrationButton() {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: vibrationActive ? Colors.white.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        onPressed: () {
          setState(() {
            vibrationActive = !vibrationActive;
          });
        },
        icon: Icon(
          Icons.vibration,
          color: vibrationActive ? Colors.white : Colors.white70,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildFontSizeButton() {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: fontSize > 18 ? Colors.white.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextButton(
        onPressed: () {
          setState(() {
            if (fontSize == 18) {
              fontSize = 20;
            } else if (fontSize == 20) {
              fontSize = 24;
            } else if (fontSize == 24) {
              fontSize = 28;
            } else {
              fontSize = 18;
            }
            setNewFontSize();
          });
        },
        child: Text(
          fontSize == 28 ? "- ع" : "+ ع",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildTopSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildActionButtons(),
          if (counter > 0 && widget.id != "0") _buildCompleteButton(),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        if (!kIsWeb) _buildActionButton(
          Icons.share,
              () => Share.share(widget.content.toString()),
          const Color(0xFF2196F3),
        ),
        _buildActionButton(
          Icons.copy,
              () => _copyToClipboard(),
          const Color(0xFF607D8B),
        ),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, VoidCallback onPressed, Color color) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: color, size: 20),
      ),
    );
  }

  Widget _buildCompleteButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () async {
          setState(() {
            counter = 0;
          });
          if (!kIsWeb && vibrationActive) {
            Vibrate.vibrate();
          }
          _triggerConfetti();

          try {
            await saveCounterOnlineResult();
            await _updateUsers();
            await _updateUserPoints();
            _showCompletionDialog();
          } catch (e) {
            showExceptionPopup(context, e.toString());
          }
        },
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
        ),
        child: const Text(
          "تم عمله بخاتم التسبيح ✅",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildContentSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildContentCard(),
            if (widget.value.isNotEmpty) _buildValueCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildContentCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        widget.content,
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: fontSize,
          fontFamily: 'Amiri',
          height: 1.8,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildValueCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkTheme ? Colors.blue.withOpacity(0.1) : Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkTheme ? Colors.blue.withOpacity(0.3) : Colors.blue.withOpacity(0.2),
        ),
      ),
      child: Text(
        widget.value,
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: fontSize - 2,
          fontFamily: 'Tajawal',
          color: secondaryTextColor,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  Widget _buildCounterSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: GestureDetector(
              onTap: () => decreaseCounter(),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: CircularPercentIndicator(
                  radius: 80.0,
                  lineWidth: 12.0,
                  percent: counter / widget.count,
                  center: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "$counter",
                        style: TextStyle(
                          fontSize: 36,
                          fontFamily: 'Tajawal',
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      Text(
                        "اضغط للعد",
                        style: TextStyle(
                          fontSize: 12,
                          color: secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                  progressColor: primaryColor,
                  backgroundColor: Colors.grey.withOpacity(0.2),
                  circularStrokeCap: CircularStrokeCap.round,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomSection() {
    return Container(
      height: 80,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (counter == 0 && widget.index != -1)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  resetCounter().catchError((e) {
                    showExceptionPopup(context, e.toString());
                  });
                },
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text(
                  "إعادة",
                  style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildConfettiWidget() {
    return Align(
      alignment: Alignment.topCenter,
      child: ConfettiWidget(
        confettiController: _confettiController,
        blastDirection: pi / 2,
        emissionFrequency: 0.05,
        numberOfParticles: 20,
        maxBlastForce: 10,
        minBlastForce: 5,
        colors: const [Colors.red, Colors.blue, Colors.green, Colors.yellow],
        shouldLoop: false,
      ),
    );
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: widget.content.toString()));
    _showCustomSnackBar('تم النسخ إلى الحافظة');
  }

  Future<void> decreaseCounter() async {
    _animateCounterTap();
    HapticFeedback.lightImpact();

    if (counter > 1) {
      setState(() {
        counter--;
      });
    } else if (counter == 1) {
      if (!kIsWeb && vibrationActive) {
        final Iterable<Duration> pauses = [
          const Duration(milliseconds: 500),
          const Duration(milliseconds: 1000),
          const Duration(milliseconds: 500),
        ];
        Vibrate.vibrateWithPauses(pauses);
      }

      setState(() {
        counter--;
      });

      _triggerConfetti();

      if (widget.id != "0") {
        try {
          await _updateUsers();
          await _updateUserPoints();
        } catch (e) {
          showExceptionPopup(context, e.toString());
        }
      }

      _showCompletionDialog();
    } else {
      Navigator.of(context).pop();
    }

    if (widget.id == "0") {
      saveCounterResult().catchError((e) {
        showExceptionPopup(context, e.toString());
      });
    } else {
      saveCounterOnlineResult().catchError((e) {
        showExceptionPopup(context, e.toString());
      });
    }
  }

  Future<void> saveCounterResult() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> athkarCurrentCount = prefs.getStringList('athkarCurrentCount')!;
    athkarCurrentCount[widget.index] = counter.toString();
    prefs.setStringList('athkarCurrentCount', athkarCurrentCount);
  }

  Future<void> saveCounterOnlineResult() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(widget.id.toString(), counter.toString());
  }

  Future<void> resetCounter() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> athkarCurrentCount = prefs.getStringList('athkarCurrentCount')!;
    setState(() {
      counter = widget.count;
    });
    athkarCurrentCount[widget.index] = widget.count.toString();
    prefs.setStringList('athkarCurrentCount', athkarCurrentCount);
  }
}