import 'package:flutter/material.dart';
import 'package:queueflow_mobileapp/theme/app_theme.dart';

/// Reusable password field with visibility toggle
class AppPasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;
  final bool enabled;

  const AppPasswordField({
    super.key,
    required this.controller,
    this.label = 'Password',
    this.hint,
    this.validator,
    this.onFieldSubmitted,
    this.enabled = true,
  });

  @override
  State<AppPasswordField> createState() => _AppPasswordFieldState();
}

class _AppPasswordFieldState extends State<AppPasswordField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      enabled: widget.enabled,
      obscureText: _obscureText,
      style: AppTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint ?? 'Enter your password',
        prefixIcon: const Icon(
          Icons.lock_outline_rounded,
          color: AppTheme.textSecondary,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureText
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: AppTheme.textSecondary,
          ),
          onPressed: widget.enabled
              ? () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                }
              : null,
        ),
        enabled: widget.enabled,
      ),
      validator: widget.validator,
      onFieldSubmitted: widget.onFieldSubmitted,
    );
  }
}
