import 'package:flutter/material.dart';
import 'app.dart';

/// 🔥 Global Navigator Key
final GlobalKey<NavigatorState> appNavigatorKey =
    GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}
