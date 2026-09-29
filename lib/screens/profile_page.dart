import 'package:flutter/material.dart';

import '../services/api_service.dart';

class ProfilePage extends StatefulWidget {
  final Map<String, dynamic>? user;

  const ProfilePage({super.key, this.user});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final api = ApiService();

  final currentPassword = TextEditingController();
  final newPassword = TextEditingController();
  final confirmPassword = TextEditingController();

  Map<String, dynamic>? profile;
  bool loading = true;
  bool saving = false;
  bool hideCurrent = true;
  bool hideNew = true;
  bool hideConfirm = true;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    try {
      final result = await api.getMe();

      if (!mounted) return;

      setState(() {
        profile = result['user'] as Map<String, dynamic>?;
        loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> updatePassword() async {
    if (newPassword.text.length < 8) {
      showMessage('New password must be at least 8 characters.');
      return;
    }

    if (newPassword.text != confirmPassword.text) {
      showMessage('New passwords do not match.');
      return;
    }

    setState(() => saving = true);

    try {
      await api.changePassword(
        currentPassword: currentPassword.text,
        newPassword: newPassword.text,
        confirmation: confirmPassword.text,
      );

      currentPassword.clear();
      newPassword.clear();
      confirmPassword.clear();

      showMessage('Password updated successfully.');
    } catch (e) {
      showMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    currentPassword.dispose();
    newPassword.dispose();
    confirmPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = profile ?? widget.user ?? <String, dynamic>{};
    final width = MediaQuery.sizeOf(context).width;
    final scale = (width / 340).clamp(.92, 1.3).toDouble();

    if (loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF4F7F4),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF7FB79A)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F4),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: loadProfile,
          child: ListView(
            padding: EdgeInsets.only(bottom: 28 * scale),
            children: [
              _profileHeader(data, scale),
              SizedBox(height: 20 * scale),
              _infoRow('Employee ID', data['employee_id'], scale),
              _infoRow('Designation', data['designation'], scale),
              _infoRow('Email', data['email'], scale, small: true),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  24 * scale,
                  18 * scale,
                  24 * scale,
                  0,
                ),
                child: Column(
                  children: [
                    _passwordField(
                      currentPassword,
                      'Current password',
                      hideCurrent,
                      scale,
                      () => setState(() => hideCurrent = !hideCurrent),
                    ),
                    SizedBox(height: 12 * scale),
                    _passwordField(
                      newPassword,
                      'New password',
                      hideNew,
                      scale,
                      () => setState(() => hideNew = !hideNew),
                    ),
                    SizedBox(height: 12 * scale),
                    _passwordField(
                      confirmPassword,
                      'Confirm new password',
                      hideConfirm,
                      scale,
                      () => setState(() => hideConfirm = !hideConfirm),
                    ),
                    SizedBox(height: 6 * scale),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: saving ? null : updatePassword,
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFF7FB79A),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 15 * scale),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(
                          saving ? 'Saving...' : 'Update Password',
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profileHeader(Map<String, dynamic> data, double scale) {
    final name = data['name']?.toString() ?? 'Employee';
    final designation = data['designation']?.toString() ?? 'Employee';

    return Container(
      margin: EdgeInsets.fromLTRB(20 * scale, 20 * scale, 20 * scale, 0),
      padding: EdgeInsets.all(26 * scale),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40 * scale),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7FB79A), Color(0xFF8FB8D9)],
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 66 * scale,
            height: 66 * scale,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color.fromRGBO(255, 255, 255, .3),
              shape: BoxShape.circle,
            ),
            child: Text('🧑', style: TextStyle(fontSize: 26 * scale)),
          ),
          SizedBox(height: 10 * scale),
          Text(
            name,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16 * scale,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4 * scale),
          Text(
            designation,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 11.5 * scale),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(
    String label,
    dynamic value,
    double scale, {
    bool small = false,
  }) {
    final text = value?.toString().isNotEmpty == true ? value.toString() : '-';

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 24 * scale,
        vertical: 14 * scale,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11 * scale,
              color: const Color(0xFF7E9088),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              text,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: (small ? 11.5 : 13) * scale,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2B3B33),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _passwordField(
    TextEditingController controller,
    String hint,
    bool hidden,
    double scale,
    VoidCallback toggle,
  ) {
    return TextField(
      controller: controller,
      obscureText: hidden,
      style: TextStyle(fontSize: 13 * scale, color: const Color(0xFF2B3B33)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: 13 * scale,
          color: const Color(0xFF7E9088),
        ),
        prefixIcon: Icon(
          Icons.lock_outline,
          size: 18 * scale,
          color: const Color(0xFF7E9088),
        ),
        suffixIcon: IconButton(
          onPressed: toggle,
          icon: Icon(
            hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: const Color(0xFF7E9088),
          ),
        ),
        filled: true,
        fillColor: const Color(0xFFF4F7F4),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 20 * scale,
          vertical: 14 * scale,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
