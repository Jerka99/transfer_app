import 'dart:convert';

import 'package:async_redux/async_redux.dart';
import 'package:business/store/app_state.dart';
import 'package:business/store/app_store.dart';
import 'package:client/home/home_page_connector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'download/download_page.dart';
import 'download/link_expired_view.dart';

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
            try {
              final folderEncoded = state.uri.queryParameters['folder'];
              final filesEncoded = state.uri.queryParameters['files'];

              if (folderEncoded == null || filesEncoded == null)
                return const LinkExpiredView();

              final folderKey = utf8.decode(base64Url.decode(folderEncoded));
              final filesJsonString = utf8.decode(
                base64Url.decode(filesEncoded),
              );

              final List rawFiles = jsonDecode(filesJsonString);

              final files = rawFiles.map<Map<String, String>>((e) {
                return {
                  'key': utf8.decode(base64Url.decode(e['key'] as String)),
                  'url': utf8.decode(base64Url.decode(e['url'] as String)),
                };
              }).toList();

              return DownloadPage(folderKey: folderKey, files: files);
            } catch (e, st) {
              debugPrint(' Failed to parse download-folder link: $e');
              debugPrintStack(stackTrace: st);
              return const LinkExpiredView();
            }
          },
        ),
        GoRoute(
          path: '/expired',
          builder: (context, state) => const LinkExpiredView(),
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
