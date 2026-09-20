// lib/pages/settings_page.dart
import 'package:flutter/material.dart';
import '../shared/constants.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _brightness = 'system'; // system, light, dark
  String _apiKey = '';
  String _baseUrl = 'https://api.openai.com/v1';
  int _workMinutes = 25;
  int _restMinutes = 5;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionTitle('外观设置'),
              RadioListTile<String>(
                title: const Text('跟随系统'),
                value: 'system',
                groupValue: _brightness,
                onChanged: (v) => setState(() => _brightness = v!),
              ),
              RadioListTile<String>(
                title: const Text('浅色'),
                value: 'light',
                groupValue: _brightness,
                onChanged: (v) => setState(() => _brightness = v!),
              ),
              RadioListTile<String>(
                title: const Text('深色'),
                value: 'dark',
                groupValue: _brightness,
                onChanged: (v) => setState(() => _brightness = v!),
              ),
              const Divider(height: 32),
              _SectionTitle('AI 聊天 (电灯)'),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'API Key',
                  prefixIcon: Icon(Icons.key),
                ),
                obscureText: true,
                onChanged: (v) => setState(() => _apiKey = v),
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Base URL',
                  prefixIcon: Icon(Icons.link),
                ),
                onChanged: (v) => setState(() => _baseUrl = v),
              ),
              const SizedBox(height: 8),
              const Text('示例: https://api.openai.com/v1',
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
              const Divider(height: 32),
              _SectionTitle('番茄钟'),
              TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: '工作时长',
                  prefixIcon: const Icon(Icons.timer),
                  suffixText: 'min',
                ),
                onChanged: (v) => setState(() => _workMinutes = int.tryParse(v) ?? 25),
              ),
              const SizedBox(height: 12),
              TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: '休息时长',
                  prefixIcon: const Icon(Icons.pause_circle),
                  suffixText: 'min',
                ),
                onChanged: (v) => setState(() => _restMinutes = int.tryParse(v) ?? 5),
              ),
              const Divider(height: 32),
              _SectionTitle('关于'),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text(AppConstants.appName),
                subtitle: Text('版本 ${AppConstants.appVersion}'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Text(text,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              )),
    );
  }
}
