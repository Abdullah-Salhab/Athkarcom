import 'dart:convert';

import 'package:athkar/models/section_detail_model.dart';
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
  _CounterPageState createState() => _CounterPageState();
}

class _CounterPageState extends State<CounterPage> {
  List<SectionDetailModel> sectionDetails = [];
  bool isLoad = false;
  final _pageController = PageController();
  List<int> counterValues = [];
  int currentPage = 0;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    loadSectionDetail();
  }

  void decrementCounter(int index) {
    print(counterValues[index]);
    setState(() {
      if (counterValues[index] > 0) {
        counterValues[index] = counterValues[index] - 1;
      }
      if (counterValues[index] == 0 &&
          _pageController.page != sectionDetails.length - 1) {
        if (!kIsWeb) Vibrate.vibrate();
        print("Enter");
        _pageController.nextPage(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
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
          style: TextStyle(
            fontFamily: 'Amiri',
            fontSize: 24.0,
          ),
        ),
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
              event.logicalKey == LogicalKeyboardKey.arrowDown ) {
            _pageController.nextPage(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOut,
            );
            // decrementCounter(index);
          }
          else if(event.logicalKey == LogicalKeyboardKey.arrowUp){
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
                                "${sectionDetails[index].content}",
                                textDirection: TextDirection.rtl,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 18, fontFamily: 'Amiri', height: 2),
                              ),
                            ),
                          ),
                          if (sectionDetails[index].description!.isNotEmpty)
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
                        style:
                            const TextStyle(fontSize: 30, fontFamily: 'Tajawal'),
                      ),
                      progressColor: Colors.green,
                    ),
                  ),
                ],
              ),
              SizedBox(),
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
