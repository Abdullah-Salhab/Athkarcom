import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
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

    Navigator.of(context).pop();
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
            fontFamily: 'Tajawal',
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                width: 1000,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        !kIsWeb? IconButton(
                            onPressed: () {
                              Share.share(widget.content.toString());
                            },
                            icon: const Icon(Icons.share)):SizedBox(),
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
                                      style: TextStyle(
                                        fontFamily: 'Tajawal',
                                      ),
                                    )),
                              );
                            },
                            icon: const Icon(Icons.copy)),
                      ],
                    ),
                    Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.amber,
                        ),
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 5),
                        child: const Text("1/1",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ))),
                  ],
                ),
              ),
              Container(
                margin: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(.5),
                        spreadRadius: 5,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      )
                    ],
                    borderRadius: BorderRadius.circular(10)),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                      maxHeight: 300, maxWidth: 1300, minWidth: 1300),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 10),
                      child: Text(
                        "الذكر: ${widget.content}",
                        textDirection: TextDirection.rtl,
                        style: const TextStyle(
                            fontSize: 20, fontFamily: 'Tajawal'),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: 15,
              ),
              if (widget.value != "")
                Container(
                  margin: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(.5),
                          spreadRadius: 5,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        )
                      ],
                      borderRadius: BorderRadius.circular(10)),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: 200, maxWidth: 1300),
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 10),
                        child: Text(
                          "الفضل: ${widget.value}",
                          textDirection: TextDirection.rtl,
                          style: const TextStyle(
                              fontSize: 18, fontFamily: 'Tajawal'),
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(
                height: 200,
              ),
              GestureDetector(
                onTap: () {
                  decreaseCounter();
                },
                child: CircularPercentIndicator(
                  radius: 100.0,
                  lineWidth: 13.0,
                  percent: counter / int.parse(widget.count.toString()),
                  center: Text(
                    "$counter",
                    style: const TextStyle(
                      fontSize: 30,
                    ),
                  ),
                  progressColor: Colors.green,
                ),
              ),
              SizedBox(
                height: 10,
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
                    ))
            ],
          ),
        ),
      ),
    );
  }

  void decreaseCounter() {
    setState(() {
      if (counter > 0) {
        counter--;

        if (widget.id == "0") saveCounterResult();
        else saveCounterOnlineResult();
      }
      if (counter == 0) {
        if (widget.id == "0") {
          print("Finished Offline");
        } else {
          _updateUsers();
          print("Finished Online");
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text('تم إنهاء الذكر 👏✅'),
            duration: Duration(seconds: 1),
          ),
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
