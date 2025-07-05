import 'dart:convert';
import 'dart:math';

import 'package:athkar/models/section_detail_model.dart';
import 'package:just_audio/just_audio.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:share/share.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:confetti/confetti.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../ExceptionDialog.dart';

class CounterPage extends StatefulWidget {
  final int id;
  final String title;

  const CounterPage({Key? key, required this.id, required this.title})
      : super(key: key);

  @override
  CounterPageState createState() => CounterPageState();
}

class CounterPageState extends State<CounterPage> {
  List<SectionDetailModel> sectionDetails = [];
  bool isLoad = false;
  final _pageController = PageController();
  List<int> counterValues = [];
  int currentPage = 0;
  final FocusNode _focusNode = FocusNode();
  bool vibrationActive = true;
  bool voiceActive = false;
  late AudioPlayer _player;
  int currentCounterValue = 0;
  double playbackRate = 1;
  late ConfettiController _confettiController;
  bool isCheckingRemaining = false;
  double fontSize = 18;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 5));
    try {
      loadSectionDetail();
      _player = AudioPlayer();

      // Listen to player completion event
      _player.playerStateStream.listen((state) async {
        if (state.processingState == ProcessingState.completed && voiceActive) {
          if (currentCounterValue > 1) {
            await _player.seek(Duration.zero);
            await _player.play();
          }
          decrementCounter(currentPage);
        }
      });
      // Keep the screen on
      WakelockPlus.enable();
    } catch (e) {
      showExceptionPopup(context, e.toString());
    }
    getFontSize();
  }

  @override
  void dispose() {
    _player.dispose();
    _confettiController.dispose();
    WakelockPlus.disable();
    super.dispose();
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

  Future<void> _toggleSound(String? soundId) async {
    try {
      if (voiceActive == false) {
        // stop the sound when press the stop button
        await _player.stop();
      } else {
        final path = _getSoundPath(soundId!);
        if (path != null) {
          await _player.setAsset(path);
          await _player.setSpeed(playbackRate);
          await _player.play(); // or stop()
        }
      }
    } catch (e) {
      showExceptionPopup(context, e.toString());
    }
  }

  String? _getSoundPath(String soundId) {
    if (soundId.contains("C")) {
      return 'assets/sounds/common/Athkar_$soundId.mp3';
    } else if (soundId.contains("E")) {
      return 'assets/sounds/evening/Athkar_$soundId.mp3';
    } else {
      return 'assets/sounds/morning/Athkar_$soundId.mp3';
    }
  }

  // decrement the counter, the index is the current page value
  void decrementCounter(int index) {
    setState(() {
      if (counterValues[index] > 0) {
        counterValues[index] = counterValues[index] -
            1; // decrease the current value for this theker
        currentCounterValue--; // decrease the current counter value
      }
      if (counterValues[index] == 0 &&
          _pageController.page != sectionDetails.length - 1) {
        currentCounterValue = counterValues[
            index + 1]; // set the next counter into current counter value
        if (!kIsWeb && vibrationActive) Vibrate.vibrate();
        if (sectionDetails[index + 1].soundId == "") {
          setState(() {
            voiceActive = false;
          });
        }
        _pageController
            .nextPage(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
        )
            .whenComplete(() {
          // play next sound if the value counter is more than 0 and voice is active
          if (currentCounterValue > 0 && voiceActive) {
            _toggleSound(sectionDetails[index + 1].soundId);
          }
        });
      }
      if (counterValues[index] == 0 &&
          _pageController.page == sectionDetails.length - 1) {
        // check all values if are 0 or not
        bool isFinishAll = true;
        for (int x = 0; x < sectionDetails.length; x++) {
          if (counterValues[x] != 0) {
            isFinishAll = false;
            isCheckingRemaining = true;
            _pageController.animateToPage(x,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOut);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text(
                '😊 لم تكمل جميع الأذكار 😊',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.black,
              duration: Duration(seconds: 3),
            ));
            break;
          }
        }

        // check if finish all athkars
        if (isFinishAll) {
          // show many pauses to inform the user that the Athkars finished
          final Iterable<Duration> pauses = [
            const Duration(milliseconds: 500),
            const Duration(milliseconds: 1000),
            const Duration(milliseconds: 500),
          ];
          if (!kIsWeb && vibrationActive) Vibrate.vibrateWithPauses(pauses);
          _triggerConfetti();
          voiceActive = false;
          showModalBottomSheet<void>(
            context: context,
            builder: (BuildContext context) {
              return SizedBox(
                height: 250,
                child: Column(
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const SizedBox(
                          width: 5,
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.close,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    Image.asset(
                      "assets/images/celebrate.gif",
                      width: 150,
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    const Text(
                      'تم إكمال الأذكار هنيئاً لك',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ],
                ),
              );
            },
          );
        }
      }
    });
  }

  void _triggerConfetti() {
    _confettiController.play();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(
            fontFamily: 'Amiri',
            fontSize: 24.0,
          ),
        ),
        actions: [
          if (!kIsWeb)
            IconButton(
                onPressed: () {
                  setState(() {
                    vibrationActive = !vibrationActive;
                  });
                },
                icon: Icon(
                  Icons.vibration,
                  color: vibrationActive ? Colors.amber : Colors.white,
                  size: 27,
                )),
          TextButton(
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
                style: TextStyle(
                    color: fontSize > 18 ? Colors.amber : Colors.white,
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold),
              )),
        ],
      ),
      body: !isLoad
          ? const Center(
              child: CircularProgressIndicator(
                value: 5,
              ),
            )
          : Stack(
              children: [
                PageView(
                    scrollDirection: Axis.vertical,
                    controller: _pageController,
                    onPageChanged: (int page) {
                      setState(() {
                        // move to the page that not 0
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
                    },
                    children: [
                      for (int index = 0;
                          index < sectionDetails.length;
                          index++)
                        buildGestureDetector(index),
                    ]),
                // Confetti Widget positioned at the top center
                Align(
                  alignment: Alignment.topCenter,
                  child: ConfettiWidget(
                    confettiController: _confettiController,
                    blastDirection: pi / 2,
                    // Downward
                    emissionFrequency: 0.05,
                    // Customize the effect
                    numberOfParticles: 20,
                    maxBlastForce: 10,
                    // Higher number for more spread
                    minBlastForce: 5,
                    // Lower number for closer particles
                    colors: const [
                      Colors.red,
                      Colors.blue,
                      Colors.green,
                      Colors.yellow
                    ],
                    shouldLoop: false,
                  ),
                ),
              ],
            ),
    );
  }

  KeyboardListener buildGestureDetector(int index) {
    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: (KeyEvent event) {
        if (event is KeyDownEvent) {
          // Handle only KeyDownEvent
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
          color: Theme.of(context).scaffoldBackgroundColor,
          height: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Column(
                children: [
                  Container(
                    width: 1300,
                    margin:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            !kIsWeb
                                ? IconButton(
                                    onPressed: () {
                                      Share.share(sectionDetails[index]
                                          .content
                                          .toString());
                                    },
                                    icon: const Icon(Icons.share))
                                : const SizedBox(),
                            IconButton(
                                onPressed: () {
                                  // Copy the content to the clipboard
                                  Clipboard.setData(ClipboardData(
                                      text: sectionDetails[index]
                                          .content
                                          .toString()));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        backgroundColor: Colors.blue,
                                        duration: Duration(seconds: 2),
                                        content: Text(
                                          'تم النسخ الى الحافظة',
                                        )),
                                  );
                                },
                                icon: const Icon(Icons.copy)),
                            if (sectionDetails[index].soundId != "")
                              IconButton(
                                  onPressed: () {
                                    setState(() {
                                      currentCounterValue =
                                          counterValues[index];
                                      if (currentCounterValue > 0 &&
                                          sectionDetails[index].soundId != "") {
                                        voiceActive = !voiceActive;
                                      }
                                    });
                                    if (currentCounterValue > 0) {
                                      _toggleSound(
                                          sectionDetails[index].soundId);
                                    } else {
                                      decrementCounter(index);
                                    }
                                  },
                                  icon: Icon(voiceActive
                                      ? Icons.stop
                                      : Icons.volume_up)),
                            if (voiceActive)
                              TextButton(
                                  onPressed: () {
                                    setState(() {
                                      if (playbackRate == 1) {
                                        playbackRate = 5.5;
                                      } else if (playbackRate == 1.5) {
                                        playbackRate = 2;
                                      } else if (playbackRate == 2) {
                                        playbackRate = 2.5;
                                      } else {
                                        playbackRate = 1;
                                      }
                                      // Apply the new playback rate immediately
                                      _player.setSpeed(playbackRate);
                                    });
                                  },
                                  child: Text(
                                    "${playbackRate}x",
                                    style: TextStyle(
                                        color: playbackRate > 1.5
                                            ? Colors.red
                                            : playbackRate > 1
                                                ? Colors.blue
                                                : Theme.of(context).hintColor,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ))
                          ],
                        ),
                        Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: Colors.amber,
                            ),
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 5),
                            child: Text(
                              "${currentPage + 1}/${counterValues.length}",
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            )),
                      ],
                    ),
                  ),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                        maxHeight: index == 0
                            ? 330
                            : fontSize > 23
                                ? 480
                                : 430),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Container(
                            width: 1300,
                            margin: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 5),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 5),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Theme.of(context).dialogBackgroundColor,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(.5),
                                    spreadRadius: 2,
                                    blurRadius: 7,
                                    offset: const Offset(0, 3),
                                  )
                                ]),
                            child: ListTile(
                              title: Text(
                                "${sectionDetails[index].content}",
                                textDirection: TextDirection.rtl,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: fontSize,
                                    fontFamily: 'Amiri',
                                    height: 2),
                              ),
                            ),
                          ),
                          if (sectionDetails[index].description!.isNotEmpty)
                            Container(
                              width: 1300,
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 5),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 5),
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color:
                                      Theme.of(context).dialogBackgroundColor,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(.5),
                                      spreadRadius: 2,
                                      blurRadius: 7,
                                      offset: const Offset(0, 3),
                                    )
                                  ]),
                              child: ListTile(
                                subtitle: Text(
                                  "${sectionDetails[index].description}",
                                  textDirection: TextDirection.rtl,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: fontSize - 2,
                                      fontFamily: 'Tajawal',
                                      fontWeight: FontWeight.w100),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  GestureDetector(
                    onTap: () => decrementCounter(index),
                    child: CircularPercentIndicator(
                      radius: fontSize > 23 ? 70 : 80.0,
                      lineWidth: 9.0,
                      percent: counterValues[index] /
                          int.parse(sectionDetails[index].count.toString()),
                      center: Text(
                        "${counterValues[index]}",
                        style: const TextStyle(
                            fontSize: 30, fontFamily: 'Tajawal'),
                      ),
                      progressColor: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(),
              if (index == 0)
                Image.asset(
                  "assets/images/swipe-down.png",
                  width: 120,
                  opacity: const AlwaysStoppedAnimation(0.2),
                ),
            ],
          ),
        ),
      ),
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
