import 'package:business/models/cloud/link_expiry.dart';
import 'package:business/models/cloud/s3_file.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class FolderItem extends StatefulWidget {
  final S3File file;
  final int indent;
  final Function(BuildContext, String, LinkExpiry) generateDownloadLink;
  final void Function(String) deleteFile;
  final Widget Function(BuildContext, S3File, {int indent}) buildFileItem;

  const FolderItem({
    super.key,
    required this.file,
    required this.indent,
    required this.generateDownloadLink,
    required this.deleteFile,
    required this.buildFileItem,
  });

  @override
  State<FolderItem> createState() => FolderItemState();
}

class FolderItemState extends State<FolderItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      leading: const Icon(Icons.folder, color: Colors.orange),
      title: Text(widget.file.key),
      initiallyExpanded: _isExpanded,
      onExpansionChanged: (expanded) => setState(() => _isExpanded = expanded),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          MenuAnchor(
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
                    onPressed: () => widget.generateDownloadLink(
                      context,
                      widget.file.key,
                      expiry,
                    ),
                    child: Text(expiry.label),
                  );
                }).toList(),
                child: const Text('Copy link for all'),
              ),
              MenuItemButton(
                onPressed: () => widget.deleteFile(widget.file.key),
                child: const Text('Delete'),
              ),
            ],
          ),
          Icon(
            _isExpanded ? Icons.expand_less : Icons.expand_more,
            color: Colors.grey[600],
          ),
        ],
      ),
      children: [
        for (final child in widget.file.children)
          widget.buildFileItem(context, child, indent: widget.indent + 16),
      ],
    );
  }
}
