import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/pibd_theme.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final apiService = ApiService();
  bool loading = true;
  String? error;
  List<dynamic> notifications = [];

  @override
  void initState() {
    super.initState();
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    try {
      final data = await apiService.getNotifications();
      if (!mounted) return;
      setState(() {
        notifications = _extractList(data);
        loading = false;
        error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  List<dynamic> _extractList(Map<String, dynamic> response) {
    for (final key in const ['notifications', 'data']) {
      final value = response[key];
      if (value is List) return value;
      if (value is Map) {
        final nested = Map<String, dynamic>.from(value);
        for (final nestedKey in const ['notifications', 'data']) {
          if (nested[nestedKey] is List)
            return nested[nestedKey] as List<dynamic>;
        }
      }
    }
    return <dynamic>[];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PibdTheme.page,
      appBar: AppBar(title: const Text('Notifications')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(error!, textAlign: TextAlign.center),
              ),
            )
          : RefreshIndicator(
              onRefresh: loadNotifications,
              child: notifications.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 180),
                        Center(child: Text('No notifications yet.')),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: notifications.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (_, index) {
                        final item = Map<String, dynamic>.from(
                          notifications[index] as Map,
                        );
                        return Card(
                          child: ListTile(
                            leading: const Icon(
                              Icons.notifications_outlined,
                              color: PibdTheme.blue,
                            ),
                            title: Text(
                              item['title']?.toString() ?? 'Notification',
                            ),
                            subtitle: Text(
                              item['message']?.toString() ??
                                  item['body']?.toString() ??
                                  '',
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
