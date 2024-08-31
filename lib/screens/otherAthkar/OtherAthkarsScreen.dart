import 'dart:convert';

import 'package:athkar/screens/OtherAthkar/SectionDetailScreen.dart';
import 'package:flutter/material.dart';

class OtherAthkarScreen extends StatefulWidget {
  const OtherAthkarScreen({super.key});

  @override
  State<OtherAthkarScreen> createState() => _OtherAthkarScreenState();
}

class _OtherAthkarScreenState extends State<OtherAthkarScreen> {
  List<SectionModel> sectionsList = [];

  @override
  void initState() {
    loadSectionDetail();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'أذكار أخرى',
          style: TextStyle(
            fontFamily: 'Amiri',
            fontSize: 22.0,
          ),
        ),
      ),
      body: ListView.builder(
        itemCount: sectionsList.length,
        physics: BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 1300,
                margin: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                padding: const EdgeInsets.symmetric(
                    horizontal: 5, vertical: 5),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color:
                    Theme.of(context).dialogBackgroundColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(.5),
                        spreadRadius: 2,
                        blurRadius: 7,
                        offset: const Offset(0, 3),
                      )
                    ]),
                child: ListTile(
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => SectionDetailScreen(
                        id: sectionsList[index].sectionId,
                        title: sectionsList[index].sectionName,
                      ),
                    ));
                  },
                  trailing: Icon(Icons.arrow_forward_ios,size: 20,),
                  title: Text(sectionsList[index].sectionName.toString(),style: const TextStyle(
                      fontSize: 18,
                      fontFamily: 'Tajawal',
                      fontWeight: FontWeight.w100),),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  loadSectionDetail() async {
    sectionsList = [];
    DefaultAssetBundle.of(context)
        .loadString("assets/database/sections_db.json")
        .then((data) {
      var response = json.decode(data);
      response.forEach((section) {
        SectionModel currentSection = SectionModel.fromJson(section);
        if (currentSection.sectionId != 1 && currentSection.sectionId != 2) {
          sectionsList.add(currentSection);
        }
      });
      setState(() {});
    }).catchError((error) {
      print(error);
    });
  }
}

class SectionModel {
  int? sectionId;
  String? sectionName;

  SectionModel(this.sectionId, this.sectionName);

  SectionModel.fromJson(Map<String, dynamic> json) {
    sectionId = json["id"];
    sectionName = json["name"];
  }
}
