import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../../../shared/services/api_service.dart';
import '../../../shared/widgets/single_file_tool_scaffold.dart';

class SplitScreen extends StatefulWidget {
  const SplitScreen({super.key});
  @override
  State<SplitScreen> createState() => _SplitScreenState();
}

class _SplitScreenState extends State<SplitScreen> {
  final _rangeCtrl = TextEditingController(text: '1-3,5,7-9');

  @override
  Widget build(BuildContext context) => SingleFileToolScaffold(
        title: 'Split PDF',
        icon: Icons.call_split,
        iconColor: const Color(0xFF3B82F6),
        allowedExtensions: const ['pdf'],
        buttonLabel: 'Tách PDF',
        optionsBuilder: (ctx, file) => TextField(
          controller: _rangeCtrl,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Khoảng trang',
            hintText: 'VD: 1-3,5,7-9',
            helperText: 'Kết quả trả về file .zip, mỗi khoảng 1 PDF',
            helperStyle: TextStyle(color: FKTheme.zinc400),
          ),
        ),
        onProcess: (file) => ApiService.splitPdf(file, _rangeCtrl.text),
      );
}
