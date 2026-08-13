import 'package:flutter/material.dart';
import '../../../shared/services/api_service.dart';
import '../../../shared/widgets/single_file_tool_scaffold.dart';

class TranslateScreen extends StatefulWidget {
  const TranslateScreen({super.key});
  @override
  State<TranslateScreen> createState() => _TranslateScreenState();
}

class _TranslateScreenState extends State<TranslateScreen> {
  String _lang = 'VI';
  static const _langs = {
    'VI': 'Tiếng Việt',
    'EN': 'English',
    'JA': '日本語',
    'KO': '한국어',
    'FR': 'Français',
    'DE': 'Deutsch'
  };

  @override
  Widget build(BuildContext context) => SingleFileToolScaffold(
        title: 'Dịch PDF',
        icon: Icons.translate,
        iconColor: const Color(0xFF06B6D4),
        allowedExtensions: const ['pdf'],
        buttonLabel: 'Dịch',
        optionsBuilder: (ctx, file) => DropdownButtonFormField<String>(
          initialValue: _lang,
          dropdownColor: const Color(0xFF18181B),
          items: _langs.entries
              .map((e) => DropdownMenuItem(
                  value: e.key,
                  child: Text(e.value,
                      style: const TextStyle(color: Colors.white))))
              .toList(),
          onChanged: (v) => setState(() => _lang = v!),
          decoration: const InputDecoration(labelText: 'Dịch sang'),
        ),
        onProcess: (file) => ApiService.translatePdf(file, _lang),
      );
}
