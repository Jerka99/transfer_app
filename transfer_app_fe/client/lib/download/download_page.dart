import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'video_player_widget.dart';
import 'pdf_widget.dart';
import 'package:http/http.dart' as http;

class DownloadPage extends StatefulWidget {
  final String fileKey;
  final String url;

  const DownloadPage({super.key, required this.fileKey, required this.url});

  @override
  State<DownloadPage> createState() => _DownloadPageState();
}

class _DownloadPageState extends State<DownloadPage> {
  late final bool isImage;
  late final bool isVideo;
  late final bool isPdf;
  bool isHovering = false; // hover state for button styling

  @override
  void initState() {
    super.initState();

    isImage = _isImage(widget.fileKey);
    isVideo = _isVideo(widget.fileKey);
    isPdf = _isPdf(widget.fileKey);
  }

  bool _isImage(String name) =>
      RegExp(r'\.(png|jpg|jpeg|gif|webp)$', caseSensitive: false)
          .hasMatch(name);

  bool _isVideo(String name) =>
      RegExp(r'\.(mp4|mov|webm|avi)$', caseSensitive: false).hasMatch(name);

  bool _isPdf(String name) => RegExp(r'\.pdf$', caseSensitive: false).hasMatch(name);

  Future<void> _downloadFile() async {
    try {
      if (isVideo || (kIsWeb && isPdf)) {
        final uri = Uri.parse(widget.url);
        final launched = await launchUrl(
          uri,
          mode: kIsWeb
              ? LaunchMode.externalApplication
              : LaunchMode.externalNonBrowserApplication,
        );
        if (!launched) throw 'Could not launch ${widget.url}';
      } else {
        final response = await http.get(Uri.parse(widget.url));
        if (response.statusCode != 200) throw 'Failed to download file';

        await FileSaver.instance.saveFile(
          name: widget.fileKey,
          bytes: response.bodyBytes,
          fileExtension: '',
          mimeType: MimeType.other,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Download started...')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (isVideo) {
      content = VideoPlayerWidget(url: widget.url);
    } else if (isImage) {
      content = Image.network(widget.url);
    } else if (isPdf) {
      content = const PdfWidget();
    } else {
      content = const Center(child: Text('Unsupported file type'));
    }

    // Define colors matching HomePage
    final borderColor = Colors.blue;
    final bgColor = isHovering ? Colors.blue[100] : Colors.blue[50];
    final textColor = Colors.blue;

    return Scaffold(
      appBar: AppBar(title: Text(widget.fileKey)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            content,
            const SizedBox(height: 32),
            MouseRegion(
              onEnter: (_) => setState(() => isHovering = true),
              onExit: (_) => setState(() => isHovering = false),
              child: GestureDetector(
                onTap: _downloadFile,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  decoration: BoxDecoration(
                    color: bgColor,
                    border: Border.all(color: borderColor, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.download, color: textColor),
                      const SizedBox(width: 8),
                      Text(
                        'Download',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
