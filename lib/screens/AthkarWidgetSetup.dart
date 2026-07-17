// Widget to display in your app that allows users to add the widget
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';

import '../models/AnalyticsMixin.dart';
import '../models/AthkarWidgetProvider.dart';
import '../models/PrayerWidgetProvider.dart';

class AthkarWidgetSetup extends StatefulWidget {
  const AthkarWidgetSetup({Key? key}) : super(key: key);

  @override
  State<AthkarWidgetSetup> createState() => _AthkarWidgetSetupState();
}

class _AthkarWidgetSetupState extends State<AthkarWidgetSetup> with AnalyticsMixin{
  @override
  String get screenName => 'HomeWidgetSetupScreen';

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'إعداد الأدوات على الشاشة الرئيسية',
          style: TextStyle(fontFamily: 'Amiri'),
        ),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Card 1: Athkar Widget ──
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'أداة تقرير الأذكار',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Amiri',
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'اعرض تقدمك اليومي في الأذكار والنسبة المئوية مباشرة على الشاشة الرئيسية لهاتفك',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontFamily: 'Amiri',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              try {
                                await AthkarWidgetProvider.initializeWidget();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'تم تحديث الأذكار على الشاشة الرئيسية'),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('خطأ في تحديث الأذكار: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('تحديث البيانات'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0C979F),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              try {
                                await AthkarWidgetProvider.initializeWidget();
                                final isPinSupported = await HomeWidget.isRequestPinWidgetSupported();
                                if (isPinSupported ?? false) {
                                  await HomeWidget.requestPinWidget(
                                    name: AthkarWidgetProvider.androidWidgetName,
                                    androidName: AthkarWidgetProvider.androidWidgetName,
                                    qualifiedAndroidName: 'com.athkar.athkarcom.AthkarWidgetProvider',
                                  );
                                } else {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'يرجى الذهاب للشاشة الرئيسية وإضافة الأداة يدوياً.',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('خطأ: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.add_to_home_screen),
                            label: const Text('إضافة الأداة'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2196F3),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Card 2: Prayer Widget ──
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'أداة مواقيت الصلاة',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Amiri',
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'اعرض مواقيت الصلاة اليومية والصلاة القادمة مباشرة على الشاشة الرئيسية لهاتفك',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontFamily: 'Amiri',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              try {
                                await PrayerWidgetProvider.initializeWidget();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'تم تحديث مواقيت الصلاة على الشاشة الرئيسية'),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('خطأ في تحديث الصلاة: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('تحديث البيانات'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0C979F),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              try {
                                await PrayerWidgetProvider.initializeWidget();
                                final isPinSupported = await HomeWidget.isRequestPinWidgetSupported();
                                if (isPinSupported ?? false) {
                                  await HomeWidget.requestPinWidget(
                                    name: PrayerWidgetProvider.androidWidgetName,
                                    androidName: PrayerWidgetProvider.androidWidgetName,
                                    qualifiedAndroidName: 'com.athkar.athkarcom.PrayerWidgetProvider',
                                  );
                                } else {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'يرجى الذهاب للشاشة الرئيسية وإضافة الأداة يدوياً.',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('خطأ: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.add_to_home_screen),
                            label: const Text('إضافة الأداة'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2196F3),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Card 3: Info & Guide ──
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تفاصيل عرض الأدوات:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Amiri',
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• أداة الأذكار: تعرض التاريخ الحالي، الأذكار المطلوبة المنجزة اليوم، النسبة المئوية للإنجاز، والأيام المتتالية.\n'
                      '• أداة الصلاة: تعرض مواقيت الصلاة الخمس اليومية والشروق، والمدينة، والوقت المتبقي للصلاة القادمة.',
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'Amiri',
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 12),
                    Divider(),
                    SizedBox(height: 12),
                    Text(
                      'كيفية الاستخدام اليدوي:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Amiri',
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '1. اذهب للشاشة الرئيسية لهاتفك.\n'
                      '2. اضغط مطولاً على مساحة فارغة.\n'
                      '3. اختر "Widgets" أو "الأدوات".\n'
                      '4. ابحث عن "أذكاركم" واختر الأداة المناسبة لتقوم بإضافتها.',
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'Amiri',
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
