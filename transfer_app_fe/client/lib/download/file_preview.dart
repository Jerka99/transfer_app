import 'package:client/download/pdf_widget.dart';
import 'package:client/download/video_player_widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FilePreview extends StatelessWidget {
  final String keyName;
  final String url;

  const FilePreview({super.key, required this.keyName, required this.url});

  @override
  Widget build(BuildContext context) {
    final isImage = RegExp(
      r'\.(png|jpg|jpeg|gif|webp)$',
      caseSensitive: false,
    ).hasMatch(keyName);
    final isVideo = RegExp(
      r'\.(mp4|mov|webm|avi)$',
      caseSensitive: false,
    ).hasMatch(keyName);
    final isPdf = RegExp(r'\.pdf$', caseSensitive: false).hasMatch(keyName);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        color: Colors.grey[100],
        child: isVideo
            ? VideoPlayerWidget(url: url)
            : isImage
            ? Image.network(
                url,
                headers: {'Cache-Control': 'no-cache'},
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    context.go('/expired');
                  });

                  return const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
              )
            : isPdf
            ? const PdfWidget()
            : const Center(child: Icon(Icons.insert_drive_file, size: 48)),
      ),
    );
  }
}
