import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/providers/download_provider.dart';
import 'core/providers/inference_provider.dart';
import 'core/services/inference_service.dart';
import 'features/setup/download_screen.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MarsApp(),
    ),
  );
}

class MarsApp extends StatelessWidget {
  const MarsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mars',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const _StartupRouter(),
      routes: {
        '/home': (_) => const _PlaceholderHome(),
      },
    );
  }
}

// Decides which screen to show on cold start:
// - Model not downloaded → DownloadScreen
// - Model downloaded but not loaded → loads engine, then home
// - Model loaded → home
class _StartupRouter extends ConsumerWidget {
  const _StartupRouter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modelDownloaded = ref.watch(modelDownloadedProvider);

    return modelDownloaded.when(
      loading: () => const _SplashScreen(),
      error: (e, st) => const DownloadScreen(),
      data: (isDownloaded) {
        if (!isDownloaded) return const DownloadScreen();
        return const _ModelLoaderGate();
      },
    );
  }
}

// When the file exists on disk, this widget triggers the engine load
// and shows a loading indicator until the model is in memory.
class _ModelLoaderGate extends ConsumerWidget {
  const _ModelLoaderGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loaderState = ref.watch(modelLoaderProvider);

    // Trigger load on first build if not already started.
    ref.listen(modelLoaderProvider, (_, next) {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (loaderState.valueOrNull == InferenceStatus.unloaded) {
        ref.read(modelLoaderProvider.notifier).loadModel();
      }
    });

    return loaderState.when(
      loading: () => const _SplashScreen(message: 'Loading AI engine…'),
      error: (e, _) => _ErrorScreen(message: e.toString()),
      data: (status) {
        if (status == InferenceStatus.ready) {
          return const _PlaceholderHome();
        }
        if (status == InferenceStatus.loading) {
          return const _SplashScreen(message: 'Loading AI engine…');
        }
        if (status == InferenceStatus.error) {
          return const _ErrorScreen(message: 'Failed to load model.');
        }
        return const _SplashScreen();
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  final String message;
  const _SplashScreen({this.message = 'Starting Mars…'});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(message, style: const TextStyle(color: Colors.white54, fontSize: 15)),
          ],
        ),
      ),
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  final String message;
  const _ErrorScreen({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            message,
            style: TextStyle(color: Colors.red.shade400, fontSize: 15),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

// Placeholder — replaced in Step 4 with the real agent home screen.
class _PlaceholderHome extends StatelessWidget {
  const _PlaceholderHome();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0D0D0D),
      body: Center(
        child: Text(
          'Mars — AI engine ready',
          style: TextStyle(color: Colors.white70, fontSize: 18),
        ),
      ),
    );
  }
}
