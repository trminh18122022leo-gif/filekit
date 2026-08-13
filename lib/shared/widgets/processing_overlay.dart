import 'package:flutter/material.dart';
import '../../app/theme.dart';

class ProcessingOverlay extends StatelessWidget {
  final double progress;
  final String label;
  const ProcessingOverlay(
      {super.key, required this.progress, required this.label});

  @override
  Widget build(BuildContext ctx) => Container(
        color: Colors.black.withValues(alpha: 0.7),
        child: Center(
          child: Container(
            width: 300,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: FKTheme.zinc900,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: FKTheme.zinc800),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: FKTheme.emerald500.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.auto_awesome,
                    color: FKTheme.emerald500, size: 34),
              ),
              const SizedBox(height: 20),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress > 0 ? progress : null,
                  backgroundColor: FKTheme.zinc800,
                  color: FKTheme.emerald500,
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                progress > 0 ? '${(progress * 100).toInt()}%' : 'Đang xử lý...',
                style: const TextStyle(
                    color: FKTheme.zinc400,
                    fontSize: 13,
                    fontFamily: 'monospace'),
              ),
            ]),
          ),
        ),
      );
}
