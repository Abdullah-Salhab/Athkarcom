import 'package:athkar/screens/onlineAthkar/Add_Group.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'GroupsAthkarsScreen.dart';

class GroupsListScreen extends StatefulWidget {
  const GroupsListScreen({super.key});

  @override
  State<GroupsListScreen> createState() => _GroupsListScreenState();
}

class _GroupsListScreenState extends State<GroupsListScreen> {
  String searchQuery = "";
  String userName = "";

  @override
  void initState() {
    getUserName();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // backgroundColor: Colors.blueAccent,
        title: const Text(
          'الأذكار الجماعية',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 24.0,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                PageTransition(
                  type: PageTransitionType.leftToRightWithFade,
                  duration: const Duration(milliseconds: 500),
                  child: const AddGroupScreen(),
                ),
              );
            },
            tooltip: 'إضافة مجموعة',
            icon: const Icon(Icons.add_circle, size: 30, color: Colors.white),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: Colors.green),
                hintText: "ابحث عن مجموعة...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('Groups').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset("assets/images/no_users.png", width: 120),
                        const SizedBox(height: 10),
                        const Text(
                          "لا يوجد أي مجموعة",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Tajawal',
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Filter groups based on search query
                List<QueryDocumentSnapshot> documents =
                    snapshot.data!.docs.where((doc) {
                  String groupName =
                      doc.get("name").toString().toLowerCase().trim();
                  return groupName.contains(searchQuery.trim());
                }).toList();

                // Sort groups: user members first, then others
                documents.sort((a, b) {
                  bool isMemberA =
                      (a.get("members") as Map).containsKey(userName);
                  bool isMemberB =
                      (b.get("members") as Map).containsKey(userName);

                  if (isMemberA && !isMemberB) {
                    return -1; // `a` comes first
                  } else if (!isMemberA && isMemberB) {
                    return 1; // `b` comes first
                  } else {
                    return a
                        .get("name")
                        .compareTo(b.get("name")); // Alphabetical sorting
                  }
                });
                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: documents.length,
                  padding: const EdgeInsets.all(15),
                  itemBuilder: (BuildContext context, int index) {
                    var group = documents[index];
                    bool isGroupAdmin = group.get("createdBy") == userName;
                    Map members = group.get("members");
                    Map requesters = group.get("requests");
                    bool userIsMember = members.containsKey(userName);
                    bool userIsRequester = requesters.containsKey(userName);
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        gradient: LinearGradient(
                          colors: isGroupAdmin
                              ? [Colors.deepPurple, Colors.blueAccent]
                              : [Colors.teal, Colors.cyan],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ListTile(
                          onTap: () {
                            userIsMember
                                ? Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => GroupsAthkarsScreen(
                                        groupName: group.get("name"),
                                        groupId: group.id,
                                        groupDesc: group.get("desc"),
                                      ),
                                    ),
                                  )
                                : ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: Colors.blueGrey,
                                      content: Text(userIsRequester
                                          ? 'تم طلب الانضمام للمجموعة, ادمن المجموعة ينظر في طلبك'
                                          : 'يجب الانضمام للمجموعة'),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                          },
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                          leading: const CircleAvatar(
                            backgroundColor: Colors.white,
                            child: Icon(Icons.group, color: Colors.teal),
                          ),
                          title: Text(
                            isGroupAdmin
                                ? "👑 ${group.get("name")}"
                                : group.get("name"),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'Tajawal',
                            ),
                          ),
                          subtitle: Text(
                            "${group.get("members").length} أعضاء",
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                              fontFamily: 'Tajawal',
                            ),
                          ),
                          trailing: userIsRequester
                              ? const Text(
                                  'تم ارسال طلبك',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontFamily: 'Tajawal',
                                  ),
                                )
                              : ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.teal,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: () => userIsMember
                                      ? Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                GroupsAthkarsScreen(
                                              groupName: group.get("name"),
                                              groupId: group.id,
                                              groupDesc: group.get("desc"),
                                            ),
                                          ),
                                        )
                                      : requestJoinGroup(
                                          group.id, group.get("name")),
                                  child: Text(
                                    userIsMember ? "فتح" : "طلب الانضمام",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontFamily: 'Tajawal',
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> requestJoinGroup(String groupId, String groupName) async {
    final CollectionReference objects =
        FirebaseFirestore.instance.collection('Groups');
    final docRef = objects.doc(groupId);
    final docSnapshot = await docRef.get();

    if (docSnapshot.exists) {
      final data = docSnapshot.data() as Map<String, dynamic>;

      if (!data['requests'].containsKey(userName) &&
          !data['members'].containsKey(userName)) {
        await docRef.update({
          'requests.$userName': DateTime.now().toIso8601String(),
        });
      }
    } else {
      print('Document does not exist');
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Colors.green,
        content: Text('تم إرسال طلب الانضمام لمسؤول المجموعة'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  getUserName() async {
    // Check Shared Preferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      if (prefs.containsKey("userName")) {
        userName = prefs.getString('userName')!.trim();
      }
    });
  }
}
