import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:queueflow_mobileapp/providers/auth_provider.dart';
import 'package:queueflow_mobileapp/theme/app_theme.dart';
import 'package:queueflow_mobileapp/widgets/app_text_field.dart';
import 'package:queueflow_mobileapp/widgets/app_password_field.dart';
import 'package:queueflow_mobileapp/widgets/primary_button.dart';
import 'package:queueflow_mobileapp/utils/app_snackbar.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _displayError;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    // Clear any previous errors
    setState(() {
      _displayError = null;
    });

    FocusScope.of(context).unfocus();

    await ref
        .read(authProvider.notifier)
        .register(
          _usernameController.text.trim(),
          _emailController.text.trim(),
          _passwordController.text,
        );
  }

  String _getErrorMessage(String error) {
    final errorLower = error.toLowerCase();

    if (errorLower.contains('username') &&
        (errorLower.contains('taken') ||
            errorLower.contains('exists') ||
            errorLower.contains('already'))) {
      return 'This username is already taken';
    }

    if (errorLower.contains('email') &&
        (errorLower.contains('taken') ||
            errorLower.contains('exists') ||
            errorLower.contains('already'))) {
      return 'This email is already registered';
    }

    if (errorLower.contains('network') ||
        errorLower.contains('connection') ||
        errorLower.contains('timeout') ||
        errorLower.contains('socketexception') ||
        errorLower.contains('failed host lookup')) {
      return 'Unable to connect to server. Please check your internet connection.';
    }

    if (errorLower.contains('server') || errorLower.contains('500')) {
      return 'Server error. Please try again later.';
    }

    return 'Registration failed. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // Listen for errors and show snackbar + update local error state
    ref.listen(authProvider, (previous, next) {
      if (next.error != null && previous?.error != next.error) {
        final errorMessage = _getErrorMessage(next.error!);

        // Show snackbar
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            AppSnackbar.showError(context, errorMessage);
          }
        });

        // Also update local state to show error on screen
        setState(() {
          _displayError = errorMessage;
        });
      }

      // Clear error on successful registration
      if (next.isAuthenticated && previous?.isAuthenticated != true) {
        setState(() {
          _displayError = null;
        });
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: authState.isLoading ? null : () => context.pop(),
          tooltip: 'Back',
        ),
        title: Text('Create Account', style: AppTheme.headlineMedium),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingXXL),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppTheme.spacingXL),

                // Icon
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(AppTheme.spacingXL),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppTheme.secondaryColor,
                          AppTheme.secondaryDark,
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.secondaryColor.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.person_add_alt_1_rounded,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: AppTheme.spacingXXL),

                // Title
                Text(
                  'Join QueueFlow',
                  textAlign: TextAlign.center,
                  style: AppTheme.displayLarge,
                ),

                const SizedBox(height: AppTheme.spacingSM),

                // Subtitle
                Text(
                  'Create your account to get started',
                  textAlign: TextAlign.center,
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),

                const SizedBox(height: AppTheme.spacing3XL),

                // ERROR DISPLAY - Always visible if there's an error
                if (_displayError != null) ...[
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingLG),
                    margin: const EdgeInsets.only(bottom: AppTheme.spacingLG),
                    decoration: BoxDecoration(
                      color: AppTheme.errorLight,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                      border: Border.all(color: AppTheme.errorColor),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: AppTheme.errorColor,
                          size: 24,
                        ),
                        const SizedBox(width: AppTheme.spacingMD),
                        Expanded(
                          child: Text(
                            _displayError!,
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.errorColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: AppTheme.errorColor,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _displayError = null;
                            });
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                ],

                // Username Field
                AppTextField(
                  controller: _usernameController,
                  label: 'Username',
                  hint: 'Choose a username',
                  prefixIcon: Icons.account_circle_outlined,
                  enabled: !authState.isLoading,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Username is required';
                    }
                    if (value.trim().length < 3) {
                      return 'Username must be at least 3 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppTheme.spacingLG),

                // Email Field
                AppTextField(
                  controller: _emailController,
                  label: 'Email Address',
                  hint: 'Enter your email',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  enabled: !authState.isLoading,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email is required';
                    }
                    // Basic email validation
                    final emailRegex = RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    );
                    if (!emailRegex.hasMatch(value.trim())) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppTheme.spacingLG),

                // Password Field
                AppPasswordField(
                  controller: _passwordController,
                  label: 'Password',
                  hint: 'Create a password',
                  enabled: !authState.isLoading,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password is required';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppTheme.spacingLG),

                // Confirm Password Field
                AppPasswordField(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                  hint: 'Re-enter your password',
                  enabled: !authState.isLoading,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => _register(),
                ),

                const SizedBox(height: AppTheme.spacingXXL),

                // Register Button
                PrimaryButton(
                  text: 'Create Account',
                  onPressed: authState.isLoading ? null : _register,
                  isLoading: authState.isLoading,
                  backgroundColor: AppTheme.secondaryColor,
                ),

                const SizedBox(height: AppTheme.spacingXL),

                // Already have account
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account?',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    TextButton(
                      onPressed: authState.isLoading
                          ? null
                          : () => context.pushReplacement("/login"),
                      style: ButtonStyle(
                        padding: WidgetStatePropertyAll(EdgeInsets.zero),
                      ),
                      child: const Text(
                        'Sign In',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppTheme.spacingXL),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
