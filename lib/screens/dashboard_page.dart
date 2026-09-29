import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'attendance_page.dart';
import 'leave_page.dart';
import 'profile_page.dart';
import '../widgets/app_navigation_drawer.dart';

String _formatDashboardDate(dynamic value) {
  final parsed = DateTime.tryParse(value?.toString() ?? '');
  if (parsed == null) return '-';
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${parsed.day.toString().padLeft(2, '0')} ${months[parsed.month - 1]} ${parsed.year}';
}

class DashboardPage extends StatefulWidget {
  final Map<String, dynamic>? user;
  const DashboardPage({super.key, this.user});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final apiService = ApiService();
  bool loading = true;
  String? errorMessage;
  Map<String, dynamic> dashboard = {};

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    try {
      final data = await apiService.getDashboard();
      if (!mounted) return;
      setState(() {
        dashboard = data;
        loading = false;
        errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        loading = false;
        errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void openAttendance() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => AttendancePage()),
  );

  void openLeave() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const LeavePage()),
  );

  void openProfile() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => ProfilePage(user: widget.user)),
  );

  @override
  Widget build(BuildContext context) {
    final employeeId =
        dashboard['employee_id'] ?? widget.user?['employee_id'] ?? '---';
    final leaves = (dashboard['leave_requests'] as List?) ?? [];

    return Scaffold(
      backgroundColor: const Color(0xffEFEDE6),
      drawer: AppNavigationDrawer(user: widget.user),
      floatingActionButton: _attendanceButton(),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xff2952FF)),
            )
          : errorMessage != null
          ? _errorView()
          : RefreshIndicator(
              color: const Color(0xff2952FF),
              onRefresh: loadDashboard,
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _header(employeeId.toString()),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _statCard(
                                'LEAVE PENDING',
                                '${leaves.length}',
                                const Color(0xffFCF6C6),
                                Icons.event_note,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        _sectionTitle('Leave Requests'),
                        const SizedBox(height: 10),
                        if (leaves.isEmpty)
                          _emptyCard('No leave requests yet.')
                        else
                          ...leaves.map(
                            (item) => _leaveCard(item as Map<String, dynamic>),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _header(String employeeId) => Container(
    padding: const EdgeInsets.fromLTRB(18, 52, 18, 20),
    decoration: const BoxDecoration(
      color: Color(0xffE3E9FF),
      border: Border(bottom: BorderSide(color: Color(0xff111111), width: 3)),
    ),
    child: Row(
      children: [
        Builder(
          builder: (context) => InkWell(
            onTap: () => Scaffold.of(context).openDrawer(),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xff2952FF),
                border: Border.all(color: const Color(0xff111111), width: 2),
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(color: Color(0xff111111), offset: Offset(3, 3)),
                ],
              ),
              child: const Icon(Icons.menu, color: Colors.white),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome back',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  color: Color(0xff111111),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'EMP-ID $employeeId',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: Color(0xff111111),
                ),
              ),
            ],
          ),
        ),
        InkWell(
          onTap: openProfile,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xff111111), width: 2),
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(color: Color(0xff111111), offset: Offset(3, 3)),
              ],
            ),
            child: const Icon(Icons.person, color: Color(0xff2952FF), size: 28),
          ),
        ),
      ],
    ),
  );

  Widget _statCard(String label, String value, Color color, IconData icon) =>
      Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: const Color(0xff111111), width: 2),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: Color(0xff111111), offset: Offset(4, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xff111111), size: 25),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: .5,
              ),
            ),
          ],
        ),
      );

  Widget _sectionTitle(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w800,
      color: Color(0xff111111),
    ),
  );

  Widget _leaveCard(Map<String, dynamic> leave) => _contentCard(
    icon: Icons.event_note,
    iconColor: const Color(0xffE3E9FF),
    title: leave['leave_type'] ?? 'Leave',
    subtitle:
        '${_formatDashboardDate(leave['start_date'])} - ${_formatDashboardDate(leave['end_date'])}\nStatus: ${leave['status'] ?? 'Pending'}',
    onTap: openLeave,
  );

  Widget _contentCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xff111111), width: 2),
      borderRadius: BorderRadius.circular(12),
      boxShadow: const [
        BoxShadow(color: Color(0xff111111), offset: Offset(4, 4)),
      ],
    ),
    child: ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.all(12),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconColor,
          border: Border.all(color: const Color(0xff111111), width: 2),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, color: const Color(0xff111111)),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          color: Color(0xff111111),
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 5),
        child: Text(
          subtitle,
          style: const TextStyle(height: 1.45, color: Color(0xff333333)),
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Color(0xff111111),
      ),
    ),
  );

  Widget _emptyCard(String text) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xff111111), width: 2),
      borderRadius: BorderRadius.circular(12),
      boxShadow: const [
        BoxShadow(color: Color(0xff111111), offset: Offset(4, 4)),
      ],
    ),
    child: Text(text, style: const TextStyle(color: Color(0xff555555))),
  );

  Widget _attendanceButton() => FloatingActionButton.extended(
    backgroundColor: const Color(0xff2952FF),
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(11),
      side: const BorderSide(color: Color(0xff111111), width: 2),
    ),
    elevation: 5,
    onPressed: openAttendance,
    icon: const Icon(Icons.calendar_today),
    label: const Text(
      'Attendance',
      style: TextStyle(fontWeight: FontWeight.w800),
    ),
  );

  Widget _errorView() => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        errorMessage!,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.red),
      ),
    ),
  );
}
