import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../auth_wrapper.dart';
import '../theme/app_theme.dart';
import '../theme/neo_brutal_widgets.dart';

class SetAccountPasswordPage extends StatefulWidget {
  const SetAccountPasswordPage({super.key});

  @override
  State<SetAccountPasswordPage> createState() => _SetAccountPasswordPageState();
}

class _SetAccountPasswordPageState extends State<SetAccountPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _hidePassword = true;
  bool _hideConfirm = true;
  bool _loading = false;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Use at least 8 characters';
    return null;
  }

  String? _validateConfirm(String? value) {
    if (value == null || value.isEmpty) return 'Confirm your password';
    if (value != _passwordCtrl.text) return 'Passwords do not match';
    return null;
  }

  Future<void> _linkPassword() async {
    if (!_formKey.currentState!.validate()) return;

    final user = _auth.currentUser;
    if (user == null || (user.email ?? '').isEmpty) {
      _showError('Session expired. Please sign in again.');
      return;
    }

    setState(() => _loading = true);

    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _passwordCtrl.text.trim(),
      );

      await user.linkWithCredential(credential);
      await user.reload();
      if (!mounted) return;
      _goToAuthGate();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'provider-already-linked') {
        if (!mounted) return;
        _goToAuthGate();
        return;
      }
      _showError(_authMessage(e.code));
    } catch (_) {
      _showError('Could not set password right now. Please retry.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _authMessage(String code) {
    switch (code) {
      case 'weak-password':
        return 'Use a stronger password.';
      case 'invalid-credential':
        return 'Invalid credentials. Try again.';
      case 'credential-already-in-use':
        return 'This email/password combination is already in use.';
      case 'requires-recent-login':
        return 'Please sign in with Google again and retry.';
      default:
        return 'Unable to link password to this account.';
    }
  }

  void _goToAuthGate() {
    Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const AuthWrapper(),
        transitionDuration: const Duration(milliseconds: 240),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
      (route) => false,
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.punchRed),
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = _auth.currentUser?.email ?? 'your email';

    return Scaffold(
      backgroundColor: AppTheme.paperCream,
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NeoPanel(
                  color: AppTheme.signalYellow,
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppTheme.electricBlue,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.inkBlack, width: 3),
                        ),
                        child: const Icon(Icons.lock_reset_rounded, color: AppTheme.inkBlack, size: 28),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'SET ACCOUNT PASSWORD',
                          style: TextStyle(
                            color: AppTheme.inkBlack,
                            fontWeight: FontWeight.w900,
                            fontSize: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                NeoPanel(
                  color: AppTheme.warmWhite,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Signed in with Google as $email. Add a password so this same account can also log in with email and password.',
                        style: const TextStyle(
                          color: AppTheme.inkBlack,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _passwordCtrl,
                        validator: _validatePassword,
                        obscureText: _hidePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          hintText: '********',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            onPressed: () => setState(() => _hidePassword = !_hidePassword),
                            icon: Icon(
                              _hidePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _confirmCtrl,
                        validator: _validateConfirm,
                        obscureText: _hideConfirm,
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          hintText: '********',
                          prefixIcon: const Icon(Icons.lock_clock_outlined),
                          suffixIcon: IconButton(
                            onPressed: () => setState(() => _hideConfirm = !_hideConfirm),
                            icon: Icon(
                              _hideConfirm
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      NeoPrimaryButton(
                        label: 'Save Password',
                        onPressed: _loading ? null : _linkPassword,
                        loading: _loading,
                        icon: Icons.verified_user_rounded,
                      ),
                    ],
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
