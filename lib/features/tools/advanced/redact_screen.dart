import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../../../shared/services/api_service.dart';
import '../../../shared/widgets/single_file_tool_scaffold.dart';

class RedactScreen extends StatefulWidget {
  const RedactScreen({super.key});
  @override
  State<RedactScreen> createState() => _RedactScreenState();
}

class _RedactScreenState extends State<RedactScreen> {
  final Set<String> _types = {'phone', 'email', 'cccd'};
  static const _all = {
    'phone': 'Số điện thoại',
    'email': 'Email',
    'cccd': 'CCCD',
    'credit_card': 'Thẻ tín dụng'
  };

  @override
  Widget build(BuildContext context) => SingleFileToolScaffold(
        title: 'Smart Redact',
        icon: Icons.security_outlined,
        iconColor: const Color(0xFF84CC16),
        allowedExtensions: const ['pdf'],
        buttonLabel: 'Ẩn thông tin nhạy cảm',
        optionsBuilder: (ctx, file) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _all.entries
              .map((e) => CheckboxListTile(
                    value: _types.contains(e.key),
                    onChanged: (v) => setState(
                        () => v! ? _types.add(e.key) : _types.remove(e.key)),
                    title: Text(e.value,
                        style: const TextStyle(color: Colors.white)),
                    activeColor: FKTheme.emerald500,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                  ))
              .toList(),
        ),
        onProcess: (file) => ApiService.smartRedact(file, _types.join(',')),
      );
}
