import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../auth_wrapper.dart';
import '../theme/app_theme.dart';
import '../theme/neo_brutal_widgets.dart';
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  bool _obscure = true;
  bool _loading = false;
  bool _googleLoading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    final ok = RegExp(r'^[\w\-.]+@([\w\-]+\.)+[\w\-]{2,4}$').hasMatch(value.trim());
    if (!ok) return 'Enter a valid email address';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Minimum 8 characters';
    return null;
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );
      if (cred.user == null || !mounted) return;
      _goToAuthGate();
    } on FirebaseAuthException catch (e) {
      _showError(_authMessage(e.code));
    } catch (_) {
      _showError('Could not sign in. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _googleLoading = true);
    try {
      await _googleSignIn.signOut();
      final account = await _googleSignIn.signIn();
      if (account == null) return;

      final auth = await account.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: auth.accessToken,
        idToken: auth.idToken,
      );
      final cred = await _auth.signInWithCredential(credential);
      if (cred.user == null || !mounted) return;

      _goToAuthGate();
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? _authMessage(e.code));
    } catch (_) {
      _showError('Google sign-in failed. Please retry.');
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      _showError('Enter your email first to reset password.');
      return;
    }
    try {
      await _auth.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset mail sent.')),
      );
    } on FirebaseAuthException {
      _showError('Could not send reset email. Check your email and retry.');
    }
  }

  void _goToAuthGate() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const AuthWrapper(),
        transitionDuration: const Duration(milliseconds: 250),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  String _authMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'invalid-email':
        return 'This email format looks incorrect.';
      case 'user-disabled':
        return 'This account is disabled.';
      default:
        return 'Login failed. Please try again.';
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.punchRed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.paperCream,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final panelMinHeight =
                  (constraints.maxHeight - 96).clamp(420.0, double.infinity).toDouble();

              return SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 8),
                        NeoPanel(
                          color: AppTheme.warmWhite,
                          radius: 18,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minHeight: panelMinHeight),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'LOG IN',
                                  style: TextStyle(
                                    color: AppTheme.inkBlack,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 28,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Need camera access to practice signs with AI.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _emailCtrl,
                                  validator: _validateEmail,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: const InputDecoration(
                                    labelText: 'Email',
                                    hintText: 'you@example.com',
                                    prefixIcon: Icon(Icons.email_outlined),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _passCtrl,
                                  obscureText: _obscure,
                                  validator: _validatePassword,
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    hintText: '********',
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    suffixIcon: IconButton(
                                      onPressed: () => setState(() => _obscure = !_obscure),
                                      icon: Icon(_obscure
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined),
                                    ),
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: _loading ? null : _forgotPassword,
                                    child: const Text('Forgot password?'),
                                  ),
                                ),
                                NeoPrimaryButton(
                                  label: 'Let\'s Sign In',
                                  onPressed: _loading ? null : _signIn,
                                  loading: _loading,
                                  icon: Icons.login_rounded,
                                ),
                                const SizedBox(height: 12),
                                NeoSecondaryButton(
                                  label: _googleLoading
                                      ? 'Connecting to Google...'
                                      : 'Continue with Google',
                                  onPressed: _googleLoading ? null : _signInWithGoogle,
                                  icon: Icons.g_mobiledata,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Center(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (context, animation, secondaryAnimation) => const SignUpPage(),
                                  transitionDuration: const Duration(milliseconds: 240),
                                  transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                                      FadeTransition(opacity: animation, child: child),
                                ),
                              );
                            },
                            child: const Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'New here? ',
                                    style: TextStyle(
                                      color: AppTheme.inkBlack,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'Create account',
                                    style: TextStyle(
                                      color: AppTheme.cobaltBlue,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              );
            },
          ),
        ),
      ),
    );
  }
}
