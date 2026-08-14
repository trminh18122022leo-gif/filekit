import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import 'processing_overlay.dart';

/// Khung dùng chung: chọn 1 file → chọn option → bấm xử lý → sang /result
class SingleFileToolScaffold extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final List<String> allowedExtensions;
  final String buttonLabel;
  final Widget Function(BuildContext context, PlatformFile? file)
      optionsBuilder;
  final Future<String> Function(PlatformFile file) onProcess;

  const SingleFileToolScaffold({
    super.key,
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.allowedExtensions,
    required this.buttonLabel,
    required this.optionsBuilder,
    required this.onProcess,
  });

  @override
  State<SingleFileToolScaffold> createState() => _SingleFileToolScaffoldState();
}

class _SingleFileToolScaffoldState extends State<SingleFileToolScaffold> {
  PlatformFile? _file;
  bool _loading = false;

  Future<void> _pick() async {
    final r = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: widget.allowedExtensions,
      withData: true,
    );
    if (r != null) setState(() => _file = r.files.first);
  }

  Future<void> _run() async {
    if (_file == null) return;
    setState(() => _loading = true);
    try {
      final path = await widget.onProcess(_file!);
      if (mounted) {
        context.push('/result', extra: {'path': path, 'tool': widget.title});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: FKTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Stack(children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _FilePickCard(
              file: _file,
              icon: widget.icon,
              color: widget.iconColor,
              extensions: widget.allowedExtensions,
              onPick: _pick,
            ),
            if (_file != null) ...[
              const SizedBox(height: 20),
              widget.optionsBuilder(context, _file),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: _run, child: Text(widget.buttonLabel)),
            ],
          ]),
        ),
        if (_loading)
          const ProcessingOverlay(progress: 0, label: 'Đang xử lý...'),
      ]),
    );
  }
}

class _FilePickCard extends StatelessWidget {
  final PlatformFile? file;
  final IconData icon;
  final Color color;
  final List<String> extensions;
  final VoidCallback onPick;

  const _FilePickCard({
    required this.file,
    required this.icon,
    required this.color,
    required this.extensions,
    required this.onPick,
  });

  @override
  Widget build(BuildContext ctx) => GestureDetector(
        onTap: onPick,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: FKTheme.zinc900,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: file == null
                    ? FKTheme.zinc800
                    : color.withValues(alpha: 0.4)),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file?.name ??
                          'Chọn file ${extensions.join("/").toUpperCase()}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (file != null)
                      Text('${(file!.size / 1024).toStringAsFixed(0)} KB',
                          style: const TextStyle(
                              color: FKTheme.zinc400, fontSize: 12)),
                  ]),
            ),
            Icon(file == null ? Icons.upload_file : Icons.check_circle,
                color: file == null ? FKTheme.zinc600 : FKTheme.emerald500),
          ]),
        ),
      );
}
