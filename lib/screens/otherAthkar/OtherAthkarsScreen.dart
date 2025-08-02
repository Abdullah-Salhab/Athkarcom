import 'dart:convert';

import 'package:athkar/screens/OtherAthkar/SectionDetailScreen.dart';
import 'package:flutter/material.dart';

import '../../models/AnalyticsMixin.dart';
import '../ExceptionDialog.dart';

class OtherAthkarScreen extends StatefulWidget {
  const OtherAthkarScreen({super.key});

  @override
  State<OtherAthkarScreen> createState() => _OtherAthkarScreenState();
}

class _OtherAthkarScreenState extends State<OtherAthkarScreen>
    with TickerProviderStateMixin , AnalyticsMixin {
  @override
  String get screenName => 'OtherAthkarsScreen';

  List<SectionModel> sectionsList = [];
  bool isLoading = true;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    loadSectionDetail();
  }

  @override
  void dispose() {
    _animationController.dispose();
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
        title: const Text(
          'أذكار أخرى',
          style: TextStyle(
            fontFamily: 'Amiri',
            fontSize: 24.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? _buildLoadingState()
          : sectionsList.isEmpty
          ? _buildEmptyState()
          : _buildSectionsList(),
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
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.book_outlined,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'لا توجد أذكار متاحة',
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

  Widget _buildSectionsList() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return ListView.builder(
          itemCount: sectionsList.length,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            // Clamp delay to avoid Interval assertion error
            final start = (index * 0.1).clamp(0.0, 0.9);
            final animation = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(
              CurvedAnimation(
                parent: _animationController,
                curve: Interval(start, 1.0, curve: Curves.easeOutCubic),
              ),
            );

            return AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, 50 * (1 - animation.value)),
                  child: Opacity(
                    opacity: animation.value,
                    child: _buildSectionCard(index),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSectionCard(int index) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(16),
        color: isDark ? Colors.grey[800] : Colors.white,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _navigateToDetail(index),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [Colors.grey[800]!, Colors.grey[850]!]
                    : [Colors.white, Colors.grey[50]!],
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
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
                  child: const Icon(
                    Icons.auto_stories,
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
                        sectionsList[index].sectionName ?? '',
                        style: TextStyle(
                          fontSize: 18,
                          fontFamily: 'Tajawal',
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'اضغط للعرض',
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'Tajawal',
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: isDark ? Colors.grey[700] : Colors.grey[100],
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    size: 18,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToDetail(int index) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            SectionDetailScreen(
              id: sectionsList[index].sectionId,
              title: sectionsList[index].sectionName,
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  loadSectionDetail() async {
    try {
      sectionsList = [];
      final data = await DefaultAssetBundle.of(context)
          .loadString("assets/database/sections_db.json");

      final response = json.decode(data);
      for (var section in response) {
        SectionModel currentSection = SectionModel.fromJson(section);
        if (currentSection.sectionId != 1 && currentSection.sectionId != 2) {
          sectionsList.add(currentSection);
        }
      }

      setState(() {
        isLoading = false;
      });

      // Start animations after data is loaded
      _animationController.forward();
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      showExceptionPopup(context, error.toString());
    }
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