import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/download_provider.dart';
import '../../core/providers/inference_provider.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/services/inference_service.dart';
import '../../core/services/model_download_service.dart';

// Hugging Face URL for the Gemma model.
const _kModelUrl =
    'https://huggingface.co/PSIteam/gemma-4-E2B-it/resolve/main/gemma-4-E2B-it.litertlm?download=true';

class DownloadScreen extends ConsumerStatefulWidget {
  const DownloadScreen({super.key});

  @override
  ConsumerState<DownloadScreen> createState() => _DownloadScreenState();
}

class _DownloadScreenState extends ConsumerState<DownloadScreen> {
  void _startDownload() {
    final downloadService = ref.read(modelDownloadServiceProvider);
    final downloadState = ref.read(downloadStateProvider.notifier);

    if (ref.read(downloadStateProvider).status == DownloadStatus.downloading) {
      return;
    }

    downloadState.state = const DownloadState(status: DownloadStatus.downloading);

    downloadService.download(_kModelUrl).listen(
      (state) {
        ref.read(downloadStateProvider.notifier).state = state;

        if (state.status == DownloadStatus.completed) {
          // Model is on disk — now load it into the inference engine.
          ref.read(modelLoaderProvider.notifier).loadModel();
        }
      },
      onError: (e) {
        ref.read(downloadStateProvider.notifier).state = DownloadState(
          status: DownloadStatus.error,
          errorMessage: e.toString(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final modelLoader = ref.watch(modelLoaderProvider);
    final download = ref.watch(downloadStateProvider);
    final l10n = ref.watch(localizationProvider);

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
      body: Directionality(
        textDirection: l10n.textDirection,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),
                _Header(download: download, modelLoader: modelLoader),
                const SizedBox(height: 48),
                _ProgressSection(download: download),
                const SizedBox(height: 32),
                _ActionButton(
                  download: download,
                  modelLoader: modelLoader,
                  onStart: _startDownload,
                ),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  final DownloadState download;
  final AsyncValue<InferenceStatus> modelLoader;

  const _Header({required this.download, required this.modelLoader});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localizationProvider);
    final String title;
    final String subtitle;

    if (modelLoader.isLoading || modelLoader.valueOrNull == InferenceStatus.loading) {
      title = l10n.translate('download_title_prep_engine');
      subtitle = l10n.translate('download_subtitle_prep_engine');
    } else if (download.status == DownloadStatus.completed) {
      title = l10n.translate('download_title_complete');
      subtitle = l10n.translate('download_subtitle_complete');
    } else if (download.status == DownloadStatus.downloading) {
      title = l10n.translate('download_title_active');
      subtitle = l10n.translate('download_subtitle_active');
    } else if (download.status == DownloadStatus.error) {
      title = l10n.translate('download_title_error');
      subtitle = l10n.translate('download_subtitle_error');
    } else {
      title = l10n.translate('download_title_setup');
      subtitle = l10n.translate('download_subtitle_setup');
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
  final DownloadState download;

  const _ProgressSection({required this.download});

  @override
  Widget build(BuildContext context) {
    if (download.status == DownloadStatus.idle) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: download.progress > 0 ? download.progress : null,
            minHeight: 6,
            backgroundColor: Colors.white12,
            valueColor: AlwaysStoppedAnimation<Color>(
              download.status == DownloadStatus.error
                  ? Colors.red.shade400
                  : Colors.deepPurple.shade300,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (download.progress > 0)
              Text(
                '${(download.progress * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  color: Colors.deepPurple.shade300,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        if (download.errorMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            download.errorMessage!,
            style: TextStyle(color: Colors.red.shade400, fontSize: 13),
          ),
        ],
      ],
    );
  }
}

class _ActionButton extends ConsumerWidget {
  final DownloadState download;
  final AsyncValue<InferenceStatus> modelLoader;
  final VoidCallback onStart;

  const _ActionButton({
    required this.download,
    required this.modelLoader,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localizationProvider);
    final isLoading =
        modelLoader.isLoading || modelLoader.valueOrNull == InferenceStatus.loading;

    if (isLoading || download.status == DownloadStatus.completed) {
      return const Center(child: CircularProgressIndicator());
    }

    if (download.status == DownloadStatus.error) {
      return _button(l10n.translate('download_btn_retry'), onStart, Colors.red.shade700);
    }

    if (download.status == DownloadStatus.downloading) {
      return _button(
        l10n.translate('download_btn_active'),
        () {},
        Colors.deepPurple.withValues(alpha: 0.5),
      );
    }

    return _button(l10n.translate('download_btn_start'), onStart, Colors.deepPurple);
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
