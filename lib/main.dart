import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/api_client.dart';
import 'data/cloud_sync.dart';
import 'data/water_store.dart';
import 'screens/home_shell.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppTheme.registerFontLicenses();

  // Never throws: if Firebase isn't configured yet the app still works offline.
  final cloud = CloudSync();
  await cloud.init();

  final notifications = NotificationService();
  await notifications.init();

  final store = WaterStore(cloud: cloud, notifications: notifications);
  await store.load();

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: store),
      Provider.value(value: ApiClient()),
    ],
    child: const H2GoApp(),
  ));
}

class H2GoApp extends StatelessWidget {
  const H2GoApp({super.key, this.showSplash = true});

  /// Off in tests that want to start on the home screen.
  final bool showSplash;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'H2Go',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: showSplash
          ? SplashScreen(next: (_) => const HomeShell())
          : const HomeShell(),
    );
  }
}
