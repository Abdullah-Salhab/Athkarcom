import 'package:athkar/screens/onlineAthkar/Add_Athkar.dart';
import 'package:athkar/screens/onlineAthkar/Counter_Athkar.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AthkarListScreen extends StatefulWidget {
  const AthkarListScreen({super.key});

  @override
  State<AthkarListScreen> createState() => _AthkarListScreenState();
}

class _AthkarListScreenState extends State<AthkarListScreen> {
  String userName = "";
  int currentCount = 1;
  late SharedPreferences prefs;

  getUserName() async {
    // Check Shared Preferences
    prefs = await SharedPreferences.getInstance();
    setState(() {
      if (prefs.containsKey("userName")) {
        userName = prefs.getString('userName')!.trim();
      }
    });
  }

  int getCounterOnlineResult(String id) {
    if (prefs.containsKey(id)) {
      return int.parse(prefs.getString(id)!);
    } else {
      return -1;
    }
  }

  @override
  void initState() {
    getUserName();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'الأذكار الجماعية',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 24.0,
          ),
        ),
        actions: [
          IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddAthkarScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add_box))
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('athkar_group')
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final documents = snapshot.data!.docs;

          Map<DateTime, List<DocumentSnapshot>> groupedObjects = {};
          documents.forEach((doc) {
            final date = (doc['date'] as Timestamp).toDate();
            final dateKey = DateTime(date.year, date.month, date.day);

            if (!groupedObjects.containsKey(dateKey)) {
              groupedObjects[dateKey] = [];
            }
            groupedObjects[dateKey]!.add(doc);
          });

          return ListView(
            children: groupedObjects.entries.map((entry) {
              final date = entry.key;
              final objects = entry.value;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        '${date.day}/${date.month}/${date.year}',
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Tajawal'),
                      ),
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: objects.length,
                    itemBuilder: (context, index) {
                      final object = objects[index];
                      final List users = object['users'];
                      currentCount = getCounterOnlineResult(object.id);
                      // print(object['content']);
                      // print(users);
                      return Container(
                        margin: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.5),
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: const Offset(
                                  0, 2), // changes position of shadow
                            ),
                          ],
                        ),
                        child: ListTile(
                          onTap: () {
                            if (!users.contains(userName)) {
                              currentCount = getCounterOnlineResult(object.id);
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => CounterAthkarScreen(
                                            count: object["count"],
                                            content: object['content'],
                                            id: object.id,
                                            value: object['value'],
                                            index: -1,
                                            currentCount: currentCount >= 0
                                                ? currentCount
                                                : object["count"],
                                            userName: userName,
                                            users: users,
                                          ))).then((value) {
                                setState(() {
                                  currentCount =
                                      getCounterOnlineResult(object.id);
                                });
                                return true;
                              });
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  backgroundColor: Colors.green,
                                  content: Text('تم إنهاءه سابقاً'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            }
                          },
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              users.contains(userName)
                                  ? const Icon(
                                      Icons.done_outline,
                                      color: Colors.green,
                                    )
                                  : const SizedBox(),
                              SizedBox(
                                width: MediaQuery.sizeOf(context).width > 600
                                    ? 300
                                    : 120,
                                child: Text(
                                  object['content'],
                                  style: const TextStyle(
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
                                  '${users.contains(userName) ? 0 : currentCount >= 0 ? currentCount : object["count"]}/${object['count']}',
                                  style: const TextStyle(
                                    fontFamily: 'Tajawal',
                                  ),
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () {
                                      _showDeleteConfirmationDialog(
                                          context, object.id);
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
                  ),
                ],
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Future<void> _showDeleteConfirmationDialog(
      BuildContext context, String objectId) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('حذف ذكر'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('هل انت متأكد من حذف هذا الذكر؟'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('الغاء'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('حذف'),
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('athkar_group')
                    .doc(objectId)
                    .delete();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
