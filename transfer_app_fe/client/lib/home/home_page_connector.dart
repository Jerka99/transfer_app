import 'dart:convert';

import 'package:async_redux/async_redux.dart';
import 'package:business/models/cloud/cloud_action.dart';
import 'package:business/models/cloud/cloud_list_response_state.dart';
import 'package:business/models/cloud/link_expiry.dart';
import 'package:business/store/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'dart:typed_data';

import '../base_factory.dart';
import 'home_page.dart';

class Factory extends BaseFactory<HomePageConnector, ViewModel> {
  @override
  ViewModel fromStore() => ViewModel(
    cloudListResponseState: state.cloudListResponseState,
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
            if (!context.mounted) return;

            // Encode key and signed URL in Base64
            final encodedKey = base64UrlEncode(utf8.encode(key));
            final encodedUrl = base64UrlEncode(utf8.encode(url));

            // Shareable link
            final shareableLink =
                'http://localhost:52341/download?key=$encodedKey&url=$encodedUrl';

            Clipboard.setData(ClipboardData(text: shareableLink));

            // Navigate via GoRouter — browser URL is safe
            context.go('/download?key=$encodedKey&url=$encodedUrl');
          },
        ),
      );
    },
    generateDownloadLinkForAllFiles:
        (BuildContext context, String folderKey, LinkExpiry expiry) {
          dispatch(
            GenerateTempLinksForFolderAction(
              folderKey: folderKey,
              expiry: expiry,
              context: context,
              callbackFun: (urls) {
                if (!context.mounted) return;

                final filesEncoded = urls
                    .map(
                      (e) => {
                        'key': base64UrlEncode(utf8.encode(e['key']!)),
                        'url': base64UrlEncode(utf8.encode(e['url']!)),
                      },
                    )
                    .toList();

                final filesJson = jsonEncode(filesEncoded);

                final encodedFilesJson = base64UrlEncode(
                  utf8.encode(filesJson),
                );
                final encodedFolderKey = base64UrlEncode(
                  utf8.encode(folderKey),
                );

                final shareableLink =
                    'http://localhost:52341/download-folder?folder=$encodedFolderKey&files=$encodedFilesJson';

                Clipboard.setData(ClipboardData(text: shareableLink));

                context.go(
                  '/download-folder?folder=$encodedFolderKey&files=$encodedFilesJson',
                );
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
          cloudListResponseState: vm.cloudListResponseState,
          fetchCloudFiles: vm.fetchCloudFiles,
          uploadFile: vm.uploadFile,
          deleteFile: vm.deleteFile,
          generateDownloadLink: vm.generateDownloadLink,
          generateDownloadLinkForAllFiles: vm.generateDownloadLinkForAllFiles,
        );
      },
    );
  }
}

class ViewModel extends Vm {
  final CloudListResponseState cloudListResponseState;
  final VoidCallback fetchCloudFiles;
  final void Function(String, Uint8List) uploadFile;
  final void Function(String) deleteFile;
  final Function(BuildContext, String, LinkExpiry) generateDownloadLink;
  final Function(BuildContext, String, LinkExpiry)
  generateDownloadLinkForAllFiles;

  ViewModel({
    required this.cloudListResponseState,
    required this.fetchCloudFiles,
    required this.uploadFile,
    required this.deleteFile,
    required this.generateDownloadLink,
    required this.generateDownloadLinkForAllFiles,
  }) : super(equals: [cloudListResponseState]);
}
