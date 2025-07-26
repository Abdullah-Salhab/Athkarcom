// Widget to display in your app that allows users to add the widget
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';

import '../models/AthkarWidgetProvider.dart';

class AthkarWidgetSetup extends StatefulWidget {
  const AthkarWidgetSetup({Key? key}) : super(key: key);

  @override
  State<AthkarWidgetSetup> createState() => _AthkarWidgetSetupState();
}

class _AthkarWidgetSetupState extends State<AthkarWidgetSetup> {
  bool _isWidgetSupported = true; // Most devices support widgets

  @override
  void initState() {
    super.initState();
    // Widget support check is handled differently in home_widget
    // Most Android and iOS devices support widgets
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'إعداد الأذكار على الشاشة الرئيسية',
          style: TextStyle(fontFamily: 'Amiri'),
        ),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'أذكار على الشاشة الرئيسية',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Amiri',
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'اعرض تقدمك اليومي في الأذكار مباشرة على الشاشة الرئيسية لهاتفك',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontFamily: 'Amiri',
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
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
                      label: const Text('تحديث الأذكار'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0C979F),
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () async {
                        // Update widget data first
                        try {
                          await AthkarWidgetProvider.initializeWidget();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'تم تحديث البيانات. الآن اذهب للشاشة الرئيسية واضغط مطولاً لإضافة الأذكار',
                                ),
                              ),
                            );
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
                      icon: const Icon(Icons.add),
                      label: const Text('تحضير الأذكار للشاشة الرئيسية'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2196F3),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ما يعرضه الأذكار:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Amiri',
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• التاريخ الحالي\n'
                      '• عدد الأذكار المكتملة اليوم\n'
                      '• النسبة المئوية للإنجاز\n'
                      '• عدد الأيام المتتالية\n'
                      '• الأذكار المكتملة',
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'Amiri',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'كيفية الاستخدام:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Amiri',
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '1. اضغط على "تحضير الأذكار للشاشة الرئيسية"\n'
                      '2. اذهب للشاشة الرئيسية\n'
                      '3. اضغط مطولاً على مساحة فارغة\n'
                      '4. اختر "Widgets" أو "الأدوات"\n'
                      '5. ابحث عن أذكار وأضفها\n'
                      '6. سيتم تحديث الأذكار تلقائياً',
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'Amiri',
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
