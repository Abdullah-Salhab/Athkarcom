import 'dart:convert';

import 'package:athkar/models/section_detail_model.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:share/share.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';

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

  @override
  void initState() {
    super.initState();
    loadSectionDetail();
    _player = AudioPlayer();
    // Set the release mode to keep the source after playback has completed.
    _player.setReleaseMode(ReleaseMode.stop); // Replay the sound required

    // Listen to player completion event
    _player.onPlayerComplete.listen((event) async {
      if (currentCounterValue > 1) {
        await _player.resume(); // Replay the sound
      }
      decrementCounter(currentPage);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  void _toggleSound(String? soundId) async {
    if (voiceActive == false) {
      // stop the sound when press the stop button
      await _player.stop();
    } else {
      final path = _getSoundPath(soundId!);
      if (path != null) {
        await _player.setSource(AssetSource(path));
        await _player.setPlaybackRate(playbackRate); // Set playback speed
        await _player.resume(); // play
      }
    }
  }

  String? _getSoundPath(String soundId) {
    if (soundId.contains("C")) {
      return 'sounds/common/Athkar_$soundId.mp3';
    } else if (soundId.contains("E")) {
      return 'sounds/evening/Athkar_$soundId.mp3';
    } else {
      return 'sounds/morning/Athkar_$soundId.mp3';
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
        _pageController.nextPage(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
        );
        // play next sound if the value counter is more than 0 and voice is active
        if (currentCounterValue > 0 && voiceActive) {
          _toggleSound(sectionDetails[index + 1].soundId);
        }
      }
      if (counterValues[index] == 0 &&
          _pageController.page == sectionDetails.length - 1) {
        // show many pauses to inform the user that the Athkars finished
        final Iterable<Duration> pauses = [
          const Duration(milliseconds: 500),
          const Duration(milliseconds: 1000),
          const Duration(milliseconds: 500),
        ];
        if (!kIsWeb && vibrationActive) Vibrate.vibrateWithPauses(pauses);
        Navigator.pop(context);
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
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
            );
          },
        );
      }
    });
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
                ))
        ],
      ),
      body: !isLoad
          ? const Center(
              child: CircularProgressIndicator(
                value: 5,
              ),
            )
          : PageView(
              scrollDirection: Axis.vertical,
              controller: _pageController,
              onPageChanged: (int page) {
                setState(() {
                  currentPage = page;
                });
              },
              children: [
                  for (int index = 0; index < sectionDetails.length; index++)
                    buildGestureDetector(index),
                ]),
    );
  }

  KeyboardListener buildGestureDetector(int index) {
    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: (KeyEvent event) {
        if (event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.space ||
            event.logicalKey == LogicalKeyboardKey.arrowDown) {
          _pageController.nextPage(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
          );
          // decrementCounter(index);
        } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
          _pageController.previousPage(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
          );
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
                            IconButton(
                                onPressed: () {
                                  setState(() {
                                    currentCounterValue = counterValues[index];
                                    if (currentCounterValue > 0) {
                                      voiceActive = !voiceActive;
                                    }
                                  });
                                  if (currentCounterValue > 0) {
                                    _toggleSound(sectionDetails[index].soundId);
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
                                        playbackRate = 1.5;
                                      } else if (playbackRate == 1.5) {
                                        playbackRate = 2;
                                      } else if (playbackRate == 2) {
                                        playbackRate = 2.5;
                                      } else {
                                        playbackRate = 1;
                                      }
                                      // Apply the new playback rate immediately
                                      _player.setPlaybackRate(playbackRate);
                                    });
                                  },
                                  child: Text(
                                    playbackRate.toString(),
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
                    constraints:
                        BoxConstraints(maxHeight: index == 0 ? 330 : 430),
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
                                style: const TextStyle(
                                    fontSize: 18,
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
                                  style: const TextStyle(
                                      fontSize: 16,
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
                      radius: 80.0,
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
        SectionDetailModel _sectionDetail =
            SectionDetailModel.fromJson(section);

        if (_sectionDetail.sectionId == widget.id) {
          sectionDetails.add(_sectionDetail);
        }
      });
      setState(() {
        for (int index = 0; index < sectionDetails.length; index++) {
          counterValues.add(int.parse(sectionDetails[index].count.toString()));
        }
        isLoad = true;
      });
    }).catchError((error) {
      print(error);
    });
  }

}
