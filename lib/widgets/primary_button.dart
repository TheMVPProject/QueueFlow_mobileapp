import 'package:flutter/material.dart';
import 'package:queueflow_mobileapp/theme/app_theme.dart';

/// Reusable primary button with loading state
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool fullWidth;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;

  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.fullWidth = true,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    final button = isLoading || onPressed == null
        ? _buildButton(context, enabled: false)
        : _buildButton(context, enabled: true);

    return fullWidth
        ? SizedBox(width: double.infinity, child: button)
        : button;
  }

  Widget _buildButton(BuildContext context, {required bool enabled}) {
    Widget child;

    if (isLoading) {
      child = const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 2.5,
        ),
      );
    } else if (icon != null) {
      child = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: AppTheme.spacingMD),
          Text(text),
        ],
      );
    } else {
      child = Text(text);
    }

    if (backgroundColor != null || elevation != null) {
      return ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor ?? Colors.white,
          elevation: elevation,
          disabledBackgroundColor: backgroundColor?.withValues(alpha: 0.6),
        ),
        child: child,
      );
    }

    return ElevatedButton(
      onPressed: enabled ? onPressed : null,
      child: child,
    );
  }
}
