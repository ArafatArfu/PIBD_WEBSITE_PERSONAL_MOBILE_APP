import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/pibd_theme.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  final apiService = ApiService();

  bool loading = true;
  bool submitting = false;
  String? errorMessage;
  List<dynamic> attendance = [];

  @override
  void initState() {
    super.initState();
    loadAttendance();
  }

  Future<void> loadAttendance() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final data = await apiService.getAttendance();
      final rawAttendance = data['attendance'];

      List<dynamic> records = [];

      if (rawAttendance is List) {
        records = rawAttendance;
      } else if (rawAttendance is Map) {
        final nestedData = rawAttendance['data'];

        if (nestedData is List) {
          records = nestedData;
        } else {
          records = rawAttendance.entries.map((entry) {
            final value = entry.value;

            if (value is Map) {
              return {
                'date': entry.key.toString(),
                ...Map<String, dynamic>.from(value),
              };
            }

            return {'date': entry.key.toString(), 'status': value.toString()};
          }).toList();
        }
      }

      if (!mounted) return;

      setState(() {
        attendance = records;
        loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = error.toString().replaceFirst('Exception: ', '');
        loading = false;
      });
    }
  }

  Future<void> submitAttendance() async {
    setState(() => submitting = true);

    try {
      await apiService.submitAttendance();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Attendance submitted successfully.'),
          backgroundColor: Colors.green,
        ),
      );

      await loadAttendance();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => submitting = false);
      }
    }
  }

  int get presentCount {
    return attendance.where((item) {
      final status = _status(item);
      return status == 'P' || status == 'Present';
    }).length;
  }

  int get absentCount {
    return attendance.where((item) {
      final status = _status(item);
      return status == 'A' || status == 'Absent';
    }).length;
  }

  int get leaveCount {
    return attendance.where((item) {
      final status = _status(item);
      return status == 'L' || status == 'Leave';
    }).length;
  }

  bool get todaySubmitted {
    final today = DateTime.now();
    final key =
        '${today.year.toString().padLeft(4, '0')}-'
        '${today.month.toString().padLeft(2, '0')}-'
        '${today.day.toString().padLeft(2, '0')}';
    return attendance.any((item) {
      final status = _status(item).toLowerCase();
      final date = _date(item).split('T').first.split(' ').first;
      return date == key && (status == 'p' || status == 'present');
    });
  }

  String _status(dynamic item) {
    if (item is! Map) return 'N/A';

    return (item['status'] ??
            item['attendance_status'] ??
            item['state'] ??
            'N/A')
        .toString()
        .trim();
  }

  String _date(dynamic item) {
    if (item is! Map) return '';

    return (item['date'] ?? item['attendance_date'] ?? item['day'] ?? '')
        .toString();
  }

  String _submittedTime(dynamic item) {
    if (item is! Map) return '';
    final raw =
        item['submitted_at'] ??
        item['attendance_time'] ??
        item['check_in'] ??
        item['created_at'] ??
        item['time'];
    final parsed = DateTime.tryParse(raw?.toString() ?? '');
    if (parsed == null) return raw?.toString() ?? '';
    final local = parsed.toLocal();
    final hour = local.hour == 0
        ? 12
        : (local.hour > 12 ? local.hour - 12 : local.hour);
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${local.hour >= 12 ? 'PM' : 'AM'}';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final scale = (MediaQuery.sizeOf(context).width / 340)
        .clamp(.92, 1.3)
        .toDouble();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F4),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: PibdTheme.blue),
            )
          : errorMessage != null
          ? _errorView()
          : RefreshIndicator(
              color: PibdTheme.blue,
              onRefresh: loadAttendance,
              child: ListView(
                padding: EdgeInsets.only(bottom: 30 * scale),
                children: [
                  _monthHeader(now, scale),
                  SizedBox(height: 16 * scale),
                  _todayAttendanceCard(scale),
                  SizedBox(height: 16 * scale),
                  _statisticsSection(scale),
                  SizedBox(height: 18 * scale),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20 * scale),
                    child: const Text(
                      'Attendance History',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 8 * scale),
                  if (attendance.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20 * scale),
                      child: _emptyCard(),
                    )
                  else
                    ...attendance.map((item) => _attendanceTile(item)),
                ],
              ),
            ),
    );
  }

  Widget _monthHeader(DateTime now, double scale) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return Container(
      margin: EdgeInsets.fromLTRB(20 * scale, 20 * scale, 20 * scale, 0),
      padding: EdgeInsets.all(22 * scale),
      decoration: BoxDecoration(
        color: const Color(0xFF8FB8D9),
        borderRadius: BorderRadius.circular(36 * scale),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly Attendance',
            style: TextStyle(color: Colors.white, fontSize: 11 * scale),
          ),
          SizedBox(height: 4 * scale),
          Text(
            '${months[now.month - 1]} ${now.year}',
            style: TextStyle(
              color: Colors.white,
              fontSize: 19 * scale,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _todayAttendanceCard(double scale) {
    final locked = todaySubmitted;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20 * scale),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 18 * scale,
          vertical: 18 * scale,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30 * scale),
        ),
        child: Row(
          children: [
            Container(
              width: 54 * scale,
              height: 54 * scale,
              decoration: const BoxDecoration(
                color: Color(0xFFE4F3EC),
                shape: BoxShape.circle,
              ),
              child: Icon(
                locked ? Icons.check_rounded : Icons.calendar_month_rounded,
                color: const Color(0xFF4CAF65),
                size: 28 * scale,
              ),
            ),
            SizedBox(width: 14 * scale),
            Expanded(
              child: Text(
                locked ? 'Attendance submitted' : 'Submit your attendance',
                style: TextStyle(
                  color: const Color(0xFF2B3B33),
                  fontSize: 15 * scale,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton(
              onPressed: locked || submitting ? null : submitAttendance,
              style: TextButton.styleFrom(
                foregroundColor: locked
                    ? Colors.grey.shade500
                    : const Color(0xFF7FB79A),
                padding: EdgeInsets.symmetric(horizontal: 4 * scale),
              ),
              child: Text(
                locked ? 'Submitted' : 'Submit',
                style: TextStyle(
                  fontSize: 13 * scale,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statisticsSection(double scale) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20 * scale),
      child: Row(
        children: [
          Expanded(
            child: _statCard(
              title: 'Present',
              value: '$presentCount',
              icon: Icons.check_rounded,
              color: const Color(0xFF4CAF65),
              scale: scale,
            ),
          ),
          SizedBox(width: 14 * scale),
          Expanded(
            child: _statCard(
              title: 'Absent',
              value: '$absentCount',
              icon: Icons.close_rounded,
              color: const Color(0xFFFF453A),
              scale: scale,
            ),
          ),
          SizedBox(width: 14 * scale),
          Expanded(
            child: _statCard(
              title: 'Leave',
              value: '$leaveCount',
              icon: Icons.event_busy_rounded,
              color: const Color(0xFFFF9800),
              scale: scale,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required double scale,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 20 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFF202020), width: 2),
        borderRadius: BorderRadius.circular(20 * scale),
      ),
      child: Column(
        children: [
          Container(
            width: 31 * scale,
            height: 31 * scale,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 22 * scale),
          ),
          SizedBox(height: 15 * scale),
          Text(
            value,
            style: TextStyle(
              color: const Color(0xFF151515),
              fontSize: 27 * scale,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 5 * scale),
          Text(
            title,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14 * scale),
          ),
        ],
      ),
    );
  }

  Widget _attendanceTile(dynamic item) {
    final status = _status(item);
    final date = _date(item);

    final isPresent =
        status.toLowerCase() == 'p' || status.toLowerCase() == 'present';

    final isLeave =
        status.toLowerCase() == 'l' || status.toLowerCase() == 'leave';

    final color = isPresent
        ? Colors.green
        : isLeave
        ? Colors.orange
        : Colors.red;

    final icon = isPresent
        ? Icons.check_circle_rounded
        : isLeave
        ? Icons.event_busy_rounded
        : Icons.cancel_rounded;

    final label = isPresent
        ? 'Present'
        : isLeave
        ? 'Leave'
        : status.toLowerCase() == 'a'
        ? 'Absent'
        : status;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: .12),
          child: Icon(icon, color: color),
        ),
        title: Text(
          date.isEmpty ? 'Attendance record' : date,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          _submittedTime(item).isEmpty
              ? 'Daily attendance record'
              : 'Submitted at ${_submittedTime(item)}',
          style: const TextStyle(
            color: PibdTheme.muted,
            fontFamily: 'monospace',
            fontSize: 11.5,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyCard() {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.event_available_rounded,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 10),
            const Text(
              'No attendance records found.',
              style: TextStyle(color: Colors.black54, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.red,
              size: 52,
            ),
            const SizedBox(height: 12),
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: loadAttendance,
              style: FilledButton.styleFrom(backgroundColor: PibdTheme.blue),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
