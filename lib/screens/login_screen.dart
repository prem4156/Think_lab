import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/user_profile.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isSignUp = false;
  bool isPasswordVisible = false;
  bool isLoading = false;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  String _deriveNameFromEmail(String email, String enteredName) {
    if (enteredName.isNotEmpty) return enteredName;
    if (email.contains('@')) {
      String userPart = email.split('@').first;
      List<String> parts = userPart.replaceAll(RegExp(r'[._-]'), ' ').split(' ');
      String formatted = parts.where((p) => p.isNotEmpty).map((w) {
        if (w.isEmpty) return '';
        return w[0].toUpperCase() + (w.length > 1 ? w.substring(1).toLowerCase() : '');
      }).join(' ');
      if (formatted.trim().isNotEmpty) return formatted.trim();
    }
    return 'Mind Trainer';
  }

  void _handleAuthSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    SoundService.instance.playTap();
    setState(() => isLoading = true);

    await Future.delayed(const Duration(milliseconds: 700));

    final storage = StorageService.instance;
    UserProfile profile = await storage.loadProfile();

    String enteredName = nameController.text.trim();
    String enteredEmail = emailController.text.trim();

    profile.name = _deriveNameFromEmail(enteredEmail, enteredName);
    profile.email = enteredEmail.isNotEmpty ? enteredEmail : 'trainer@thinkcity.app';

    await storage.saveProfile(profile);
    await storage.setLoggedIn(true);

    if (mounted) {
      setState(() => isLoading = false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    }
  }

  void _handleGuestAccess() async {
    SoundService.instance.playTap();
    setState(() => isLoading = true);

    await Future.delayed(const Duration(milliseconds: 500));

    final storage = StorageService.instance;
    UserProfile profile = await storage.loadProfile();
    profile.name = 'Guest Trainer';
    await storage.saveProfile(profile);
    await storage.setLoggedIn(true);

    if (mounted) {
      setState(() => isLoading = false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Top Hero Logo & Glow Halo
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppTheme.primaryGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryNeon.withValues(alpha: 0.35),
                        blurRadius: 30,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.psychology_rounded,
                    color: Colors.white,
                    size: 56,
                  ),
                )
                    .animate()
                    .scale(duration: 600.ms, curve: Curves.elasticOut)
                    .fadeIn(),

                const SizedBox(height: 20),

                Text(
                  'THINK CITY',
                  style: TextStyle(
                    color: AppTheme.primaryNeon,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3.0,
                  ),
                ).animate().fadeIn(delay: 150.ms),

                const SizedBox(height: 4),

                const Text(
                  'Personalized Mind Gym & Cognitive Training',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 32),

                // Sign In / Sign Up Segmented Pill Switcher
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.surfaceCardBorder),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            SoundService.instance.playTap();
                            setState(() => isSignUp = false);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: !isSignUp
                                  ? AppTheme.primaryNeon
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Text(
                                'Sign In',
                                style: TextStyle(
                                  color: !isSignUp
                                      ? Colors.white
                                      : AppTheme.textSecondary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            SoundService.instance.playTap();
                            setState(() => isSignUp = true);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSignUp
                                  ? AppTheme.primaryNeon
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Text(
                                'Create Account',
                                style: TextStyle(
                                  color: isSignUp
                                      ? Colors.white
                                      : AppTheme.textSecondary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 250.ms),

                const SizedBox(height: 28),

                // Form Container Card
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: AppTheme.surfaceCardBorder),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryNeon.withValues(alpha: 0.05),
                        blurRadius: 16,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name Field (Always available, required for Sign Up)
                        _buildTextField(
                          controller: nameController,
                          label: isSignUp ? 'Full Name' : 'Display Name (Optional)',
                          hint: 'e.g. Prem',
                          icon: Icons.person_outline_rounded,
                          validator: isSignUp
                              ? (v) => v == null || v.isEmpty ? 'Name required for Sign Up' : null
                              : null,
                        ),
                        const SizedBox(height: 16),

                        // Email Field
                        _buildTextField(
                          controller: emailController,
                          label: 'Email Address',
                          hint: 'name@example.com',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) =>
                              v == null || !v.contains('@') ? 'Enter a valid email' : null,
                        ),

                        const SizedBox(height: 16),

                        // Password Field
                        _buildTextField(
                          controller: passwordController,
                          label: 'Password',
                          hint: '••••••••',
                          icon: Icons.lock_outline_rounded,
                          isObscure: !isPasswordVisible,
                          suffixIcon: IconButton(
                            icon: Icon(
                              isPasswordVisible
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              color: AppTheme.textMuted,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                isPasswordVisible = !isPasswordVisible;
                              });
                            },
                          ),
                          validator: (v) =>
                              v == null || v.length < 6 ? 'Min 6 characters' : null,
                        ),

                        if (!isSignUp) ...[
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                SoundService.instance.playTap();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Password reset instructions sent to email.'),
                                  ),
                                );
                              },
                              child: const Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  color: AppTheme.primaryNeon,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ] else ...[
                          const SizedBox(height: 16),
                        ],

                        // Primary Action Button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryNeon
                                      .withValues(alpha: 0.3),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              onPressed: isLoading ? null : _handleAuthSubmit,
                              child: isLoading
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          isSignUp
                                              ? Icons.person_add_rounded
                                              : Icons.login_rounded,
                                          color: Colors.white,
                                          size: 22,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          isSignUp
                                              ? 'CREATE ACCOUNT'
                                              : 'SIGN IN',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 1.1,
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
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.05, end: 0),

                const SizedBox(height: 24),

                // Divider Or
                Row(
                  children: const [
                    Expanded(child: Divider(color: AppTheme.surfaceCardBorder)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'OR CONTINUE WITH',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: AppTheme.surfaceCardBorder)),
                  ],
                ).animate().fadeIn(delay: 350.ms),

                const SizedBox(height: 20),

                // Social Options & Guest Mode
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(
                              color: AppTheme.surfaceCardBorder),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _handleGuestAccess,
                        icon: const Icon(Icons.g_mobiledata_rounded,
                            color: AppTheme.primaryNeon, size: 24),
                        label: const Text(
                          'Google',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(
                              color: AppTheme.surfaceCardBorder),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _handleGuestAccess,
                        icon: const Icon(Icons.apple_rounded,
                            color: AppTheme.textPrimary, size: 20),
                        label: const Text(
                          'Apple',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 400.ms),

                const SizedBox(height: 16),

                // Quick Guest Access CTA
                TextButton.icon(
                  onPressed: _handleGuestAccess,
                  icon: const Icon(Icons.bolt_rounded,
                      color: AppTheme.amberProblemSolving, size: 20),
                  label: const Text(
                    'Quick Demo Access (Guest Mode)',
                    style: TextStyle(
                      color: AppTheme.amberProblemSolving,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                ).animate().fadeIn(delay: 450.ms),
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
    required String hint,
    required IconData icon,
    bool isObscure = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: isObscure,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 13,
            ),
            prefixIcon: Icon(icon, color: AppTheme.primaryNeon, size: 20),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: AppTheme.bgDark,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppTheme.surfaceCardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  const BorderSide(color: AppTheme.primaryNeon, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
