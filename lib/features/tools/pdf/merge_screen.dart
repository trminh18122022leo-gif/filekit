import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../shared/services/api_service.dart';
import '../../../shared/widgets/processing_overlay.dart';

class MergeScreen extends StatefulWidget {
  const MergeScreen({super.key});
  @override
  State<MergeScreen> createState() => _State();
}

class _State extends State<MergeScreen> {
  List<PlatformFile> _files = [];
  bool _loading = false;
  double _progress = 0;

  Future<void> _pick() async {
    final r = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: true,
      withData: true,
    );
    if (r != null) setState(() => _files = [..._files, ...r.files]);
  }

  Future<void> _merge() async {
    if (_files.length < 2) return;
    setState(() {
      _loading = true;
      _progress = 0;
    });
    try {
      final path = await ApiService.mergePdfs(
          _files, (p) => setState(() => _progress = p));
      if (mounted) {
        ctx.push('/result', extra: {'path': path, 'tool': 'Merge PDF'});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: FKTheme.error),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  BuildContext get ctx => context;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Merge PDF'),
          actions: [
            if (_files.isNotEmpty)
              TextButton.icon(
                  onPressed: _pick,
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm')),
          ],
        ),
        body: Stack(children: [
          Column(children: [
            Expanded(
                child: _files.isEmpty
                    ? _Empty(onPick: _pick)
                    : _List(
                        files: _files,
                        onReorder: (o, n) => setState(() {
                          if (n > o) n--;
                          _files.insert(n, _files.removeAt(o));
                        }),
                        onRemove: (i) => setState(() => _files.removeAt(i)),
                      )),
            _Bar(count: _files.length, onPick: _pick, onMerge: _merge),
          ]),
          if (_loading)
            ProcessingOverlay(
                progress: _progress,
                label: 'Đang gộp ${_files.length} files...'),
        ]),
      );
}

class _List extends StatelessWidget {
  final List<PlatformFile> files;
  final Function(int, int) onReorder;
  final Function(int) onRemove;
  const _List(
      {required this.files, required this.onReorder, required this.onRemove});

  @override
  Widget build(BuildContext context) => ReorderableListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: files.length,
        onReorderItem: onReorder,
        itemBuilder: (ctx, i) {
          final f = files[i];
          final kb = (f.size / 1024).toStringAsFixed(0);
          return Container(
            key: ValueKey('$i${f.name}'),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: FKTheme.zinc900,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: FKTheme.zinc800),
            ),
            child: ListTile(
              leading:
                  const Icon(Icons.picture_as_pdf, color: Color(0xFFEF4444)),
              title: Text(f.name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis),
              subtitle: Text('$kb KB',
                  style: const TextStyle(color: FKTheme.zinc400, fontSize: 12)),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: FKTheme.zinc800,
                      borderRadius: BorderRadius.circular(6)),
                  child: Text('${i + 1}',
                      style: const TextStyle(
                          color: FKTheme.emerald500,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'monospace')),
                ),
                IconButton(
                    icon: const Icon(Icons.close,
                        size: 18, color: FKTheme.zinc400),
                    onPressed: () => onRemove(i)),
                const Icon(Icons.drag_handle, color: FKTheme.zinc600),
              ]),
            ),
          );
        },
      );
}

class _Bar extends StatelessWidget {
  final int count;
  final VoidCallback onPick, onMerge;
  const _Bar(
      {required this.count, required this.onPick, required this.onMerge});
  @override
  Widget build(BuildContext ctx) => Container(
        padding: EdgeInsets.fromLTRB(
            16, 12, 16, 12 + MediaQuery.of(ctx).padding.bottom),
        decoration: const BoxDecoration(
            color: FKTheme.zinc900,
            border: Border(top: BorderSide(color: FKTheme.zinc800))),
        child: count == 0
            ? SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                    onPressed: onPick,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Chọn file PDF')))
            : Row(children: [
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                      Text('$count file đã chọn',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600)),
                      const Text('Kéo để sắp xếp thứ tự',
                          style:
                              TextStyle(color: FKTheme.zinc400, fontSize: 12)),
                    ])),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                    onPressed: count >= 2 ? onMerge : null,
                    icon: const Icon(Icons.merge, size: 18),
                    label: const Text('Gộp PDF')),
              ]),
      );
}

class _Empty extends StatelessWidget {
  final VoidCallback onPick;
  const _Empty({required this.onPick});
  @override
  Widget build(BuildContext ctx) => Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
              color: FKTheme.zinc900,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: FKTheme.zinc800)),
          child: const Icon(Icons.picture_as_pdf,
              size: 48, color: Color(0xFFEF4444)),
        ),
        const SizedBox(height: 20),
        const Text('Chưa có file nào',
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        const Text('Chọn ít nhất 2 file PDF để gộp',
            style: TextStyle(color: FKTheme.zinc400)),
        const SizedBox(height: 24),
        ElevatedButton.icon(
            onPressed: onPick,
            icon: const Icon(Icons.add),
            label: const Text('Chọn file PDF')),
      ]));
}
