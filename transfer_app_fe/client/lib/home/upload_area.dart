import 'dart:typed_data';
import 'dart:js_util' as js_util;
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';

class UploadArea extends StatefulWidget {
  final bool isHovering;
  final ValueChanged<bool> onHoverChanged;
  final void Function(String, Uint8List) onDropFile;

  const UploadArea({
    super.key,
    required this.isHovering,
    required this.onHoverChanged,
    required this.onDropFile,
  });

  @override
  State<UploadArea> createState() => _UploadAreaState();
}

class _UploadAreaState extends State<UploadArea> {
  DropzoneViewController? dropController;

  @override
  void initState() {
    super.initState();

    // Register Dart callback callable from JS for folder drops
    js_util.setProperty(
      js_util.globalThis,
      'flutterFolderDropCallback',
      js_util.allowInterop((String path, dynamic bytes) {
        widget.onDropFile(path, Uint8List.fromList(List<int>.from(bytes)));
        widget.onHoverChanged(false); // remove hover after drop
      }),
    );

    // Call JS function defined in drop_folder.js
    js_util.callMethod(js_util.globalThis, 'handleFolderDrop', ['flutterFolderDropCallback']);

    // Optional: detect folder hover
    js_util.callMethod(js_util.globalThis, 'addEventListener', [
      'dragenter',
      js_util.allowInterop((event) {
        widget.onHoverChanged(true);
      })
    ]);
    js_util.callMethod(js_util.globalThis, 'addEventListener', [
      'dragleave',
      js_util.allowInterop((event) {
        widget.onHoverChanged(false);
      })
    ]);
  }

  /// Opens system file picker (Finder/Explorer) and allows files + folders
  Future<void> selectFilesOrFolder() async {
    final isFolder = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.blue[50], // light background
        title: const Text(
          'Select files or folder',
          style: TextStyle(
            color: Colors.blue,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Choose whether you want to select individual files or an entire folder.',
          style: TextStyle(color: Colors.blueAccent),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[300],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Folder'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[300],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Files'),
          ),
        ],
      ),
    );

    if (isFolder == null) return;

    final input = html.FileUploadInputElement()
      ..multiple = true;
    if (isFolder) js_util.setProperty(input, 'webkitdirectory', true);

    input.click();

    input.onChange.listen((event) async {
      final files = input.files;
      if (files == null) return;

      for (final file in files) {
        final reader = html.FileReader();
        reader.readAsArrayBuffer(file);
        await reader.onLoad.first;
        final bytes = reader.result as Uint8List;

        final fileName = file.relativePath?.isNotEmpty == true ? file.relativePath! : file.name;
        widget.onDropFile(fileName, bytes);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Dropzone handles drag & drop of single files
        DropzoneView(
          onCreated: (c) => dropController = c,
          onHover: () => widget.onHoverChanged(true),
          onLeave: () => widget.onHoverChanged(false),
          onDropFile: (ev) async {
            // Prevent duplicate when folder drop occurs
            final isFolderDrop = js_util.getProperty(js_util.globalThis, '__isFolderDrop') ?? false;
            if (isFolderDrop) return;

            if (dropController == null) return;
            final name = await dropController!.getFilename(ev);
            final bytes = await dropController!.getFileData(ev);
            widget.onDropFile(name, bytes);
            widget.onHoverChanged(false);
          },
        ),

        // Clickable overlay
        GestureDetector(
          onTap: selectFilesOrFolder, // <- open Finder/Explorer
          child: Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: widget.isHovering ? Colors.blue[100] : Colors.blue[50],
              border: Border.all(color: Colors.blue, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'Drag & drop files or folders here\nor click to select',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.blue,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
