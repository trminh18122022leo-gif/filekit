import 'package:flutter/material.dart';
import '../../../shared/services/api_service.dart';
import '../../../shared/widgets/single_file_tool_scaffold.dart';

class HandwritingScreen extends StatefulWidget {
  const HandwritingScreen({super.key});
  @override
  State<HandwritingScreen> createState() => _HandwritingScreenState();
}

class _HandwritingScreenState extends State<HandwritingScreen> {
  String _style = 'caveat';
  static const _styles = {
    'caveat': 'Caveat',
    'kalam': 'Kalam',
    'dancingscript': 'Dancing Script'
  };

  @override
  Widget build(BuildContext context) => SingleFileToolScaffold(
        title: 'Font → Handwriting',
        icon: Icons.draw_outlined,
        iconColor: const Color(0xFFEC4899),
        allowedExtensions: const ['pdf'],
        buttonLabel: 'Chuyển sang chữ viết tay',
        optionsBuilder: (ctx, file) => DropdownButtonFormField<String>(
          initialValue: _style,
          dropdownColor: const Color(0xFF18181B),
          items: _styles.entries
              .map((e) => DropdownMenuItem(
                  value: e.key,
                  child: Text(e.value,
                      style: const TextStyle(color: Colors.white))))
              .toList(),
          onChanged: (v) => setState(() => _style = v!),
          decoration: const InputDecoration(labelText: 'Kiểu chữ'),
        ),
        onProcess: (file) => ApiService.toHandwriting(file, _style),
      );
}
