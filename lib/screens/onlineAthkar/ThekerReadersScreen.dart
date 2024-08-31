import 'package:flutter/material.dart';

class ThekerReadersScreen extends StatefulWidget {
  List users;
  String content;
  String userName;

  ThekerReadersScreen(
      {super.key,
      required this.users,
      required this.content,
      required this.userName});

  @override
  State<ThekerReadersScreen> createState() => _ThekerReadersScreenState();
}

class _ThekerReadersScreenState extends State<ThekerReadersScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text(
            'الذاكرين',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 24.0,
            ),
          ),
        ),
        body: widget.users.isEmpty
            ? noUsersEmptyWidget(context)
            : ListView.builder(
                itemCount: widget.users.length,
                physics: BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  return Column(
                    children: [
                      if (index == 0)
                        Container(
                          width: 1300,
                          margin: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 10),
                          padding: const EdgeInsets.all(30),
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
                          child: Center(
                            child: Text(
                              "${widget.content}",
                              style: const TextStyle(
                                  fontSize: 22, fontFamily: 'Tajawal'),
                            ),
                          ),
                        ),
                      Container(
                        width: 1300,
                        margin: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          color: Theme.of(context).dialogBackgroundColor,
                          border: Border.all(
                              color: widget.users[index] == widget.userName
                                  ? Colors.green
                                  : Colors.white,
                              width: 2),
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
                          trailing: const Icon(
                            size: 30,
                            Icons.star,
                            color: Colors.yellow,
                          ),
                          leading: Text(
                            "${index + 1}",
                            style: const TextStyle(
                                fontSize: 18, fontFamily: 'Tajawal'),
                          ),
                          title: Text(
                            widget.users[index],
                            style: const TextStyle(
                                fontSize: 18, fontFamily: 'Tajawal'),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ));
  }

  Center noUsersEmptyWidget(BuildContext context) {
    return Center(
      child: Container(
        height: 250,
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: Theme.of(context).dialogBackgroundColor,
        ),
        child: Column(
          children: [
            Image.asset(
              "assets/images/no_users.png",
              width: 150,
            ),
            const SizedBox(
              height: 10,
            ),
            const Text(
              "لا يوجد من فعل هذا الذكر\n كن أول السابقين وافعل الذكر",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Tajawal'),
            ),
          ],
        ),
      ),
    );
  }
}
