import 'dart:convert';

import 'package:async_redux/async_redux.dart';
import 'package:business/store/app_state.dart';
import 'package:business/store/app_store.dart';
import 'package:client/home/home_page_connector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'download/download_page.dart';

void main() {
  usePathUrlStrategy();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final _router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const HomePageConnector(),
        ),
        GoRoute(
          path: '/download',
          builder: (context, state) {
            final keyEncoded = state.uri.queryParameters['key'];
            final urlEncoded = state.uri.queryParameters['url'];

            if (keyEncoded == null || urlEncoded == null) {
              return const Scaffold(
                body: Center(child: Text('Missing file info')),
              );
            }

            // Decode Base64
            final fileKey = utf8.decode(base64Url.decode(keyEncoded));
            final fileUrl = utf8.decode(base64Url.decode(urlEncoded));

            return DownloadPage(fileKey: fileKey, url: fileUrl);
          },
        ),
        GoRoute(
          path: '/download-folder',
          builder: (context, state) {
            final folderKeyEncoded = state.uri.queryParameters['folder']!;
            final filesJsonEncoded = state.uri.queryParameters['files']!;

            // Decode Base64 URL safe
            final folderKey = utf8.decode(base64Url.decode(folderKeyEncoded));
            final filesJson = utf8.decode(base64Url.decode(filesJsonEncoded));

            final files = (jsonDecode(filesJson) as List)
                .map(
                  (e) => {
                    'key': utf8.decode(base64Url.decode(e['key'])),
                    'url': utf8.decode(base64Url.decode(e['url'])),
                  },
                )
                .toList();

            return DownloadPage(folderKey: folderKey, files: files);
          },
        ),
      ],
    );

    return StoreProvider<AppState>(
      store: store,
      child: MaterialApp.router(
        title: 'R2 File Uploader',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(primarySwatch: Colors.blue),
        routerConfig: _router,
      ),
    );
  }
}
