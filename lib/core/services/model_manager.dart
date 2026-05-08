import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class ModelManager {
  // 1. ضع رابط Hugging Face المباشر هنا
  final String modelUrl = "https://huggingface.co/PSIteam/gemma-4-E2B-it/resolve/main/gemma-4-E2B-it.litertlm?download=true";
  final String fileName = "gemma-4-E2B-it.litertlm";

  // 2. دالة التنزيل مع متابعة التقدم (Progress)
  Future<void> downloadModel(Function(double progress) onProgressUpdate) async {
    try {
      // الوصول للمجلد الآمن والمخفي في الهاتف
      final Directory dir = await getApplicationDocumentsDirectory();
      final String finalPath = '${dir.path}/$fileName';
      final String tempPath = '${dir.path}/$fileName.tmp'; // الملف المؤقت

      // التحقق مما إذا كان الموديل موجوداً بالفعل
      if (File(finalPath).existsSync()) {
        print("الموديل موجود بالفعل. لا حاجة للتنزيل.");
        onProgressUpdate(1.0); // 100%
        return;
      }

      final Dio dio = Dio();

      print("بدء تنزيل العقل الذكي...");

      // 3. بدء التنزيل باستخدام Dio
      await dio.download(
        modelUrl,
        tempPath, // نحفظه كملف مؤقت أولاً
        onReceiveProgress: (receivedBytes, totalBytes) {
          if (totalBytes != -1) {
            // حساب النسبة المئوية (من 0.0 إلى 1.0) لتشغيل شريط التقدم في الواجهة
            double progress = receivedBytes / totalBytes;
            onProgressUpdate(progress);
          }
        },
      );

      // 4. خطوة الأمان: تحويل الملف المؤقت إلى الملف النهائي بعد نجاح التنزيل
      File(tempPath).renameSync(finalPath);
      print("تم تنزيل الموديل وحفظه بنجاح في: $finalPath");

    } catch (e) {
      print("حدث خطأ أثناء التنزيل: $e");
      throw Exception("فشل تنزيل الموديل، يرجى التحقق من اتصال الإنترنت.");
    }
  }

  // دالة مساعدة للحصول على مسار الموديل لتشغيله لاحقاً
  Future<String?> getModelPath() async {
    final Directory dir = await getApplicationDocumentsDirectory();
    final String path = '${dir.path}/$fileName';
    if (File(path).existsSync()) {
      return path;
    }
    return null;
  }
}
