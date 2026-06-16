import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'services/purchase_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  // Start the app immediately; billing initializes in the background so a
  // billing hiccup can never block or crash launch.
  runApp(const TikbooApp());
  PurchaseService.instance.init();
}

class TikbooApp extends StatelessWidget {
  const TikbooApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'tikboo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const HomeScreen(),
    );
  }
}
