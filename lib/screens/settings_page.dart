import 'package:flutter/material.dart';

import '../services/app_language.dart';
import '../theme/pibd_theme.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: AppLanguage.instance,
    builder: (context, _) {
      final lang = AppLanguage.instance;
      return Scaffold(
        backgroundColor: PibdTheme.page,
        appBar: AppBar(title: Text(lang.text('Settings', 'সেটিংস'))),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.language, color: PibdTheme.blue),
                  title: Text(lang.text('Language', 'ভাষা')),
                  subtitle: Text(
                    lang.text(
                      'Choose app language',
                      'অ্যাপের ভাষা নির্বাচন করুন',
                    ),
                  ),
                ),
                RadioListTile(
                  value: 'en',
                  groupValue: lang.code,
                  title: const Text('English'),
                  onChanged: (v) => lang.setCode(v!),
                ),
                RadioListTile(
                  value: 'bn',
                  groupValue: lang.code,
                  title: const Text('বাংলা'),
                  onChanged: (v) => lang.setCode(v!),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
