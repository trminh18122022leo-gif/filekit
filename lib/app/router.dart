import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../features/home/home_screen.dart';
import '../features/tools/pdf/merge_screen.dart';
import '../features/tools/pdf/split_screen.dart';
import '../features/tools/pdf/compress_screen.dart';
import '../features/tools/advanced/ai_summarize_screen.dart';
import '../features/tools/advanced/handwriting_screen.dart';
import '../features/tools/advanced/translate_screen.dart';
import '../features/tools/advanced/redact_screen.dart';
import '../features/result/result_screen.dart';
import '../features/history/history_screen.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (ctx, state, child) => _Shell(child: child),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/history', builder: (_, __) => const HistoryScreen()),
        ]),
      ],
    ),
    GoRoute(path: '/merge', builder: (_, __) => const MergeScreen()),
    GoRoute(path: '/split', builder: (_, __) => const SplitScreen()),
    GoRoute(path: '/compress', builder: (_, __) => const CompressScreen()),
    GoRoute(path: '/ai-summary', builder: (_, __) => const AiSummarizeScreen()),
    GoRoute(
        path: '/handwriting', builder: (_, __) => const HandwritingScreen()),
    GoRoute(path: '/translate', builder: (_, __) => const TranslateScreen()),
    GoRoute(path: '/redact', builder: (_, __) => const RedactScreen()),
    GoRoute(
      path: '/result',
      builder: (_, s) {
        final e = s.extra as Map<String, dynamic>;
        return ResultScreen(outputPath: e['path'], toolName: e['tool']);
      },
    ),
  ],
);

class _Shell extends StatefulWidget {
  final Widget child;
  const _Shell({required this.child});
  @override
  State<_Shell> createState() => _ShellState();
}

class _ShellState extends State<_Shell> {
  int _idx = 0;

  @override
  Widget build(BuildContext ctx) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _idx,
        onDestinationSelected: (i) {
          setState(() => _idx = i);
          i == 0 ? ctx.go('/') : ctx.go('/history');
        },
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.history_outlined),
              selectedIcon: Icon(Icons.history),
              label: 'Lịch sử'),
        ],
      ),
    );
  }
}
