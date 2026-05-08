import 'dart:io';
import 'package:path_provider/path_provider.dart';

class ModelStorageService {
  static const String _modelFileName = 'gemma-4-E2B-it.litertlm';

  Future<String> get modelDirectory async {
    final appDir = await getApplicationDocumentsDirectory();
    return appDir.path;
  }

  // Path of the completed, ready-to-use model file.
  Future<String> get modelFilePath async {
    final dir = await modelDirectory;
    return '$dir/$_modelFileName';
  }

  // Path of the in-progress download. Written during download, renamed to
  // modelFilePath only when the download completes successfully.
  // This guarantees the final file is never left in a corrupt half-written state.
  Future<String> get tempFilePath async {
    final path = await modelFilePath;
    return '$path.tmp';
  }

  Future<bool> isModelDownloaded() async {
    final path = await modelFilePath;
    final file = File(path);
    return file.existsSync() && await file.length() > 0;
  }

  // Returns how many bytes of the .tmp file already exist on disk.
  // Used to build the Range header: "bytes=X-"
  Future<int> getDownloadedTempBytes() async {
    final path = await tempFilePath;
    final file = File(path);
    if (!file.existsSync()) return 0;
    return await file.length();
  }

  Future<void> deleteModel() async {
    final finalPath = await modelFilePath;
    final tmpPath = await tempFilePath;
    for (final path in [finalPath, tmpPath]) {
      final f = File(path);
      if (f.existsSync()) await f.delete();
    }
  }
}
