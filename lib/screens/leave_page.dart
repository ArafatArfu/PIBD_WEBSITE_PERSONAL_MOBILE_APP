import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/pibd_theme.dart';

String _formatLeaveDate(dynamic value) {
  if (value == null || value.toString().isEmpty) {
    return '-';
  }

  final parsed = DateTime.tryParse(value.toString());

  if (parsed == null) {
    return value.toString();
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

  return '${parsed.day.toString().padLeft(2, '0')} '
      '${months[parsed.month - 1]} ${parsed.year}';
}

class LeavePage extends StatefulWidget {
  const LeavePage({super.key});

  @override
  State<LeavePage> createState() => _LeavePageState();
}

class _LeavePageState extends State<LeavePage> {
  final apiService = ApiService();

  bool loading = true;
  bool submitting = false;
  String? errorMessage;
  List<dynamic> leaveRequests = [];

  @override
  void initState() {
    super.initState();
    loadLeaves();
  }

  Future<void> loadLeaves() async {
    try {
      final data = await apiService.getLeaveRequests();

      if (!mounted) return;

      setState(() {
        leaveRequests = data['leave_requests'] as List? ?? [];
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

  Future<void> openLeaveForm() async {
    final result = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(builder: (_) => const LeaveFormPage()),
    );

    if (result == null) return;

    setState(() => submitting = true);

    try {
      await apiService.submitLeaveRequest(
        leaveType: result['leave_type']!,
        project: result['project'],
        startDate: result['start_date']!,
        endDate: result['end_date']!,
        reason: result['reason']!,
        relieverName: result['reliever_name']!,
        relieverDesignation: result['reliever_designation'],
        comments: result['comments'],
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Leave request submitted successfully.'),
          backgroundColor: Colors.green,
        ),
      );

      await loadLeaves();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  Future<void> download(int id) async {
    try {
      await apiService.downloadLeaveDocument(id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Leave document downloaded.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color statusColor(String status) {
    switch (status) {
      case 'Approved':
        return PibdTheme.green;
      case 'Rejected':
        return PibdTheme.coral;
      default:
        return PibdTheme.yellow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave Requests'),
        backgroundColor: PibdTheme.blueSoft,
        foregroundColor: PibdTheme.ink,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: submitting ? null : openLeaveForm,
        backgroundColor: PibdTheme.blue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'Request Leave',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      backgroundColor: PibdTheme.page,
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? _errorView()
          : RefreshIndicator(
              onRefresh: loadLeaves,
              child: leaveRequests.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 180),
                        Center(child: Text('No leave requests yet.')),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: leaveRequests.length,
                      itemBuilder: (context, index) {
                        final leave = Map<String, dynamic>.from(
                          leaveRequests[index] as Map,
                        );

                        final status = leave['status']?.toString() ?? 'Pending';
                        final id = leave['id'] as int?;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        leave['leave_type']?.toString() ??
                                            'Leave',
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Chip(
                                      label: Text(status),
                                      labelStyle: const TextStyle(
                                        color: PibdTheme.ink,
                                        fontSize: 12,
                                      ),
                                      backgroundColor: statusColor(status),
                                      side: const BorderSide(
                                        color: PibdTheme.ink,
                                        width: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  leave['application_no']?.toString() ??
                                      'Application pending',
                                  style: const TextStyle(
                                    color: PibdTheme.muted,
                                    fontSize: 11.5,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${_formatLeaveDate(leave['start_date'])} - '
                                  '${_formatLeaveDate(leave['end_date'])}',
                                ),
                                if (leave['reason'] != null) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    leave['reason'].toString(),
                                    maxLines: 4,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      height: 1.5,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                ],
                                if (status == 'Approved' && id != null)
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton.icon(
                                      onPressed: () => download(id),
                                      icon: const Icon(
                                        Icons.download,
                                        color: PibdTheme.blue,
                                      ),
                                      label: const Text(
                                        'DOWNLOAD DOCX',
                                        style: TextStyle(
                                          color: PibdTheme.blue,
                                          fontFamily: 'monospace',
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                if (leave['admin_note'] != null &&
                                    leave['admin_note'].toString().isNotEmpty)
                                  Text(
                                    'Admin note: '
                                    '${leave['admin_note']}',
                                    style: const TextStyle(
                                      color: Colors.black54,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
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
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 12),
            FilledButton(onPressed: loadLeaves, child: const Text('Try Again')),
          ],
        ),
      ),
    );
  }
}

class LeaveFormPage extends StatefulWidget {
  const LeaveFormPage({super.key});

  @override
  State<LeaveFormPage> createState() => _LeaveFormPageState();
}

class _LeaveFormPageState extends State<LeaveFormPage> {
  final formKey = GlobalKey<FormState>();
  final project = TextEditingController();
  final reason = TextEditingController();
  final relieverName = TextEditingController();
  final relieverDesignation = TextEditingController();
  final comments = TextEditingController();

  String? leaveType;
  DateTime? startDate;
  DateTime? endDate;

  final leaveTypes = const [
    'Casual Leave',
    'Compensatory Leave',
    'Earned Leave',
    'Maternity Leave',
    'Paternity Leave',
    'Extraordinary Leave',
  ];

  Future<void> pickDate(bool start) async {
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: startDate ?? DateTime.now(),
    );

    if (selected == null) return;

    setState(() {
      if (start) {
        startDate = selected;
        if (endDate != null && endDate!.isBefore(selected)) {
          endDate = null;
        }
      } else {
        endDate = selected;
      }
    });
  }

  String dateValue(DateTime? date) {
    if (date == null) return 'Select date';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  void submit() {
    if (!formKey.currentState!.validate()) return;

    if (leaveType == null || startDate == null || endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete leave type and dates.')),
      );
      return;
    }

    Navigator.pop(context, {
      'leave_type': leaveType!,
      'project': project.text.trim(),
      'start_date': dateValue(startDate),
      'end_date': dateValue(endDate),
      'reason': reason.text.trim(),
      'reliever_name': relieverName.text.trim(),
      'reliever_designation': relieverDesignation.text.trim(),
      'comments': comments.text.trim(),
    });
  }

  @override
  void dispose() {
    project.dispose();
    reason.dispose();
    relieverName.dispose();
    relieverDesignation.dispose();
    comments.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Leave'),
        backgroundColor: PibdTheme.blueSoft,
        foregroundColor: PibdTheme.ink,
      ),
      backgroundColor: PibdTheme.page,
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            DropdownButtonFormField<String>(
              initialValue: leaveType,
              decoration: const InputDecoration(
                labelText: 'Type of Leave',
                border: OutlineInputBorder(),
              ),
              items: leaveTypes
                  .map(
                    (type) => DropdownMenuItem(value: type, child: Text(type)),
                  )
                  .toList(),
              onChanged: (value) => setState(() => leaveType = value),
              validator: (value) => value == null ? 'Select leave type' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: project,
              decoration: const InputDecoration(
                labelText: 'Project',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: () => pickDate(true),
              icon: const Icon(Icons.date_range),
              label: Align(
                alignment: Alignment.centerLeft,
                child: Text('Starting date: ${dateValue(startDate)}'),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: startDate == null ? null : () => pickDate(false),
              icon: const Icon(Icons.event),
              label: Align(
                alignment: Alignment.centerLeft,
                child: Text('Ending date: ${dateValue(endDate)}'),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: reason,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Purpose of Leave',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Purpose is required'
                  : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: relieverName,
              decoration: const InputDecoration(
                labelText: 'Reliever Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Reliever name is required'
                  : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: relieverDesignation,
              decoration: const InputDecoration(
                labelText: 'Reliever Designation',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: comments,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Comments',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: submit,
              icon: const Icon(Icons.send),
              label: const Text('Submit Leave Application'),
            ),
          ],
        ),
      ),
    );
  }
}
