import 'package:flutter/material.dart';
import 'package:business/models/cloud/link_expiry.dart';
import 'package:business/models/cloud/s3_file.dart';
import 'folder_item.dart';
import 'panel.dart';

class CloudPanel extends StatelessWidget {
  final List<S3File> cloudFiles;
  final void Function(String) deleteFile;
  final Function(BuildContext, String, LinkExpiry) generateDownloadLink;
  final Function(BuildContext, String, LinkExpiry) generateDownloadLinkForAllFiles;

  const CloudPanel({
    super.key,
    required this.cloudFiles,
    required this.deleteFile,
    required this.generateDownloadLink,
    required this.generateDownloadLinkForAllFiles,
  });

  @override
  Widget build(BuildContext context) {
    return Panel(
      title: 'Cloud files',
      child: ListView(
        children: cloudFiles
            .map((file) => _buildFileItem(context, file))
            .toList(),
      ),
    );
  }

  Widget _buildFileItem(BuildContext context, S3File file, {int indent = 0}) {
    if (file.isFolder) {
      return FolderItem(
        file: file,
        indent: indent,
        generateDownloadLink: generateDownloadLinkForAllFiles,
        deleteFile: deleteFile,
        buildFileItem: _buildFileItem,
      );
    } else {
      return ListTile(
        contentPadding: EdgeInsets.only(left: indent.toDouble() + 16),
        leading: const Icon(Icons.cloud, color: Colors.blue),
        title: Text(file.key),
        trailing: MenuAnchor(
          builder: (context, controller, child) {
            return IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () => controller.open(),
            );
          },
          menuChildren: [
            SubmenuButton(
              menuChildren: LinkExpiry.values.map((expiry) {
                return MenuItemButton(
                  onPressed: () =>
                      generateDownloadLink(context, file.key, expiry),
                  child: Text(expiry.label),
                );
              }).toList(),
              child: const Text('Copy link'),
            ),
            MenuItemButton(
              onPressed: () => deleteFile(file.key),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
    }
  }
}
