import 'package:athkar/screens/onlineAthkar/Add_Athkar.dart';
import 'package:athkar/screens/onlineAthkar/Counter_Athkar.dart';
import 'package:athkar/screens/onlineAthkar/ThekerReadersScreen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:page_transition/page_transition.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/AnalyticsMixin.dart';
import '../ExceptionDialog.dart';
import '../check_connection.dart';

class GroupsAthkarsScreen extends StatefulWidget {
  final String groupId;
  String groupName;
  String groupDesc;

  GroupsAthkarsScreen(
      {super.key,
      required this.groupId,
      required this.groupName,
      required this.groupDesc});

  @override
  State<GroupsAthkarsScreen> createState() => _GroupsAthkarsScreenState();
}

class _GroupsAthkarsScreenState extends State<GroupsAthkarsScreen>
    with SingleTickerProviderStateMixin, AnalyticsMixin {
  @override
  String get screenName => 'GroupScreen';

  String userName = "";
  int currentCount = 1;
  bool isAdmin = false;
  String adminName = "";
  late SharedPreferences prefs;
  late TabController _tabController;
  bool isLoading = true;

  Future getUserName() async {
    // Check Shared Preferences
    prefs = await SharedPreferences.getInstance();
    setState(() {
      if (prefs.containsKey("userName")) {
        userName = prefs.getString('userName')!.trim();
      }
    });
    await checkIfNameExistsInAdminList();
  }

  Future checkIfNameExistsInAdminList() async {
    try {
      // Reference the 'admins' collection
      final DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
          .collection('Groups')
          .doc(widget.groupId)
          .get();

      String name = await documentSnapshot.get('createdBy');

      setState(() {
        isAdmin = name == userName;
        adminName = name;
      });
    } catch (e) {
      showExceptionPopup(context, e.toString());
    }
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
    super.initState();
    getConnection(context);
    getUserName().catchError((e) {
      showExceptionPopup(context, e.toString());
    }).whenComplete(() {
      if (isAdmin) {
        _tabController = TabController(length: 3, vsync: this);
      } else {
        _tabController = TabController(length: 2, vsync: this);
      }
      setState(() {
        isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: isLoading
            ? AppBar(
                title: const Center(child: CircularProgressIndicator()),
              )
            : AppBar(
                title: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Text(
                        widget.groupName,
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 24.0,
                        ),
                      ),
                      Text(
                        widget.groupDesc,
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 16.0,
                        ),
                      ),
                    ],
                  ),
                ),
                bottom: TabBar(
                  indicatorColor: Colors.white,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.black54,
                  labelStyle: const TextStyle(fontSize: 16.0),
                  unselectedLabelStyle: const TextStyle(fontSize: 12.0),
                  controller: _tabController,
                  tabs: [
                    const Tab(text: 'الأذكار', icon: Icon(Icons.list_alt)),
                    const Tab(text: 'الأوائل', icon: Icon(Icons.star)),
                    if (isAdmin)
                      const Tab(
                          text: 'إدارة المجموعة',
                          icon: Icon(Icons.admin_panel_settings)),
                  ],
                ),
                actions: [
                  if (isAdmin)
                    IconButton(
                        onPressed: () {
                          Navigator.push(
                              context,
                              PageTransition(
                                type: PageTransitionType.leftToRightWithFade,
                                reverseDuration:
                                    const Duration(milliseconds: 500),
                                duration: const Duration(milliseconds: 500),
                                child: AddAthkarScreen(groupId: widget.groupId),
                              ));
                        },
                        tooltip: 'إضافة ذكر',
                        icon: const Icon(Icons.add_box)),
                  if (isAdmin)
                    IconButton(
                        onPressed: () {
                          _showEditGroupDialog(context, widget.groupId,
                              widget.groupName, widget.groupDesc);
                        },
                        tooltip: 'إعدادات',
                        icon: const Icon(Icons.settings))
                ],
              ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  athkarListStreamBuilder(),
                  topUsersStreamBuilder(),
                  if (isAdmin) groupAdminSection(),
                ],
              ));
  }

  StreamBuilder<QuerySnapshot<Object?>> topUsersStreamBuilder() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Users')
          .where('groupId', isEqualTo: widget.groupId.toString())
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
              child: Text("لا يوجد أي شخص")); // Handle empty data
        }

        final documents = snapshot.data!.docs;

        // Sort the documents after fetching them
        documents.sort((a, b) {
          // Compare 'points' in descending order
          int pointsComparison = b.get("points").compareTo(a.get("points"));
          if (pointsComparison != 0) {
            return pointsComparison;
          }
          // If points are equal, sort by 'last_update' ascending
          return a.get("last_update").compareTo(b.get("last_update"));
        });

        int firstUser0Index = 0;

        for (int x = 0; x < documents.length; x++) {
          if (documents[x].get("points") == 0) {
            firstUser0Index = x;
            break;
          }
        }

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          itemCount: documents.length,
          itemBuilder: (context, currentIndex) {
            return Column(
              children: [
                if (currentIndex == 3)
                  const SizedBox(
                    width: 1300,
                    child: Divider(
                      thickness: 2,
                    ),
                  ),
                Container(
                  width: 1300,
                  margin:
                      const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                  padding:
                      const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: Theme.of(context).dialogBackgroundColor,
                    border: Border.all(
                        color: documents[currentIndex].get("name") == userName
                            ? Colors.teal
                            : Colors.white,
                        width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset:
                            const Offset(3, 3), // changes position of shadow
                      ),
                    ],
                  ),
                  child: ListTile(
                    trailing: currentIndex < 3
                        ? Image.asset(
                            "assets/images/medal_${currentIndex + 1}.png",
                            width: 30,
                          )
                        : currentIndex < firstUser0Index
                            ? const Icon(
                                size: 30,
                                Icons.stars_sharp,
                                color: Colors.yellow,
                              )
                            : const SizedBox(),
                    leading: CircleAvatar(
                      backgroundColor:
                          documents[currentIndex].get("name") == adminName
                              ? Colors.teal
                              : Colors.blueAccent,
                      child: Text("${currentIndex + 1}",
                          style: const TextStyle(color: Colors.white)),
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          documents[currentIndex].get("name") == adminName
                              ? documents[currentIndex].get("name") + " 👑 "
                              : documents[currentIndex].get("name"),
                          style: const TextStyle(
                              fontSize: 18, fontFamily: 'Tajawal'),
                        ),
                        Text(
                          "${documents[currentIndex].get("points")} نقطة",
                          style: const TextStyle(
                              fontSize: 18, fontFamily: 'Tajawal'),
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
          .collection('Groups')
          .doc(widget.groupId)
          .collection("Athkars")
          .orderBy('date', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "لا يوجد أذكار",
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 24.0,
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                if (isAdmin)
                  ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(
                          Theme.of(context).dialogBackgroundColor,
                        ),
                        shadowColor: MaterialStateProperty.all(
                            Colors.grey.withOpacity(0.5)),
                      ),
                      onPressed: () {
                        Navigator.push(
                            context,
                            PageTransition(
                              type: PageTransitionType.leftToRightWithFade,
                              reverseDuration:
                                  const Duration(milliseconds: 500),
                              duration: const Duration(milliseconds: 500),
                              child: AddAthkarScreen(groupId: widget.groupId),
                            ));
                      },
                      child: Text(
                        "إضافة ذكر",
                        style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 22.0,
                            color: Theme.of(context).hintColor),
                      ))
              ],
            ),
          ); // Handle empty data
        }

        final documents = snapshot.data!.docs;

        Map<DateTime, List<DocumentSnapshot>> groupedObjects = {};
        for (var doc in documents) {
          final date = (doc['date'] as Timestamp).toDate();
          final dateKey = DateTime(date.year, date.month, date.day);

          if (!groupedObjects.containsKey(dateKey)) {
            groupedObjects[dateKey] = [];
          }
          groupedObjects[dateKey]!.add(doc);
        }

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
                    currentCount = getCounterOnlineResult(object.id + userName.toString());
                    return Column(
                      children: [
                        Container(
                          width: 1300,
                          margin: const EdgeInsets.symmetric(
                              vertical: 5, horizontal: 10),
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            color: Theme.of(context).dialogBackgroundColor,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.5),
                                spreadRadius: 2,
                                blurRadius: 5,
                                offset: const Offset(
                                    3, 3), // changes position of shadow
                              ),
                            ],
                          ),
                          child: ListTile(
                            onTap: () {
                              if (!users.contains(userName)) {
                                currentCount =
                                    getCounterOnlineResult(object.id + userName.toString());
                                Navigator.push(
                                    context,
                                    PageTransition(
                                      type: PageTransitionType.size,
                                      alignment: Alignment.bottomCenter,
                                      curve: Curves.bounceOut,
                                      duration:
                                          const Duration(milliseconds: 500),
                                      reverseDuration:
                                          const Duration(milliseconds: 500),
                                      child: CounterAthkarScreen(
                                        count: object["count"],
                                        content: object['content'],
                                        id: object.id,
                                        value: object['value'],
                                        index: -1,
                                        currentCount: currentCount >= 0
                                            ? currentCount
                                            : object["count"],
                                        userName: userName,
                                        groupId: widget.groupId,
                                      ),
                                    )).then((value) {
                                  setState(() {
                                    currentCount =
                                        getCounterOnlineResult(object.id + userName.toString());
                                  });
                                  return true;
                                });
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    backgroundColor: Colors.teal,
                                    content: Text('تم إنهاءه سابقاً'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              }
                            },
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
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
                                      : 64,
                                  child: Text(
                                    '${users.contains(userName) ? 0 : currentCount >= 0 ? currentCount : object["count"]}/${object['count']}',
                                    style: const TextStyle(
                                      fontFamily: 'Tajawal',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isAdmin)
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    tooltip: 'حذف ذكر',
                                    onPressed: () {
                                      _showDeleteConfirmationDialog(
                                          context, object.id, "");
                                    },
                                  ),
                                if (users.contains(userName))
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.teal,
                                  )
                              ],
                            ),

                            leading: IconButton(
                              tooltip: "الذاكرين",
                              onPressed: () => Navigator.push(
                                  context,
                                  PageTransition(
                                    type:
                                        PageTransitionType.rightToLeftWithFade,
                                    reverseDuration:
                                        const Duration(milliseconds: 500),
                                    duration: const Duration(milliseconds: 500),
                                    child: ThekerReadersScreen(
                                        users: users,
                                        content: object['content'],
                                        userName: userName),
                                  )),
                              icon: const CircleAvatar(
                                backgroundColor: Colors.blueAccent,
                                child: Icon(
                                  Icons.groups_rounded,
                                  color: Colors.white,
                                  size: 25,
                                ),
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

  Widget groupAdminSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            const SizedBox(height: 5),
            const Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text("طلبات الإنضمام",
                    style: TextStyle(
                        fontSize: 18,
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 5),
            Expanded(flex: 1, child: requestsMembersStreamBuilder()),
            const SizedBox(height: 5),
            const Divider(thickness: 2),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Card(
                    elevation: 4,
                    child: Padding(
                      padding:
                      EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Text("إدارة الأعضاء",
                          style: TextStyle(
                              fontSize: 18,
                              fontFamily: 'Tajawal',
                              fontWeight: FontWeight.bold)),
                    )),
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ElevatedButton.icon(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(Colors.orange),
                    ),
                    onPressed: () {
                      _showResetPointsConfirmationDialog(context);
                    },
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    label: const Text(
                      "إعادة تعيين النقاط",
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'Tajawal',
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Expanded(flex: 2, child: membersAdminStreamBuilder()),
          ],
        );
      },
    );
  }

  StreamBuilder<DocumentSnapshot> requestsMembersStreamBuilder() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Groups')
          .doc(widget.groupId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // Get 'requests' map safely
        final Map<String, dynamic> requests =
            (snapshot.data!.get('requests') as Map<String, dynamic>?) ?? {};

        if (requests.isEmpty) {
          return const Center(
              child: Text(
            "لا يوجد أي طلب إنضمام",
            style: TextStyle(fontSize: 16, fontFamily: 'Tajawal'),
          )); // No requests found
        }
        // Convert to a List and Sort by Timestamp (descending)
        final List<MapEntry<String, String>> sortedRequests = requests.entries
            .map((e) => MapEntry(
                e.key, e.value.toString())) // Ensure values are Strings
            .toList()
          ..sort((a, b) =>
              DateTime.parse(b.value).compareTo(DateTime.parse(a.value)));

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          itemCount: sortedRequests.length,
          itemBuilder: (context, index) {
            final name = sortedRequests[index].key;
            final timestamp = sortedRequests[index].value;
            final formattedTime =
                DateTime.parse(timestamp); // Convert to DateTime

            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  margin: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: Theme.of(context).dialogBackgroundColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset:
                            const Offset(3, 3), // changes position of shadow
                      ),
                    ],
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blueAccent,
                      child: Text(name[0],
                          style: const TextStyle(color: Colors.white)),
                    ),
                    title: Text(
                      name,
                      style: const TextStyle(fontSize: 18),
                    ),
                    subtitle: Text(
                      "وقت الطلب: ${formattedTime.toLocal().toString().split(' ').first}",
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check_circle,
                              color: Colors.green, size: 30),
                          onPressed: () {
                            joinGroup(widget.groupId, widget.groupName, name);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.cancel,
                              color: Colors.red, size: 30),
                          onPressed: () async {
                            await rejectRequest(name);
                          },
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

  Future<void> rejectRequest(String name) async {
    await FirebaseFirestore.instance
        .collection('Groups')
        .doc(widget.groupId)
        .update({
      "requests.$name": FieldValue.delete(),
      // Remove the user from the map
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Colors.grey,
        content: Text('تم رفض الطلب'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  StreamBuilder<QuerySnapshot<Object?>> membersAdminStreamBuilder() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Users')
          .where('groupId', isEqualTo: widget.groupId.toString())
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
              child: Text("لا يوجد أي شخص")); // Handle empty data
        }

        List<QueryDocumentSnapshot> documents = snapshot.data!.docs;

        // Sort remaining users based on 'created_in' timestamp
        documents.sort((a, b) {
          Timestamp timeA = a.get("created_in");
          Timestamp timeB = b.get("created_in");
          return timeA.compareTo(timeB); // Ascending order (oldest first)
        });

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          itemCount: documents.length,
          itemBuilder: (context, currentIndex) {
            return Column(
              children: [
                Container(
                  width: 1300,
                  margin:
                      const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                  padding:
                      const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: Theme.of(context).dialogBackgroundColor,
                    border: Border.all(
                        color: documents[currentIndex].get("name") == userName
                            ? Colors.teal
                            : Colors.white,
                        width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset:
                            const Offset(3, 3), // changes position of shadow
                      ),
                    ],
                  ),
                  child: ListTile(
                    trailing: (documents[currentIndex].get("name") != adminName)
                        ? ElevatedButton.icon(
                            style: const ButtonStyle(
                              backgroundColor:
                                  MaterialStatePropertyAll(Colors.blueAccent),
                            ),
                            onPressed: () {
                              _showDeleteConfirmationDialog(
                                  context,
                                  widget.groupId,
                                  documents[currentIndex].get("name"));
                            },
                            icon: const Icon(
                              size: 25,
                              Icons.highlight_remove,
                              color: Colors.white,
                            ),
                            label: const Text("حذف المستخدم",
                                style: TextStyle(
                                    fontSize: 14,
                                    fontFamily: 'Tajawal',
                                    color: Colors.white)))
                        : const SizedBox(
                            child: Text(
                            "مسؤول المجموعة 👑",
                            style:
                                TextStyle(fontSize: 14, fontFamily: 'Tajawal'),
                          )),
                    leading: CircleAvatar(
                      backgroundColor:
                          documents[currentIndex].get("name") != adminName
                              ? Colors.blueAccent
                              : Colors.teal,
                      child: Text("${currentIndex + 1}",
                          style: const TextStyle(color: Colors.white)),
                    ),
                    title: Text(
                      documents[currentIndex].get("name"),
                      style: const TextStyle(
                          fontSize: 18,
                          fontFamily: 'Tajawal',
                          fontWeight: FontWeight.bold),
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

  Future<void> _showDeleteConfirmationDialog(
      BuildContext context, String objectId, String deletedUser) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(deletedUser.isEmpty ? 'حذف ذكر' : 'حذف مستخدم'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(deletedUser.isEmpty
                    ? 'هل انت متأكد من حذف هذا الذكر؟'
                    : 'هل انت متأكد من حذف هذا المستخدم ('
                        '$deletedUser'
                        ') من المجموعة؟'),
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
                if (await getConnection(context)) {
                  if (deletedUser.isEmpty) {
                    // delete a theker
                    await FirebaseFirestore.instance
                        .collection('Groups')
                        .doc(widget.groupId)
                        .collection("Athkars")
                        .doc(objectId)
                        .delete()
                        .catchError((e) {
                      showExceptionPopup(context, e.toString());
                    });
                  } else {
                    // delete a user
                    try {
                      var user = await FirebaseFirestore.instance
                          .collection('Users')
                          .where("name", isEqualTo: deletedUser)
                          .get();

                      if (user.docs.isNotEmpty) {
                        if (user.size > 1) {
                          // If multiple users exist, find those with the matching groupId
                          var filteredDocs = user.docs
                              .where((doc) => doc['groupId'] == widget.groupId);

                          if (filteredDocs.isNotEmpty) {
                            await filteredDocs.first.reference.delete();
                          }
                        } else {
                          // If only one user exists, update their groupId and groupName
                          await user.docs.first.reference.update({
                            'groupId': '',
                            'groupName': '',
                            'last_update': DateTime.now().toIso8601String(),
                            'points': 0,
                          });
                        }
                      }

                      var doc = await FirebaseFirestore.instance
                          .collection('Groups')
                          .doc(widget.groupId)
                          .get();
                      doc.reference.update({
                        "members.$deletedUser": FieldValue.delete(),
                        // Remove the user from the map
                      });
                    } catch (e) {
                      showExceptionPopup(context, e.toString());
                    }
                  }
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> joinGroup(
      String groupId, String groupName, String userName) async {
    try {
      var userQuerySnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .where("name", isEqualTo: userName)
          .get();
      // user was deleted (not exist)
      if (userQuerySnapshot.docs.isNotEmpty) {
        final CollectionReference objects =
            FirebaseFirestore.instance.collection('Groups');
        final docRef = objects.doc(groupId);
        final docSnapshot = await docRef.get();

        if (docSnapshot.exists) {
          final data = docSnapshot.data() as Map<String, dynamic>;

          if (!data['members'].containsKey(userName)) {
            await docRef.update({
              'members.$userName': false,
            });
          }
        } else {
          print('Document does not exist');
        }

        // set group id to the user
        if (userQuerySnapshot.docs.length == 1 &&
            userQuerySnapshot.docs.first.get('groupId') == '') {
          var userDocument = userQuerySnapshot.docs.first;
          await userDocument.reference.update({
            'created_in': DateTime(
              DateTime.now().year,
              DateTime.now().month,
              DateTime.now().day,
              DateTime.now().hour,
              DateTime.now().minute,
            ),
            'last_update': DateTime.now().toIso8601String(),
            'points': 0,
            'groupId': docRef.id,
            'groupName': groupName,
          });
        } else {
          // create new user with the group id
          CollectionReference users =
              FirebaseFirestore.instance.collection('Users');
          await users.add({
            'name': userName,
            'created_in': DateTime(
              DateTime.now().year,
              DateTime.now().month,
              DateTime.now().day,
              DateTime.now().hour,
              DateTime.now().minute,
            ),
            'last_update': DateTime.now().toIso8601String(),
            'points': 0,
            'groupId': docRef.id,
            'groupName': groupName
          });
        }
        // delete it from the requester map
        await FirebaseFirestore.instance
            .collection('Groups')
            .doc(widget.groupId)
            .update({
          "requests.$userName": FieldValue.delete(),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text('تمت الموافقة'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.black,
            content: Text('المستخدم غادر التطبيق'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      showExceptionPopup(context, e.toString());
    }
  }

  Future<void> _showEditGroupDialog(BuildContext context, String groupId,
      String groupName, String groupDesc) async {
    final TextEditingController nameController =
        TextEditingController(text: groupName);
    final TextEditingController descController =
        TextEditingController(text: groupDesc);
    final formKey = GlobalKey<FormState>();
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          surfaceTintColor: Colors.white,
          title: const Text(
            'تعديل معلومات المجموعة',
            style: TextStyle(fontFamily: 'Tajawal', fontSize: 20),
          ),
          content: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          labelText: "* اسم المجموعة"),
                      validator: (value) {
                        if (value!.trim().isEmpty) {
                          return 'يرجى إدخال الاسم';
                        }
                        return null;
                      },
                      maxLength: 15,
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    TextFormField(
                      controller: descController,
                      decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          labelText: "* الوصف"),
                      validator: (value) {
                        if (value!.trim().isEmpty) {
                          return 'يرجى إدخال وصف للمجموعة';
                        }
                        return null;
                      },
                      maxLength: 25,
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                        style: const ButtonStyle(
                          backgroundColor:
                              MaterialStatePropertyAll(Colors.blue),
                        ),
                        onPressed: () {
                          _showDeleteGroupConfirmationDialog(context);
                        },
                        icon: const Icon(
                          size: 25,
                          Icons.delete,
                          color: Colors.white,
                        ),
                        label: const Text("حذف المجموعة",
                            style: TextStyle(
                                fontSize: 14,
                                fontFamily: 'Tajawal',
                                color: Colors.white))),
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
                'تعديل',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                ),
              ),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  formKey.currentState!.save();

                  bool nameExist = await _checkIfGroupExist(nameController.text)
                      .catchError((e) {
                    showExceptionPopup(context, e.toString());
                  });
                  if (widget.groupName == nameController.text.trim() &&
                      widget.groupDesc == descController.text.trim()) {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('لم تقم بأي تغيير'),
                          content: const Text('لم تقم بأي تغيير على المعلومات'),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: const Text('حسنا'),
                            ),
                          ],
                        );
                      },
                    );
                  } else if (nameExist &&
                      widget.groupName != nameController.text.trim()) {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('المجموعة موجودة'),
                          content: const Text(
                              'يوجد مجموعة بهذا الاسم يرجى تعديل الاسم'),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: const Text('حسنا'),
                            ),
                          ],
                        );
                      },
                    );
                  } else {
                    try {
                      var doc = await FirebaseFirestore.instance
                          .collection('Groups')
                          .doc(groupId)
                          .get();
                      doc.reference.update({
                        "name": nameController.text.trim(),
                        "desc": descController.text.trim(),
                      });
                      setState(() {
                        widget.groupName = nameController.text.trim();
                        widget.groupDesc = descController.text.trim();
                      });
                    } catch (e) {
                      showExceptionPopup(context, e.toString());
                    }
                    Navigator.of(context).pop();
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<bool> _checkIfGroupExist(String name) async {
    // Check Firestore
    CollectionReference groups =
        FirebaseFirestore.instance.collection('Groups');
    var doc = await groups.where("name", isEqualTo: name).get();
    if (doc.size != 0) {
      return true;
    }

    return false;
  }

  Future<void> _showDeleteGroupConfirmationDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('حذف المجموعة ❌',
              style: TextStyle(
                  fontSize: 22,
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.bold)),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('هل انت متأكد من حذف المجموعة؟\nلا يمكن التراجع 🛑❗❗❗❗❗🛑',
                    style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.bold))
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
                if (await getConnection(context)) {
                  try {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                    var groupMembers = await FirebaseFirestore.instance
                        .collection('Users')
                        .where("groupId", isEqualTo: widget.groupId)
                        .get();

                    if (groupMembers.docs.isNotEmpty) {
                      for (var element in groupMembers.docs) {
                        String userName = element.get('name');
                        var user = await FirebaseFirestore.instance
                            .collection('Users')
                            .where("name", isEqualTo: userName)
                            .get();
                        if (user.size > 1) {
                          // If multiple users exist, find those with the matching groupId
                          var filteredDocs = user.docs
                              .where((doc) => doc['groupId'] == widget.groupId);

                          if (filteredDocs.isNotEmpty) {
                            await filteredDocs.first.reference.delete();
                          }
                        } else {
                          // If only one user exists, update their groupId and groupName
                          await user.docs.first.reference.update({
                            'groupId': '',
                            'groupName': '',
                            'last_update': DateTime.now().toIso8601String(),
                            'points': 0,
                          });
                        }
                      }

                      var doc = await FirebaseFirestore.instance
                          .collection('Groups')
                          .doc(widget.groupId)
                          .get();
                      doc.reference.delete();
                    }
                  } catch (e) {
                    showExceptionPopup(context, e.toString());
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showResetPointsConfirmationDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'إعادة تعيين النقاط',
            style: TextStyle(
              fontSize: 22,
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  'هل أنت متأكد من إعادة تعيين نقاط جميع الأعضاء إلى 0؟',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Tajawal',
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'إلغاء',
                style: TextStyle(fontFamily: 'Tajawal'),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text(
                'نعم، إعادة تعيين',
                style: TextStyle(fontFamily: 'Tajawal', color: Colors.orange),
              ),
              onPressed: () async {
                if (await getConnection(context)) {
                  try {
                    // Get all users in this group
                    var groupMembers = await FirebaseFirestore.instance
                        .collection('Users')
                        .where("groupId", isEqualTo: widget.groupId)
                        .get();

                    if (groupMembers.docs.isNotEmpty) {
                      // Reset points for each member
                      for (var userDoc in groupMembers.docs) {
                        await userDoc.reference.update({
                          'points': 0,
                          'last_update': DateTime.now().toIso8601String(),
                        });
                      }

                      Navigator.of(context).pop();

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: Colors.green,
                          content: Text(
                            'تم إعادة تعيين النقاط لجميع الأعضاء',
                            style: TextStyle(fontFamily: 'Tajawal'),
                          ),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  } catch (e) {
                    Navigator.of(context).pop();
                    showExceptionPopup(context, e.toString());
                  }
                } else {
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
