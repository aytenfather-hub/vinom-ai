import 'package:fb_core/fb_core.dart';
import 'package:flutter/material.dart';

import 'src/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = FbConfig.fromEnvironment()..validate();
  final state = AppState(createRepository(config));
  await state.init();
  runApp(CustomerApp(state: state, config: config));
}
