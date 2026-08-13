import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../app/theme.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final box = Hive.box('history');
    return Scaffold(
      appBar: AppBar(title: const Text('Lịch sử')),
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, Box b, _) {
          if (b.isEmpty) {
            return const Center(
              child: Text('Chưa có lịch sử xử lý file',
                  style: TextStyle(color: FKTheme.zinc400)),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: b.length,
            itemBuilder: (ctx, i) =>
                Card(child: ListTile(title: Text(b.getAt(i).toString()))),
          );
        },
      ),
    );
  }
}
