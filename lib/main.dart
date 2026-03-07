import 'dart:convert';
import 'package:flutter/material.dart';
import 'app.dart';
import 'package:app_project/core/network/api_client.dart';
import 'package:app_project/core/socket/global_socket_manager.dart';

/// 🔥 Global Navigator Key
final GlobalKey<NavigatorState> appNavigatorKey =
    GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _initSocket();

  runApp(const MyApp());
}

Future<void> _initSocket() async {
  final token = await ApiClient.getToken();

  if (token == null) return;

  final payload = jsonDecode(
    utf8.decode(
      base64Url.decode(
        base64Url.normalize(token.split(".")[1]),
      ),
    ),
  );

  final userId = payload["id"];

  await GlobalSocketManager.instance.init(userId);
}
