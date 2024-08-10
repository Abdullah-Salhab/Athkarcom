import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

class MyPdfViewer extends StatefulWidget {
  const MyPdfViewer({super.key});

  @override
  _MyPdfViewerState createState() => _MyPdfViewerState();
}
class _MyPdfViewerState extends State<MyPdfViewer> {
  final pdfController = PdfController(
    document: PdfDocument.openAsset('assets/files/wird_musafa.pdf'),
  );


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
      ),
      body:
      PdfView(
        controller: pdfController,
        scrollDirection: Axis.vertical,
      ),
    );
  }

}