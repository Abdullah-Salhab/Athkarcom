import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:page_transition/page_transition.dart';
import 'DashboardScreen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPageData> _slides = [
    OnboardingPageData(
      title: 'أهلاً بك في أذكاركم',
      description: 'تطبيقك الإسلامي المتكامل لقراءة الأذكار اليومية والقرآن الكريم ومتابعة عبادتك اليومية بكل يسر وسهولة.',
      imagePath: 'assets/images/App_Icon.jpg',
      isGif: false,
    ),
    OnboardingPageData(
      title: 'أذكار الصباح والمساء',
      description: 'حافظ على أذكارك اليومية مع مسبحة وعداد تفاعلي ذكي يساعدك على تتبع أورادك اليومية وتذكيرك بأوقاتها.',
      imagePath: 'assets/images/day-and-night.png',
      isGif: false,
    ),
    OnboardingPageData(
      title: 'القرآن الكريم والتلاوات',
      description: 'اقرأ القرآن الكريم كاملاً واستمع إلى تلاوات خاشعة لعدد كبير من القراء في الخلفية أثناء تنقلك.',
      imagePath: 'assets/images/quran2.png',
      isGif: false,
    ),
    OnboardingPageData(
      title: 'الأذكار الجماعية والمسابقات',
      description: 'انضم لمجموعات الأذكار وشارك التسابيح مع عائلتك وأصدقائك، وتنافس في مسابقات دينية يومية ممتعة.',
      imagePath: 'assets/images/society.gif',
      isGif: true,
    ),
  ];

  Future<void> _completeOnboarding() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_shown', true);
    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageTransition(
          type: PageTransitionType.fade,
          duration: const Duration(milliseconds: 500),
          child: const DashboardScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0C979F), // Sleek Teal matching splash screen
              Color(0xFF08686E),
              Color(0xFF1C2D37), // Dark deep contrast
            ],
            stops: [0.0, 0.4, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Skip button at the top
              Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: TextButton(
                    onPressed: _completeOnboarding,
                    child: const Text(
                      'تخطي',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        color: Colors.white70,
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

              // PageView Slides
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _slides.length,
                  onPageChanged: (int page) {
                    setState(() {
                      _currentPage = page;
                    });
                  },
                  itemBuilder: (context, index) {
                    final slide = _slides[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Slide Image with nice shadow and borders
                          Container(
                            height: MediaQuery.of(context).size.height * 0.35,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.15),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(30),
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Image.asset(
                                  slide.imagePath,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 40.0),
                          
                          // Slide Title
                          Text(
                            slide.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'Tajawal',
                              color: Colors.white,
                              fontSize: 26.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16.0),

                          // Slide Description
                          Text(
                            slide.description,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 16.0,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Pagination and Bottom Controls
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Page Indicator Dots
                    Row(
                      children: List.generate(
                        _slides.length,
                        (index) => _buildDot(index),
                      ),
                    ),

                    // Next / Get Started Button
                    ElevatedButton(
                      onPressed: () {
                        if (_currentPage == _slides.length - 1) {
                          _completeOnboarding();
                        } else {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF08686E),
                        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 12.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        elevation: 4,
                      ),
                      child: Text(
                        _currentPage == _slides.length - 1 ? 'ابدأ الآن' : 'التالي',
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    bool isSelected = _currentPage == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(right: 8.0),
      height: 8.0,
      width: isSelected ? 24.0 : 8.0,
      decoration: BoxDecoration(
        color: isSelected ? Colors.white : Colors.white30,
        borderRadius: BorderRadius.circular(4.0),
      ),
    );
  }
}

class OnboardingPageData {
  final String title;
  final String description;
  final String imagePath;
  final bool isGif;

  OnboardingPageData({
    required this.title,
    required this.description,
    required this.imagePath,
    this.isGif = false,
  });
}
