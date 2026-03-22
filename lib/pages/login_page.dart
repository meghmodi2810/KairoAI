import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'signup_page.dart';
import '../main_navigation.dart';
import '../admin/pages/admin_dashboard_page.dart';
import '../admin/models/admin_models.dart';
import '../theme/app_theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey      = GlobalKey<FormState>();
  final _emailCtrl    = TextEditingController();
  final _passCtrl     = TextEditingController();
  bool _obscure       = true;
  bool _loading       = false;
  bool _googleLoading = false;
  final _auth         = FirebaseAuth.instance;
  final _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  // Design tokens (inline — auth pages intentionally avoid theme context before app is loaded)
  static const _bg     = Color(0xFF0D0D12);
  static const _card   = Color(0xFF14141C);
  static const _alt    = Color(0xFF1A1A26);
  static const _border = Color(0xFF252530);
  static const _accent = Color(0xFF6C63FF);
  static const _textP  = Color(0xFFF0F0FF);
  static const _textS  = Color(0xFF8888A8);
  static const _textM  = Color(0xFF50506A);

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  String? _validateEmail(String? v) {
    if (v == null || v.isEmpty) return 'Email is required';
    final re = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!re.hasMatch(v)) return 'Enter a valid email';
    return null;
  }

  String? _validatePass(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 8) return 'Minimum 8 characters';
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
      if (mounted && cred.user != null) {
        await _navigateAfterLogin(cred.user!.uid);
      }
    } on FirebaseAuthException catch (e) {
      _showError(_authMessage(e.code));
    } catch (e) {
      _showError('An unexpected error occurred.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _googleLoading = true);
    try {
      await _googleSignIn.signOut();
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;
      final gAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: gAuth.accessToken,
        idToken: gAuth.idToken,
      );
      final cred = await _auth.signInWithCredential(credential);
      if (mounted && cred.user != null) {
        await _navigateAfterLogin(cred.user!.uid);
      }
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'Google sign-in failed.');
    } catch (_) {
      _showError('Google sign-in failed. Please try again.');
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  Future<void> _navigateAfterLogin(String uid) async {
    Widget dest = const MainNavigation();
    try {
      final adminDoc = await FirebaseFirestore.instance.collection('admins').doc(uid).get();
      if (adminDoc.exists) {
        final admin = AdminModel.fromFirestore(adminDoc);
        if (admin.isActive) dest = AdminDashboardPage(admin: admin);
      }
    } catch (_) {}
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => dest,
        transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  String _authMessage(String code) {
    switch (code) {
      case 'user-not-found':      return 'No account found with this email.';
      case 'wrong-password':      return 'Incorrect password.';
      case 'invalid-email':       return 'Invalid email address.';
      case 'user-disabled':       return 'This account has been disabled.';
      case 'invalid-credential':  return 'Invalid credentials. Check email and password.';
      default:                    return 'An error occurred. Please try again.';
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppTheme.danger,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
            ),
            child: IntrinsicHeight(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 48),

                    // ── Brand logo ────────────────────────────────
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_accent, Color(0xFF9B94FF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: _accent.withOpacity(0.4),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.sign_language_rounded, color: Colors.white, size: 36),
                      ),
                    ),

                    const SizedBox(height: 36),

                    // ── Headline ─────────────────────────────────
                    const Text('Welcome back',
                      style: TextStyle(color: _textP, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                    const SizedBox(height: 6),
                    const Text('Sign in to continue your ISL journey.',
                      style: TextStyle(color: _textS, fontSize: 15, height: 1.5)),

                    const SizedBox(height: 36),

                    // ── Email ─────────────────────────────────────
                    _Label('Email'),
                    const SizedBox(height: 8),
                    _Field(
                      controller: _emailCtrl,
                      hint: 'you@example.com',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: _validateEmail,
                      enabled: !_loading,
                    ),

                    const SizedBox(height: 20),

                    // ── Password ──────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _Label('Password'),
                        GestureDetector(
                          onTap: () {},
                          child: const Text('Forgot password?',
                            style: TextStyle(color: _accent, fontSize: 13, fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _Field(
                      controller: _passCtrl,
                      hint: '••••••••',
                      icon: Icons.lock_outline_rounded,
                      obscure: _obscure,
                      validator: _validatePass,
                      enabled: !_loading,
                      suffix: IconButton(
                        icon: Icon(
                          _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: _textM,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── Sign In button ────────────────────────────
                    _PrimaryBtn(
                      label: 'Sign In',
                      loading: _loading,
                      onPressed: _loading ? null : _signIn,
                    ),

                    const SizedBox(height: 20),

                    // ── Divider ───────────────────────────────────
                    Row(children: [
                      const Expanded(child: Divider(color: _border, thickness: 1)),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14),
                        child: Text('or', style: TextStyle(color: _textM, fontSize: 13)),
                      ),
                      const Expanded(child: Divider(color: _border, thickness: 1)),
                    ]),

                    const SizedBox(height: 20),

                    // ── Google ────────────────────────────────────
                    _GoogleBtn(loading: _googleLoading, onPressed: _signInWithGoogle),

                    const Spacer(),
                    const SizedBox(height: 32),

                    // ── Sign Up link ──────────────────────────────
                    Center(
                      child: GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (_, __, ___) => const SignUpPage(),
                            transitionsBuilder: (_, anim, __, child) =>
                                FadeTransition(opacity: anim, child: child),
                            transitionDuration: const Duration(milliseconds: 250),
                          ),
                        ),
                        child: RichText(
                          text: const TextSpan(style: TextStyle(fontSize: 14), children: [
                            TextSpan(text: "Don't have an account? ", style: TextStyle(color: _textS)),
                            TextSpan(text: 'Sign up', style: TextStyle(color: _accent, fontWeight: FontWeight.w600)),
                          ]),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────
//  Local shared widgets
// ────────────────────────────────────────────────
class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  static const _textS = Color(0xFF8888A8);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(color: _textS, fontSize: 13, fontWeight: FontWeight.w500));
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscure;
  final String? Function(String?)? validator;
  final bool enabled;
  final Widget? suffix;

  static const _card   = Color(0xFF1A1A26);
  static const _border = Color(0xFF252530);
  static const _accent = Color(0xFF6C63FF);
  static const _textP  = Color(0xFFF0F0FF);
  static const _textM  = Color(0xFF50506A);
  static const _danger = Color(0xFFF87171);

  const _Field({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.obscure = false,
    this.validator,
    this.enabled = true,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      enabled: enabled,
      style: const TextStyle(color: _textP, fontSize: 15),
      cursorColor: _accent,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _textM, fontSize: 15),
        prefixIcon: Icon(icon, color: _textM, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: _card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _danger, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _danger, width: 1.5),
        ),
        errorStyle: const TextStyle(color: _danger, fontSize: 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

class _PrimaryBtn extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onPressed;

  static const _accent = Color(0xFF6C63FF);

  const _PrimaryBtn({required this.label, required this.loading, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: onPressed != null
                ? [_accent, const Color(0xFF9B94FF)]
                : [_accent.withOpacity(0.4), const Color(0xFF9B94FF).withOpacity(0.4)],
          ),
          borderRadius: BorderRadius.circular(13),
          boxShadow: onPressed != null
              ? [BoxShadow(color: _accent.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 6))]
              : null,
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
          ),
          child: loading
              ? const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}

class _GoogleBtn extends StatelessWidget {
  final bool loading;
  final VoidCallback onPressed;

  static const _card   = Color(0xFF1A1A26);
  static const _border = Color(0xFF252530);
  static const _textP  = Color(0xFFF0F0FF);

  const _GoogleBtn({required this.loading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: loading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: _card,
          side: const BorderSide(color: _border, width: 1),
          foregroundColor: _textP,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
        ),
        child: loading
            ? const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
                    padding: const EdgeInsets.all(3),
                    child: Image.network(
                      'https://www.google.com/favicon.ico',
                      errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata, size: 14, color: Colors.red),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('Continue with Google',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: _textP)),
                ],
              ),
      ),
    );
  }
}