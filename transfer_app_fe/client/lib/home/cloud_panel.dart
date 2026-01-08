import 'package:flutter/material.dart';
import 'package:business/models/cloud/link_expiry.dart';
import 'package:business/models/cloud/s3_file.dart';
import 'panel.dart';

class CloudPanel extends StatelessWidget {
  final List<S3File> cloudFiles;
  final void Function(String) deleteFile;
  final Function(BuildContext, String, LinkExpiry) generateDownloadLink;

  const CloudPanel({
    super.key,
    required this.cloudFiles,
    required this.deleteFile,
    required this.generateDownloadLink,
  });

  @override
  Widget build(BuildContext context) {
    return Panel(
      title: 'Cloud files',
      child: ListView.builder(
        itemCount: cloudFiles.length,
        itemBuilder: (context, index) {
          final file = cloudFiles[index];
          return ListTile(
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
                  child: const Text('Copy link'),
                  menuChildren: LinkExpiry.values.map((expiry) {
                    return MenuItemButton(
                      onPressed: () => generateDownloadLink(context, file.key, expiry),
                      child: Text(expiry.label),
                    );
                  }).toList(),
                ),
                MenuItemButton(
                  onPressed: () => deleteFile(file.key),
                  child: const Text('Delete'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
