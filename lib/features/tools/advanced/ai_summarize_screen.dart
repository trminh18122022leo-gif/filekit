import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../app/theme.dart';
import '../../../shared/services/api_service.dart';
import '../../../shared/widgets/processing_overlay.dart';

class AiSummarizeScreen extends StatefulWidget {
  const AiSummarizeScreen({super.key});
  @override
  State<AiSummarizeScreen> createState() => _AiSummarizeScreenState();
}

class _AiSummarizeScreenState extends State<AiSummarizeScreen> {
  PlatformFile? _file;
  String _length = 'medium', _style = 'bullets';
  bool _loading = false;
  String? _summary;

  Future<void> _pick() async {
    final r = await FilePicker.platform.pickFiles(
        type: FileType.custom, allowedExtensions: ['pdf'], withData: true);
    if (r != null) {
      setState(() {
        _file = r.files.first;
        _summary = null;
      });
    }
  }

  Future<void> _run() async {
    if (_file == null) return;
    setState(() => _loading = true);
    try {
      final res = await ApiService.aiSummarize(_file!,
          language: 'vi', length: _length, style: _style);
      setState(() => _summary = res['summary'] as String);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e'), backgroundColor: FKTheme.error));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('AI Summarizer')),
        body: Stack(children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GestureDetector(
                    onTap: _pick,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                          color: FKTheme.zinc900,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: FKTheme.zinc800)),
                      child: Row(children: [
                        const Icon(Icons.auto_awesome,
                            color: FKTheme.emerald500),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Text(_file?.name ?? 'Chọn file PDF',
                                style: const TextStyle(color: Colors.white))),
                      ]),
                    ),
                  ),
                  if (_file != null) ...[
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(
                          child: DropdownButtonFormField<String>(
                        initialValue: _length,
                        dropdownColor: const Color(0xFF18181B),
                        items: const [
                          DropdownMenuItem(
                              value: 'short',
                              child: Text('Ngắn',
                                  style: TextStyle(color: Colors.white))),
                          DropdownMenuItem(
                              value: 'medium',
                              child: Text('Vừa',
                                  style: TextStyle(color: Colors.white))),
                          DropdownMenuItem(
                              value: 'detailed',
                              child: Text('Chi tiết',
                                  style: TextStyle(color: Colors.white))),
                        ],
                        onChanged: (v) => setState(() => _length = v!),
                        decoration: const InputDecoration(labelText: 'Độ dài'),
                      )),
                      const SizedBox(width: 12),
                      Expanded(
                          child: DropdownButtonFormField<String>(
                        initialValue: _style,
                        dropdownColor: const Color(0xFF18181B),
                        items: const [
                          DropdownMenuItem(
                              value: 'bullets',
                              child: Text('Bullet points',
                                  style: TextStyle(color: Colors.white))),
                          DropdownMenuItem(
                              value: 'paragraph',
                              child: Text('Đoạn văn',
                                  style: TextStyle(color: Colors.white))),
                          DropdownMenuItem(
                              value: 'mindmap',
                              child: Text('Mindmap',
                                  style: TextStyle(color: Colors.white))),
                        ],
                        onChanged: (v) => setState(() => _style = v!),
                        decoration:
                            const InputDecoration(labelText: 'Định dạng'),
                      )),
                    ]),
                    const SizedBox(height: 20),
                    ElevatedButton(
                        onPressed: _run, child: const Text('Tóm tắt')),
                  ],
                  if (_summary != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: FKTheme.zinc900,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: FKTheme.zinc800)),
                      child: SelectableText(_summary!,
                          style: const TextStyle(
                              color: FKTheme.zinc200, height: 1.5)),
                    ),
                  ],
                ]),
          ),
          if (_loading)
            const ProcessingOverlay(
                progress: 0, label: 'Đang tóm tắt bằng AI...'),
        ]),
      );
}
