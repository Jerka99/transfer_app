import 'dart:typed_data';
import 'package:business/models/cloud/cloud_list_response_state.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:business/models/cloud/link_expiry.dart';
import 'upload_area.dart';
import 'local_upload_panel.dart';
import 'cloud_panel.dart';

class HomePage extends StatefulWidget {
  final CloudListResponseState cloudListResponseState;
  final VoidCallback fetchCloudFiles;
  final Function(String, Uint8List) uploadFile;
  final void Function(String) deleteFile;
  final Function(BuildContext, String, LinkExpiry) generateDownloadLink;
  final Function(BuildContext, String, LinkExpiry)
  generateDownloadLinkForAllFiles;

  const HomePage({
    super.key,
    required this.cloudListResponseState,
    required this.fetchCloudFiles,
    required this.uploadFile,
    required this.deleteFile,
    required this.generateDownloadLink,
    required this.generateDownloadLinkForAllFiles,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<String> localFiles = [];
  Map<String, Uint8List> localFileData = {};
  bool isHovering = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.fetchCloudFiles();
    });
  }

  Future<void> selectFiles() async {
    await _selectFiles();
  }

  Future<void> _selectFiles() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null) {
      for (final f in result.files) {
        if (f.bytes != null) {
          localFileData[f.name] = f.bytes!;
          setState(() => localFiles.add(f.name));
        }
      }
    }
  }

  Future<void> uploadAllLocalFiles() async {
    for (final name in localFiles) {
      final bytes = localFileData[name];
      if (bytes != null) {
        await widget.uploadFile(name, bytes);
      }
    }
    setState(() {
      localFiles.clear();
      localFileData.clear();
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All local files uploaded to cloud')),
      );
    }

    widget.fetchCloudFiles();
  }

  void showLinkDurationDialog(BuildContext context, String key) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Link valid for'),
        children: [
          _durationOption(context, key, '1 hour', 60),
          _durationOption(context, key, '1 day', 24 * 60),
          _durationOption(context, key, '1 week', 24 * 60 * 7),
          _durationOption(context, key, '1 month', 24 * 60 * 30),
        ],
      ),
    );
  }

  SimpleDialogOption _durationOption(
    BuildContext context,
    String key,
    String label,
    int seconds,
  ) {
    return SimpleDialogOption(
      child: Text(label),
      onPressed: () async {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Link copied')));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('File Manager'), centerTitle: true),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 900;

          if (isMobile) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Expanded(
                    flex: 3,
                    child: CloudPanel(
                      cloudListResponseState: widget.cloudListResponseState,
                      deleteFile: widget.deleteFile,
                      generateDownloadLink: widget.generateDownloadLink,
                      generateDownloadLinkForAllFiles:
                          widget.generateDownloadLinkForAllFiles,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    flex: 2,
                    child: UploadArea(
                      onHoverChanged: (hover) =>
                          setState(() => isHovering = hover),
                      isHovering: isHovering,
                      onDropFile: (name, bytes) {
                        localFileData[name] = bytes;
                        setState(() => localFiles.add(name));
                      },
                      // selectFiles: selectFiles, // <- pass the function here
                    ),
                  ),

                  const SizedBox(height: 16),
                  Expanded(
                    flex: 3,
                    child: LocalUploadPanel(
                      localFiles: localFiles,
                      localFileData: localFileData,
                      isHovering: isHovering,
                      onHoverChanged: (hover) =>
                          setState(() => isHovering = hover),
                      selectFiles: selectFiles,
                      onRemoveFile: (name) {},
                      uploadAllLocalFiles: uploadAllLocalFiles,
                    ),
                  ),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      Expanded(
                        flex: 2,
                        child: UploadArea(
                          onHoverChanged: (hover) =>
                              setState(() => isHovering = hover),
                          isHovering: isHovering,
                          onDropFile: (name, bytes) {
                            localFileData[name] = bytes;
                            setState(() => localFiles.add(name));
                          },
                          // selectFiles: selectFiles, // <- pass the function here
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        flex: 3,
                        child: LocalUploadPanel(
                          localFiles: localFiles,
                          localFileData: localFileData,
                          isHovering: isHovering,
                          onHoverChanged: (hover) =>
                              setState(() => isHovering = hover),
                          selectFiles: selectFiles,
                          onRemoveFile: (name) {
                            setState(() {
                              localFiles.remove(name);
                              localFileData.remove(name);
                            });
                          },
                          uploadAllLocalFiles: uploadAllLocalFiles,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: CloudPanel(
                    cloudListResponseState: widget.cloudListResponseState,
                    deleteFile: widget.deleteFile,
                    generateDownloadLink: widget.generateDownloadLink,
                    generateDownloadLinkForAllFiles:
                        widget.generateDownloadLinkForAllFiles,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
