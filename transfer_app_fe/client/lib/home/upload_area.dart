import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';

class UploadArea extends StatefulWidget {
  final bool isHovering;
  final ValueChanged<bool> onHoverChanged;
  final void Function(String, Uint8List) onDropFile;
  final Future<void> Function() selectFiles; // <- add this

  const UploadArea({
    super.key,
    required this.isHovering,
    required this.onHoverChanged,
    required this.onDropFile,
    required this.selectFiles, // <- add this
  });

  @override
  State<UploadArea> createState() => _UploadAreaState();
}

class _UploadAreaState extends State<UploadArea> {
  DropzoneViewController? dropController;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        DropzoneView(
          onCreated: (c) => dropController = c,
          onHover: () => widget.onHoverChanged(true),
          onLeave: () => widget.onHoverChanged(false),
          onDropFile: (ev) async {
            if (dropController == null) return;
            final name = await dropController!.getFilename(ev);
            final bytes = await dropController!.getFileData(ev);
            widget.onDropFile(name, bytes);
            widget.onHoverChanged(false);
          },
        ),
        GestureDetector(
          onTap: widget.selectFiles, // <- open file picker on click
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: widget.isHovering ? Colors.blue[100] : Colors.blue[50],
              border: Border.all(color: Colors.blue, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'Drag & drop files here\nor click to select',
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
