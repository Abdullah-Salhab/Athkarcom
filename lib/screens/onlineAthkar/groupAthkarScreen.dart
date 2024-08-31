import 'package:athkar/screens/onlineAthkar/Add_Athkar.dart';
import 'package:athkar/screens/onlineAthkar/Counter_Athkar.dart';
import 'package:athkar/screens/onlineAthkar/ThekerReadersScreen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/SettingsProvider.dart';

class GroupAthkarListScreen extends StatefulWidget {
  const GroupAthkarListScreen({super.key});

  @override
  State<GroupAthkarListScreen> createState() => _GroupAthkarListScreenState();
}

class _GroupAthkarListScreenState extends State<GroupAthkarListScreen>
    with SingleTickerProviderStateMixin {
  String userName = "";
  int currentCount = 1;
  late SharedPreferences prefs;
  late TabController _tabController;

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
    _tabController = TabController(length: 2, vsync: this);
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
        bottom: TabBar(
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.black54,
          labelStyle: TextStyle(fontSize: 16.0),
          unselectedLabelStyle: TextStyle(fontSize: 12.0),
          controller: _tabController,
          tabs: [
            Tab(text: 'الأذكار', icon: Icon(Icons.list_alt)),
            Tab(text: 'الأوائل', icon: Icon(Icons.star)),
          ],
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
              tooltip: 'إضافة ذكر',
              icon: const Icon(Icons.add_box))
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          athkarListStreamBuilder(),
          topUsersStreamBuilder(),
        ],
      ),
    );
  }

  StreamBuilder<QuerySnapshot<Object?>> topUsersStreamBuilder() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Users')
          .orderBy('points', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final documents = snapshot.data!.docs;
        int userIndex = 0;

        for (int x = 0; x < documents.length; x++) {
          if (documents[x].get("name") == userName) {
            userIndex = x;
            break;
          }
        }

        return ListView.builder(
          physics: BouncingScrollPhysics(),
          itemCount: documents.length < 10
              ? documents.length
              : userIndex >= 10
                  ? 11
                  : 10,
          itemBuilder: (context, currentIndex) {
            // to show my index
            int index = currentIndex == 10 ? userIndex : currentIndex;
            return Column(
              children: [
                if (index == 3 || currentIndex == 10)
                  SizedBox(
                    width: 1300,
                    child: Divider(
                      thickness: 2,
                    ),
                  ),
                Container(
                  width: 1300,
                  margin: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: Theme.of(context).dialogBackgroundColor,
                    border: Border.all(
                        color: documents[index].get("name") == userName
                            ? Colors.green
                            : Colors.white,
                        width: 2),
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
                    trailing: index < 3
                        ? Image.asset(
                            "assets/images/medal_${index + 1}.png",
                            width: 30,
                          )
                        : index < 10
                            ? const Icon(
                                size: 30,
                                Icons.stars_sharp,
                                color: Colors.yellow,
                              )
                            : SizedBox(),
                    leading: Text(
                      "${currentIndex == 11 ? userIndex : index + 1}",
                      style: TextStyle(fontSize: 18, fontFamily: 'Tajawal'),
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          documents[index].get("name"),
                          style: TextStyle(fontSize: 18, fontFamily: 'Tajawal'),
                        ),
                        Text(
                          documents[index].get("points").toString() + " نقطة",
                          style: TextStyle(fontSize: 18, fontFamily: 'Tajawal'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  StreamBuilder<QuerySnapshot<Object?>> athkarListStreamBuilder() {
    return StreamBuilder<QuerySnapshot>(
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
                    return Column(
                      children: [
                        Container(
                          width: 1300,
                          margin: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            color: Theme.of(context).dialogBackgroundColor,
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
                                currentCount =
                                    getCounterOnlineResult(object.id);
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            CounterAthkarScreen(
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
                                      : 100,
                                  child: Text(
                                    object['content'],
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                ),
                                SizedBox(
                                  width: MediaQuery.sizeOf(context).width > 600
                                      ? 150
                                      : 60,
                                  child: Text(
                                    '${users.contains(userName) ? 0 : currentCount >= 0 ? currentCount : object["count"]}/${object['count']}',
                                    style: const TextStyle(
                                      fontFamily: 'Tajawal',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              tooltip: 'حذف ذكر',
                              onPressed: () {
                                _showDeleteConfirmationDialog(
                                    context, object.id);
                              },
                            ),
                            leading: IconButton(
                              color: Colors.green,
                              tooltip: "الذاكرين",
                              onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (context) => ThekerReadersScreen(
                                          users: users,
                                          content: object['content'],
                                          userName: userName))),
                              icon: Icon(
                                Icons.supervised_user_circle_sharp,
                                size: 30,
                              ),
                            ),
                            // Add more fields if needed
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            );
          }).toList(),
        );
      },
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
