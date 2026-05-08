import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/model_storage_service.dart';
import '../services/model_download_service.dart';

final modelStorageServiceProvider = Provider<ModelStorageService>(
  (_) => ModelStorageService(),
);

final modelDownloadServiceProvider = Provider<ModelDownloadService>((ref) {
  final storage = ref.read(modelStorageServiceProvider);
  return ModelDownloadService(storage);
});

final modelDownloadedProvider = FutureProvider<bool>((ref) async {
  final storage = ref.read(modelStorageServiceProvider);
  return storage.isModelDownloaded();
});

// Tracks live download state during an active download session.
final downloadStateProvider =
    StateProvider<DownloadState>((ref) => const DownloadState(status: DownloadStatus.idle));
