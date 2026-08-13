import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../shared/utils/responsive.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext ctx) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: R.maxW(ctx)),
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 110,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: const Text('FileKit Pro',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, letterSpacing: -0.5)),
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [FKTheme.zinc950, Color(0xFF064E3B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: R.padding(ctx),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: R.cols(ctx),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: R.isDesktop(ctx) ? 1.4 : 1.2,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _ToolCard(tool: _tools[i]),
                    childCount: _tools.length,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  final _Tool tool;
  const _ToolCard({required this.tool});

  @override
  Widget build(BuildContext ctx) {
    return GestureDetector(
      onTap: () => ctx.push(tool.route),
      child: Container(
        decoration: BoxDecoration(
          color: FKTheme.zinc900,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: FKTheme.zinc800),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: tool.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(tool.icon, color: tool.color, size: 22),
            ),
            const Spacer(),
            Text(tool.name,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
            const SizedBox(height: 2),
            Text('${tool.count} công cụ',
                style: const TextStyle(color: FKTheme.zinc400, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _Tool {
  final String name, route;
  final IconData icon;
  final Color color;
  final int count;
  const _Tool(this.name, this.route, this.icon, this.color, this.count);
}

const _tools = [
  _Tool('PDF Tools', '/merge', Icons.picture_as_pdf, Color(0xFFEF4444), 6),
  _Tool('Chuyển đổi', '/compress', Icons.swap_horiz, Color(0xFF3B82F6), 5),
  _Tool('Hình ảnh', '/compress', Icons.image_outlined, Color(0xFFA855F7), 4),
  _Tool('Nén / Giải', '/compress', Icons.compress, Color(0xFFF59E0B), 3),
  _Tool(
      'AI Features', '/ai-summary', Icons.auto_awesome, FKTheme.emerald500, 4),
  _Tool('Viết tay', '/handwriting', Icons.draw_outlined, Color(0xFFEC4899), 2),
  _Tool('Dịch thuật', '/translate', Icons.translate, Color(0xFF06B6D4), 2),
  _Tool('Bảo mật', '/redact', Icons.security_outlined, Color(0xFF84CC16), 3),
];
