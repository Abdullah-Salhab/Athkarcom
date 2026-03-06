import 'package:athkar/models/section_detail_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';


import '../../models/AnalyticsMixin.dart';
import '../ExceptionDialog.dart';

class SectionDetailScreen extends StatefulWidget {
  final int? id;
  final String? title;

  const SectionDetailScreen({Key? key, required this.id, required this.title})
      : super(key: key);

  @override
  SectionDetailScreenState createState() => SectionDetailScreenState();
}

class SectionDetailScreenState extends State<SectionDetailScreen>
    with TickerProviderStateMixin , AnalyticsMixin {
  @override
  String get screenName => 'OtherAthkarsDetailsScreen';

  List<SectionDetailModel> sectionDetails = [];
  bool isLoading = true;
  late AnimationController _animationController;
  late AnimationController _fabAnimationController;
  late ScrollController _scrollController;
  bool _showScrollToTop = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    loadSectionDetail();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fabAnimationController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        title: Text(
          widget.title ?? '',
          style: const TextStyle(
            fontFamily: 'Amiri',
            fontSize: 22.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          if (sectionDetails.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.share_outlined),
              onPressed: _shareAllContent,
              tooltip: 'مشاركة الكل',
            ),
        ],
      ),
      body: isLoading
          ? _buildLoadingState()
          : sectionDetails.isEmpty
          ? _buildEmptyState()
          : _buildContentList(),
      floatingActionButton: sectionDetails.isNotEmpty && _showScrollToTop
          ? ScaleTransition(
        scale: _fabAnimationController,
        child: FloatingActionButton.extended(
          onPressed: _scrollToTop,
          backgroundColor: Colors.teal.shade600,
          icon: const Icon(Icons.arrow_upward, color: Colors.white),
          label: const Text(
            'العودة للأعلى',
            style: TextStyle(
              fontFamily: 'Tajawal',
              color: Colors.white,
            ),
          ),
        ),
      )
          : null,
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
            'جاري تحميل الأذكار...',
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
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'لا توجد أذكار في هذا القسم',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentList() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return ListView.builder(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: sectionDetails.length,
          itemBuilder: (context, index) {
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
                    child: _buildContentCard(index),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildContentCard(int index) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final content = sectionDetails[index].content ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        elevation: 3,
        borderRadius: BorderRadius.circular(20),
        color: isDark ? Colors.grey[800] : Colors.white,
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
              color: Colors.teal.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.teal.shade400,
                          Colors.teal.shade600,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.teal.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        "${index + 1}",
                        style: const TextStyle(
                          fontSize: 16,
                          fontFamily: 'Tajawal',
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SelectableText(
                          content,
                          textDirection: TextDirection.rtl,
                          style: TextStyle(
                            fontSize: _getResponsiveFontSize(context),
                            fontFamily: 'Tajawal',
                            fontWeight: FontWeight.w400,
                            height: 1.8,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildActionButton(
                    icon: Icons.copy_outlined,
                    label: 'نسخ',
                    onPressed: () => _copyContent(content),
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  if (!kIsWeb)
                    _buildActionButton(
                      icon: Icons.share_outlined,
                      label: 'مشاركة',
                      onPressed: () => _shareContent(content),
                      color: Colors.green,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: color.withOpacity(0.1),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: color,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _getResponsiveFontSize(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (kIsWeb) {
      return screenWidth > 1200 ? 20 : screenWidth > 800 ? 18 : 16;
    }
    return screenWidth > 400 ? 18 : 16;
  }

  void _copyContent(String content) async {
    await Clipboard.setData(ClipboardData(text: content));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'تم نسخ النص',
            style: TextStyle(fontFamily: 'Tajawal'),
          ),
          backgroundColor: Colors.teal,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _shareContent(String content) {
    Share.share(content);
  }

  void _shareAllContent() {
    final allContent = sectionDetails
        .asMap()
        .entries
        .map((entry) => "${entry.key + 1}. ${entry.value.content}")
        .join('\n\n');

    final fullContent = "${widget.title}\n\n$allContent";
    Share.share(fullContent);
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _scrollListener() {
    if (_scrollController.offset > 200 && !_showScrollToTop) {
      setState(() {
        _showScrollToTop = true;
      });
    } else if (_scrollController.offset <= 200 && _showScrollToTop) {
      setState(() {
        _showScrollToTop = false;
      });
    }
  }

  loadSectionDetail() async {
    try {
      sectionDetails = [];
      final data = await DefaultAssetBundle.of(context)
          .loadString("assets/database/section_details_db.json");

      final response = json.decode(data);
      for (var section in response) {
        SectionDetailModel sectionDetail = SectionDetailModel.fromJson(section);
        if (sectionDetail.sectionId == widget.id) {
          sectionDetails.add(sectionDetail);
        }
      }

      setState(() {
        isLoading = false;
      });

      // Start animations after data is loaded
      _animationController.forward();
      _fabAnimationController.forward();
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      showExceptionPopup(context, error.toString());
    }
  }
}