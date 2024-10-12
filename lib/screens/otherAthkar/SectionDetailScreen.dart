import 'package:athkar/models/section_detail_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

import 'package:share/share.dart';

import '../ExceptionDialog.dart';

class SectionDetailScreen extends StatefulWidget {
  final int? id;
  final String? title;

  const SectionDetailScreen({Key? key, required this.id, required this.title})
      : super(key: key);

  @override
  SectionDetailScreenState createState() => SectionDetailScreenState();
}

class SectionDetailScreenState extends State<SectionDetailScreen> {
  List<SectionDetailModel> sectionDetails = [];

  @override
  void initState() {
    super.initState();
    loadSectionDetail();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "${widget.title}",
          style: const TextStyle(
            fontFamily: 'Amiri',
            fontSize: 22.0,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              return Container(
                width: 1300,
                margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Theme.of(context).dialogBackgroundColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(.5),
                        spreadRadius: 2,
                        blurRadius: 3,
                        offset: const Offset(0, 3),
                      )
                    ]),
                child: ListTile(
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        width: kIsWeb?MediaQuery.sizeOf(context).width/1.5
                            : MediaQuery.sizeOf(context).width > 400
                                ? 300
                                : 200,
                        child: Text(
                          "${sectionDetails[index].content}",
                          textDirection: TextDirection.rtl,
                          style: const TextStyle(
                              fontSize: 18,
                              fontFamily: 'Tajawal',
                              fontWeight: FontWeight.w100),
                        ),
                      ),
                      const SizedBox(
                        width: 20,
                      ),
                      if (!kIsWeb)
                        SizedBox(
                          width:
                              MediaQuery.sizeOf(context).width > 600 ? 30 : 21,
                          child: IconButton(
                              onPressed: () {
                                Share.share(
                                    sectionDetails[index].content.toString());
                              },
                              icon: const Icon(Icons.share)),
                        )
                    ],
                  ),
                  leading: Text(
                    "${index + 1}",
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(
                        fontSize: 18,
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.w900),
                  ),
                ),
              );
            },
            itemCount: sectionDetails.length),
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
        SectionDetailModel sectionDetail = SectionDetailModel.fromJson(section);

        if (sectionDetail.sectionId == widget.id) {
          sectionDetails.add(sectionDetail);
        }
      });
      setState(() {});
    }).catchError((error) {
      showExceptionPopup(context, error.toString());
    });
  }
}
