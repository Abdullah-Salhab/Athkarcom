import 'package:athkar/screens/offlineAthkar/openPDF.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'counter_page.dart';

class MorningEveningAthkars extends StatefulWidget {
  const MorningEveningAthkars({super.key});

  @override
  State<MorningEveningAthkars> createState() => _MorningEveningAthkarsState();
}

class _MorningEveningAthkarsState extends State<MorningEveningAthkars> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'أذكار الصباح/المساء',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 24.0,
          ),
        ),
      ),
      body: const Center(
        child: SizedBox(
          width: 1000,
          child: SplitRectangleIntoTriangles(
            leftImageAsset: 'assets/images/day.png',
            rightImageAsset: 'assets/images/night.png',
          ),
        ),
      ),
    );
  }
}

class SplitRectangleIntoTriangles extends StatelessWidget {
  final String leftImageAsset;
  final String rightImageAsset;

  const SplitRectangleIntoTriangles({
    Key? key,
    required this.leftImageAsset,
    required this.rightImageAsset,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double width = constraints.maxWidth;
        double height = constraints.maxHeight;

        return Container(
          width: width,
          height: height,
          child: Stack(
            children: [
              Positioned(
                top: 0,
                child: LeftTriangleButton(
                  imageAsset: leftImageAsset,
                  width: width,
                  height: height,
                ),
              ),
              Positioned(
                bottom: 0,
                child: RightTriangleButton(
                  imageAsset: rightImageAsset,
                  width: width,
                  height: height,
                ),
              ),
              Positioned(
                  bottom: 0, // Adjust bottom position as needed
                  left: 0,
                  right: 0,
                  child: Row(
                    children: [
                      Expanded(child: Container()),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MyPdfViewer(),
                            ),
                          );
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            'الذكر المطول',
                            style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 20.0,
                                color: Colors.white),
                          ),
                        ),
                      ),
                      Expanded(child: Container()),
                    ],
                  )),
            ],
          ),
        );
      },
    );
  }

  Future<void> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}

class LeftTriangleButton extends StatefulWidget {
  final String imageAsset;
  final double width;
  final double height;

  const LeftTriangleButton({
    Key? key,
    required this.imageAsset,
    required this.width,
    required this.height,
  }) : super(key: key);

  @override
  _LeftTriangleButtonState createState() => _LeftTriangleButtonState();
}

class _LeftTriangleButtonState extends State<LeftTriangleButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => CounterPage(
                  id: 1,
                  title: "أذكار الصباح",
                )));
      },
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: Transform.scale(
        scale: _isPressed ? 1.1 : 1.0,
        child: ClipPath(
          clipper: LeftTriangleClipper(widget.height / 2),
          child: Stack(children: [
            Image.asset(
              widget.imageAsset,
              width: widget.width,
              height: widget.height,
              fit: BoxFit.cover,
            ),
            Positioned(
              left: widget.width / 4,
              top: widget.height / 3,
              child: const Center(
                child: Text(
                  "اذكار الصباح",
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class RightTriangleButton extends StatefulWidget {
  final String imageAsset;
  final double width;
  final double height;

  const RightTriangleButton({
    Key? key,
    required this.imageAsset,
    required this.width,
    required this.height,
  }) : super(key: key);

  @override
  _RightTriangleButtonState createState() => _RightTriangleButtonState();
}

class _RightTriangleButtonState extends State<RightTriangleButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigator.of(context).push(MaterialPageRoute(builder: (context) => SectionDetailScreen(id: 2,title: "أذكار المساء",)));
        Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => CounterPage(
                  id: 2,
                  title: "أذكار المساء",
                )));
      },
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: Transform.scale(
        scale: _isPressed ? 1.1 : 1.0,
        child: ClipPath(
          clipper: RightTriangleClipper(widget.height / 2),
          child: Stack(children: [
            Image.asset(
              widget.imageAsset,
              width: widget.width,
              height: widget.height,
              fit: BoxFit.cover,
            ),
            Positioned(
              right: widget.width / 4,
              top: widget.height / 1.5,
              child: Center(
                child: Text(
                  "اذكار المساء",
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class LeftTriangleClipper extends CustomClipper<Path> {
  final double triangleHeight;

  LeftTriangleClipper(this.triangleHeight);

  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height);
    path.lineTo(size.width, 0);
    path.lineTo(0, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return false;
  }
}

class RightTriangleClipper extends CustomClipper<Path> {
  final double triangleHeight;

  RightTriangleClipper(this.triangleHeight);

  @override
  Path getClip(Size size) {
    Path path = Path();
    path.moveTo(0, size.height); // starting point
    path.lineTo(size.width, 0); // top right corner
    path.lineTo(size.width, size.height); // bottom right corner
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return false;
  }
}
