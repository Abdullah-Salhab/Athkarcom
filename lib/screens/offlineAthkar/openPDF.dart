import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/AnalyticsMixin.dart';

class MyPdfViewer extends StatefulWidget {
  const MyPdfViewer({super.key});

  @override
  MyPdfViewerState createState() => MyPdfViewerState();
}

class MyPdfViewerState extends State<MyPdfViewer> with AnalyticsMixin {
  @override
  String get screenName => 'WirdMusafaPDFScreen';

  final pdfController = PdfController(
    document: PdfDocument.openAsset('assets/files/wird_musafa.pdf'),
  );

  Future<void> _openYouTubeVideo() async {
    final Uri url = Uri.parse('https://www.youtube.com/watch?v=vNJUs0Gl7ZQ');

    if (!await launchUrl(
      url,
      mode: LaunchMode.inAppWebView,
    )) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'لا يمكن فتح الفيديو',
              style: TextStyle(fontFamily: 'Tajawal'),
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    pdfController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "الذكر المطول",
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 22.0,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.play_circle),
            iconSize: 32,
            tooltip: 'استماع',
            onPressed: _openYouTubeVideo,
          ),
        ],
      ),
      body: PdfView(
        controller: pdfController,
        scrollDirection: Axis.vertical,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openYouTubeVideo,
        icon: const Icon(Icons.headphones),
        label: const Text(
          'استماع',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}