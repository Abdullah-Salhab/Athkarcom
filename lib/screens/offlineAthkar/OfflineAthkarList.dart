import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../onlineAthkar/Counter_Athkar.dart';

class OfflineAthkarList extends StatefulWidget {
  const OfflineAthkarList({super.key});

  @override
  State<OfflineAthkarList> createState() => _OfflineAthkarListState();
}

class _OfflineAthkarListState extends State<OfflineAthkarList> {
  List<String> athkarList = [];
  List<String> athkarCount = [];
  List<String> athkarCurrentCount = [];
  bool isLoad = false;

  @override
  void initState() {
    getAthkarList();
  }

  getAthkarList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      if (prefs.containsKey('athkarList') &&
          prefs.containsKey("athkarCount") &&
          prefs.containsKey("athkarCurrentCount")) {
        athkarList = prefs.getStringList('athkarList')!;
        athkarCount = prefs.getStringList('athkarCount')!;
        athkarCurrentCount = prefs.getStringList('athkarCurrentCount')!;
      }
      isLoad = true;
    });
  }

  updateAthkarList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('athkarList', athkarList);
    await prefs.setStringList('athkarCount', athkarCount);
    await prefs.setStringList('athkarCurrentCount', athkarCurrentCount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'أذكاري',
          style: TextStyle(
            fontFamily: 'Amiri',
            fontSize: 24.0,
          ),
        ),
        actions: [
          IconButton(
              onPressed: () {
                _showAddAthkarDialog(context);
              },
              icon: const Icon(Icons.add_box))
        ],
      ),
      body: athkarList.isNotEmpty
          ? ListView.builder(
              shrinkWrap: true,
              itemCount: athkarList.length,
              itemBuilder: (BuildContext context, int index) {
                return Container(
                  margin: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: Theme.of(context).dialogBackgroundColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset:
                            const Offset(0, 2), // changes position of shadow
                      ),
                    ],
                  ),
                  child: ListTile(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => CounterAthkarScreen(
                                    count: int.parse(athkarCount[index]),
                                    currentCount:
                                        int.parse(athkarCurrentCount[index]),
                                    content: athkarList[index],
                                    id: "0",
                                    value: "",
                                    index: index,
                                  ))).then((value) => getAthkarList());
                    },
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // athkarStatus[index]?Icon(Icons.done,size: 10,color: Colors.green,):SizedBox(),
                        SizedBox(
                          width: MediaQuery.sizeOf(context).width > 600
                              ? 300
                              : 120,
                          child: Text(
                            athkarList[index],
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                            ),
                          ),
                        ),
                        SizedBox(
                          width: MediaQuery.sizeOf(context).width > 600
                              ? 150
                              : MediaQuery.sizeOf(context).width > 350
                                  ? 125
                                  : 70,
                          child: Text(
                              "${athkarCurrentCount[index]}/${athkarCount[index]}"),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                _showDeleteConfirmationDialog(context, index);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    // Add more fields if needed
                  ),
                );
              },
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "لا يوجد لديك أذكار",
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 24.0,
                    ),
                  ),
                  ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(
                          Theme.of(context).dialogBackgroundColor,
                        ),
                        shadowColor: MaterialStateProperty.all(
                            Colors.grey.withOpacity(0.5)),
                      ),
                      onPressed: () {
                        _showAddAthkarDialog(context);
                      },
                      child:  Text(
                        "إضافة ذكر",
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 22.0,
                          color: Theme.of(context).hintColor
                        ),
                      ))
                ],
              ),
            ),
    );
  }

  Future<void> _showDeleteConfirmationDialog(
      BuildContext context, int index) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'حذف ذكر',
            style: TextStyle(
              fontFamily: 'Tajawal',
            ),
          ),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  'هل انت متأكد من حذف هذا الذكر؟',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'الغاء',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text(
                'حذف',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                ),
              ),
              onPressed: () async {
                setState(() {
                  athkarList.removeAt(index);
                  athkarCount.removeAt(index);
                  athkarCurrentCount.removeAt(index);
                });
                await updateAthkarList();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAddAthkarDialog(BuildContext context) async {
    final TextEditingController _countController = TextEditingController();
    final TextEditingController _contentController = TextEditingController();
    final _formKey = GlobalKey<FormState>();
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'إضافة ذكر',
            style: TextStyle(
              fontFamily: 'Tajawal',
            ),
          ),
          content: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _contentController,
                      decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          labelText: "* الذكر"),
                      validator: (value) {
                        if (value!.trim().isEmpty) {
                          return 'يرجى إدخال الذكر';
                        }
                        return null;
                      },
                      maxLength: 100,
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    TextFormField(
                      controller: _countController,
                      decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          labelText: "* العدد"),
                      validator: (value) {
                        if (value!.trim().isEmpty) {
                          return 'يرجى إدخال العدد';
                        }
                        return null;
                      },
                      maxLength: 6,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'الغاء',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text(
                'إضافة',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                ),
              ),
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  setState(() {
                    athkarList.add(_contentController.text);
                    athkarCount.add(_countController.text);
                    athkarCurrentCount.add(_countController.text);
                  });
                  await updateAthkarList();
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }
}
