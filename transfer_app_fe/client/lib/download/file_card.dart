import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'download_button.dart';
import 'file_preview.dart';

class FileCard extends StatelessWidget {
  final String fileKey;
  final String url;

  const FileCard({super.key, required this.fileKey, required this.url});

  @override
  Widget build(BuildContext context) {
    final name = fileKey.split('/').last;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: FilePreview(keyName: fileKey, url: url),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 8),
          DownloadButton(fileKey: fileKey, url: url),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
