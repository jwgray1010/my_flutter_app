import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum PremiumButtonVariant { primary, secondary, outline, text }

class PremiumButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final PremiumButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final bool fullWidth;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final Color? backgroundColor;

  const PremiumButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = PremiumButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.fullWidth = false,
    this.padding,
    this.width,
    this.height,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget child = Row(
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null && !isLoading) ...[
          Icon(icon, size: 18),
          const SizedBox(width: AppTheme.spaceSM),
        ],
        if (isLoading) ...[
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: AppTheme.spaceSM),
        ],
        Text(text),
      ],
    );

    switch (variant) {
      case PremiumButtonVariant.primary:
        return Container(
          width: width ?? (fullWidth ? double.infinity : null),
          height: height,
          decoration: BoxDecoration(
            gradient: backgroundColor != null
                ? null
                : const LinearGradient(
                    colors: [Color(0xFF6C47FF), Color(0xFF4A2FE7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            color: backgroundColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            child: InkWell(
              onTap: isLoading ? null : onPressed,
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              child: Padding(
                padding:
                    padding ??
                    const EdgeInsets.symmetric(
                      horizontal: AppTheme.spaceLG,
                      vertical: AppTheme.spaceMD,
                    ),
                child: DefaultTextStyle(
                  style: theme.textTheme.labelLarge!.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  child: child,
                ),
              ),
            ),
          ),
        );

      case PremiumButtonVariant.secondary:
        return Container(
          width: fullWidth ? double.infinity : null,
          decoration: BoxDecoration(
            color: theme.colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            child: InkWell(
              onTap: isLoading ? null : onPressed,
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              child: Padding(
                padding:
                    padding ??
                    const EdgeInsets.symmetric(
                      horizontal: AppTheme.spaceLG,
                      vertical: AppTheme.spaceMD,
                    ),
                child: DefaultTextStyle(
                  style: theme.textTheme.labelLarge!.copyWith(
                    color: theme.colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                  child: child,
                ),
              ),
            ),
          ),
        );

      case PremiumButtonVariant.outline:
        return Container(
          width: fullWidth ? double.infinity : null,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            border: Border.all(color: theme.colorScheme.primary, width: 1.5),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            child: InkWell(
              onTap: isLoading ? null : onPressed,
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              child: Padding(
                padding:
                    padding ??
                    const EdgeInsets.symmetric(
                      horizontal: AppTheme.spaceLG,
                      vertical: AppTheme.spaceMD,
                    ),
                child: DefaultTextStyle(
                  style: theme.textTheme.labelLarge!.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  child: child,
                ),
              ),
            ),
          ),
        );

      case PremiumButtonVariant.text:
        return Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          child: InkWell(
            onTap: isLoading ? null : onPressed,
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            child: Padding(
              padding:
                  padding ??
                  const EdgeInsets.symmetric(
                    horizontal: AppTheme.spaceMD,
                    vertical: AppTheme.spaceSM,
                  ),
              child: DefaultTextStyle(
                style: theme.textTheme.labelLarge!.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
                child: child,
              ),
            ),
          ),
        );
    }
  }
}
