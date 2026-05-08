import 'dart:io';
import 'package:path_provider/path_provider.dart';

class ModelStorageService {
  static const String _modelFileName = 'gemma-4-E2B-it.litert.lm';

  Future<String> get modelDirectory async {
    final appDir = await getApplicationSupportDirectory();
    final modelsDir = Directory('${appDir.path}/models');
    if (!modelsDir.existsSync()) {
      await modelsDir.create(recursive: true);
    }
    return modelsDir.path;
  }

  Future<String> get modelFilePath async {
    final dir = await modelDirectory;
    return '$dir/$_modelFileName';
  }

  Future<bool> isModelDownloaded() async {
    final path = await modelFilePath;
    final file = File(path);
    return file.existsSync() && await file.length() > 0;
  }

  Future<int> getDownloadedBytes() async {
    final path = await modelFilePath;
    final file = File(path);
    if (!file.existsSync()) return 0;
    return await file.length();
  }

  Future<void> deleteModel() async {
    final path = await modelFilePath;
    final file = File(path);
    if (file.existsSync()) await file.delete();
  }
}
