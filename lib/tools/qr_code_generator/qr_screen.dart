import 'package:flutter/material.dart';
import '../../shared/widgets/common_app_bar.dart';
import 'widgets/qr_output.dart';

class QrScreen extends StatefulWidget {
  const QrScreen({super.key});

  @override
  State<QrScreen> createState() => _QrScreenState();
}

class _QrScreenState extends State<QrScreen> {
  final _controller = TextEditingController();
  String _output = '';
  bool _visible = false;

  void _generate() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _output = text;
      _visible = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: '二维码生成器'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: '输入文字或链接...',
                  prefixIcon: Icon(Icons.qr_code_scanner),
                ),
                maxLines: null,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _generate(),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _generate,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: const Text('生成二维码'),
              ),
              const Spacer(),
              if (_visible && _output.isNotEmpty)
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        QrOutput(data: _output),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            OutlinedButton.icon(
                              icon: const Icon(Icons.copy),
                              label: const Text('复制文本'),
                              onPressed: () {
                                // TODO: Clipboard.setData
                              },
                            ),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.download),
                              label: const Text('保存'),
                              onPressed: () {
                                // TODO: 保存图片
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              if (!_visible)
                Expanded(
                  child: Center(
                    child: Icon(Icons.qr_code_2,
                        size: 80, color: Colors.grey[400]),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
