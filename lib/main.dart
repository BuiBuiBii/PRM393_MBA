import 'package:flutter/material.dart';

import 'app.dart';
import 'core/storage/token_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final tokenStorage = await createTokenStorage();

  runApp(AppBootstrap(tokenStorage: tokenStorage));
}
