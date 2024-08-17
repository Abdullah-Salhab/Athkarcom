import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share/share.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutApp extends StatefulWidget {
  const AboutApp({Key? key}) : super(key: key);

  @override
  State<AboutApp> createState() => _AboutAppState();
}

class _AboutAppState extends State<AboutApp> {
  @override
  Widget build(BuildContext context) {
    // final settingsProvider = context.read<SettingsProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "حول التطبيق",
          // style: GoogleFonts.getFont(settingsProvider.getFontFamily,
          //     fontSize: settingsProvider.getFontSize),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Container(
              width: 1000,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  Container(
                    child: Image.asset('assets/images/App_Icon.jpg'),
                    width: 150,
                    height: 150,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'تطبيق أذكاركم',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'version 1.0.0',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      "\"تطبيق أذكاركم\" تطبيق يوفر العديد من الخدمات الجديدة والحماسية للنشجيع على الذكر "
                          "\nالخدمات التي يوفرها التطبيق:"
                          "\n✅ ذكر جماعي: إنشاء والانضمام لجلسات ذكر جماعي."
                          "\n✅ ذكر خاص: جلسات ذكر مخصصة للمستخدم مع تذكيرات يومية."
                          "\n✅ ذكر المساء والصباح: قسم خاص بأذكار المساء والصباح مع تذكيرات."
                          "\n✅ إنشاء حساب: تسجيل حساب شخصي وحفظ الأنشطة."
                          "\n✅ إعدادات: تخصيص الوضع المظلم.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Divider(thickness: 2),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(kIsWeb ? "نسخ الرابط:" : "مشاركة الرابط:"),
                      const SizedBox(width: 10,),
                      IconButton(
                        icon: const Icon(kIsWeb ? Icons.copy : Icons.share),
                        onPressed: () {
                          if (!kIsWeb) {
                            Share.share("https://athkar-com.web.app/");
                          } else {
                            // Copy the content to the clipboard
                            Clipboard.setData(const ClipboardData(
                                text: "https://athkar-com.web.app/"));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  backgroundColor: Colors.blue,
                                  duration: Duration(seconds: 2),
                                  content: Text(
                                    'تم النسخ الى الحافظة',
                                  )),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 35),
                  const Center(child: Text('2024 \u00a9 جميع الحقوق محفوظة',
                    style: TextStyle(fontWeight: FontWeight.w200,
                      fontSize: 14,
                      color: Colors.grey,),),),
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
