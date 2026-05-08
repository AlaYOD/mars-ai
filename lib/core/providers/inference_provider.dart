import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/inference_service.dart';
import 'download_provider.dart';

final inferenceServiceProvider = Provider<InferenceService>((ref) {
  final storage = ref.read(modelStorageServiceProvider);
  final service = InferenceService(storage);
  // Dispose the engine when the provider is destroyed (app shutdown).
  ref.onDispose(service.dispose);
  return service;
});

// Notifier that owns the model loading lifecycle.
// Widgets watch this to know: is the AI engine ready to answer questions?
class ModelLoaderNotifier extends AsyncNotifier<InferenceStatus> {
  @override
  Future<InferenceStatus> build() async {
    final service = ref.read(inferenceServiceProvider);
    // Don't auto-load on startup — wait for explicit call after download check.
    return service.status;
  }

  Future<void> loadModel() async {
    state = const AsyncLoading();
    final service = ref.read(inferenceServiceProvider);
    state = await AsyncValue.guard(() async {
      await service.loadModel();
      return service.status;
    });
  }
}

final modelLoaderProvider =
    AsyncNotifierProvider<ModelLoaderNotifier, InferenceStatus>(
  ModelLoaderNotifier.new,
);
