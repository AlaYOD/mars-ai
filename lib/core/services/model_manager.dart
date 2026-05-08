import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class ModelManager {
  final String modelUrl =
      'https://huggingface.co/PSIteam/gemma-4-E2B-it/resolve/main/gemma-4-E2B-it.litertlm?download=true';
  final String fileName = 'gemma-4-E2B-it.litertlm';

  Future<void> downloadModel(
    void Function(double progress) onProgressUpdate,
  ) async {
    final Directory dir = await getApplicationDocumentsDirectory();
    final String finalPath = '${dir.path}/$fileName';
    final String tempPath = '$finalPath.tmp';

    // Already fully downloaded — nothing to do.
    if (File(finalPath).existsSync()) {
      onProgressUpdate(1.0);
      return;
    }

    final Dio dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(minutes: 30),
    ));

    final File tmpFile = File(tempPath);

    // How many bytes did a previous interrupted download save?
    final int alreadyDownloaded =
        tmpFile.existsSync() ? tmpFile.lengthSync() : 0;

    // Ask the server for total file size.
    final headResponse = await dio.head(modelUrl);
    final int totalBytes = int.tryParse(
          headResponse.headers.value(Headers.contentLengthHeader) ?? '',
        ) ??
        0;

    // .tmp already complete — just rename it.
    if (alreadyDownloaded > 0 && alreadyDownloaded == totalBytes) {
      tmpFile.renameSync(finalPath);
      onProgressUpdate(1.0);
      return;
    }

    // Range header: tell the server "start from byte X, not byte 0".
    // Hugging Face supports this and responds with HTTP 206 Partial Content.
    final options = Options(
      headers: alreadyDownloaded > 0
          ? {'Range': 'bytes=$alreadyDownloaded-'}
          : null,
      responseType: ResponseType.stream,
    );

    final response = await dio.get<ResponseBody>(modelUrl, options: options);

    // In a 206 response, Content-Length = remaining bytes only.
    // Reconstruct the true total from what we already had.
    final int remaining = int.tryParse(
          response.headers.value(Headers.contentLengthHeader) ?? '',
        ) ??
        0;
    final int knownTotal = alreadyDownloaded > 0
        ? alreadyDownloaded + remaining
        : (totalBytes > 0 ? totalBytes : remaining);

    // Append mode: new bytes are added after existing bytes, not overwriting.
    final RandomAccessFile raf = tmpFile.openSync(mode: FileMode.append);
    int received = alreadyDownloaded;

    try {
      await for (final chunk in response.data!.stream) {
        raf.writeFromSync(chunk);
        received += chunk.length;
        if (knownTotal > 0) onProgressUpdate(received / knownTotal);
      }
    } finally {
      raf.closeSync();
    }

    // Atomic rename — only happens after every byte is written successfully.
    tmpFile.renameSync(finalPath);
    onProgressUpdate(1.0);
  }

  Future<String?> getModelPath() async {
    final Directory dir = await getApplicationDocumentsDirectory();
    final String path = '${dir.path}/$fileName';
    return File(path).existsSync() ? path : null;
  }
}
