import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/AnalyticsMixin.dart';
import '../ExceptionDialog.dart';
import '../onlineAthkar/Counter_Athkar.dart';

class OfflineAthkarList extends StatefulWidget {
  const OfflineAthkarList({super.key});

  @override
  State<OfflineAthkarList> createState() => _OfflineAthkarListState();
}

class _OfflineAthkarListState extends State<OfflineAthkarList>
    with TickerProviderStateMixin , AnalyticsMixin {
  @override
  String get screenName => 'OfflineAthkarListScreen';

  List<String> athkarList = [];
  List<String> athkarCount = [];
  List<String> athkarCurrentCount = [];
  bool isLoad = false;
  late AnimationController _animationController;
  late AnimationController _fabController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    getAthkarList().catchError((e) {
      showExceptionPopup(context, e.toString());
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fabController.dispose();
    super.dispose();
  }

  getAthkarList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      if (prefs.containsKey('athkarList') &&
          prefs.containsKey("athkarCount") &&
          prefs.containsKey("athkarCurrentCount")) {
        athkarList = prefs.getStringList('athkarList')!;
        athkarCount = prefs.getStringList('athkarCount')!;
        athkarCurrentCount = prefs.getStringList('athkarCurrentCount')!;
      }
      isLoad = true;
    });

    if (athkarList.isNotEmpty) {
      _animationController.forward();
    }
    _fabController.forward();
  }

  updateAthkarList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('athkarList', athkarList);
    await prefs.setStringList('athkarCount', athkarCount);
    await prefs.setStringList('athkarCurrentCount', athkarCurrentCount);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? Colors.grey[850] : Colors.teal,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        title: const Text(
          'أذكاري',
          style: TextStyle(
            fontFamily: 'Amiri',
            fontSize: 26.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _showAddAthkarDialog(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.black.withOpacity(0.1),
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: isLoad
          ? athkarList.isNotEmpty
          ? _buildAthkarList()
          : _buildEmptyState()
          : _buildLoadingState(),
      floatingActionButton: ScaleTransition(
        scale: _fabController,
        child: FloatingActionButton.extended(
          onPressed: () => _showAddAthkarDialog(context),
          backgroundColor: Colors.teal.shade600,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text(
            'إضافة ذكر',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'جاري التحميل...',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(60),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.teal.shade300.withOpacity(0.3),
                  Colors.teal.shade600.withOpacity(0.3),
                ],
              ),
            ),
            child: Icon(
              Icons.auto_stories_outlined,
              size: 60,
              color: Colors.teal.shade600,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "لا يوجد لديك أذكار",
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 24.0,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "ابدأ بإضافة أول ذكر لك",
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 16.0,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _showAddAthkarDialog(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.teal.shade400,
                      Colors.teal.shade600,
                    ],
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, color: Colors.white, size: 24),
                    SizedBox(width: 8),
                    Text(
                      "إضافة ذكر",
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 18.0,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAthkarList() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: athkarList.length,
          itemBuilder: (BuildContext context, int index) {
            final delay = index * 0.1;
            final animation = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(
              CurvedAnimation(
                parent: _animationController,
                curve: Interval(delay, 1.0, curve: Curves.easeOutCubic),
              ),
            );

            return AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, 30 * (1 - animation.value)),
                  child: Opacity(
                    opacity: animation.value,
                    child: _buildAthkarCard(index),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildAthkarCard(int index) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentCount = int.parse(athkarCurrentCount[index]);
    final totalCount = int.parse(athkarCount[index]);
    final progress = currentCount / totalCount;
    final isCompleted = currentCount <= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        elevation: 3,
        borderRadius: BorderRadius.circular(20),
        color: isDark ? Colors.grey[800] : Colors.white,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _navigateToCounter(index),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [Colors.grey[800]!, Colors.grey[850]!]
                    : [Colors.white, Colors.grey[50]!],
              ),
              border: Border.all(
                color: isCompleted
                    ? Colors.green.withOpacity(0.3)
                    : Colors.teal.withOpacity(0.1),
                width: 2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isCompleted
                              ? [Colors.green.shade400, Colors.green.shade600]
                              : [Colors.teal.shade400, Colors.teal.shade600],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (isCompleted ? Colors.green : Colors.teal)
                                .withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        isCompleted ? Icons.check_rounded : Icons.auto_stories,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            athkarList[index],
                            style: TextStyle(
                              fontFamily: 'Amiri',
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isCompleted ? 'مكتمل' : 'قيد التقدم',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 12,
                              color: isCompleted
                                  ? Colors.green.shade600
                                  : Colors.orange.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: Colors.red.shade400,
                        size: 22,
                      ),
                      onPressed: () => _showDeleteConfirmationDialog(context, index),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${athkarCurrentCount[index]}/${athkarCount[index]}",
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: 1 - progress,
                              backgroundColor: Colors.grey.withOpacity(0.3),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isCompleted ? Colors.green : Colors.teal,
                              ),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: (isCompleted ? Colors.green : Colors.teal)
                            .withOpacity(0.1),
                        border: Border.all(
                          color: (isCompleted ? Colors.green : Colors.teal)
                              .withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        "${((1 - progress) * 100).round()}%",
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isCompleted ? Colors.green.shade700 : Colors.teal.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToCounter(int index) {
    Navigator.push(
      context,
      PageTransition(
        type: PageTransitionType.rightToLeftWithFade,
        alignment: Alignment.center,
        curve: Curves.easeInOutCubic,
        reverseDuration: const Duration(milliseconds: 400),
        duration: const Duration(milliseconds: 400),
        child: CounterAthkarScreen(
          count: int.parse(athkarCount[index]),
          currentCount: int.parse(athkarCurrentCount[index]),
          content: athkarList[index],
          id: "0",
          value: "",
          index: index,
          groupId: "",
        ),
      ),
    ).then((value) => getAthkarList());
  }

  Future<void> _showDeleteConfirmationDialog(BuildContext context, int index) async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDark ? Colors.grey[800] : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.red.withOpacity(0.1),
                ),
                child: Icon(
                  Icons.delete_outline,
                  color: Colors.red.shade600,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'حذف ذكر',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            'هل أنت متأكد من حذف هذا الذكر؟\n"${athkarList[index]}"',
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 16,
            ),
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[600],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'إلغاء',
                style: TextStyle(fontFamily: 'Tajawal'),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'حذف',
                style: TextStyle(fontFamily: 'Tajawal'),
              ),
              onPressed: () async {
                setState(() {
                  athkarList.removeAt(index);
                  athkarCount.removeAt(index);
                  athkarCurrentCount.removeAt(index);
                });
                await updateAthkarList().catchError((e) {
                  showExceptionPopup(context, e.toString());
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAddAthkarDialog(BuildContext context) async {
    final TextEditingController countController = TextEditingController();
    final TextEditingController contentController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: isDark ? Colors.grey[800] : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.teal.withOpacity(0.1),
                    ),
                    child: Icon(
                      Icons.add_rounded,
                      color: Colors.teal.shade600,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'إضافة ذكر',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: contentController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15.0),
                            borderSide: BorderSide(color: Colors.teal.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15.0),
                            borderSide: BorderSide(color: Colors.teal.shade600, width: 2),
                          ),
                          labelText: "الذكر *",
                          labelStyle: TextStyle(
                            fontFamily: 'Tajawal',
                            color: Colors.teal.shade600,
                          ),
                          prefixIcon: Icon(Icons.auto_stories, color: Colors.teal.shade600),
                        ),
                        style: const TextStyle(fontFamily: 'Tajawal'),
                        validator: (value) {
                          if (value!.trim().isEmpty) {
                            return 'يرجى إدخال الذكر';
                          }
                          return null;
                        },
                        maxLength: 100,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: countController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15.0),
                            borderSide: BorderSide(color: Colors.teal.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15.0),
                            borderSide: BorderSide(color: Colors.teal.shade600, width: 2),
                          ),
                          labelText: "العدد *",
                          labelStyle: TextStyle(
                            fontFamily: 'Tajawal',
                            color: Colors.teal.shade600,
                          ),
                          prefixIcon: Icon(Icons.numbers, color: Colors.teal.shade600),
                        ),
                        style: const TextStyle(fontFamily: 'Tajawal'),
                        validator: (value) {
                          if (value!.trim().isEmpty) {
                            return 'يرجى إدخال العدد';
                          }
                          if (int.tryParse(value.trim()) == null) {
                            return 'يرجى إدخال رقم صحيح';
                          }
                          return null;
                        },
                        maxLength: 6,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          color: Colors.teal.withOpacity(0.05),
                          border: Border.all(color: Colors.teal.withOpacity(0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.lightbulb_outline,
                                    color: Colors.teal.shade600, size: 20),
                                const SizedBox(width: 8),
                                const Text(
                                  "أذكار مقترحة:",
                                  style: TextStyle(
                                    fontFamily: 'Tajawal',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildSuggestionChip("سبحان الله", "33", contentController, countController, setDialogState),
                                _buildSuggestionChip("الحمد لله", "33", contentController, countController, setDialogState),
                                _buildSuggestionChip("الله أكبر", "34", contentController, countController, setDialogState),
                                _buildSuggestionChip("استغفر الله", "100", contentController, countController, setDialogState),
                                _buildSuggestionChip("لا إله إلا الله", "100", contentController, countController, setDialogState),
                                _buildSuggestionChip("سُبْحـانَ اللهِ وَبِحَمْـدِهِ", "100", contentController, countController, setDialogState),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'إلغاء',
                    style: TextStyle(fontFamily: 'Tajawal'),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'إضافة',
                    style: TextStyle(fontFamily: 'Tajawal'),
                  ),
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      formKey.currentState!.save();
                      setState(() {
                        athkarList.add(contentController.text);
                        athkarCount.add(countController.text);
                        athkarCurrentCount.add(countController.text);
                      });
                      await updateAthkarList().catchError((e) {
                        showExceptionPopup(context, e.toString());
                      });
                      Navigator.of(context).pop();
                      // Restart animation for new items
                      _animationController.reset();
                      _animationController.forward();
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSuggestionChip(String label, String count,
      TextEditingController contentController,
      TextEditingController countController,
      StateSetter setDialogState) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          setDialogState(() {
            contentController.text = label;
            countController.text = count;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.teal.withOpacity(0.1),
            border: Border.all(color: Colors.teal.withOpacity(0.3)),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 14,
              color: Colors.teal.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}