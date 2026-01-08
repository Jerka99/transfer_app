import 'package:async_redux/async_redux.dart';
import 'package:business/models/cloud/cloud_action.dart';
import 'package:business/models/cloud/link_expiry.dart';
import 'package:business/models/cloud/s3_file.dart';
import 'package:business/store/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';

import '../base_factory.dart';
import 'home_page.dart';

class Factory extends BaseFactory<HomePageConnector, ViewModel> {
  @override
  ViewModel fromStore() => ViewModel(
    cloudFiles: state.cloudFiles,
    fetchCloudFiles: () => dispatch(FetchCloudFilesAction()),
    uploadFile: (String filename, Uint8List bytes) => dispatch(
      UploadFileAction(
        filename: filename,
        bytes: bytes,
        expiry: LinkExpiry.oneDay,
      ),
    ),
    deleteFile: (String filename) =>
        dispatch(DeleteCloudFileAction(filename: filename)),
    generateDownloadLink: (BuildContext context, String key, LinkExpiry expiry) {
      dispatch(
        GenerateTempLinkAction(
          key: key,
          expiry: expiry,
          context: context,
          callbackFun: (url) {
            if (context.mounted) {
              final encodedUrl = Uri.encodeComponent(url);

              final shareableLink =
                  'http://localhost:52341/download?key=${Uri.encodeComponent(key)}&url=$encodedUrl';
              Clipboard.setData(ClipboardData(text: shareableLink));

              Navigator.pushNamed(
                context,
                '/download?key=${Uri.encodeComponent(key)}&url=$encodedUrl',
              );
            }
          },
        ),
      );
    },
  );
}

class HomePageConnector extends StatelessWidget {
  const HomePageConnector({super.key});

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, ViewModel>(
      vm: () => Factory(),
      builder: (BuildContext context, ViewModel vm) {
        return HomePage(
          cloudFiles: vm.cloudFiles,
          fetchCloudFiles: vm.fetchCloudFiles,
          uploadFile: vm.uploadFile,
          deleteFile: vm.deleteFile,
          generateDownloadLink: vm.generateDownloadLink,
        );
      },
    );
  }
}

class ViewModel extends Vm {
  final List<S3File> cloudFiles;
  final VoidCallback fetchCloudFiles;
  final void Function(String, Uint8List) uploadFile;
  final void Function(String) deleteFile;
  final Function(BuildContext, String, LinkExpiry) generateDownloadLink;

  ViewModel({
    required this.cloudFiles,
    required this.fetchCloudFiles,
    required this.uploadFile,
    required this.deleteFile,
    required this.generateDownloadLink,
  }) : super(equals: [cloudFiles]);
}
