import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'video_player_widget.dart';
import 'pdf_widget.dart';
import 'package:http/http.dart' as http;

class DownloadPage extends StatefulWidget {
  final String? fileKey; // single file
  final String? url;     // single file URL
  final String? folderKey;
  final List<Map<String, String>>? files;

  const DownloadPage({
    super.key,
    this.fileKey,
    this.url,
    this.folderKey,
    this.files,
  });

  bool get isSingleFile => fileKey != null && url != null;
  bool get isFolder => folderKey != null && files != null && files!.isNotEmpty;

  @override
  State<DownloadPage> createState() => _DownloadPageState();
}

class _DownloadPageState extends State<DownloadPage> {
  @override
  Widget build(BuildContext context) {
    if (widget.isSingleFile) {
      return _buildSingleFile(widget.fileKey!, widget.url!);
    } else if (widget.isFolder) {
      return _buildFolder(widget.folderKey!, widget.files!);
    } else {
      return const Scaffold(
        body: Center(child: Text('No file(s) to display')),
      );
    }
  }

  Widget _buildSingleFile(String key, String url) {
    final displayName = Uri.decodeComponent(Uri.parse(url).pathSegments.last);
    return Scaffold(
      appBar: AppBar(title: Text(displayName)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildFilePreview(key, url),
            const SizedBox(height: 32),
            _DownloadButton(fileKey: key, url: url),
          ],
        ),
      ),
    );
  }

  Widget _buildFolder(String folderKey, List<Map<String, String>> files) {
    return Scaffold(
      appBar: AppBar(title: Text(folderKey)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: files.map((file) {
            final key = file['key']!;
            final url = file['url']!;
            return Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(key, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _buildFilePreview(key, url),
                  const SizedBox(height: 12),
                  _DownloadButton(fileKey: key, url: url),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildFilePreview(String key, String url) {
    final isImage = RegExp(r'\.(png|jpg|jpeg|gif|webp)$', caseSensitive: false).hasMatch(key);
    final isVideo = RegExp(r'\.(mp4|mov|webm|avi)$', caseSensitive: false).hasMatch(key);
    final isPdf = RegExp(r'\.pdf$', caseSensitive: false).hasMatch(key);

    if (isVideo) return VideoPlayerWidget(url: url);
    if (isImage) return Image.network(url);
    if (isPdf) return const PdfWidget();
    return const Center(child: Text('Unsupported file type'));
  }
}

class _DownloadButton extends StatefulWidget {
  final String fileKey;
  final String url;

  const _DownloadButton({required this.fileKey, required this.url});

  @override
  State<_DownloadButton> createState() => _DownloadButtonState();
}

class _DownloadButtonState extends State<_DownloadButton> {
  bool isHovering = false;

  Future<void> _downloadFile() async {
    try {
      final isVideo = RegExp(r'\.(mp4|mov|webm|avi)$', caseSensitive: false)
          .hasMatch(widget.fileKey);
      final isPdf = RegExp(r'\.pdf$', caseSensitive: false).hasMatch(widget.fileKey);

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
