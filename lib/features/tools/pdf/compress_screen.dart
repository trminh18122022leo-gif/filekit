import 'package:flutter/material.dart';
import '../../../shared/services/api_service.dart';
import '../../../shared/widgets/single_file_tool_scaffold.dart';

class CompressScreen extends StatefulWidget {
  const CompressScreen({super.key});
  @override
  State<CompressScreen> createState() => _CompressScreenState();
}

class _CompressScreenState extends State<CompressScreen> {
  String _quality = 'medium';

  @override
  Widget build(BuildContext context) => SingleFileToolScaffold(
        title: 'Compress PDF',
        icon: Icons.compress,
        iconColor: const Color(0xFFF59E0B),
        allowedExtensions: const ['pdf'],
        buttonLabel: 'Nén PDF',
        optionsBuilder: (ctx, file) => SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'low', label: Text('Nén nhiều')),
            ButtonSegment(value: 'medium', label: Text('Vừa')),
            ButtonSegment(value: 'high', label: Text('Chất lượng cao')),
          ],
          selected: {_quality},
          onSelectionChanged: (s) => setState(() => _quality = s.first),
        ),
        onProcess: (file) => ApiService.compressPdf(file, _quality),
      );
}
