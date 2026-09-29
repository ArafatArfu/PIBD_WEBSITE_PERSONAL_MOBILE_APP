import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'task_details_page.dart';

class TaskPage extends StatefulWidget {
  const TaskPage({super.key});

  @override
  State<TaskPage> createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {
  final ApiService _apiService = ApiService();

  List<Map<String, dynamic>> _tasks = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await _apiService.getTasks();

      dynamic raw;

      if (result is List) {
        raw = result;
      } else if (result is Map) {
        raw =
            result['tasks'] ??
            result['assignments'] ??
            result['items'] ??
            result['data'] ??
            [];

        if (raw is Map) {
          raw =
              raw['data'] ??
              raw['tasks'] ??
              raw['assignments'] ??
              raw['items'] ??
              [];
        }
      }

      if (raw is! List) {
        throw Exception('Task list was not found.');
      }

      _tasks = raw
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();

      _tasks.sort((a, b) {
        final aTask = a['task'] is Map
            ? Map<String, dynamic>.from(a['task'])
            : a;

        final bTask = b['task'] is Map
            ? Map<String, dynamic>.from(b['task'])
            : b;

        final aDate =
            DateTime.tryParse(
              (a['updated_at'] ??
                      aTask['updated_at'] ??
                      a['created_at'] ??
                      aTask['created_at'] ??
                      '')
                  .toString(),
            ) ??
            DateTime(1900);

        final bDate =
            DateTime.tryParse(
              (b['updated_at'] ??
                      bTask['updated_at'] ??
                      b['created_at'] ??
                      bTask['created_at'] ??
                      '')
                  .toString(),
            ) ??
            DateTime(1900);

        final dateResult = bDate.compareTo(aDate);

        if (dateResult != 0) {
          return dateResult;
        }

        final aId =
            int.tryParse((a['assignment_id'] ?? a['id'] ?? 0).toString()) ?? 0;

        final bId =
            int.tryParse((b['assignment_id'] ?? b['id'] ?? 0).toString()) ?? 0;

        return bId.compareTo(aId);
      });
    } catch (error) {
      _error = error.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  DateTime _date(Map<String, dynamic> task) {
    final value =
        task['deadline'] ??
        task['due_date'] ??
        task['assigned_at'] ??
        task['created_at'];

    return DateTime.tryParse(value?.toString() ?? '') ?? DateTime(9999, 12, 31);
  }

  int _taskId(Map<String, dynamic> task) {
    final value = task['assignment_id'] ?? task['id'] ?? task['task_id'];
    return int.tryParse(value.toString()) ?? 0;
  }

  String _text(Map<String, dynamic> task, String key, String fallback) {
    final value = task[key]?.toString().trim();
    return value == null || value.isEmpty ? fallback : value;
  }

  String _dateText(Map<String, dynamic> task) {
    final date = _date(task);

    if (date.year == 9999) {
      return 'No deadline';
    }

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

    return '${date.day.toString().padLeft(2, '0')} '
        '${months[date.month - 1]} ${date.year}';
  }

  Color _priorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return const Color(0xFFE8A9B8);
      case 'high':
        return const Color(0xFFE3A87C);
      case 'low':
        return const Color(0xFF8FB8D9);
      default:
        return const Color(0xFF7FB79A);
    }
  }

  Future<void> _openTask(Map<String, dynamic> task) async {
    final id = _taskId(task);

    if (id == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task ID is not available.')),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TaskDetailsPage(assignmentId: id)),
    );

    _loadTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F4),
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF7FB79A),
                      ),
                    )
                  : _error != null
                  ? _errorView()
                  : RefreshIndicator(
                      color: const Color(0xFF7FB79A),
                      onRefresh: _loadTasks,
                      child: _tasks.isEmpty
                          ? ListView(
                              children: const [
                                SizedBox(height: 180),
                                Center(
                                  child: Text(
                                    'No tasks available',
                                    style: TextStyle(
                                      color: Color(0xFF7E9088),
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                              itemCount: _tasks.length,
                              itemBuilder: (context, index) {
                                return _taskCard(
                                  _tasks[index],
                                  _tasks.length - index,
                                );
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 20, 18),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios_new,
              size: 19,
              color: Color(0xFF2B3B33),
            ),
          ),
          const SizedBox(width: 4),
          const Text(
            'My Tasks',
            style: TextStyle(
              color: Color(0xFF2B3B33),
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Text(
            '${_tasks.length}',
            style: const TextStyle(
              color: Color(0xFF7FB79A),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _taskCard(Map<String, dynamic> task, int serial) {
    final nestedTask = task['task'];
    final taskData = nestedTask is Map
        ? Map<String, dynamic>.from(nestedTask)
        : task;
    final title = taskData['title']?.toString().trim().isNotEmpty == true
        ? taskData['title'].toString()
        : 'Untitled Task';
    final priority = _text(taskData, 'priority', 'Normal');
    final status = _text(task, 'status', 'Pending');

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        elevation: 2,
        shadowColor: const Color(0x142B3B33),
        borderRadius: BorderRadius.circular(26),
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: () => _openTask(task),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _priorityColor(priority),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$serial',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF2B3B33),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        'Deadline: ${_dateText(task)}',
                        style: const TextStyle(
                          color: Color(0xFF7E9088),
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _badge(priority, _priorityColor(priority)),
                          const SizedBox(width: 6),
                          _badge(status, const Color(0xFF7FB79A)),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Color(0xFF7E9088)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .16),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
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
            const Text(
              'Unable to load tasks',
              style: TextStyle(
                color: Color(0xFF2B3B33),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF7E9088), fontSize: 12),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _loadTasks,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
