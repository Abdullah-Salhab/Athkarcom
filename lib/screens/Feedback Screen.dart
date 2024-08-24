import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'check_connection.dart';

class FeedbackScreen extends StatefulWidget {
  final userName;

  FeedbackScreen(this.userName);

  @override
  _FeedbackScreenState createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  String dropdownValue = 'مراجعة عامة';
  TextEditingController myController = TextEditingController();
  int charNum = 0;

  var feedbackDoc = FirebaseFirestore.instance.collection("Feedback");

  @override
  Widget build(BuildContext context) {
    // final settingsProvider = context.read<SettingsProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "التغذية الراجعة - إقتراحات",
          // style: GoogleFonts.playfairDisplay(
          //     textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
        ),
        centerTitle: true,
      ),
      body: DefaultTextStyle(
        style: GoogleFonts.acme(textStyle: TextStyle(color: Colors.black)),
        child: SingleChildScrollView(
          child: Center(
            child: Container(
              width: 1000,
              padding: EdgeInsets.symmetric(vertical: 70, horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Row(
                    // mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        minRadius: 25,
                        backgroundColor: Theme.of(context).splashColor,
                        child: Icon(
                          Icons.perm_identity,
                        ),
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${widget.userName} ",
                            style: TextStyle(fontSize: 22, color: Theme.of(context).hintColor),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    // mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "النوع",
                        style: TextStyle(fontSize: 18, color: Theme.of(context).hintColor),
                      ),
                      SizedBox(
                        width: 20,
                      ),
                      DropdownButton<String>(
                        value: dropdownValue,
                        iconSize: 24,
                        elevation: 16,
                        underline: Container(
                          height: 2,
                          color: Colors.blueAccent,
                        ),
                        onChanged: (newValue) {
                          setState(() {
                            dropdownValue = newValue!;
                          });
                        },
                        items: <String>[
                          'مراجعة عامة',
                          'إقتراحات',
                          'مشاكل تقنية أو أخطاء',
                          'أخرى'
                        ].map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 40,
                  ),
                  TextField(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10.0)),
                      ),
                      labelText: 'يرجى تزويدنا بملاحظاتك وإقتراحاتك هنا',
                      hintText: 'أدخل هنا',
                    ),
                    controller: myController,
                    keyboardType: TextInputType.multiline,
                    minLines: 2,
                    maxLines: 7,
                    maxLength: 2040,
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      SizedBox(
                        height: 50,
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          if (myController.text.trim() != "" &&
                              await getConnection(context)) {
                            await feedbackDoc.add({
                              'Type': dropdownValue,
                              'Body': myController.text,
                              'From': widget.userName,
                            });
                            AwesomeDialog(
                              context: context,
                              dialogType: DialogType.success,
                              headerAnimationLoop: false,
                              title: 'النتيجة',
                              desc:
                                  "شكرا جزيلا على اقتراحاتكم وملاحظاتكم, سوف نأخذ ملاحظاتكم بعين الإعتبار",
                              buttonsTextStyle: TextStyle(color: Colors.black),
                              showCloseIcon: true,
                            )..show();
                            myController.text = "";
                            dropdownValue = 'مراجعة عامة';
                            FocusScope.of(context).unfocus();
                            setState(() {});
                          } else {
                            AwesomeDialog(
                              context: context,
                              dialogType: DialogType.error,
                              headerAnimationLoop: false,
                              title: 'النتيجة',
                              desc:
                                  'يرجى وضع ملاحظاتكم في الصندوق الذي في الأعلى',
                              buttonsTextStyle: TextStyle(color: Colors.black),
                              showCloseIcon: true,
                            )..show();
                            myController.text = "";
                            FocusScope.of(context).unfocus();
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 20),
                          child: Text(
                            "إرسال",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 20),
                          ),
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
