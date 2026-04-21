import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:queueflow_mobileapp/theme/app_theme.dart';

class AuthSelectionScreen extends StatelessWidget {
  const AuthSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor,
              AppTheme.primaryLight,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: SizedBox(
              height: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
              child: Column(
                children: [
                  // Header Section
                  SizedBox(
                    height: (MediaQuery.of(context).size.height * 0.35),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // App Icon
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/icon/app_icon.png',
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),

                        const SizedBox(height: AppTheme.spacingXXL),

                        // App Name
                        const Text(
                          'QueueFlow',
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),

                        const SizedBox(height: AppTheme.spacingMD),

                        // Tagline
                        Text(
                          'Smart Queue Management',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withValues(alpha: 0.9),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Content Section
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(AppTheme.spacingXXL),
                          topRight: Radius.circular(AppTheme.spacingXXL),
                        ),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(AppTheme.spacingXXL),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: AppTheme.spacingSM),

                            // Welcome Text
                            Text(
                              'Welcome Back',
                              textAlign: TextAlign.center,
                              style: AppTheme.displayMedium,
                            ),

                            const SizedBox(height: AppTheme.spacingSM),

                            // Subtitle
                            Text(
                              'Select your role to continue',
                              textAlign: TextAlign.center,
                              style: AppTheme.bodyMedium.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),

                            const SizedBox(height: AppTheme.spacing3XL),

                            // User Login Card
                            _RoleCard(
                              icon: Icons.person_outline_rounded,
                              title: 'User Login',
                              description: 'Join and manage your queues',
                              gradient: const LinearGradient(
                                colors: [
                                  AppTheme.userColor,
                                  Color(0xFF2563EB),
                                ],
                              ),
                              onTap: () => context.push('/login', extra: 'user'),
                            ),

                            const SizedBox(height: AppTheme.spacingLG),

                            // Admin Login Card
                            _RoleCard(
                              icon: Icons.shield_outlined,
                              title: 'Admin Login',
                              description: 'Manage queues and operations',
                              gradient: const LinearGradient(
                                colors: [
                                  AppTheme.adminColor,
                                  Color(0xFFDB2777),
                                ],
                              ),
                              onTap: () => context.push('/login', extra: 'admin'),
                            ),

                            const SizedBox(height: AppTheme.spacingXXL),

                            // Register Link
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'New here?',
                                  style: AppTheme.bodyMedium.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => context.push('/register'),
                                  style: ButtonStyle(
                                    padding: WidgetStatePropertyAll(EdgeInsets.zero)
                                  ),
                                  child: const Text(
                                    ' Create Account',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: AppTheme.spacingMD),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Gradient gradient;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        boxShadow: AppTheme.shadowMD,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingXL),
            child: Row(
              children: [
                // Icon Container
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingLG),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  ),
                  child: Icon(
                    icon,
                    size: 32,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(width: AppTheme.spacingLG),

                // Text Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingXS),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrow Icon
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white.withValues(alpha: 0.9),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
