import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool loading;
  final bool outlined;
  final bool danger;
  final IconData? icon;

  const AppButton({
    super.key,
    required this.label,
    this.onTap,
    this.loading = false,
    this.outlined = false,
    this.danger = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg = danger
        ? AppTheme.red
        : outlined
        ? Colors.transparent
        : AppTheme.green;
    final Color fg = outlined
        ? (danger ? AppTheme.red : AppTheme.green)
        : Colors.white;

    return GestureDetector(
      onTap: loading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: loading ? AppTheme.textLight : bg,
          borderRadius: BorderRadius.circular(14),
          border: outlined
              ? Border.all(
                  color: danger ? AppTheme.red : AppTheme.green,
                  width: 1.5,
                )
              : null,
          boxShadow: (!outlined && !loading)
              ? [
                  BoxShadow(
                    color: (danger ? AppTheme.red : AppTheme.green).withOpacity(
                      0.25,
                    ),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: loading
            ? const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: fg, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      color: fg,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
