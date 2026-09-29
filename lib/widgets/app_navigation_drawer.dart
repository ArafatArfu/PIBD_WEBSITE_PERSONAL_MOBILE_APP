import 'package:flutter/material.dart';

import '../screens/attendance_page.dart';
import '../screens/leave_page.dart';
import '../screens/notifications_page.dart';
import '../screens/profile_page.dart';
import '../screens/stock_page.dart';
import '../screens/task_page.dart';

class AppNavigationDrawer extends StatelessWidget {
  final Map<String, dynamic>? user;

  const AppNavigationDrawer({super.key, this.user});

  void _open(BuildContext context, Widget page) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  String _initial() {
    final name = user?['name']?.toString().trim() ?? '';
    return name.isEmpty ? 'P' : name.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final drawerWidth = (width * .86).clamp(300.0, 380.0);

    return Drawer(
      width: drawerWidth,
      backgroundColor: const Color(0xFFF4F7F4),
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const SizedBox(height: 30),
            CircleAvatar(
              radius: 35,
              backgroundColor: const Color(0xFF7FB79A),
              child: Text(
                _initial(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                'PIBD Employee',
                style: const TextStyle(
                  color: Color(0xFF2B3B33),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 3),
            const Center(
              child: Text(
                'Application Menu',
                style: TextStyle(color: Color(0xFF7E9088), fontSize: 11),
              ),
            ),
            const SizedBox(height: 20),
            _item(
              context,
              '🏠',
              'Dashboard',
              const Color(0xFF7FB79A),
              () => Navigator.pop(context),
            ),
            _item(
              context,
              '📅',
              'Attendance',
              const Color(0xFF8FB8D9),
              () => _open(context, AttendancePage()),
            ),
            _item(
              context,
              '📋',
              'My Tasks',
              const Color(0xFFE3A87C),
              () => _open(context, TaskPage()),
            ),
            _item(
              context,
              '🗓️',
              'Leave Requests',
              const Color(0xFFE8A9B8),
              () => _open(context, LeavePage()),
            ),
            _item(
              context,
              '📦',
              'Stock Management',
              const Color(0xFF7FB79A),
              () => _open(context, StockPage()),
            ),
            _item(
              context,
              '🔔',
              'Notifications',
              const Color(0xFF8FB8D9),
              () => _open(context, NotificationsPage()),
            ),
            _item(
              context,
              '👤',
              'Profile',
              const Color(0xFFE3A87C),
              () => _open(context, ProfilePage()),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => Navigator.pop(context),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Center(
                  child: Text(
                    '↩️  Log out',
                    style: TextStyle(
                      color: Color(0xFFE8A9B8),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _item(
    BuildContext context,
    String icon,
    String label,
    Color iconColor,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Material(
        color: Colors.white,
        elevation: 2,
        shadowColor: const Color(0x142B3B33),
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: iconColor,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(icon, style: const TextStyle(fontSize: 16)),
                ),
                const SizedBox(width: 14),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF2B3B33),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
