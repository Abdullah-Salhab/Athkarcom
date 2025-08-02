import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share/share.dart';

import '../models/AnalyticsMixin.dart';

class AboutApp extends StatefulWidget {
  const AboutApp({Key? key}) : super(key: key);

  @override
  State<AboutApp> createState() => _AboutAppState();
}

class _AboutAppState extends State<AboutApp> with AnalyticsMixin {
  @override
  String get screenName => 'AboutAppScreen';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "حول التطبيق",
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 24.0,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: SizedBox(
              width: 1200,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  SizedBox(
                    width: 150,
                    height: 150,
                    child: Image.asset('assets/images/App_Icon.jpg'),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'تطبيق أذكاركم',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'version 3.0.0',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      "\"تطبيق أذكاركم\" تطبيق يوفر العديد من الخدمات الجديدة والحماسية للتشجيع على الذكر "
                      "\nالخدمات التي يوفرها التطبيق:"
                      "\n✅ الذكر الجماعي:هي خاصية الأول من نوعها التي تسمح بالانضمام لمجموعات ذكر جماعي والمنافسة بين الجميع🏅."
                      "\n✅ التقرير اليومي والاسبوعي الشهري: متابعة الاذكار التي تم انجازها خلال الفترة الزمنية الماضية بالإضافة لعرض عدد ايام الحماس التي تعرض كم يوم استمريت بشكل يومي + امكانية عرضها على الشاشة الرئيسية للهاتف."
                      "\n✅ اذكاري (ذكر خاص بك): بإمكان المستخدم اضافة الذكر الذي يفصله وبالعدد الذي يفضله."
                      "\n✅ أذكار الصباح والمساء: قسم خاص بأذكار الصباح والمساء وعرضه بطريقة فعالة ومرتبة بالإضافة إمكانية السماع للإذكار بالسرعة التي تفضلها مع تذكيرات يومية."
                      "\n✅ أذكار النوم وأذكار بعد السلام من الصلاة : قسم خاص بأذكار النوم وأذكار بعد السلام من الصلاة وعرضه بطريقة فعالة ومرتبة بالإضافة إمكانية السماع للإذكار بالسرعة التي تفضلها."
                      "\n✅ إنشاء عدة حسابات: تسجيل حساب شخصي وحفظ الأنشطة مع امكانية اضافات حسابات اخرى للأولاد على نفس الجهاز."
                      "\n✅ أذكار أخرى: قراءة الأذكار الأخرى كدعاء السفر وغيرها من الأذكار."
                      "\n✅ إعدادات: تخصيص الوضع المظلم وتغيير حجم الخط.",
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Divider(thickness: 2),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      "تم إنشاء التطبيق لوجه الله تعالى ونسأل الله القبول, نتمنى منكم دعوة في ظهر الغيب لنا ولكل من ساهم في عمل هذا التطبيق,"
                      " وندعوكم لنشر الخير بين الناس عن طريق مشاركة التطبيق مع الأهل والاصدقاء او على منصات التواصل الاجتماعي من خلال رابط رمز المشاركة الموجود في الاسفل:",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(kIsWeb ? "نسخ الرابط:" : "مشاركة الرابط:"),
                      const SizedBox(width: 10),
                      IconButton(
                        icon: const Icon(kIsWeb ? Icons.copy : Icons.share),
                        onPressed: () {
                          if (!kIsWeb) {
                            Share.share("تطبيق أذكاركم\n"
                                " التطبيق الذي يساعدك على الذكر والمنافسة مع الجميع🏅✨\n"
                                " قم بتحميل التطبيق من جوجل بلاي الان من خلال الرابط التالي:📱\n"
                                "https://play.google.com/store/apps/details?id=com.athkar.athkarcom "
                                "\n أو يمكن استخدامه عن طريق المتصفح على الرابط التالي:🌐\n"
                                "https://athkar-com.web.app/ "
                                "\n\n اكسب الاجر والثواب ماذا تنتظر✨");
                          } else {
                            // Copy the content to the clipboard
                            Clipboard.setData(const ClipboardData(
                                text: " تطبيق أذكاركم "
                                    " التطبيق الذي يساعدك على الذكر والمنافسة مع الجميع "
                                    " قم بتحميل التطبيق من جوجل بلاي الان من خلال الرابط التالي: "
                                    " https://play.google.com/store/apps/details?id=com.athkar.athkarcom "
                                    " أو يمكن استخدامه عن طريق المتصفح على الرابط التالي: "
                                    " https://athkar-com.web.app/ "
                                    " اكسب الاجر والثواب ماذا تنتظر "));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  backgroundColor: Colors.blue,
                                  duration: Duration(seconds: 2),
                                  content: Text('تم النسخ الى الحافظة')),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  Center(
                    child: Text(
                      '  جميع الحقوق محفوظة ${DateTime.now().year} \u00a9 ',
                      style: const TextStyle(
                        fontWeight: FontWeight.w200,
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
