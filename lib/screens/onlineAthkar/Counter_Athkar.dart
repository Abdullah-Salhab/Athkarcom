import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:share/share.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CounterAthkarScreen extends StatefulWidget {
  final int count;
  final String content;
  final String value;
  final String id;
  final int index;
  final int currentCount;
  final List? users;
  final String? userName;

  const CounterAthkarScreen({
    super.key,
    required this.count,
    required this.content,
    required this.value,
    required this.id,
    required this.index,
    required this.currentCount,
    this.users,
    this.userName,
  });

  @override
  _CounterAthkarScreenState createState() => _CounterAthkarScreenState();
}

class _CounterAthkarScreenState extends State<CounterAthkarScreen> {
  int counter = 0;

  Future<void> _updateUsers() async {
    final objectRef =
        FirebaseFirestore.instance.collection('athkar_group').doc(widget.id);
    List? users = widget.users;
    users?.add(widget.userName);
    await objectRef.update({
      'users': users,
    });

  }

  @override
  void initState() {
    super.initState();
    setState(() {
      counter = widget.currentCount;
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
      child: Container(
        width: double.infinity,
        color: const Color.fromRGBO(240, 248, 255, 1.0),
        height: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Column(
              children: [
                Container(
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
                    ],
                  ),
                ),
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: 430),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                          margin:
                              EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                          padding:
                              EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(.5),
                                  spreadRadius: 2,
                                  blurRadius: 1,
                                  offset: const Offset(0, 3),
                                )
                              ]),
                          child: ListTile(
                            title: Text(
                              "${widget.content}",
                              textDirection: TextDirection.rtl,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 18, fontFamily: 'Amiri', height: 2),
                            ),
                          ),
                        ),
                        if (widget.value!.isNotEmpty)
                          Container(
                            margin: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 5),
                            padding: EdgeInsets.symmetric(
                                horizontal: 5, vertical: 5),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(.5),
                                    spreadRadius: 2,
                                    blurRadius: 1,
                                    offset: const Offset(0, 3),
                                  )
                                ]),
                            child: ListTile(
                              subtitle: Text(
                                "${widget.value}",
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
                  onTap: () => decreaseCounter(),
                  child: CircularPercentIndicator(
                    radius: 80.0,
                    lineWidth: 9.0,
                    percent: counter / int.parse(widget.count.toString()),
                    center: Text(
                      "${counter}",
                      style:
                          const TextStyle(fontSize: 30, fontFamily: 'Tajawal'),
                    ),
                    progressColor: Colors.green,
                  ),
                ),
              ],
            ),
            if (counter == 0 && widget.index != -1)
              ElevatedButton.icon(
                  onPressed: () {
                    resetCounter();
                  },
                  icon: Icon(Icons.refresh),
                  label: Text(
                    "إعادة",
                    style: TextStyle(fontSize: 20),
                  )),
            SizedBox(
              height: 10,
            ),
          ],
        ),
      ),
    );
  }

  void decreaseCounter() {
    setState(() {
      if (counter > 0) {
        counter--;

        if (widget.id == "0")
          saveCounterResult();
        else
          saveCounterOnlineResult();
      }
      if (counter == 0) {
        Vibrate.vibrate();
        if (widget.id == "0") {
          print("Finished Offline");
        } else {
          _updateUsers();
          print("Finished Online");
        }
        if (widget.id != "0")
        Navigator.of(context).pop();
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
                      SizedBox(
                        width: 5,
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.close,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 5,
                  ),
                  Image.asset(
                    "assets/images/celebrate.gif",
                    width: 150,
                  ),
                  SizedBox(
                    height: 5,
                  ),
                  const Text(
                    'تم إكمال الذكر هنيئاً لك',
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
