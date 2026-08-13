import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

class ApiService {
  static const _base = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://filekit-api.onrender.com',
  );

  static final _dio = Dio(BaseOptions(
    baseUrl: _base,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(minutes: 5),
    sendTimeout: const Duration(minutes: 2),
  ));

  // ── Merge PDFs ──────────────────────────────────────────────────────────────
  static Future<String> mergePdfs(List<PlatformFile> files,
      [void Function(double)? onProg]) async {
    final form = FormData();
    for (final f in files) {
      form.files.add(MapEntry(
          'files', MultipartFile.fromBytes(f.bytes!, filename: f.name)));
    }
    final res = await _dio.post('/api/pdf/merge',
        data: form,
        onSendProgress: (s, t) => onProg?.call(s / t),
        options: Options(responseType: ResponseType.bytes));
    return _save(res.data, 'merged.pdf');
  }

  // ── Compress PDF ─────────────────────────────────────────────────────────────
  static Future<String> compressPdf(PlatformFile file, String quality,
      [void Function(double)? onProg]) async {
    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(file.bytes!, filename: file.name),
      'quality': quality,
    });
    final res = await _dio.post('/api/pdf/compress',
        data: form,
        onSendProgress: (s, t) => onProg?.call(s / t),
        options: Options(responseType: ResponseType.bytes));
    return _save(res.data, 'compressed.pdf');
  }

// ── Split PDF ──────────────────────────────────────────────────────────────
  static Future<String> splitPdf(PlatformFile file, String pageRanges) async {
    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(file.bytes!, filename: file.name),
      'page_ranges': pageRanges,
    });
    final res = await _dio.post('/api/pdf/split',
        data: form, options: Options(responseType: ResponseType.bytes));
    return _save(res.data, 'split.zip');
  }

// ── Smart Redact ──────────────────────────────────────────────────────────
  static Future<String> smartRedact(
      PlatformFile file, String redactTypes) async {
    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(file.bytes!, filename: file.name),
      'redact_types': redactTypes,
    });
    final res = await _dio.post('/api/advanced/smart-redact',
        data: form, options: Options(responseType: ResponseType.bytes));
    return _save(res.data, 'redacted.pdf');
  }

  // ── AI Summarize ──────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> aiSummarize(
    PlatformFile file, {
    String language = 'vi',
    String length = 'medium',
    String style = 'bullets',
  }) async {
    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(file.bytes!, filename: file.name),
      'language': language,
      'length': length,
      'style': style,
    });
    final res = await _dio.post('/api/advanced/ai-summarize', data: form);
    return res.data as Map<String, dynamic>;
  }

  // ── Font → Handwriting ────────────────────────────────────────────────────
  static Future<String> toHandwriting(PlatformFile file, String style,
      [void Function(double)? onProg]) async {
    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(file.bytes!, filename: file.name),
      'style': style,
    });
    final res = await _dio.post('/api/advanced/font-to-handwriting',
        data: form,
        onSendProgress: (s, t) => onProg?.call(s / t),
        options: Options(responseType: ResponseType.bytes));
    return _save(res.data, 'handwriting.pdf');
  }

  // ── Smart Translate ───────────────────────────────────────────────────────
  static Future<String> translatePdf(PlatformFile file, String targetLang,
      [void Function(double)? onProg]) async {
    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(file.bytes!, filename: file.name),
      'target_lang': targetLang,
    });
    final res = await _dio.post('/api/advanced/translate',
        data: form, options: Options(responseType: ResponseType.bytes));
    return _save(res.data, 'translated.pdf');
  }

  // ── Lưu file xuống thiết bị ──────────────────────────────────────────────
  static Future<String> _save(List<int> bytes, String filename) async {
    late String dirPath;

    if (Platform.isWindows) {
      dirPath =
          p.join(Platform.environment['USERPROFILE']!, 'Downloads', 'FileKit');
    } else if (Platform.isAndroid) {
      dirPath = '/storage/emulated/0/Download/FileKit';
    } else {
      final dir = await getApplicationDocumentsDirectory();
      dirPath = p.join(dir.path, 'FileKit');
    }

    await Directory(dirPath).create(recursive: true);
    final ts = DateTime.now().millisecondsSinceEpoch;
    final path = p.join(dirPath, '${ts}_$filename');
    await File(path).writeAsBytes(bytes);
    return path;
  }
}
