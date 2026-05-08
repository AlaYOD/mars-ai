import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/inference_provider.dart';
import '../../core/services/model_manager.dart';

class DownloadScreen extends ConsumerStatefulWidget {
  const DownloadScreen({super.key});

  @override
  ConsumerState<DownloadScreen> createState() => _DownloadScreenState();
}

enum ScreenStatus { idle, downloading, completed, error }

class _DownloadScreenState extends ConsumerState<DownloadScreen> {
  final ModelManager _modelManager = ModelManager();
  
  ScreenStatus _status = ScreenStatus.idle;
  double _progress = 0.0;
  String? _errorMessage;

  void _startDownload() async {
    if (_status == ScreenStatus.downloading) return;
    
    setState(() {
      _status = ScreenStatus.downloading;
      _errorMessage = null;
      _progress = 0.0;
    });

    try {
      await _modelManager.downloadModel((progress) {
        setState(() {
          _progress = progress;
        });
      });
      
      setState(() {
        _status = ScreenStatus.completed;
        _progress = 1.0;
      });
      
      // Model is on disk — now load it into the inference engine.
      ref.read(modelLoaderProvider.notifier).loadModel();
      
    } catch (e) {
      setState(() {
        _status = ScreenStatus.error;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final modelLoader = ref.watch(modelLoaderProvider);

    // Once the engine is ready, hand off to the main app.
    if (modelLoader.valueOrNull == InferenceStatus.ready) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              _Header(status: _status, modelLoader: modelLoader),
              const SizedBox(height: 48),
              _ProgressSection(status: _status, progress: _progress, errorMessage: _errorMessage),
              const SizedBox(height: 32),
              _ActionButton(
                status: _status,
                modelLoader: modelLoader,
                onStart: _startDownload,
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final ScreenStatus status;
  final AsyncValue<InferenceStatus> modelLoader;

  const _Header({required this.status, required this.modelLoader});

  @override
  Widget build(BuildContext context) {
    final String title;
    final String subtitle;

    if (modelLoader.isLoading || modelLoader.valueOrNull == InferenceStatus.loading) {
      title = 'Preparing AI Engine';
      subtitle = 'Loading model into memory…';
    } else if (status == ScreenStatus.completed) {
      title = 'Download Complete';
      subtitle = 'Initializing the AI engine…';
    } else if (status == ScreenStatus.downloading) {
      title = 'Downloading AI Model';
      subtitle = 'Please connect to Wi-Fi. Downloading your smart assistant to work offline.';
    } else if (status == ScreenStatus.error) {
      title = 'Download Failed';
      subtitle = 'Check your connection and try again.';
    } else {
      title = 'One-time Setup';
      subtitle = 'Mars needs to download the AI model (~2 GB).\nThis happens once. The model runs fully offline after this.';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          subtitle,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 15,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _ProgressSection extends StatelessWidget {
  final ScreenStatus status;
  final double progress;
  final String? errorMessage;

  const _ProgressSection({
    required this.status,
    required this.progress,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = status == ScreenStatus.downloading || status == ScreenStatus.completed;

    if (!isActive && status == ScreenStatus.idle) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress > 0 ? progress : null,
            minHeight: 6,
            backgroundColor: Colors.white12,
            valueColor: AlwaysStoppedAnimation<Color>(
              status == ScreenStatus.error
                  ? Colors.red.shade400
                  : Colors.deepPurple.shade300,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (progress > 0)
              Text(
                '${(progress * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  color: Colors.deepPurple.shade300,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            errorMessage!,
            style: TextStyle(color: Colors.red.shade400, fontSize: 13),
          ),
        ],
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final ScreenStatus status;
  final AsyncValue<InferenceStatus> modelLoader;
  final VoidCallback onStart;

  const _ActionButton({
    required this.status,
    required this.modelLoader,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final isLoading = modelLoader.isLoading || modelLoader.valueOrNull == InferenceStatus.loading;

    if (isLoading || status == ScreenStatus.completed) {
      return const Center(child: CircularProgressIndicator());
    }

    if (status == ScreenStatus.error) {
      return _button('Retry Download', onStart, Colors.red.shade700);
    }

    if (status == ScreenStatus.downloading) {
      return _button('Downloading...', () {}, Colors.deepPurple.withValues(alpha: 0.5));
    }

    return _button('Download Model (~2 GB)', onStart, Colors.deepPurple);
  }

  Widget _button(String label, VoidCallback onTap, Color color) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
