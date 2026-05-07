import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/admin_database_service.dart';
import 'screens/admin_shell.dart';
import 'models/admin_models.dart';
import '../theme/app_theme.dart';
import '../theme/neo_brutal_widgets.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  final _adminDbService = AdminDatabaseService();
  
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (userCredential.user == null) throw Exception('Auth failed');
      final isAdmin = await _adminDbService.isAdmin();

      if (!isAdmin) {
        await _auth.signOut();
        _showStatus('ACCESS DENIED. ADMIN ONLY.', isError: true);
        return;
      }

      await _adminDbService.updateAdminLastLogin();
      if (mounted) {
        final admin = AdminModel(
          id: userCredential.user!.uid,
          email: userCredential.user!.email ?? '',
          displayName: 'Admin',
          role: 'admin',
          permissions: [],
          isActive: true,
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => AdminShell(admin: admin)),
        );
      }
    } catch (e) {
      _showStatus('LOGIN FAILED. CHECK CREDENTIALS.', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showStatus(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
        backgroundColor: isError ? AppTheme.punchRed : AppTheme.mintGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.charcoalNight,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: [
                  // Logo
                  Container(
                    transform: Matrix4.rotationZ(-0.05),
                    child: NeoPanel(
                      color: AppTheme.signalYellow,
                      padding: const EdgeInsets.all(24),
                      child: const Icon(Icons.terminal_rounded, size: 64, color: AppTheme.inkBlack),
                    ),
                  ),
                  const SizedBox(height: 48),
                  
                  // Title
                  const Text(
                    'CONTROL ROOM',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Archivo Black',
                      letterSpacing: -1,
                    ),
                  ),
                  const Text(
                    'KAIROAI ADMIN AUTHENTICATION',
                    style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                  const SizedBox(height: 40),

                  // Login Card
                  NeoPanel(
                    color: Colors.white,
                    padding: const EdgeInsets.all(32),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildInput(
                            controller: _emailController,
                            label: 'ADMIN EMAIL',
                            icon: Icons.admin_panel_settings_rounded,
                          ),
                          const SizedBox(height: 24),
                          _buildInput(
                            controller: _passwordController,
                            label: 'SECURE KEY',
                            icon: Icons.vpn_key_rounded,
                            obscure: _obscurePassword,
                            suffix: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          const SizedBox(height: 40),
                          NeoButton(
                            label: _isLoading ? 'SYNCING...' : 'INITIALIZE SESSION',
                            color: AppTheme.signalYellow,
                            onPressed: _isLoading ? null : _signIn,
                            icon: Icons.power_settings_new_rounded,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Security Sticker
                  Container(
                    transform: Matrix4.rotationZ(0.02),
                    child: const NeoSticker(
                      label: 'ENCRYPTED CHANNEL ACTIVE',
                      color: AppTheme.mintGreen,
                      icon: Icons.security_rounded,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'KairoAI Engine v2.4.0',
                    style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.inkBlack),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          style: const TextStyle(fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppTheme.inkBlack),
            suffixIcon: suffix,
            filled: true,
            fillColor: AppTheme.paperCream,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.inkBlack, width: 3),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.inkBlack, width: 3),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.cobaltBlue, width: 3),
            ),
          ),
        ),
      ],
    );
  }
}
