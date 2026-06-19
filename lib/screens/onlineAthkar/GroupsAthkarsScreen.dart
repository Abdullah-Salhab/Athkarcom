import 'package:athkar/screens/onlineAthkar/Add_Athkar.dart';
import 'package:athkar/screens/onlineAthkar/Counter_Athkar.dart';
import 'package:athkar/screens/onlineAthkar/ThekerReadersScreen.dart';
import 'package:athkar/screens/onlineAthkar/GroupChatSection.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:page_transition/page_transition.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

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
        _tabController = TabController(length: 4, vsync: this);
      } else {
        _tabController = TabController(length: 3, vsync: this);
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
                    const Tab(text: 'الدردشة', icon: Icon(Icons.chat)),
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
                  GroupChatSection(groupId: widget.groupId, userName: userName),
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
            final bool isDark = Theme.of(context).brightness == Brightness.dark;
            final String name = documents[currentIndex].get("name") as String? ?? '';
            final int points = documents[currentIndex].get("points") as int? ?? 0;
            final bool isMe = name == userName;
            final bool isUserAdmin = name == adminName;

            final Map<String, dynamic>? userData = documents[currentIndex].data() as Map<String, dynamic>?;
            final int streak = userData != null && userData.containsKey('streak')
                ? (userData['streak'] as int? ?? 0)
                : 0;

            // Define modern card background and border colors
            Color cardColor;
            Border border;
            if (isMe) {
              cardColor = isDark ? const Color(0xFF202A35) : Colors.teal.shade50.withOpacity(0.4);
              border = Border.all(color: Colors.teal.shade400, width: 2.0);
            } else {
              cardColor = isDark ? const Color(0xFF1E2832) : Colors.white;
              border = Border.all(
                color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade200,
                width: 1.0,
              );
            }

            // Define metallic rank colors/gradients for top 3
            Gradient? rankGradient;
            Color? rankBgColor;
            if (currentIndex == 0) {
              rankGradient = const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA000)]); // Gold
            } else if (currentIndex == 1) {
              rankGradient = const LinearGradient(colors: [Color(0xFFE0E0E0), Color(0xFF9E9E9E)]); // Silver
            } else if (currentIndex == 2) {
              rankGradient = const LinearGradient(colors: [Color(0xFFD7CCC8), Color(0xFF8D6E63)]); // Bronze
            } else {
              rankBgColor = isUserAdmin
                  ? Colors.teal
                  : (isDark ? const Color(0xFF303A46) : Colors.blueAccent);
            }

            return Column(
              children: [
                if (currentIndex == 3)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: Divider(
                      thickness: 1.5,
                      color: isDark ? Colors.white10 : Colors.grey.shade300,
                      indent: 16,
                      endIndent: 16,
                    ),
                  ),
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: cardColor,
                    border: border,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.40 : 0.08),
                        blurRadius: 12,
                        spreadRadius: 1,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    trailing: currentIndex < 3
                        ? Image.asset(
                            "assets/images/medal_${currentIndex + 1}.png",
                            width: 34,
                          )
                        : currentIndex < firstUser0Index
                            ? const Icon(
                                size: 30,
                                Icons.stars_sharp,
                                color: Colors.amber,
                              )
                            : const SizedBox(),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: rankGradient,
                        color: rankBgColor,
                      ),
                      child: Center(
                        child: Text(
                          "${currentIndex + 1}",
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  isUserAdmin ? "$name 👑" : name,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontFamily: 'Tajawal',
                                    fontWeight: isMe ? FontWeight.bold : FontWeight.w500,
                                    color: isMe
                                        ? (isDark ? Colors.teal.shade200 : Colors.teal.shade800)
                                        : (isDark ? Colors.white70 : Colors.black87),
                                  ),
                                ),
                              ),
                              if (streak > 0) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        "🔥",
                                        style: TextStyle(fontSize: 13),
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        "$streak",
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange,
                                          fontFamily: 'Tajawal',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "$points نقطة",
                              style: TextStyle(
                                fontSize: 16,
                                fontFamily: 'Tajawal',
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.amber.shade200 : Colors.amber.shade800,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.emoji_events_rounded,
                              size: 18,
                              color: currentIndex == 0
                                  ? const Color(0xFFFFD700)
                                  : (isDark ? Colors.amber.shade200 : Colors.amber.shade700),
                            ),
                          ],
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

        final bool isDark = Theme.of(context).brightness == Brightness.dark;

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
          );
        }

        final documents = snapshot.data!.docs;

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          itemCount: documents.length,
          itemBuilder: (context, currentIndex) {
            final doc = documents[currentIndex];
            final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            final String id = doc.id;
            final String content = data['content'] ?? '';
            final String value = data['value'] ?? '';
            final int count = data['count'] ?? 1;
            final Timestamp timestamp = data['date'] ?? Timestamp.now();
            final DateTime date = timestamp.toDate();
            final List<dynamic> users = data['users'] ?? [];

            final bool isSharedTarget = data['isSharedTarget'] ?? false;
            final int sharedTargetCount = data['sharedTargetCount'] ?? 0;
            final int sharedCompletedCount = data['sharedCompletedCount'] ?? 0;

            final int currentCount = getCounterOnlineResult(id + userName.toString());
            final bool hasCompleted = users.contains(userName);

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2832) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: hasCompleted
                      ? Colors.teal.withOpacity(0.4)
                      : (isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade200),
                  width: hasCompleted ? 1.5 : 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.45 : 0.08),
                    blurRadius: 14,
                    spreadRadius: 1.5,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      if (isSharedTarget) {
                        if (sharedCompletedCount < sharedTargetCount) {
                          Navigator.push(
                              context,
                              PageTransition(
                                type: PageTransitionType.size,
                                alignment: Alignment.bottomCenter,
                                duration: const Duration(milliseconds: 500),
                                reverseDuration: const Duration(milliseconds: 500),
                                child: CounterAthkarScreen(
                                  count: count,
                                  content: content,
                                  id: id,
                                  value: value,
                                  index: -1,
                                  currentCount: currentCount >= 0
                                      ? currentCount
                                      : count,
                                  userName: userName,
                                  groupId: widget.groupId,
                                  isSharedTarget: true,
                                  sharedTargetCount: sharedTargetCount,
                                  sharedCompletedCount: sharedCompletedCount,
                                ),
                              )).then((value) {
                            setState(() {});
                            return true;
                          });
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: Colors.teal,
                              content: Text(
                                'تم إكمال الهدف الجماعي بالفعل! 🎉',
                                style: TextStyle(fontFamily: 'Tajawal'),
                              ),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      } else {
                        if (!hasCompleted) {
                          Navigator.push(
                              context,
                              PageTransition(
                                type: PageTransitionType.size,
                                alignment: Alignment.bottomCenter,
                                duration: const Duration(milliseconds: 500),
                                reverseDuration: const Duration(milliseconds: 500),
                                child: CounterAthkarScreen(
                                  count: count,
                                  content: content,
                                  id: id,
                                  value: value,
                                  index: -1,
                                  currentCount: currentCount >= 0
                                      ? currentCount
                                      : count,
                                  userName: userName,
                                  groupId: widget.groupId,
                                  isSharedTarget: false,
                                ),
                              )).then((value) {
                            setState(() {});
                            return true;
                          });
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: Colors.teal,
                              content: Text(
                                'تم إنهاؤه سابقاً',
                                style: TextStyle(fontFamily: 'Tajawal'),
                              ),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        }
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.calendar_month_rounded, size: 14, color: Colors.teal.shade400),
                                    const SizedBox(width: 4),
                                    Text(
                                      "${date.day}/${date.month}/${date.year}",
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? Colors.white70 : Colors.black87,
                                        fontFamily: 'Tajawal',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  if (isSharedTarget)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        "هدف جماعي 👥",
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.blue,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Tajawal',
                                        ),
                                      ),
                                    ),
                                  if (isAdmin) ...[
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      tooltip: 'حذف الذكر',
                                      onPressed: () {
                                        _showDeleteConfirmationDialog(context, id, "");
                                      },
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            content,
                            textDirection: TextDirection.rtl,
                            style: TextStyle(
                              fontSize: 17,
                              fontFamily: 'Amiri',
                              height: 1.5,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (value.isNotEmpty) ...[
                            Text(
                              value,
                              textDirection: TextDirection.rtl,
                              style: TextStyle(
                                fontSize: 13,
                                fontFamily: 'Tajawal',
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          const Divider(height: 1, thickness: 0.5),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: _buildAvatarStack(users, content),
                              ),
                              const SizedBox(width: 12),
                              _buildCardProgress(
                                isSharedTarget,
                                sharedCompletedCount,
                                sharedTargetCount,
                                count,
                                currentCount,
                                hasCompleted,
                                isDark,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAvatarStack(List<dynamic> users, String content) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    if (users.isEmpty) {
      return InkWell(
        onTap: () {
          Navigator.push(
            context,
            PageTransition(
              type: PageTransitionType.rightToLeftWithFade,
              reverseDuration: const Duration(milliseconds: 500),
              duration: const Duration(milliseconds: 500),
              child: ThekerReadersScreen(
                users: users,
                content: content,
                userName: userName,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.emoji_objects_outlined, color: Colors.amber, size: 18),
              const SizedBox(width: 4),
              Text(
                "كن أول الذاكرين! ✨",
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 13,
                  color: isDark ? Colors.teal.shade200 : Colors.teal.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final int displayCount = users.length > 3 ? 3 : users.length;
    final List<dynamic> displayUsers = users.sublist(0, displayCount);

    String namesText = "";
    if (users.length == 1) {
      namesText = "أنهى القراءة: ${users[0]}";
    } else if (users.length == 2) {
      namesText = "أنهى القراءة: ${users[0]} و ${users[1]}";
    } else if (users.length == 3) {
      namesText = "أنهى القراءة: ${users[0]}، ${users[1]} و ${users[2]}";
    } else {
      namesText = "أنهى القراءة: ${users[0]}، ${users[1]} و ${users.length - 2} آخرين";
    }

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          PageTransition(
            type: PageTransitionType.rightToLeftWithFade,
            reverseDuration: const Duration(milliseconds: 500),
            duration: const Duration(milliseconds: 500),
            child: ThekerReadersScreen(
              users: users,
              content: content,
              userName: userName,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: (displayCount * 18.0) + 10,
              height: 28,
              child: Stack(
                children: List.generate(displayCount, (index) {
                  final String userInitial = displayUsers[index].toString().isNotEmpty
                      ? displayUsers[index].toString()[0]
                      : "?";
                  final List<Color> colors = [
                    Colors.teal,
                    Colors.blueAccent,
                    Colors.amber,
                  ];
                  final Color avatarColor = colors[index % colors.length];

                  return Positioned(
                    left: index * 14.0,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: avatarColor,
                        border: Border.all(
                          color: isDark ? const Color(0xFF1E2832) : Colors.white,
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          userInitial,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                namesText,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 12,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardProgress(
    bool isSharedTarget,
    int sharedCompletedCount,
    int sharedTargetCount,
    int count,
    int currentCount,
    bool hasCompleted,
    bool isDark,
  ) {
    if (isSharedTarget) {
      double percent = sharedTargetCount > 0
          ? (sharedCompletedCount / sharedTargetCount).clamp(0.0, 1.0)
          : 0.0;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularPercentIndicator(
            radius: 20.0,
            lineWidth: 3.5,
            percent: percent,
            center: Text(
              "${(percent * 100).toInt()}%",
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                fontFamily: 'Tajawal',
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            progressColor: Colors.blue,
            backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
            circularStrokeCap: CircularStrokeCap.round,
          ),
          const SizedBox(height: 4),
          Text(
            "$sharedCompletedCount/$sharedTargetCount",
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.white70 : Colors.black54,
              fontWeight: FontWeight.bold,
              fontFamily: 'Tajawal',
            ),
          ),
        ],
      );
    } else {
      if (hasCompleted) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.teal,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "تم القراءة",
              style: TextStyle(
                fontSize: 10,
                color: Colors.teal.shade400,
                fontWeight: FontWeight.bold,
                fontFamily: 'Tajawal',
              ),
            ),
          ],
        );
      } else {
        int remaining = currentCount >= 0 ? currentCount : count;
        double percent = count > 0
            ? ((count - remaining) / count).clamp(0.0, 1.0)
            : 0.0;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularPercentIndicator(
              radius: 20.0,
              lineWidth: 3.5,
              percent: percent,
              center: Text(
                "$remaining",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Tajawal',
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              progressColor: Colors.teal,
              backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
              circularStrokeCap: CircularStrokeCap.round,
            ),
            const SizedBox(height: 4),
            Text(
              "المتبقي: $remaining/$count",
              style: TextStyle(
                fontSize: 10,
                color: isDark ? Colors.white70 : Colors.black54,
                fontFamily: 'Tajawal',
              ),
            ),
          ],
        );
      }
    }
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
                            label: const Text("حذف",
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.0),
          ),
          backgroundColor: isDark ? const Color(0xFF1E2832) : Colors.white,
          surfaceTintColor: Colors.transparent,
          title: Row(
            children: [
              Icon(Icons.settings_suggest_rounded, color: Colors.teal.shade400, size: 28),
              const SizedBox(width: 10),
              const Text(
                'تعديل معلومات المجموعة',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(top: 10.0),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: nameController,
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.group_rounded, color: Colors.teal.shade400),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16.0),
                          borderSide: const BorderSide(color: Colors.teal, width: 2.0),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16.0),
                          borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        labelText: "* اسم المجموعة",
                        labelStyle: TextStyle(
                          fontFamily: 'Tajawal',
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
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
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.description_rounded, color: Colors.teal.shade400),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16.0),
                          borderSide: const BorderSide(color: Colors.teal, width: 2.0),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16.0),
                          borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        labelText: "* الوصف",
                        labelStyle: TextStyle(
                          fontFamily: 'Tajawal',
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                      validator: (value) {
                        if (value!.trim().isEmpty) {
                          return 'يرجى إدخال وصف للمجموعة';
                        }
                        return null;
                      },
                      maxLength: 25,
                    ),
                    const SizedBox(height: 15),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        _showDeleteGroupConfirmationDialog(context);
                      },
                      icon: const Icon(Icons.delete_outline_rounded, size: 22),
                      label: const Text(
                        "حذف المجموعة",
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'Tajawal',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: isDark ? Colors.white70 : Colors.black54,
              ),
              child: const Text(
                'الغاء',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.teal,
              ),
              child: const Text(
                'تعديل',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
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
