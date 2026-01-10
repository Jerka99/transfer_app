import 'package:flutter/material.dart';

import 'download_page.dart';
import 'file_card.dart';

class FolderView extends StatelessWidget {
  final String folderKey;
  final List<Map<String, String>> files;

  const FolderView({super.key, required this.folderKey, required this.files});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(folderKey),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              itemCount: files.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.9,
              ),
              itemBuilder: (context, index) {
                final file = files[index];
                return FileCard(fileKey: file['key']!, url: file['url']!);
              },
            ),
          ),

          // Positioned "Download All" button at the bottom center
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: _DownloadAllButton(
                files: files,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DownloadAllButton extends StatefulWidget {
  final List<Map<String, String>> files;
  const _DownloadAllButton({required this.files});

  @override
  State<_DownloadAllButton> createState() => _DownloadAllButtonState();
}

class _DownloadAllButtonState extends State<_DownloadAllButton> {
  bool isHovering = false;

  Future<void> _downloadAll() async {
    for (final file in widget.files) {
      await downloadDirect(context, file['key']!, file['url']!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = Colors.blue[700]!;
    final bgColor = isHovering ? Colors.blue[600] : Colors.blue;

    return MouseRegion(
      onEnter: (_) => setState(() => isHovering = true),
      onExit: (_) => setState(() => isHovering = false),
      child: GestureDetector(
        onTap: _downloadAll,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
          decoration: BoxDecoration(
            color: bgColor,
            border: Border.all(color: borderColor, width: 2),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.download, color: Colors.white),
              const SizedBox(width: 12),
              const Text(
                'Download All',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
