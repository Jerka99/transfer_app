import 'package:async_redux/async_redux.dart';
import 'package:business/store/app_state.dart';
import 'package:business/store/app_store.dart';
import 'package:client/home/home_page_connector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'download/download_page.dart';

void main() {
  usePathUrlStrategy();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return StoreProvider<AppState>(
      store: store,
      child: MaterialApp(
        title: 'R2 File Uploader',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(primarySwatch: Colors.blue),
        initialRoute: '/',
        onGenerateRoute: (settings) {
          final uri = Uri.parse(settings.name ?? '/');

          if (uri.path == '/download') {
            final fileKey = uri.queryParameters['key'];
            final encodedUrl = uri.queryParameters['url'];

            if (fileKey != null && encodedUrl != null) {
              final decodedUrl = Uri.decodeComponent(encodedUrl);

              return MaterialPageRoute(
                settings: settings,
                builder: (_) => DownloadPage(fileKey: fileKey, url: decodedUrl),
              );
            }
          }

          return MaterialPageRoute(
            settings: settings,
            builder: (_) => const HomePageConnector(),
          );
        },
      ),
    );
  }
}
