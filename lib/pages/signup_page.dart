import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../main_navigation.dart';
import '../theme/app_theme.dart';
import 'login_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey      = GlobalKey<FormState>();
  final _emailCtrl    = TextEditingController();
  final _passCtrl     = TextEditingController();
  final _confirmCtrl  = TextEditingController();
  bool _obscurePass   = true;
  bool _obscureConf   = true;
  bool _loading       = false;
  bool _googleLoading = false;
  final _auth         = FirebaseAuth.instance;
  final _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  static const _bg     = Color(0xFF0D0D12);
  static const _card   = Color(0xFF1A1A26);
  static const _border = Color(0xFF252530);
  static const _accent = Color(0xFF6C63FF);
  static const _textP  = Color(0xFFF0F0FF);
  static const _textS  = Color(0xFF8888A8);
  static const _textM  = Color(0xFF50506A);
  static const _danger = Color(0xFFF87171);

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  String? _validateEmail(String? v) {
    if (v == null || v.isEmpty) return 'Email is required';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) return 'Enter a valid email';
    return null;
  }

  String? _validatePass(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 8) return 'Minimum 8 characters';
    return null;
  }

  String? _validateConfirm(String? v) {
    if (v == null || v.isEmpty) return 'Please confirm your password';
    if (v != _passCtrl.text) return 'Passwords do not match';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await _auth.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );
      if (mounted) _navToMain();
    } on FirebaseAuthException catch (e) {
      _showError(_authMsg(e.code));
    } catch (_) {
      _showError('An unexpected error occurred.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signUpWithGoogle() async {
    setState(() => _googleLoading = true);
    try {
      await _googleSignIn.signOut();
      final gUser = await _googleSignIn.signIn();
      if (gUser == null) return;
      final gAuth = await gUser.authentication;
      final cred = GoogleAuthProvider.credential(
        accessToken: gAuth.accessToken,
        idToken: gAuth.idToken,
      );
      await _auth.signInWithCredential(cred);
      if (mounted) _navToMain();
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'Google sign-up failed.');
    } catch (_) {
      _showError('Google sign-up failed. Please try again.');
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  void _navToMain() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MainNavigation(),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  String _authMsg(String code) {
    switch (code) {
      case 'email-already-in-use': return 'An account already exists with this email.';
      case 'invalid-email':        return 'Invalid email address.';
      case 'weak-password':        return 'Password is too weak.';
      default:                     return 'An error occurred. Please try again.';
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
                    const SizedBox(height: 24),

                    // ── Back ──────────────────────────────────────
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF14141C),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _border),
                        ),
                        child: const Icon(Icons.arrow_back_rounded, color: _textS, size: 20),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── Headline ──────────────────────────────────
                    const Text('Create account',
                      style: TextStyle(color: _textP, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                    const SizedBox(height: 6),
                    const Text('Start your Indian Sign Language journey today.',
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
                      enabled: !_loading && !_googleLoading,
                    ),

                    const SizedBox(height: 20),

                    // ── Password ──────────────────────────────────
                    _Label('Password'),
                    const SizedBox(height: 8),
                    _Field(
                      controller: _passCtrl,
                      hint: '••••••••',
                      icon: Icons.lock_outline_rounded,
                      obscure: _obscurePass,
                      validator: _validatePass,
                      enabled: !_loading && !_googleLoading,
                      suffix: IconButton(
                        icon: Icon(
                          _obscurePass ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: _textM, size: 20,
                        ),
                        onPressed: () => setState(() => _obscurePass = !_obscurePass),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Confirm ───────────────────────────────────
                    _Label('Confirm Password'),
                    const SizedBox(height: 8),
                    _Field(
                      controller: _confirmCtrl,
                      hint: '••••••••',
                      icon: Icons.lock_outline_rounded,
                      obscure: _obscureConf,
                      validator: _validateConfirm,
                      enabled: !_loading && !_googleLoading,
                      suffix: IconButton(
                        icon: Icon(
                          _obscureConf ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: _textM, size: 20,
                        ),
                        onPressed: () => setState(() => _obscureConf = !_obscureConf),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── Create Account button ─────────────────────
                    _PrimaryBtn(
                      label: 'Create Account',
                      loading: _loading,
                      onPressed: (_loading || _googleLoading) ? null : _submit,
                    ),

                    const SizedBox(height: 20),

                    // ── Divider ───────────────────────────────────
                    const Row(children: [
                      Expanded(child: Divider(color: _border, thickness: 1)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14),
                        child: Text('or', style: TextStyle(color: _textM, fontSize: 13)),
                      ),
                      Expanded(child: Divider(color: _border, thickness: 1)),
                    ]),

                    const SizedBox(height: 20),

                    // ── Google ────────────────────────────────────
                    _GoogleBtn(
                      loading: _googleLoading,
                      onPressed: (_loading || _googleLoading) ? null : _signUpWithGoogle,
                    ),

                    const Spacer(),
                    const SizedBox(height: 32),

                    // ── Sign in link ──────────────────────────────
                    Center(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: RichText(
                          text: const TextSpan(style: TextStyle(fontSize: 14), children: [
                            TextSpan(text: 'Already have an account? ', style: TextStyle(color: _textS)),
                            TextSpan(text: 'Sign in', style: TextStyle(color: _accent, fontWeight: FontWeight.w600)),
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
//  Local widgets (same pattern as login_page)
// ────────────────────────────────────────────────
class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  static const _textS = Color(0xFF8888A8);
  @override
  Widget build(BuildContext context) =>
      Text(text, style: const TextStyle(color: _textS, fontSize: 13, fontWeight: FontWeight.w500));
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
    required this.controller, required this.hint, required this.icon,
    this.keyboardType, this.obscure = false, this.validator,
    this.enabled = true, this.suffix,
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
        filled: true, fillColor: _card,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _accent, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _danger)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _danger, width: 1.5)),
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
      width: double.infinity, height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: onPressed != null
              ? [_accent, const Color(0xFF9B94FF)]
              : [_accent.withOpacity(0.4), const Color(0xFF9B94FF).withOpacity(0.4)]),
          borderRadius: BorderRadius.circular(13),
          boxShadow: onPressed != null
              ? [BoxShadow(color: _accent.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 6))] : null,
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
          ),
          child: loading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}

class _GoogleBtn extends StatelessWidget {
  final bool loading;
  final VoidCallback? onPressed;
  static const _card   = Color(0xFF1A1A26);
  static const _border = Color(0xFF252530);
  static const _textP  = Color(0xFFF0F0FF);
  static const _textM  = Color(0xFF50506A);
  const _GoogleBtn({required this.loading, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity, height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: _card,
          side: const BorderSide(color: _border),
          foregroundColor: _textP,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
        ),
        child: loading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(
                  width: 20, height: 20,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
                  padding: const EdgeInsets.all(3),
                  child: Image.network('https://www.google.com/favicon.ico',
                    errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata, size: 14, color: Colors.red)),
                ),
                const SizedBox(width: 12),
                const Text('Continue with Google',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: _textP)),
              ]),
      ),
    );
  }
}
