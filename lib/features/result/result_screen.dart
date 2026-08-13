import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../../app/theme.dart';

class ResultScreen extends StatelessWidget {
  final String outputPath, toolName;
  const ResultScreen(
      {super.key, required this.outputPath, required this.toolName});

  @override
  Widget build(BuildContext ctx) {
    final size =
        File(outputPath).existsSync() ? File(outputPath).lengthSync() : 0;
    final sizeStr = size > 1024 * 1024
        ? '${(size / (1024 * 1024)).toStringAsFixed(1)} MB'
        : '${(size / 1024).toStringAsFixed(0)} KB';

    return Scaffold(
      appBar: AppBar(title: Text('$toolName — Xong')),
      body: Center(
        child: SizedBox(
            width: 320,
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: FKTheme.emerald500.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: FKTheme.emerald500.withValues(alpha: 0.3),
                      width: 2),
                ),
                child: const Icon(Icons.check_circle,
                    color: FKTheme.emerald500, size: 56),
              ),
              const SizedBox(height: 24),
              const Text('Xử lý thành công!',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text('File đã lưu ($sizeStr)',
                  style: const TextStyle(color: FKTheme.zinc400)),
              const SizedBox(height: 40),
              _Btn(Icons.open_in_new, 'Mở file',
                  () => OpenFilex.open(outputPath),
                  primary: true),
              const SizedBox(height: 10),
              _Btn(Icons.share, 'Chia sẻ',
                  () => Share.shareXFiles([XFile(outputPath)])),
              const SizedBox(height: 10),
              _Btn(Icons.home_outlined, 'Về trang chủ', () => ctx.go('/')),
            ])),
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool primary;
  const _Btn(this.icon, this.label, this.onTap, {this.primary = false});
  @override
  Widget build(BuildContext ctx) => SizedBox(
        width: double.infinity,
        child: primary
            ? ElevatedButton.icon(
                onPressed: onTap, icon: Icon(icon), label: Text(label))
            : OutlinedButton.icon(
                onPressed: onTap,
                icon: Icon(icon),
                label: Text(label),
                style: OutlinedButton.styleFrom(
                  foregroundColor: FKTheme.zinc200,
                  side: const BorderSide(color: FKTheme.zinc700),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
      );
}
