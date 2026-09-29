import 'package:flutter/material.dart';

import 'screens/dashboard_page.dart';
import 'services/api_service.dart';
import 'theme/pibd_theme.dart';

void main() {
  runApp(const PibdEmployeeApp());
}

class PibdEmployeeApp extends StatelessWidget {
  const PibdEmployeeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PIBD Employee',
      theme: PibdTheme.theme(),
      home: const LoginPage(),
      routes: {'/login': (_) => const LoginPage()},
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final apiService = ApiService();

  bool hidePassword = true;
  bool loading = false;
  bool checkingSession = true;
  bool rememberMe = true;

  String? savedEmail;

  @override
  void initState() {
    super.initState();
    prepareLogin();
  }

  Future<void> prepareLogin() async {
    final rememberedEmail = await apiService.getRememberedEmail();
    final validSession = await apiService.hasValidSession();

    if (!mounted) return;

    if (rememberedEmail != null && rememberedEmail.isNotEmpty) {
      emailController.text = rememberedEmail;

      setState(() {
        savedEmail = rememberedEmail;
      });
    }

    setState(() {
      checkingSession = false;
    });

    if (validSession) {
      openDashboard();
    }
  }

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      showMessage('Email and password are required.', Colors.orange);
      return;
    }

    setState(() => loading = true);

    try {
      await apiService.login(
        email: email,
        password: password,
        rememberMe: rememberMe,
      );

      if (!mounted) return;

      openDashboard();
    } catch (error) {
      if (!mounted) return;

      showMessage(error.toString().replaceFirst('Exception: ', ''), Colors.red);
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  void useSavedEmail() {
    if (savedEmail == null || savedEmail!.isEmpty) {
      return;
    }

    setState(() {
      emailController.text = savedEmail!;
      emailController.selection = TextSelection.fromPosition(
        TextPosition(offset: emailController.text.length),
      );
    });
  }

  void openDashboard() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const DashboardPage()),
    );
  }

  void showMessage(String message, Color color) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (checkingSession) {
      return const Scaffold(
        backgroundColor: PibdTheme.page,
        body: Center(child: CircularProgressIndicator(color: PibdTheme.blue)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F4),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final designWidth = screenWidth.clamp(320.0, 520.0).toDouble();
            final scale = (designWidth / 340).clamp(.92, 1.35).toDouble();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _loginHeader(scale),
                Expanded(
                  child: SingleChildScrollView(
                    child: _loginForm(scale),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _loginForm(double scale) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF4F7F4),
      padding: EdgeInsets.fromLTRB(
        24 * scale,
        30 * scale,
        24 * scale,
        24 * scale,
      ),
      child: Column(
        children: [
          _designField(
            controller: emailController,
            icon: Icons.email_outlined,
            hint: 'Email address',
            keyboardType: TextInputType.emailAddress,
            scale: scale,
          ),
          SizedBox(height: 12 * scale),
          _designField(
            controller: passwordController,
            icon: Icons.lock_outline,
            hint: 'Password',
            obscureText: hidePassword,
            scale: scale,
          ),
          SizedBox(height: 6 * scale),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: loading ? null : login,
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF7FB79A),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 15 * scale),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: loading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Sign In',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          SizedBox(height: 16 * scale),
          const Text(
            'Your password is never saved on this device.\nProgress through Innovation Society',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF7E9088),
              fontSize: 11,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }

  Widget _loginHeader(double scale) {
    return Container(
      padding: EdgeInsets.fromLTRB(26 * scale, 50 * scale, 26 * scale, 70 * scale),
      decoration: BoxDecoration(
        color: Color(0xFF7FB79A),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.elliptical(204 * scale, 40 * scale),
          bottomRight: Radius.elliptical(204 * scale, 40 * scale),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned(
            top: -40 * scale,
            left: -30 * scale,
            child: _decorCircle(120 * scale, .15),
          ),
          Positioned(
            bottom: 0,
            right: -20 * scale,
            child: _decorCircle(80 * scale, .12),
          ),
          Column(
            children: [
              Container(
                width: 54 * scale,
                height: 54 * scale,
                alignment: Alignment.center,
                margin: EdgeInsets.only(bottom: 14 * scale),
                decoration: const BoxDecoration(
                  color: Color.fromRGBO(255, 255, 255, .25),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(50),
                    topRight: Radius.circular(50),
                    bottomRight: Radius.circular(50),
                    bottomLeft: Radius.circular(4),
                  ),
                ),
                child: Text('👥', style: TextStyle(fontSize: 22 * scale)),
              ),
              Text(
                'Welcome back',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Georgia',
                  fontSize: 22 * scale,
                ),
              ),
              SizedBox(height: 4 * scale),
              const Text(
                'Sign in to access your dashboard',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _decorCircle(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Color.fromRGBO(255, 255, 255, opacity),
      ),
    );
  }

  Widget _designField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    TextInputType? keyboardType,
    bool obscureText = false,
    required double scale,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: TextStyle(fontSize: 13 * scale, color: const Color(0xFF2B3B33)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 13 * scale, color: const Color(0xFF7E9088)),
        prefixIcon: Icon(icon, size: 18 * scale, color: const Color(0xFF7E9088)),
        filled: true,
        fillColor: const Color(0xFFF4F7F4),
        contentPadding: EdgeInsets.symmetric(horizontal: 20 * scale, vertical: 14 * scale),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
