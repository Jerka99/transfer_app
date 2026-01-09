import 'dart:typed_data';

import 'package:async_redux/async_redux.dart';
import 'package:business/models/cloud/s3_file.dart';
import 'package:business/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../store/app_state.dart';
import 'link_expiry.dart';

class FetchCloudFilesAction extends ReduxAction<AppState> {
  @override
  Future<AppState?> reduce() async {
    final List<S3File> s3filesList = await ApiService().getFiles();

    return state.copyWith(cloudFiles: s3filesList);
  }
}

class UploadFileAction extends ReduxAction<AppState> {
  final String filename;
  final Uint8List bytes;
  final LinkExpiry expiry;

  UploadFileAction({
    required this.filename,
    required this.bytes,
    required this.expiry,
  });

  @override
  Future<AppState?> reduce() async {
    await ApiService().uploadFile(filename, bytes, expiry);
    dispatch(FetchCloudFilesAction());
    return null;
  }

  // @override
  // void before() => dispatch(WaitAction.add('uploading_file'));
  //
  // @override
  // void after() => dispatch(WaitAction.remove('uploading_file'));
}

class DeleteCloudFileAction extends ReduxAction<AppState> {
  final String filename;

  DeleteCloudFileAction({required this.filename});

  @override
  Future<AppState?> reduce() async {
    await ApiService().deleteFile(filename);
    dispatch(FetchCloudFilesAction());
    return null;
  }
}

class GenerateTempLinkAction extends ReduxAction<AppState> {
  final String key;
  final LinkExpiry expiry;
  final BuildContext context;
  final Function(String) callbackFun;

  GenerateTempLinkAction({
    required this.key,
    required this.expiry,
    required this.context,
    required this.callbackFun,
  });

  @override
  Future<AppState?> reduce() async {
    final url = await ApiService().getDownloadUrl(key, expiry);
    callbackFun(url);

    return state;
  }
}

class GenerateTempLinksForFolderAction extends ReduxAction<AppState> {
  final String folderKey;
  final LinkExpiry expiry;
  final BuildContext context;
  final Function(List<Map<String, String>>) callbackFun;

  GenerateTempLinksForFolderAction({
    required this.folderKey,
    required this.expiry,
    required this.context,
    required this.callbackFun,
  });

  @override
  Future<AppState?> reduce() async {
    final urls = await ApiService().getDownloadUrlsForFolder(folderKey, expiry);
    callbackFun(urls);
    return state;
  }
}
