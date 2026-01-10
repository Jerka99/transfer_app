import 'package:client/download/single_file_view.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

import 'folder_view.dart';

class DownloadPage extends StatelessWidget {
  final String? fileKey;
  final String? url;
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
  Widget build(BuildContext context) {
    if (isSingleFile) {
      return SingleFileView(fileKey: fileKey!, url: url!);
    } else if (isFolder) {
      return FolderView(folderKey: folderKey!, files: files!);
    }

    return const Scaffold(body: Center(child: Text('No file(s) to display')));
  }
}

Future<void> downloadDirect(
    BuildContext context,
    String fileKey,
    String url,
    ) async {
  try {
    final isVideo = RegExp(
      r'\.(mp4|mov|webm|avi)$',
      caseSensitive: false,
    ).hasMatch(fileKey);
    final isPdf = RegExp(r'\.pdf$', caseSensitive: false).hasMatch(fileKey);

    if (isVideo || (kIsWeb && isPdf)) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      final response = await http.get(Uri.parse(url));
      await FileSaver.instance.saveFile(
        name: fileKey.split('/').last,
        bytes: response.bodyBytes,
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Download failed: $e')));
  }
}
