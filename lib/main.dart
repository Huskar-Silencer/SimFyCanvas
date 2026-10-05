import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/state/providers.dart';
import 'src/widgets/common.dart';
import 'src/widgets/editor_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final container = ProviderContainer();
  await container.read(draftAutosaveProvider).restore();
  runApp(
    UncontrolledProviderScope(container: container, child: const MainApp()),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SimFyCanvas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.accent,
          brightness: Brightness.light,
        ),
        sliderTheme: const SliderThemeData(
          overlayShape: RoundSliderOverlayShape(overlayRadius: 12),
        ),
      ),
      home: const EditorShell(),
    );
  }
}
