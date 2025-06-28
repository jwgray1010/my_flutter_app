import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum GradientButtonVariant { primary, secondary, accent, outline, text }

class GradientButton extends StatelessWidget {
  final String? text;
  final VoidCallback? onPressed;
  final GradientButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final bool fullWidth;
  final EdgeInsetsGeometry? padding;
  final Widget? child;
  final Gradient? gradient;
  final BorderRadiusGeometry? borderRadius;
  final double? elevation;

  const GradientButton({
    super.key,
    this.text,
    this.onPressed,
    this.variant = GradientButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.fullWidth = false,
    this.padding,
    this.child,
    this.gradient,
    this.borderRadius,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // If child is provided (legacy API), use it directly
    if (child != null) {
      return Container(
        decoration: BoxDecoration(
          gradient: gradient ?? _getGradientForVariant(variant),
          borderRadius:
              borderRadius as BorderRadius? ??
              BorderRadius.circular(AppTheme.radiusMD),
          boxShadow: elevation != null
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: elevation! * 2,
                    offset: Offset(0, elevation!),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius:
              borderRadius as BorderRadius? ??
              BorderRadius.circular(AppTheme.radiusMD),
          child: InkWell(
            onTap: onPressed,
            borderRadius:
                borderRadius as BorderRadius? ??
                BorderRadius.circular(AppTheme.radiusMD),
            child: Padding(
              padding: padding ?? const EdgeInsets.all(AppTheme.spaceMD),
              child: child!,
            ),
          ),
        ),
      );
    }

    // Standard API with text
    Widget buttonChild = Row(
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
        if (text != null) Text(text!),
      ],
    );

    switch (variant) {
      case GradientButtonVariant.primary:
        return Container(
          width: fullWidth ? double.infinity : null,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6C47FF), Color(0xFF4A2FE7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
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
                  child: buttonChild,
                ),
              ),
            ),
          ),
        );

      case GradientButtonVariant.secondary:
        return Container(
          width: fullWidth ? double.infinity : null,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF00D2FF), Color(0xFF0080FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.secondary.withValues(alpha: 0.3),
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
                  child: buttonChild,
                ),
              ),
            ),
          ),
        );

      case GradientButtonVariant.accent:
        return Container(
          width: fullWidth ? double.infinity : null,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF6B6B), Color(0xFFFF5252)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF6B6B).withValues(alpha: 0.3),
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
                  child: buttonChild,
                ),
              ),
            ),
          ),
        );

      case GradientButtonVariant.outline:
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
                  child: buttonChild,
                ),
              ),
            ),
          ),
        );

      case GradientButtonVariant.text:
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
                child: buttonChild,
              ),
            ),
          ),
        );
    }
  }

  Gradient _getGradientForVariant(GradientButtonVariant variant) {
    switch (variant) {
      case GradientButtonVariant.primary:
        return const LinearGradient(
          colors: [Color(0xFF6C47FF), Color(0xFF4A2FE7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case GradientButtonVariant.secondary:
        return const LinearGradient(
          colors: [Color(0xFFF093FB), Color(0xFFF5576C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case GradientButtonVariant.accent:
        return const LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case GradientButtonVariant.outline:
      case GradientButtonVariant.text:
        return const LinearGradient(
          colors: [Colors.transparent, Colors.transparent],
        );
    }
  }
}
