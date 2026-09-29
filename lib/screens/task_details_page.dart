import 'dart:async';

import 'package:flutter/material.dart';

import '../services/api_service.dart';

class TaskDetailsPage extends StatefulWidget {
  final int assignmentId;

  const TaskDetailsPage({super.key, required this.assignmentId});

  @override
  State<TaskDetailsPage> createState() => _TaskDetailsPageState();
}

class _TaskDetailsPageState extends State<TaskDetailsPage> {
  final ApiService _apiService = ApiService();

  Map<String, dynamic>? _task;
  bool _loading = true;
  bool _updating = false;
  Timer? _countdownTimer;
  String _remaining = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTask();
    _countdownTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        setState(() {
          _remaining = _remainingText();
        });
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadTask() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await _apiService.getTaskDetails(widget.assignmentId);
      final raw = result['assignment'] ?? result['task'] ?? result['data'];

      if (raw is Map) {
        _task = Map<String, dynamic>.from(raw);
      } else {
        throw Exception('Task data was not found.');
      }
    } catch (error) {
      _error = error.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _updateStatus(String status) async {
    if (_updating) {
      return;
    }

    setState(() => _updating = true);

    try {
      final result = await _apiService.updateTaskStatus(
        widget.assignmentId,
        status,
      );

      final raw = result['assignment'] ?? result['task'] ?? result['data'];

      if (raw is Map) {
        _task = Map<String, dynamic>.from(raw);
      }

      _task ??= <String, dynamic>{};
      _task!['status'] = status;

      final nestedTask = _task!['task'];
      if (nestedTask is Map) {
        nestedTask['status'] = status;
      }

      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Task status updated to $status')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) {
        setState(() => _updating = false);
      }
    }
  }

  Map<String, dynamic> _taskData() {
    final result = <String, dynamic>{};
    final nested = _task?['task'];

    if (nested is Map) {
      result.addAll(Map<String, dynamic>.from(nested));
    }

    if (_task != null) {
      result.addAll(_task!);
    }

    return result;
  }

  String _value(String key, [String fallback = '']) {
    final data = _taskData();
    final value = data[key];

    return value?.toString().trim().isNotEmpty == true
        ? value.toString()
        : fallback;
  }

  String _dateText() {
    final raw = _value('deadline', 'No deadline');

    try {
      final date = DateTime.parse(raw);
      return '${date.day.toString().padLeft(2, '0')} '
          '${_month(date.month)} ${date.year}';
    } catch (_) {
      return raw;
    }
  }

  String _month(int month) {
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

    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F4),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF7FB79A)),
              )
            : _error != null
            ? _errorView()
            : RefreshIndicator(
                color: const Color(0xFF7FB79A),
                onRefresh: _loadTask,
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _topBar(),
                    _organicHeader(),
                    _summaryChips(),
                    _deadlineCountdown(),
                    _description(),
                    _statusActions(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Color(0xFF2B3B33),
              size: 19,
            ),
          ),
          const Spacer(),
          const Text(
            'Task Details',
            style: TextStyle(
              color: Color(0xFF2B3B33),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _organicHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE3A87C), Color(0xFFE8A9B8)],
        ),
        borderRadius: BorderRadius.circular(36),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _value('title', 'Task'),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Georgia',
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryChips() {
    final priority = _value('priority', 'Normal');
    final status = _value('status', 'Pending');

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: Row(
        children: [
          _chip('Priority', priority, const Color(0xFFE3A87C)),
          const SizedBox(width: 8),
          _chip('Deadline', _dateText(), const Color(0xFF2B3B33)),
          const SizedBox(width: 8),
          _chip('Status', status, const Color(0xFF7FB79A)),
        ],
      ),
    );
  }

  Widget _chip(String label, String value, Color valueColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x142B3B33),
              blurRadius: 12,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(color: Color(0xFF7E9088), fontSize: 9.5),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: valueColor,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _remainingText() {
    final raw = _value('deadline');

    if (raw.isEmpty) {
      return 'No deadline';
    }

    final deadline = DateTime.tryParse(raw);

    if (deadline == null) {
      return 'Deadline unavailable';
    }

    final difference = deadline.toLocal().difference(DateTime.now());

    if (difference.isNegative) {
      return 'Overdue';
    }

    final days = difference.inDays;
    final hours = difference.inHours.remainder(24);
    final minutes = difference.inMinutes.remainder(60);

    if (days > 0) {
      return '$days day${days == 1 ? '' : 's'} remaining';
    }

    if (hours > 0) {
      return '$hours hour${hours == 1 ? '' : 's'} remaining';
    }

    return '$minutes minute${minutes == 1 ? '' : 's'} remaining';
  }

  Widget _deadlineCountdown() {
    final remaining = _remaining.isEmpty ? _remainingText() : _remaining;

    final overdue = remaining == 'Overdue';

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x142B3B33),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            overdue ? Icons.warning_amber_rounded : Icons.schedule,
            color: overdue ? const Color(0xFFE8A9B8) : const Color(0xFFE3A87C),
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              overdue ? 'Deadline passed' : remaining,
              style: TextStyle(
                color: overdue
                    ? const Color(0xFFE8A9B8)
                    : const Color(0xFF2B3B33),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _description() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x142B3B33),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Text(
        _value('description', 'No description available.'),
        style: const TextStyle(
          color: Color(0xFF7E9088),
          fontSize: 11.5,
          height: 1.8,
        ),
      ),
    );
  }

  Widget _statusActions() {
    final status = _value('status', 'Pending');

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      child: Row(
        children: [
          Expanded(
            child: _statusButton(
              'In Progress',
              status == 'In Progress',
              () => _updateStatus('In Progress'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _statusButton(
              'Completed',
              status == 'Completed',
              () => _updateStatus('Completed'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusButton(String label, bool active, VoidCallback onPressed) {
    return OutlinedButton(
      onPressed: _updating ? null : onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: active ? const Color(0xFF7FB79A) : Colors.transparent,
        foregroundColor: active ? Colors.white : const Color(0xFF7FB79A),
        disabledForegroundColor: const Color(0xFF9DB5A8),
        side: BorderSide(
          color: active ? const Color(0xFF7FB79A) : const Color(0xFF7FB79A),
          width: 1.5,
        ),
        padding: const EdgeInsets.symmetric(vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
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
            const Icon(Icons.error_outline, color: Color(0xFFE8A9B8), size: 42),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF2B3B33), fontSize: 13),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _loadTask,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
