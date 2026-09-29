import 'package:flutter/material.dart';

import '../services/api_service.dart';

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

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: const Color(0xffF7F4F2),
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Attendance',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xff8B1E24),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: loadAttendance,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xff8B1E24)),
            )
          : errorMessage != null
          ? _errorView()
          : RefreshIndicator(
              color: const Color(0xff8B1E24),
              onRefresh: loadAttendance,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 30),
                children: [
                  _monthHeader(now),
                  const SizedBox(height: 18),
                  _todayAttendanceCard(),
                  const SizedBox(height: 22),
                  _statisticsSection(),
                  const SizedBox(height: 26),
                  const Text(
                    'Attendance History',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff252525),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (attendance.isEmpty)
                    _emptyCard()
                  else
                    ...attendance.map((item) => _attendanceTile(item)),
                ],
              ),
            ),
    );
  }

  Widget _monthHeader(DateTime now) {
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
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff8B1E24), Color(0xffB33A40)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff8B1E24).withValues(alpha: .22),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .18),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Monthly Attendance',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                '${months[now.month - 1]} ${now.year}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _todayAttendanceCard() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: const Color(0xffFBE9EA),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(
                Icons.how_to_reg_rounded,
                color: Color(0xff8B1E24),
                size: 30,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Today',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Submit your attendance',
                    style: TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 42,
              child: FilledButton(
                onPressed: submitting ? null : submitAttendance,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xff8B1E24),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Submit'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statisticsSection() {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            title: 'Present',
            value: '$presentCount',
            icon: Icons.check_circle_rounded,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            title: 'Absent',
            value: '$absentCount',
            icon: Icons.cancel_rounded,
            color: Colors.red,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            title: 'Leave',
            value: '$leaveCount',
            icon: Icons.event_busy_rounded,
            color: Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: color, size: 27),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 3),
            Text(
              title,
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
          ],
        ),
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
        subtitle: const Text(
          'Daily attendance record',
          style: TextStyle(color: Colors.black54),
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
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xff8B1E24),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
