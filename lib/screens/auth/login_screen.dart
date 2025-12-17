import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../main_navigation.dart';
import '../../services/auth_service.dart';
import 'package:icons_plus/icons_plus.dart';
import 'email_signup_screen.dart';
import '../../core/theme/typography.dart';


class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              // Language selector (top right)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.language,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'English',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontSize: 14)
                              .apply(color: Colors.grey[600]),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.keyboard_arrow_down,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const Spacer(flex: 2),

              // Main content
              Text(
                'Start Your Journey',
                style: Theme.of(context).textTheme.headlineLarge
                    ?.copyWith(fontSize: 28, fontWeight: FontWeight.bold)
                    .apply(color: Colors.black),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              Text(
                'Sign in and explore with ease.',
                style: TextStyle(
                  fontFamily: AppTypography.primaryFontFamily,
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 48),

              // Social login buttons
              _buildSocialButton(
                context,
                'Sign in with Facebook',
                Brands.facebook,
                () => _handleSocialAuth(context, 'facebook'),
              ),

              const SizedBox(height: 16),
              _buildSocialButton(
                context,
                'Sign in with Google',
                Brands.google,
                () => _handleSocialAuth(context, 'google'),
              ),

              const SizedBox(height: 16),
              _buildSocialButton(
                context,
                'Sign in with Apple',
                Brands.apple_logo,
                () => _handleSocialAuth(context, 'apple'),
              ),

              const SizedBox(height: 32),

              const SizedBox(height: 32),

              // Continue with email
              GestureDetector(
                onTap: () => _showEmailLogin(context),
                child: Text(
                  'Continue with email',
                  style: Theme.of(context).textTheme.bodyLarge
                      ?.copyWith(
                        fontSize: 16,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.primary,
                      )
                      .apply(color: AppColors.primary),
                ),
              ),

              const Spacer(flex: 3),

              // Terms and conditions
              Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(fontSize: 12)
                        .apply(color: Colors.grey[600]),
                    children: [
                      const TextSpan(
                        text: 'By continuing, you automatically accept our ',
                      ),
                      TextSpan(
                        text: 'Terms &\nConditions',
                        style: TextStyle(
                          decoration: TextDecoration.underline,
                          color: Colors.grey[800],
                        ),
                      ),
                      const TextSpan(text: ', '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: TextStyle(
                          decoration: TextDecoration.underline,
                          color: Colors.grey[800],
                        ),
                      ),
                      const TextSpan(text: ', and '),
                      TextSpan(
                        text: 'Cookies policy',
                        style: TextStyle(
                          decoration: TextDecoration.underline,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom indicator (like home indicator)
              Container(
                width: 134,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
        );
  }

  Widget _buildSocialButton(BuildContext context, String text, String icon, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.grey[300]!),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
          backgroundColor: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Using Brand icon from icons_plus package
            Brand(icon, size: 24),
            const SizedBox(width: 12),
            Text(
              text,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontSize: 16, fontWeight: FontWeight.w500)
                  .apply(color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSocialAuth(BuildContext context, String provider) async {
    try {
      switch (provider) {
        case 'google':
          await AuthService().signInWithGoogle();
          if (context.mounted) {
            _navigateToMainApp(context);
          }
          break;
        case 'facebook':
          // TODO: Implement Facebook authentication
          if (context.mounted) {
            _showSnackBar(context, 'Facebook sign-in coming soon!');
          }
          break;
        case 'apple':
          // TODO: Implement Apple authentication
          if (context.mounted) {
            _showSnackBar(context, 'Apple sign-in coming soon!');
          }
          break;
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(context, AuthService().getErrorMessage(e));
      }
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showEmailLogin(BuildContext context) {
    // Navigate to email login form or show modal
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EmailAuthScreen()),
    );
  }

  void _navigateToMainApp(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const MainNavigation()),
      (route) => false,
    );
  }
}

// Separate screen for email authentication
class EmailAuthScreen extends StatefulWidget {
  const EmailAuthScreen({super.key});

  @override
  State<EmailAuthScreen> createState() => _EmailAuthScreenState();
}

class _EmailAuthScreenState extends State<EmailAuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Sign In',
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(fontWeight: FontWeight.w600)
              .apply(color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // Sign In title
                Text(
                  'Welcome Back',
                  style: Theme.of(context).textTheme.headlineLarge
                      ?.copyWith(fontSize: 28, fontWeight: FontWeight.bold)
                      .apply(color: Colors.black),
                ),

                const SizedBox(height: 8),

                Text(
                  'Sign in to your account',
                  style: Theme.of(context).textTheme.bodyLarge
                      ?.copyWith(fontSize: 16)
                      .apply(color: AppColors.textSecondary),
                ),

                const SizedBox(height: 40),

                _buildTextField(
                  controller: _emailController,
                  label: 'Email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(value!)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                _buildTextField(
                  controller: _passwordController,
                  label: 'Password',
                  icon: Icons.lock_outline,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _handleForgotPassword,
                    child: Text(
                      'Forgot Password?',
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w500)
                          .apply(color: AppColors.primary),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Auth button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleAuth,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Sign In',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                  ),
                ),

                const SizedBox(height: 24),

                // Sign up navigation
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'No account? ',
                        style: Theme.of(context).textTheme.bodyLarge
                            ?.copyWith(fontSize: 16)
                            .apply(color: AppColors.textSecondary),
                      ),
                      GestureDetector(
                        onTap: _navigateToSignUp,
                        child: Text(
                          'Sign Up',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              )
                              .apply(color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Skip option
                Center(
                  child: TextButton(
                    onPressed: _handleSkip,
                    child: Text(
                      'Continue without account',
                      style: Theme.of(context).textTheme.bodyLarge
                          ?.copyWith(
                            fontSize: 16,
                            decoration: TextDecoration.underline,
                          )
                          .apply(color: AppColors.textSecondary),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: Theme.of(context).textTheme.bodyLarge
            ?.copyWith(fontSize: 16)
            .apply(color: AppColors.textSecondary),
        prefixIcon: Icon(icon, color: AppColors.textSecondary),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = AuthService();

      // Sign in with existing account
      await authService.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Navigate to main app on success
      if (mounted) {
        _navigateToMainApp();
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        _showSnackBar(AuthService().getErrorMessage(e));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _handleSkip() {
    _navigateToMainApp();
  }

  void _navigateToSignUp() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const EmailSignupScreen()));
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showSnackBar('Please enter your email address first');
      return;
    }

    try {
      await AuthService().sendPasswordResetEmail(email);
      if (mounted) {
        _showSnackBar('Password reset email sent! Check your inbox.');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(AuthService().getErrorMessage(e));
      }
    }
  }

  void _navigateToMainApp() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const MainNavigation()),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
