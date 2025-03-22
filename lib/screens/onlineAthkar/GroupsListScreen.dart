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
            fontWeight: FontWeight.bold,
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

                final documents = snapshot.data!.docs.where((doc) {
                  String groupName = doc.get("name").toString().toLowerCase();
                  return groupName.contains(searchQuery);
                }).toList();

                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: documents.length,
                  padding: const EdgeInsets.all(15),
                  itemBuilder: (BuildContext context, int index) {
                    var group = documents[index];
                    Map members = group.get("members");
                    bool userIsMember = members.containsKey(userName);
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        gradient: const LinearGradient(
                          colors: [Colors.teal, Colors.cyan],
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
                        onTap: (){
                          userIsMember
                              ? Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GroupsAthkarsScreen(
                                groupName: group.get("name"),
                                groupId: group.id,
                              ),
                            ),
                          ):    ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: Colors.blueGrey,
                              content: Text('يجب الانضمام للمجموعة'),
                              duration: Duration(seconds: 2),
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
                            group.get("name"),
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
                          trailing: ElevatedButton(
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
                                      builder: (context) => GroupsAthkarsScreen(
                                        groupName: group.get("name"),
                                        groupId: group.id,
                                      ),
                                    ),
                                  )
                                : joinGroup(group.id,group.get("name")),
                            child: Text(
                              userIsMember ? "فتح" : "انضمام",
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

  Future<void> joinGroup(String groupId, String groupName) async {
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

    var userQuerySnapshot = await FirebaseFirestore.instance
        .collection('Users')
        .where("name", isEqualTo: userName)
        .get();
    // set group id to the user
    if (userQuerySnapshot.docs.isNotEmpty) {
      if (userQuerySnapshot.docs.length == 1 &&
          userQuerySnapshot.docs.first.get('groupId') == '') {
        var userDocument = userQuerySnapshot.docs.first;
        await userDocument.reference.update({'groupId': docRef.id});
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
          'last_login': DateTime(
            DateTime.now().year,
            DateTime.now().month,
            DateTime.now().day,
            DateTime.now().hour,
            DateTime.now().minute,
          ),
          'last_update': DateTime.now().toIso8601String(),
          'points': 0,
          'groupId': docRef.id,
          'groupName':groupName
        });
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Colors.green,
        content: Text('تم الانضمام للمجموعة بنجاح'),
        duration: Duration(seconds: 2),
      ),
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupsAthkarsScreen(
          groupId: groupId,
          groupName: groupName,
        ),
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
