import 'package:file_saver/file_saver.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

class DownloadButton extends StatefulWidget {
  final String fileKey;
  final String url;

  const DownloadButton({super.key, required this.fileKey, required this.url});

  @override
  State<DownloadButton> createState() => DownloadButtonState();
}

class DownloadButtonState extends State<DownloadButton> {
  bool isHovering = false;

  Future<void> _downloadFile() async {
    try {
      final isVideo = RegExp(
        r'\.(mp4|mov|webm|avi)$',
        caseSensitive: false,
      ).hasMatch(widget.fileKey);
      final isPdf = RegExp(
        r'\.pdf$',
        caseSensitive: false,
      ).hasMatch(widget.fileKey);

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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Download started...')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Download failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = Colors.blue;
    final bgColor = isHovering ? Colors.blue[100] : Colors.blue[50];
    final textColor = Colors.blue;

    return MouseRegion(
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
    );
  }
}
