import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

/// Vosk small-model URLs indexed by BCP-47 language code.
/// All models are <100 MB and work 100% offline after first download.
const Map<String, String> kVoskModelUrls = {
  'en': 'https://alphacephei.com/vosk/models/vosk-model-small-en-us-0.15.zip',
  'ar': 'https://alphacephei.com/vosk/models/vosk-model-ar-mgb2-0.4.zip',
  'fr': 'https://alphacephei.com/vosk/models/vosk-model-small-fr-0.22.zip',
  'es': 'https://alphacephei.com/vosk/models/vosk-model-small-es-0.42.zip',
  'de': 'https://alphacephei.com/vosk/models/vosk-model-small-de-0.15.zip',
  'zh': 'https://alphacephei.com/vosk/models/vosk-model-small-cn-0.22.zip',
  'ja': 'https://alphacephei.com/vosk/models/vosk-model-small-ja-0.22.zip',
  'ko': 'https://alphacephei.com/vosk/models/vosk-model-small-ko-0.22.zip',
  'hi': 'https://alphacephei.com/vosk/models/vosk-model-small-hi-0.22.zip',
  'pt': 'https://alphacephei.com/vosk/models/vosk-model-small-pt-0.3.zip',
  'ru': 'https://alphacephei.com/vosk/models/vosk-model-small-ru-0.22.zip',
  'tr': 'https://alphacephei.com/vosk/models/vosk-model-small-tr-0.3.zip',
  'it': 'https://alphacephei.com/vosk/models/vosk-model-small-it-0.22.zip',
  'nl': 'https://alphacephei.com/vosk/models/vosk-model-small-nl-0.22.zip',
};

/// Fallback to English if the requested language has no model.
const String _kFallbackLang = 'en';

/// Manages downloading and extracting Vosk speech-recognition models.
///
/// Each model is downloaded once and cached in the app's documents directory:
///   <appDocDir>/vosk_models/<lang>/   ← extracted model folder
///
/// Usage:
///   final path = await VoskModelService.instance.ensureModel('en');
///   // path is the directory that VoskFlutterPlugin.createModel() expects.
class VoskModelService {
  VoskModelService._();
  static final VoskModelService instance = VoskModelService._();

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(minutes: 10),
  ));

  /// Returns the extracted model directory path for [langCode].
  ///
  /// If the model is not yet on disk it is downloaded and extracted first.
  /// Progress is reported via the optional [onProgress] callback (0.0–1.0).
  ///
  /// Throws if no URL is registered for [langCode] and English also fails.
  Future<String> ensureModel(
    String langCode, {
    void Function(double progress)? onProgress,
  }) async {
    final code = kVoskModelUrls.containsKey(langCode) ? langCode : _kFallbackLang;
    final dir = await _modelDir(code);
    if (await _isExtracted(dir)) return dir.path;

    await _downloadAndExtract(code, dir, onProgress: onProgress);
    return dir.path;
  }

  /// Whether a Vosk model for [langCode] has already been downloaded.
  Future<bool> isModelReady(String langCode) async {
    final code = kVoskModelUrls.containsKey(langCode) ? langCode : _kFallbackLang;
    final dir = await _modelDir(code);
    return _isExtracted(dir);
  }

  // ── Private helpers ──────────────────────────────────────────────────────────

  /// App-private directory that will hold the extracted model files.
  Future<Directory> _modelDir(String langCode) async {
    final base = await getApplicationDocumentsDirectory();
    return Directory('${base.path}/vosk_models/$langCode');
  }

  /// A model is considered extracted when its directory exists and is non-empty.
  Future<bool> _isExtracted(Directory dir) async {
    if (!await dir.exists()) return false;
    final children = await dir.list().toList();
    return children.isNotEmpty;
  }

  Future<void> _downloadAndExtract(
    String langCode,
    Directory targetDir, {
    void Function(double progress)? onProgress,
  }) async {
    final url = kVoskModelUrls[langCode]!;
    final base = await getApplicationDocumentsDirectory();
    final zipPath = '${base.path}/vosk_models/$langCode.zip';
    final zipFile = File(zipPath);

    // ── 1. Download the zip (resume-capable) ──────────────────────────────────
    final alreadyBytes = zipFile.existsSync() ? zipFile.lengthSync() : 0;

    final options = Options(
      headers: alreadyBytes > 0 ? {'Range': 'bytes=$alreadyBytes-'} : null,
      responseType: ResponseType.stream,
    );

    final response = await _dio.get<ResponseBody>(url, options: options);

    final contentLength = int.tryParse(
          response.headers.value(Headers.contentLengthHeader) ?? '',
        ) ??
        0;
    final totalBytes = alreadyBytes > 0
        ? alreadyBytes + contentLength
        : contentLength;

    final raf = zipFile.openSync(mode: FileMode.append);
    int received = alreadyBytes;
    try {
      await for (final chunk in response.data!.stream) {
        raf.writeFromSync(chunk);
        received += chunk.length;
        if (totalBytes > 0) {
          onProgress?.call(received / totalBytes * 0.8); // 0–80 % = download
        }
      }
    } finally {
      raf.closeSync();
    }

    // ── 2. Extract the zip ────────────────────────────────────────────────────
    onProgress?.call(0.85);
    await targetDir.create(recursive: true);

    final inputStream = InputFileStream(zipPath);
    final archive = ZipDecoder().decodeBuffer(inputStream);

    // The zip contains a single top-level folder (e.g. vosk-model-small-en-us-0.15/).
    // Flatten it into targetDir so the path is predictable.
    for (final file in archive.files) {
      if (!file.isFile) continue;

      // Strip the leading directory component.
      final parts = file.name.split('/');
      final relPath = parts.length > 1 ? parts.sublist(1).join('/') : file.name;
      if (relPath.isEmpty) continue;

      final outFile = File('${targetDir.path}/$relPath');
      await outFile.parent.create(recursive: true);
      await outFile.writeAsBytes(file.content as List<int>);
    }

    inputStream.close();
    onProgress?.call(1.0);

    // Clean up the zip to save storage.
    if (zipFile.existsSync()) zipFile.deleteSync();
  }
}
