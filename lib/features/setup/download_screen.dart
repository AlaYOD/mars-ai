import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/download_provider.dart';
import '../../core/providers/inference_provider.dart';
import '../../core/services/inference_service.dart';
import '../../core/services/model_download_service.dart';

// TODO: Replace with your actual Hugging Face / GCS model URL
const _modelUrl =
    'https://huggingface.co/google/gemma-4-E2B-it-litert/resolve/main/gemma-4-E2B-it.litert.lm';

class DownloadScreen extends ConsumerStatefulWidget {
  const DownloadScreen({super.key});

  @override
  ConsumerState<DownloadScreen> createState() => _DownloadScreenState();
}

class _DownloadScreenState extends ConsumerState<DownloadScreen> {
  bool _downloadStarted = false;

  void _startDownload() {
    if (_downloadStarted) return;
    setState(() => _downloadStarted = true);

    final service = ref.read(modelDownloadServiceProvider);
    final stream = service.download(_modelUrl);

    stream.listen(
      (state) {
        ref.read(downloadStateProvider.notifier).state = state;

        if (state.status == DownloadStatus.completed) {
          // Model is on disk — now load it into the inference engine.
          ref.read(modelLoaderProvider.notifier).loadModel();
        }
      },
      onError: (_) {
        setState(() => _downloadStarted = false);
      },
    );
  }

  void _pauseDownload() {
    ref.read(modelDownloadServiceProvider).pause();
    setState(() => _downloadStarted = false);
  }

  @override
  Widget build(BuildContext context) {
    final downloadState = ref.watch(downloadStateProvider);
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
              _Header(status: downloadState.status, modelLoader: modelLoader),
              const SizedBox(height: 48),
              _ProgressSection(state: downloadState),
              const SizedBox(height: 32),
              _ActionButton(
                downloadState: downloadState,
                modelLoader: modelLoader,
                downloadStarted: _downloadStarted,
                onStart: _startDownload,
                onPause: _pauseDownload,
                onRetry: () {
                  setState(() => _downloadStarted = false);
                  _startDownload();
                },
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
  final DownloadStatus status;
  final AsyncValue<InferenceStatus> modelLoader;

  const _Header({required this.status, required this.modelLoader});

  @override
  Widget build(BuildContext context) {
    final String title;
    final String subtitle;

    if (modelLoader.isLoading ||
        modelLoader.valueOrNull == InferenceStatus.loading) {
      title = 'Preparing AI Engine';
      subtitle = 'Loading model into memory…';
    } else if (status == DownloadStatus.completed) {
      title = 'Download Complete';
      subtitle = 'Initializing the AI engine…';
    } else if (status == DownloadStatus.downloading) {
      title = 'Downloading AI Model';
      subtitle = 'Gemma 4 E2B — ~2 GB\nKeep the app open for faster download.';
    } else if (status == DownloadStatus.error) {
      title = 'Download Failed';
      subtitle = 'Check your connection and try again.';
    } else {
      title = 'One-time Setup';
      subtitle =
          'Mars needs to download the AI model (~2 GB).\nThis happens once. The model runs fully offline after this.';
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
  final DownloadState state;

  const _ProgressSection({required this.state});

  String _formatBytes(int bytes) {
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  @override
  Widget build(BuildContext context) {
    final isActive = state.status == DownloadStatus.downloading ||
        state.status == DownloadStatus.completed;

    if (!isActive && state.status == DownloadStatus.idle) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: state.progress > 0 ? state.progress : null,
            minHeight: 6,
            backgroundColor: Colors.white12,
            valueColor: AlwaysStoppedAnimation<Color>(
              state.status == DownloadStatus.error
                  ? Colors.red.shade400
                  : Colors.deepPurple.shade300,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              state.totalBytes > 0
                  ? '${_formatBytes(state.downloadedBytes)} / ${_formatBytes(state.totalBytes)}'
                  : _formatBytes(state.downloadedBytes),
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
            ),
            if (state.progress > 0)
              Text(
                '${(state.progress * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  color: Colors.deepPurple.shade300,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        if (state.errorMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            state.errorMessage!,
            style: TextStyle(color: Colors.red.shade400, fontSize: 13),
          ),
        ],
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final DownloadState downloadState;
  final AsyncValue<InferenceStatus> modelLoader;
  final bool downloadStarted;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onRetry;

  const _ActionButton({
    required this.downloadState,
    required this.modelLoader,
    required this.downloadStarted,
    required this.onStart,
    required this.onPause,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isLoading = modelLoader.isLoading ||
        modelLoader.valueOrNull == InferenceStatus.loading;

    if (isLoading || downloadState.status == DownloadStatus.completed) {
      return const Center(child: CircularProgressIndicator());
    }

    if (downloadState.status == DownloadStatus.error) {
      return _button('Retry Download', onRetry, Colors.red.shade700);
    }

    if (downloadStarted && downloadState.status == DownloadStatus.downloading) {
      return _button('Pause Download', onPause, Colors.orange.shade800);
    }

    if (downloadState.status == DownloadStatus.paused) {
      return _button('Resume Download', onStart, Colors.deepPurple);
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
