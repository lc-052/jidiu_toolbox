// lib/pages/settings_page.dart
import 'package:flutter/material.dart';
import '../shared/constants.dart';
import '../shared/hive/hive_init.dart';
import '../shared/app_settings.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late String _brightness;
  late int _workMinutes;
  late int _restMinutes;

  final TextEditingController _workController = TextEditingController();
  final TextEditingController _restController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _brightness = AppPreferences.getBrightness();
    _workMinutes = AppPreferences.getWorkMinutes();
    _restMinutes = AppPreferences.getRestMinutes();

    _workController.text = _workMinutes.toString();
    _restController.text = _restMinutes.toString();
  }

  @override
  void dispose() {
    _workController.dispose();
    _restController.dispose();
    super.dispose();
  }

  void _saveAndNotify() {
    _workMinutes = int.tryParse(_workController.text) ?? 25;
    _restMinutes = int.tryParse(_restController.text) ?? 5;

    AppPreferences.setBrightness(_brightness);
    AppPreferences.setWorkMinutes(_workMinutes.clamp(1, 120));
    AppPreferences.setRestMinutes(_restMinutes.clamp(1, 60));

    setState(() {});

    // 实时通知主界面切换主题
    if (_brightness != 'system') {
      AppSettings.instance.setBrightness(_brightness);
    }
  }

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
                onChanged: (v) {
                  setState(() => _brightness = v!);
                  AppPreferences.setBrightness(v!);
                  AppSettings.instance.setBrightness(v!);
                },
              ),
              RadioListTile<String>(
                title: const Text('浅色'),
                value: 'light',
                groupValue: _brightness,
                onChanged: (v) {
                  setState(() => _brightness = v!);
                  AppPreferences.setBrightness(v!);
                  AppSettings.instance.setBrightness(v!);
                },
              ),
              RadioListTile<String>(
                title: const Text('深色'),
                value: 'dark',
                groupValue: _brightness,
                onChanged: (v) {
                  setState(() => _brightness = v!);
                  AppPreferences.setBrightness(v!);
                  AppSettings.instance.setBrightness(v!);
                },
              ),
              const Divider(height: 32),
              _SectionTitle('番茄钟'),
              TextField(
                controller: _workController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: '工作时长',
                  prefixIcon: const Icon(Icons.timer),
                  suffixText: 'min',
                ),
                onChanged: (_) => _saveAndNotify(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _restController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: '休息时长',
                  prefixIcon: const Icon(Icons.pause_circle),
                  suffixText: 'min',
                ),
                onChanged: (_) => _saveAndNotify(),
              ),
              const Divider(height: 32),
              _SectionTitle('关于'),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text(AppConstants.appName),
                subtitle: Text('版本 ${AppConstants.appVersion}'),
              ),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _brightness = 'system';
                      _workMinutes = 25;
                      _restMinutes = 5;
                    });
                    _workController.text = '25';
                    _restController.text = '5';
                    AppPreferences.setBrightness('system');
                    AppPreferences.setWorkMinutes(25);
                    AppPreferences.setRestMinutes(5);
                    AppSettings.instance.setBrightness('system');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('已恢复默认设置')),
                    );
                  },
                  icon: const Icon(Icons.restore),
                  label: const Text('恢复默认设置'),
                ),
              ),
              const SizedBox(height: 24),
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
