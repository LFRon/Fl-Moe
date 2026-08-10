import 'package:flutter/material.dart';

import 'app/app_dependencies.dart';
import 'app/fl_moe_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final dependencies = await AppDependencies.initialize().timeout(
      const Duration(seconds: 12),
    );
    runApp(FlMoeApp(dependencies: dependencies));
  } on Object catch (error) {
    runApp(FlMoeInitializationFailureApp(error: error));
  }
}
