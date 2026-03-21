import 'package:flutter/material.dart';
import '../services/admin_auth_service.dart';
import '../widgets/admin_widgets.dart';
import 'admin_dashboard_page.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AdminAuthService();
  
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _authService.signIn(
      _emailController.text,
      _passwordController.text,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result.success && result.admin != null) {
      // Navigate to admin dashboard
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AdminDashboardPage(admin: result.admin!),
        ),
      );
    } else {
      setState(() {
        _errorMessage = result.error ?? 'Login failed. Please try again.';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorMessage!),
          backgroundColor: AdminTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter your email address first'),
          backgroundColor: AdminTheme.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    final success = await _authService.sendPasswordResetEmail(email);
    
    if (!mounted) return;
    
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success 
            ? 'Password reset email sent. Check your inbox.'
            : 'Failed to send reset email. Please try again.',
        ),
        backgroundColor: success ? AdminTheme.success : AdminTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AdminTheme.theme,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AdminTheme.primaryBlue, AdminTheme.darkBlue],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AdminTheme.spacingLg),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Logo
                        _buildLogo(),
                        const SizedBox(height: AdminTheme.spacingXl),
                        
                        // Title
                        _buildTitle(),
                        const SizedBox(height: AdminTheme.spacingXl),
                        
                        // Login Form Card
                        _buildLoginForm(),
                        const SizedBox(height: AdminTheme.spacingMd),
                        
                        // Back to App Link
                        _buildBackToApp(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: Image.asset(
          'assets/logo/logo.jpeg',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: AdminTheme.primaryBlue,
              child: const Icon(
                Icons.admin_panel_settings,
                size: 50,
                color: AdminTheme.accentYellow,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        const Text(
          'Admin Portal',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AdminTheme.textPrimary,
          ),
        ),
        const SizedBox(height: AdminTheme.spacingSm),
        Text(
          'KairoAI Management Console',
          style: TextStyle(
            fontSize: 14,
            color: AdminTheme.textSecondary.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return AdminCard(
      padding: const EdgeInsets.all(AdminTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Email Field
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            validator: _validateEmail,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),
          const SizedBox(height: AdminTheme.spacingMd),
          
          // Password Field
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            validator: _validatePassword,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outlined),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
            ),
          ),
          const SizedBox(height: AdminTheme.spacingSm),
          
          // Forgot Password
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _isLoading ? null : _handleForgotPassword,
              child: const Text(
                'Forgot Password?',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ),
          const SizedBox(height: AdminTheme.spacingMd),
          
          // Error Message
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(AdminTheme.spacingSm),
              decoration: BoxDecoration(
                color: AdminTheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AdminTheme.borderRadiusSmall),
                border: Border.all(color: AdminTheme.error.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AdminTheme.error, size: 20),
                  const SizedBox(width: AdminTheme.spacingSm),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: AdminTheme.error,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AdminTheme.spacingMd),
          ],
          
          // Login Button
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AdminTheme.primaryDark),
                      ),
                    )
                  : const Text('Sign In'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackToApp() {
    return Center(
      child: TextButton.icon(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back, size: 18),
        label: const Text('Back to App'),
      ),
    );
  }
}
