import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'panel.dart';

class LocalUploadPanel extends StatelessWidget {
  final List<String> localFiles;
  final Map<String, Uint8List> localFileData;
  final bool isHovering;
  final ValueChanged<bool> onHoverChanged;
  final Future<void> Function() selectFiles;
  final Future<void> Function() uploadAllLocalFiles;
  final void Function(String) onRemoveFile;

  const LocalUploadPanel({
    super.key,
    required this.localFiles,
    required this.localFileData,
    required this.isHovering,
    required this.onHoverChanged,
    required this.selectFiles,
    required this.uploadAllLocalFiles,
    required this.onRemoveFile,
  });

  @override
  Widget build(BuildContext context) {
    return Panel(
      title: 'Local uploads',
      child: Column(
        children: [
          Expanded(
            child: localFiles.isEmpty
                ? const Center(
                    child: Text(
                      'No local files yet',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: localFiles.length,
                    itemBuilder: (context, index) {
                      final name = localFiles[index];
                      return ListTile(
                        leading: const Icon(Icons.insert_drive_file),
                        title: Text(name),
                        trailing: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => onRemoveFile(name),
                        ),
                      );
                    },
                  ),
          ),
          if (localFiles.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, // same as before
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: uploadAllLocalFiles,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_upload, color: Colors.white),
                    const SizedBox(width: 8),
                    const Text(
                      'Upload to Cloud',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
