import 'dart:io';
import 'package:dio/dio.dart';
import 'model_storage_service.dart';

enum DownloadStatus { idle, downloading, paused, completed, error }

class DownloadState {
  final DownloadStatus status;
  final double progress;      // 0.0 to 1.0
  final int downloadedBytes;
  final int totalBytes;
  final String? errorMessage;

  const DownloadState({
    required this.status,
    this.progress = 0.0,
    this.downloadedBytes = 0,
    this.totalBytes = 0,
    this.errorMessage,
  });

  DownloadState copyWith({
    DownloadStatus? status,
    double? progress,
    int? downloadedBytes,
    int? totalBytes,
    String? errorMessage,
  }) {
    return DownloadState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      errorMessage: errorMessage,
    );
  }
}

class ModelDownloadService {
  final ModelStorageService _storage;
  final Dio _dio;
  CancelToken? _cancelToken;

  ModelDownloadService(this._storage)
      : _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(minutes: 30),
        ));

  // Downloads with resume support: sends Range header if partial file exists.
  Stream<DownloadState> download(String url) async* {
    _cancelToken = CancelToken();

    final filePath = await _storage.modelFilePath;
    final file = File(filePath);
    final alreadyDownloaded = await _storage.getDownloadedBytes();

    yield DownloadState(
      status: DownloadStatus.downloading,
      downloadedBytes: alreadyDownloaded,
    );

    try {
      final response = await _dio.head(url, cancelToken: _cancelToken);
      final totalBytes = int.tryParse(
            response.headers.value(Headers.contentLengthHeader) ?? '',
          ) ??
          0;

      if (alreadyDownloaded > 0 && alreadyDownloaded == totalBytes) {
        yield DownloadState(
          status: DownloadStatus.completed,
          progress: 1.0,
          downloadedBytes: totalBytes,
          totalBytes: totalBytes,
        );
        return;
      }

      final options = Options(
        headers: alreadyDownloaded > 0
            ? {'Range': 'bytes=$alreadyDownloaded-'}
            : null,
        responseType: ResponseType.stream,
      );

      final streamResponse = await _dio.get<ResponseBody>(
        url,
        options: options,
        cancelToken: _cancelToken,
      );

      final sink = file.openWrite(
        mode: alreadyDownloaded > 0 ? FileMode.append : FileMode.write,
      );

      int received = alreadyDownloaded;

      await for (final chunk in streamResponse.data!.stream) {
        sink.add(chunk);
        received += chunk.length;
        final progress = totalBytes > 0 ? received / totalBytes : 0.0;
        yield DownloadState(
          status: DownloadStatus.downloading,
          progress: progress,
          downloadedBytes: received,
          totalBytes: totalBytes,
        );
      }

      await sink.close();

      yield DownloadState(
        status: DownloadStatus.completed,
        progress: 1.0,
        downloadedBytes: received,
        totalBytes: totalBytes,
      );
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        yield DownloadState(
          status: DownloadStatus.paused,
          downloadedBytes: alreadyDownloaded,
        );
      } else {
        yield DownloadState(
          status: DownloadStatus.error,
          errorMessage: e.message ?? 'Download failed',
        );
      }
    }
  }

  void pause() => _cancelToken?.cancel('User paused download');
}
