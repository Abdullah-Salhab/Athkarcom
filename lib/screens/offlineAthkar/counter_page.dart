import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:athkar/models/section_detail_model.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:vibration/vibration.dart';
import 'package:confetti/confetti.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart'; // Add this import
import '../../main.dart';
import '../../models/AnalyticsMixin.dart';
import '../ExceptionDialog.dart';
import '../ReportScreen.dart';

class CounterPage extends StatefulWidget {
  final int id;
  final String title;

  const CounterPage({Key? key, required this.id, required this.title})
      : super(key: key);

  @override
  CounterPageState createState() => CounterPageState();
}

class CounterPageState extends State<CounterPage>
    with TickerProviderStateMixin, AnalyticsMixin, WidgetsBindingObserver {
  @override
  String get screenName => 'OfflineCounterScreen';

  List<SectionDetailModel> sectionDetails = [];
  bool isLoad = false;
  final _pageController = PageController();
  List<int> counterValues = [];
  int currentPage = 0;
  final FocusNode _focusNode = FocusNode();
  bool vibrationActive = true;
  bool voiceActive = false;
  late AudioPlayer _player;
  StreamSubscription<Duration>? _positionSubscription;
  int currentCounterValue = 0;
  double playbackRate = 1;
  late ConfettiController _confettiController;
  bool isCheckingRemaining = false;
  double fontSize = 18;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool isDarkTheme = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 5));
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    try {
      loadSectionDetail();
      _player = AudioPlayer();

      // Listen to player completion event (for counter decrement)
      bool _isProcessingCompletion = false;

      _positionSubscription = _player.positionStream.listen((position) async {
        if (voiceActive &&
            _player.duration != null &&
            _player.playing) {
          // If we are on the last repetition (count == 1) and loop mode is still LoopMode.one,
          // and we have successfully started playing the last repetition (position < duration / 2),
          // we switch loop mode to off.
          if (counterValues[currentPage] == 1 &&
              _player.loopMode == LoopMode.one &&
              position.inMilliseconds < _player.duration!.inMilliseconds ~/ 2) {
            _player.setLoopMode(LoopMode.off);
          }

          if (!_isProcessingCompletion) {
            // When audio completes, decrement counter
            if (position >=
                _player.duration! - const Duration(milliseconds: 100)) {
              _isProcessingCompletion = true;
              if (mounted) {
                decrementCounter(currentPage);
              }

              // Reset flag after a delay
              await Future.delayed(const Duration(milliseconds: 300));
              _isProcessingCompletion = false;
            }
          }
        }
      });
      // Keep the screen on
      WakelockPlus.enable();
    } catch (e) {
      showExceptionPopup(context, e.toString());
    }
    getFontSize();
    getCurrentTheme();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _positionSubscription?.cancel();
    _player.dispose();
    _confettiController.dispose();
    _pulseController.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (_player.playing) {
        _player.pause();
      }
    } else if (state == AppLifecycleState.resumed) {
      if (voiceActive && !_player.playing && currentCounterValue > 0) {
        _player.play();
      }
    }
  }

  // Animation for counter tap
  void _animateCounterTap() {
    _pulseController.forward().then((_) {
      _pulseController.reverse();
    });
  }

  //this function will get the current font size
  Future getFontSize() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    double? fontSizeSaved = sharedPreferences.getDouble('fontSize');
    if (fontSizeSaved != null) {
      setState(() {
        fontSize = fontSizeSaved;
      });
    }
  }

  //this function will set new font size
  Future setNewFontSize() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    sharedPreferences.setDouble('fontSize', fontSize);
  }

  //this function will get the theme
  Future getCurrentTheme() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    setState(() {
      if (sharedPreferences.containsKey('theme')) {
        isDarkTheme = sharedPreferences.getBool('theme')!;
      }
    });
  }

  // Get theme colors based on current theme
  Color get backgroundColor =>
      isDarkTheme ? const Color(0xFF1A1A1A) : const Color(0xFFF5F7FA);

  Color get gradientStart =>
      isDarkTheme ? const Color(0xFF1A1A1A) : const Color(0xFFF5F7FA);

  Color get gradientEnd =>
      isDarkTheme ? const Color(0xFF2C2C2C) : const Color(0xFFE8F5E8);

  Color get cardColor => isDarkTheme ? const Color(0xFF2C2C2C) : Colors.white;

  Color get textColor => isDarkTheme ? Colors.white : const Color(0xFF2C3E50);

  Color get secondaryTextColor =>
      isDarkTheme ? Colors.white70 : const Color(0xFF5D6D7E);

  Color get primaryColor =>
      isDarkTheme ? const Color(0xFF66BBB1) : const Color(0xFF4CAF95);

  Color get shadowColor =>
      isDarkTheme ? Colors.black26 : Colors.black.withOpacity(0.05);

  // CHANGED: This function now saves reports for the specific logged-in user.
  Future<void> _recordCompletion() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      // Get the current user to create a user-specific key
      String? userName = prefs.getString('userName');

      // If there's no user, we can't save the report.
      if (userName == null || userName.isEmpty) {
        if (kDebugMode) {
          print("Error: No user is currently selected. Cannot save report.");
        }
        return;
      }

      // Use a user-specific key for storing completion data.
      final String completionDataKey = 'athkar_completion_data_$userName';
      String? data = prefs.getString(completionDataKey);

      Map<String, dynamic> completionData = {};
      if (data != null) {
        completionData = json.decode(data);
      }

      String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // Initialize data structure if needed
      if (!completionData.containsKey(today)) {
        completionData[today] = {};
      }

      // Record completion for this section
      completionData[today][widget.id.toString()] = true;

      // Save back to preferences with the user-specific key.
      await prefs.setString(completionDataKey, json.encode(completionData));

      // After saving completion data
      await AthkarWidgetHelper.updateWidgetOnCompletion();
    } catch (e) {
      if (kDebugMode) {
        print('Error recording completion: $e');
      }
    }
  }

  Future<Uri?> _cachedArtUri() async {
    try {
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/App_Icon.jpg';
      final file = File(filePath);
      if (!await file.exists()) {
        final byteData = await rootBundle.load('assets/images/App_Icon.jpg');
        await file.writeAsBytes(byteData.buffer.asUint8List(), flush: true);
      }
      return Uri.file(filePath);
    } catch (e) {
      return null;
    }
  }

  Future<void> _toggleSound(String? soundId) async {
    try {
      if (voiceActive == false) {
        await _player.stop();
        await _player.setLoopMode(LoopMode.off);
      } else {
        final path = _getSoundPath(soundId!);
        if (path != null) {
          // Stop and clear current audio completely
          await _player.stop();
          await _player.setLoopMode(LoopMode.off);

          // Small delay to ensure cleanup on web
          if (kIsWeb) {
            await Future.delayed(const Duration(milliseconds: 500));
          }

          // Load new audio
          final artUri = await _cachedArtUri();
          await _player.setAudioSource(AudioSource.asset(
            path,
            tag: MediaItem(
              id: soundId,
              title: "Athkar Sound",
              artUri: artUri,
            ),
          ));
          if (counterValues[currentPage] > 1) {
            await _player.setLoopMode(LoopMode.one);
          } else {
            await _player.setLoopMode(LoopMode.off);
          }
          await _player.setSpeed(playbackRate);
          await _player.play();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Audio error: $e');
      }
      // Don't show popup for loading interrupted errors, just log them
      if (!e.toString().contains('Loading interrupted')) {
        showExceptionPopup(context, e.toString());
      }
    }
  }

  String? _getSoundPath(String soundId) {
    if (soundId.contains("C")) {
      return 'assets/sounds/common/Athkar_$soundId.mp3';
    } else if (soundId.contains("E")) {
      return 'assets/sounds/evening/Athkar_$soundId.mp3';
    } else if (soundId.contains("M")) {
      return 'assets/sounds/morning/Athkar_$soundId.mp3';
    } else if (soundId.contains("S")) {
      return 'assets/sounds/sleeping/Athkar_$soundId.mp3';
    } else {
      return null;
    }
  }

  // decrement the counter, the index is the current page value
  void decrementCounter(int index) {
    _animateCounterTap();
    if (!kIsWeb && vibrationActive)
      HapticFeedback.lightImpact(); // Better haptic feedback

    setState(() {
      if (counterValues[index] > 0) {
        counterValues[index] = counterValues[index] - 1;
        currentCounterValue--;
      }

      if (counterValues[index] == 0 &&
          _pageController.page != sectionDetails.length - 1) {
        currentCounterValue = counterValues[index + 1];
        if (!kIsWeb && vibrationActive) {
          Vibration.vibrate(duration: 200);
        }
        if (sectionDetails[index + 1].soundId == "") {
          setState(() {
            voiceActive = false;
          });
        }
        _player.stop(); // Stop audio immediately to prevent replaying old audio during transition
        _pageController.nextPage(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
        );
      }

      if (counterValues[index] == 0 &&
          _pageController.page == sectionDetails.length - 1) {
        bool isFinishAll = true;
        for (int x = 0; x < sectionDetails.length; x++) {
          if (counterValues[x] != 0) {
            isFinishAll = false;
            isCheckingRemaining = true;
            _player.stop(); // Stop audio immediately to prevent replaying old audio during transition
            _pageController.animateToPage(x,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOut);
            _showCustomSnackBar('😊 لم تكمل جميع الأذكار 😊');
            break;
          }
        }

        if (isFinishAll) {
          if (!kIsWeb && vibrationActive) {
            Vibration.vibrate(pattern: [
              0, // no delay
              500, // vibrate 500ms
              1000, // pause 1000ms
              500, // vibrate 500ms
            ]);
          }
          _triggerConfetti();
          voiceActive = false;
          _player.stop().then((_) {
            _player.setLoopMode(LoopMode.off);
          });

          // Stop Keeping the screen on
          WakelockPlus.disable();
          // NEW: Record completion when all athkar are finished
          if (widget.id == 1 || widget.id == 2 || widget.id == 6) {
            _recordCompletion();
          }
          _showCompletionDialog();
        }
      }
    });
  }

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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                  'تم إكمال الأذكار',
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
                // NEW: Add reports button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (widget.id == 1 || widget.id == 2 || widget.id == 6)
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ReportsScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25)),
                        ),
                        child: const Text(
                          'عرض التقارير',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25)),
                      ),
                      child: const Text(
                        'حسناً',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _triggerConfetti() {
    _confettiController.play();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildAppBar(),
      body: !isLoad
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              ),
            )
          : Stack(
              children: [
                PageView(
                  scrollDirection: Axis.vertical,
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  children: [
                    for (int index = 0; index < sectionDetails.length; index++)
                      _buildCounterPage(index),
                  ],
                ),
                _buildConfettiWidget(),
              ],
            ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      foregroundColor: Colors.white,
      title: Text(
        widget.title,
        style: const TextStyle(
          fontFamily: 'Amiri',
          fontSize: 22.0,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        // NEW: Add reports button to app bar
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ReportsScreen(),
              ),
            );
          },
          icon: const Icon(Icons.analytics_outlined),
          tooltip: 'التقارير',
        ),
        if (!kIsWeb) _buildVibrationButton(),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildVibrationButton() {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: vibrationActive
            ? Colors.white.withOpacity(0.2)
            : Colors.transparent,
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
      margin: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        color: fontSize > 18
            ? Colors.orange.withOpacity(0.1)
            : Colors.orange.withOpacity(0.05),
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
            color: Colors.orange,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
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

  void _onPageChanged(int page) {
    setState(() {
      if (counterValues[page] == 0 &&
          page > currentPage &&
          isCheckingRemaining) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeOut,
        );
      } else if (counterValues[page] == 0 &&
          page < currentPage &&
          isCheckingRemaining) {
        _pageController.previousPage(
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeOut,
        );
      }
      currentPage = page;
      if (sectionDetails[page].soundId == "") {
        setState(() {
          voiceActive = false;
        });
      }
      if (counterValues[page] != 0 && voiceActive) {
        _toggleSound(sectionDetails[page].soundId);
      } else {
        voiceActive = false;
        _toggleSound(sectionDetails[page].soundId);
      }
    });
  }

  Widget _buildCounterPage(int index) {
    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: (KeyEvent event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.enter) {
            decrementCounter(index);
          }
        }
      },
      autofocus: true,
      child: GestureDetector(
        onTap: () => decrementCounter(index),
        child: Container(
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
              _buildTopSection(index),
              Expanded(child: _buildContentSection(index)),
              _buildCounterSection(index),
              _buildBottomSection(index),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopSection(int index) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildActionButtons(index),
          _buildPageIndicator(),
        ],
      ),
    );
  }

  Widget _buildActionButtons(int index) {
    return Row(
      children: [
        if (!kIsWeb)
          _buildActionButton(
            Icons.share,
            () => Share.share(sectionDetails[index].content.toString()),
            const Color(0xFF2196F3),
          ),
        _buildFontSizeButton(),
        if (sectionDetails[index].soundId != "") _buildSoundButton(index),
        if (voiceActive) _buildSpeedButton(),
      ],
    );
  }

  Widget _buildActionButton(
      IconData icon, VoidCallback onPressed, Color color) {
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

  Widget _buildSoundButton(int index) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        color: voiceActive
            ? Colors.red.withOpacity(0.1)
            : Colors.teal.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        onPressed: () {
          setState(() {
            currentCounterValue = counterValues[index];
            if (currentCounterValue > 0 &&
                sectionDetails[index].soundId != "") {
              voiceActive = !voiceActive;
            }
          });
          if (currentCounterValue > 0) {
            _toggleSound(sectionDetails[index].soundId);
          } else {
            decrementCounter(index);
          }
        },
        icon: Icon(
          voiceActive ? Icons.stop : Icons.volume_up,
          color: voiceActive ? Colors.red : Colors.green,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildSpeedButton() {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextButton(
        onPressed: () {
          setState(() {
            if (playbackRate == 1) {
              playbackRate = 1.5;
            } else if (playbackRate == 1.5) {
              playbackRate = 2;
            } else if (playbackRate == 2) {
              playbackRate = 2.5;
            } else {
              playbackRate = 1;
            }
            _player.setSpeed(playbackRate);
          });
        },
        child: Text(
          "${playbackRate}x",
          style: const TextStyle(
            color: Colors.purple,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        "${currentPage + 1}/${counterValues.length}",
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildContentSection(int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildContentCard(index),
            if (sectionDetails[index].description!.isNotEmpty)
              _buildDescriptionCard(index),
          ],
        ),
      ),
    );
  }

  Widget _buildContentCard(int index) {
    return Container(
      width: 1200,
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
        "${sectionDetails[index].content}",
        // textDirection: TextDirection.rtl,
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

  Widget _buildDescriptionCard(int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkTheme
            ? Colors.blue.withOpacity(0.1)
            : Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkTheme
              ? Colors.blue.withOpacity(0.3)
              : Colors.blue.withOpacity(0.2),
        ),
      ),
      child: Text(
        "${sectionDetails[index].description}",
        // textDirection: TextDirection.LTR,
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

  Widget _buildCounterSection(int index) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: GestureDetector(
              onTap: () => decrementCounter(index),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.teal.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: CircularPercentIndicator(
                  radius: 80.0,
                  lineWidth: 12.0,
                  percent: counterValues[index] /
                      int.parse(sectionDetails[index].count.toString()),
                  center: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "${counterValues[index]}",
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
                  backgroundColor: primaryColor.withOpacity(0.2),
                  circularStrokeCap: CircularStrokeCap.round,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomSection(int index) {
    return Container(
      height: 60,
      child: index == 0
          ? Center(
              child: Column(
                children: [
                  Icon(
                    Icons.keyboard_arrow_down,
                    size: 30,
                    color: secondaryTextColor,
                  ),
                  Text(
                    "اسحب لأسفل",
                    style: TextStyle(
                      fontSize: 12,
                      color: secondaryTextColor,
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox(),
    );
  }

  loadSectionDetail() async {
    sectionDetails = [];
    DefaultAssetBundle.of(context)
        .loadString("assets/database/section_details_db.json")
        .then((data) {
      var response = json.decode(data);
      response.forEach((section) {
        SectionDetailModel sectionDetail = SectionDetailModel.fromJson(section);

        if (sectionDetail.sectionId == widget.id) {
          sectionDetails.add(sectionDetail);
        }
      });
      setState(() {
        for (int index = 0; index < sectionDetails.length; index++) {
          counterValues.add(int.parse(sectionDetails[index].count.toString()));
        }
        isLoad = true;
      });
    }).catchError((error) {
      showExceptionPopup(context, error.toString());
    });
  }
}
