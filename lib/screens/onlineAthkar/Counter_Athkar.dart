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

class CounterAthkarScreenState extends State<CounterAthkarScreen> {
  int counter = 0;
  double fontSize = 18;
  late ConfettiController _confettiController;

  Future<void> _updateUsers() async {
    final objectRef =
        FirebaseFirestore.instance.collection('Groups').doc(widget.groupId).collection("Athkars").doc(widget.id);
    // Fetch the document snapshot
    DocumentSnapshot docSnapshot = await objectRef.get();

    if (docSnapshot.exists) {
      // Get the 'users' field, ensuring it's a List
      List<dynamic> users =
          (docSnapshot.data() as Map<String, dynamic>)['users'] ?? [];

      // Add the new user if not already in the list
      if (!users.contains(widget.userName)) {
        users.add(widget.userName);

        // Update Firestore document
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
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 5));
    getFontSize();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _triggerConfetti() {
    _confettiController.play();
  }

  //this function will get the current font size
  Future getFontSize() async {
    SharedPreferences sharedPreferences =
        await SharedPreferences.getInstance().catchError((e) {
      showExceptionPopup(context, e.toString());
    });
    double? fontSizeSaved = sharedPreferences.getDouble('fontSize');
    if (fontSizeSaved != null) {
      setState(() {
        fontSize = fontSizeSaved;
      });
    }
  }

  //this function will set new font size
  Future setNewFontSize() async {
    SharedPreferences sharedPreferences =
        await SharedPreferences.getInstance().catchError((e) {
      showExceptionPopup(context, e.toString());
    });
    sharedPreferences.setDouble('fontSize', fontSize).catchError((e) {
      showExceptionPopup(context, e.toString());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'الذكر',
          style: TextStyle(
            fontFamily: 'Amiri',
            fontSize: 24.0,
          ),
        ),
      ),
      body: buildGestureDetector(),
    );
  }

  GestureDetector buildGestureDetector() {
    return GestureDetector(
      onTap: () {
        decreaseCounter();
      },
      child: Stack(children: [
        Container(
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
                                      Share.share(widget.content.toString());
                                    },
                                    icon: const Icon(Icons.share))
                                : const SizedBox(),
                            IconButton(
                                onPressed: () {
                                  // Copy the content to the clipboard
                                  Clipboard.setData(ClipboardData(
                                      text: widget.content.toString()));
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
                          ],
                        ),
                        counter > 0 && widget.id != "0"
                            ? ElevatedButton(
                                onPressed: () async {
                                  setState(() {
                                    counter = 0;
                                  });
                                  if(!kIsWeb) {
                                    Vibrate.vibrate();
                                  }
                                  _triggerConfetti();
                                  saveCounterOnlineResult().catchError((e) {
                                    showExceptionPopup(context, e.toString());
                                  });
                                  await _updateUsers().catchError((e) {
                                    showExceptionPopup(context, e.toString());
                                  });
                                  await _updateUserPoints().catchError((e) {
                                    showExceptionPopup(context, e.toString());
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      backgroundColor: Colors.green,
                                      content: Text('تم إكمال الذكر هنيئاً لك'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                  // Delay for 1 second before navigating back
                                  await Future.delayed(
                                      const Duration(seconds: 1));
                                  Navigator.of(context).pop();
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 15, vertical: 5),
                                  backgroundColor: Colors.green,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  elevation: 8,
                                  // Adjust the shadow depth
                                  shadowColor: Colors.black
                                      .withOpacity(0.7), // Adjust shadow color
                                ),
                                child: const Text(
                                  " تم عمله بخاتم التسبيح ✅",
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.white),
                                ),
                              )
                            : const SizedBox(),
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
                                  color: fontSize > 18
                                      ? Colors.blue
                                      : Theme.of(context).hintColor,
                                  fontSize: fontSize,
                                  fontWeight: FontWeight.bold),
                            )),
                      ],
                    ),
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 430),
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
                                widget.content,
                                textDirection: TextDirection.rtl,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: fontSize,
                                    fontFamily: 'Amiri',
                                    height: 2),
                              ),
                            ),
                          ),
                          if (widget.value.isNotEmpty)
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
                                  widget.value,
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
                    onTap: () => decreaseCounter(),
                    child: CircularPercentIndicator(
                      radius: 80.0,
                      lineWidth: 9.0,
                      percent: counter / int.parse(widget.count.toString()),
                      center: Text(
                        "$counter",
                        style: const TextStyle(
                            fontSize: 30, fontFamily: 'Tajawal'),
                      ),
                      progressColor: Colors.green,
                    ),
                  ),
                  const SizedBox(
                    height: 50,
                  ),
                ],
              ),
              if (counter == 0 && widget.index != -1)
                ElevatedButton.icon(
                    onPressed: () {
                      resetCounter().catchError((e) {
                        showExceptionPopup(context, e.toString());
                      });
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text(
                      "إعادة",
                      style: TextStyle(fontSize: 20),
                    )),
              const SizedBox(
                height: 10,
              ),
            ],
          ),
        ),
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
      ]),
    );
  }

  Future<void> decreaseCounter() async {
    if (counter > 1) {
      setState(() {
        counter--;
      });
    } else if (counter == 1) {
      if (kIsWeb == false) Vibrate.vibrate();
      setState(() {
        counter--;
      });
      if (widget.id == "0") {
        // print("Finished Offline");
      } else {
        await _updateUsers().catchError((e) {
          showExceptionPopup(context, e.toString());
        });
        await _updateUserPoints().catchError((e) {
          showExceptionPopup(context, e.toString());
        });
        // print("Finished Online");
      }
      _triggerConfetti();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text('تم إكمال الذكر هنيئاً لك'),
          duration: Duration(seconds: 2),
        ),
      );
      // Delay for 1 second before navigating back
      await Future.delayed(const Duration(seconds: 1));
      if (widget.id != "0" && counter == 0) Navigator.of(context).pop();
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
    List<String> athkarCurrentCount =
        prefs.getStringList('athkarCurrentCount')!;
    athkarCurrentCount[widget.index] = counter.toString();
    prefs.setStringList('athkarCurrentCount', athkarCurrentCount);
  }

  Future<void> saveCounterOnlineResult() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(widget.id.toString(), counter.toString());
  }

  Future<void> resetCounter() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> athkarCurrentCount =
        prefs.getStringList('athkarCurrentCount')!;
    setState(() {
      counter = widget.count;
    });
    athkarCurrentCount[widget.index] = widget.count.toString();
    prefs.setStringList('athkarCurrentCount', athkarCurrentCount);
  }
}
