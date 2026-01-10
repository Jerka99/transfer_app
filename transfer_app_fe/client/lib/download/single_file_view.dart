import 'package:flutter/material.dart';
import 'file_preview.dart';
import 'download_button.dart';

class SingleFileView extends StatelessWidget {
  final String fileKey;
  final String url;

  const SingleFileView({super.key, required this.fileKey, required this.url});

  @override
  Widget build(BuildContext context) {
    final displayName = fileKey.split('/').last;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // Fixed width for the container, responsive for smaller screens
    final double containerWidth = screenWidth < 600 ? screenWidth * 0.95 : 600;
    final containerHeight = screenHeight * 0.7; // max 70% of screen height

    return Scaffold(
      appBar: AppBar(title: Text(displayName)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: containerWidth,
                height: containerHeight,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: FilePreview(keyName: fileKey, url: url),
              ),
              const SizedBox(height: 24),
              DownloadButton(fileKey: fileKey, url: url),
            ],
          ),
        ),
      ),
    );
  }
}
