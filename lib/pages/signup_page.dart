import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../main_navigation.dart';
import '../theme/app_theme.dart';
import '../theme/neo_brutal_widgets.dart';
import 'login_page.dart';
import 'set_account_password_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  bool _hidePass = true;
  bool _hideConfirm = true;
  bool _loading = false;
  bool _googleLoading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    final ok = RegExp(r'^[\w\-.]+@([\w\-]+\.)+[\w\-]{2,4}$').hasMatch(value.trim());
    if (!ok) return 'Enter a valid email';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Minimum 8 characters';
    return null;
  }

  String? _validateConfirm(String? value) {
    if (value == null || value.isEmpty) return 'Confirm your password';
    if (value != _passCtrl.text) return 'Passwords do not match';
    return null;
  }

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await _auth.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );
      if (!mounted) return;
      _goToMain();
    } on FirebaseAuthException catch (e) {
      _showError(_authMessage(e.code));
    } catch (_) {
      _showError('Signup failed. Please retry.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signupWithGoogle() async {
    setState(() => _googleLoading = true);
    try {
      await _googleSignIn.signOut();
      final account = await _googleSignIn.signIn();
      if (account == null) return;
      final auth = await account.authentication;
      final cred = GoogleAuthProvider.credential(
        accessToken: auth.accessToken,
        idToken: auth.idToken,
      );
      final userCred = await _auth.signInWithCredential(cred);
      final isNewUser = userCred.additionalUserInfo?.isNewUser ?? false;
      if (!mounted) return;
      if (isNewUser) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SetAccountPasswordPage()),
        );
        return;
      }
      _goToMain();
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? _authMessage(e.code));
    } catch (_) {
      _showError('Google signup failed.');
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  String _authMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Email format is invalid.';
      case 'weak-password':
        return 'Use a stronger password.';
      default:
        return 'Could not create account.';
    }
  }

  void _goToMain() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MainNavigation(),
        transitionDuration: const Duration(milliseconds: 240),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  void _goToLogin() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LoginPage(),
        transitionDuration: const Duration(milliseconds: 240),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
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
    final topSpace = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppTheme.paperCream,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight - topSpace),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: _goToLogin,
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: AppTheme.warmWhite,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.inkBlack, width: 3),
                            boxShadow: const [
                              BoxShadow(
                                color: AppTheme.inkBlack,
                                offset: Offset(3, 3),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.arrow_back_rounded, color: AppTheme.inkBlack),
                        ),
                      ),
                      const SizedBox(height: 14),
                      NeoPanel(
                        color: AppTheme.mintGreen,
                        child: Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: AppTheme.signalYellow,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.inkBlack, width: 3),
                              ),
                              child: const Icon(Icons.waving_hand_rounded, color: AppTheme.inkBlack, size: 28),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'JOIN KAIROAI',
                                    style: TextStyle(
                                      color: AppTheme.inkBlack,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 26,
                                    ),
                                  ),
                                  Text(
                                    'Build your sign learning streak from day one.',
                                    style: TextStyle(
                                      color: AppTheme.inkBlack,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      NeoPanel(
                        color: AppTheme.warmWhite,
                        child: Column(
                          children: [
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
                              validator: _validatePassword,
                              obscureText: _hidePass,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                hintText: '********',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  onPressed: () => setState(() => _hidePass = !_hidePass),
                                  icon: Icon(_hidePass ? Icons.visibility_off_outlined : Icons.visibility_outlined),
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
                                  icon: Icon(_hideConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            NeoPrimaryButton(
                              label: 'Create Account',
                              loading: _loading,
                              onPressed: _loading ? null : _createAccount,
                              icon: Icons.person_add_alt_rounded,
                            ),
                            const SizedBox(height: 10),
                            NeoSecondaryButton(
                              label: _googleLoading ? 'Connecting to Google...' : 'Continue with Google',
                              onPressed: _googleLoading ? null : _signupWithGoogle,
                              icon: Icons.g_mobiledata,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Center(
                        child: GestureDetector(
                          onTap: _goToLogin,
                          child: const Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Already signed up? ',
                                  style: TextStyle(
                                    color: AppTheme.inkBlack,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                TextSpan(
                                  text: 'Log in',
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
