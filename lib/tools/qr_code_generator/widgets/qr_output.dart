import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrOutput extends StatelessWidget {
  final String data;

  const QrOutput({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final bgColor = isLight ? Colors.white : Colors.black;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: QrImageView(
          data: data,
          version: QrVersions.auto,
          size: 200.0,
          backgroundColor: bgColor,
        ),
      ),
    );
  }
}
