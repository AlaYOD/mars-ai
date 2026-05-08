import 'dart:io';
import 'package:dio/dio.dart';
import 'model_storage_service.dart';

enum DownloadStatus { idle, downloading, paused, completed, error }

class DownloadState {
  final DownloadStatus status;
  final double progress; // 0.0 to 1.0
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

  /// Downloads the model with full resume support.
  ///
  /// How it works:
  /// 1. Reads how many bytes are already in the .tmp file.
  /// 2. Sends `Range: bytes=X-` so the server starts from byte X, not byte 0.
  /// 3. Opens the .tmp file in FileMode.append — new bytes are added after the
  ///    existing ones, nothing is overwritten.
  /// 4. On completion, renames .tmp → final file atomically.
  /// 5. On pause/error, the .tmp file is left untouched for the next resume.
  Stream<DownloadState> download(String url) async* {
    _cancelToken = CancelToken();

    final finalPath = await _storage.modelFilePath;
    final tmpPath = await _storage.tempFilePath;
    final tmpFile = File(tmpPath);

    // If the final file already exists and is complete, nothing to do.
    if (await _storage.isModelDownloaded()) {
      yield const DownloadState(
        status: DownloadStatus.completed,
        progress: 1.0,
      );
      return;
    }

    // How many bytes did we download in a previous (interrupted) session?
    final alreadyDownloaded = await _storage.getDownloadedTempBytes();

    yield DownloadState(
      status: DownloadStatus.downloading,
      downloadedBytes: alreadyDownloaded,
    );

    RandomAccessFile? raf;

    try {
      // Ask the server for the full file size first (HEAD request).
      final headResponse = await _dio.head(url, cancelToken: _cancelToken);
      final totalBytes = int.tryParse(
            headResponse.headers.value(Headers.contentLengthHeader) ?? '',
          ) ??
          0;

      // If .tmp already equals full size, just rename it — no download needed.
      if (alreadyDownloaded > 0 && alreadyDownloaded == totalBytes) {
        tmpFile.renameSync(finalPath);
        yield DownloadState(
          status: DownloadStatus.completed,
          progress: 1.0,
          downloadedBytes: totalBytes,
          totalBytes: totalBytes,
        );
        return;
      }

      // Build the Range header. If alreadyDownloaded == 0, no header needed.
      final options = Options(
        headers: alreadyDownloaded > 0
            ? {'Range': 'bytes=$alreadyDownloaded-'}
            : null,
        responseType: ResponseType.stream,
      );

      final response = await _dio.get<ResponseBody>(
        url,
        options: options,
        cancelToken: _cancelToken,
      );

      // Server responds 206 Partial Content when it honours the Range header.
      // Content-Length in a 206 response = remaining bytes, not the full file.
      // Total = what we already have + what the server is about to send.
      final remainingBytes = int.tryParse(
            response.headers.value(Headers.contentLengthHeader) ?? '',
          ) ??
          0;
      final knownTotal = alreadyDownloaded > 0
          ? alreadyDownloaded + remainingBytes
          : (totalBytes > 0 ? totalBytes : remainingBytes);

      // Open .tmp in append mode — existing bytes are preserved.
      raf = tmpFile.openSync(mode: FileMode.append);

      int received = alreadyDownloaded;

      await for (final chunk in response.data!.stream) {
        raf.writeFromSync(chunk);
        received += chunk.length;
        final progress = knownTotal > 0 ? received / knownTotal : 0.0;
        yield DownloadState(
          status: DownloadStatus.downloading,
          progress: progress,
          downloadedBytes: received,
          totalBytes: knownTotal,
        );
      }

      raf.closeSync();
      raf = null;

      // Atomic rename: .tmp → final. Only happens after every byte is written.
      tmpFile.renameSync(finalPath);

      yield DownloadState(
        status: DownloadStatus.completed,
        progress: 1.0,
        downloadedBytes: received,
        totalBytes: knownTotal,
      );
    } on DioException catch (e) {
      raf?.closeSync();
      if (CancelToken.isCancel(e)) {
        // .tmp is kept intact — next call to download() will resume from here.
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
    } catch (e) {
      raf?.closeSync();
      yield DownloadState(
        status: DownloadStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void pause() => _cancelToken?.cancel('User paused download');
}
