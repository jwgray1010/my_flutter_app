import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_theme.dart';

class CustomBottomNavigationBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CustomBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<CustomBottomNavigationBar> createState() {
    return _CustomBottomNavigationBarState();
  }
}

class _CustomBottomNavigationBarState extends State<CustomBottomNavigationBar>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(CustomBottomNavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != oldWidget.currentIndex) {
      _animationController.forward().then((_) {
        _animationController.reverse();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
            spreadRadius: 0,
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLG),
          child: Row(
            children: [
              _buildNavItem(
                context,
                0,
                'Home',
                _getHomeIcon(),
                'assets/home_icon.svg',
              ),
              _buildNavItem(
                context,
                1,
                'Insights',
                _getInsightsIcon(),
                'assets/insight.svg',
              ),
              _buildNavItem(
                context,
                2,
                'Info',
                _getInfoIcon(),
                'assets/balance_icon.svg', // Use balance_icon.svg for Info tab
              ),
              _buildNavItem(
                context,
                3,
                'Settings',
                _getSettingsIcon(),
                'assets/settings_icon.svg',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    int index,
    String label,
    IconData? iconData,
    String? svgPath,
  ) {
    final theme = Theme.of(context);
    final isSelected = widget.currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onTap(index);
        },
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            final scale = isSelected ? _scaleAnimation.value : 1.0;

            return Transform.scale(
              scale: scale,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon with gradient background for selected state
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: isSelected ? AppTheme.primaryGradient : null,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: svgPath != null
                          ? SvgPicture.asset(
                              svgPath,
                              color: isSelected
                                  ? Colors.white
                                  : theme.colorScheme.onSurface.withOpacity(
                                      0.6,
                                    ),
                              width: 24,
                              height: 24,
                              semanticsLabel: label,
                            )
                          : Icon(
                              iconData,
                              color: isSelected
                                  ? Colors.white
                                  : theme.colorScheme.onSurface.withOpacity(
                                      0.6,
                                    ),
                              size: 24,
                            ),
                    ),
                  ),

                  const SizedBox(height: AppTheme.spaceXS),

                  // Label with animated color
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style:
                        theme.textTheme.bodySmall?.copyWith(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface.withOpacity(0.6),
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ) ??
                        const TextStyle(),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // Active indicator dot
                  const SizedBox(height: AppTheme.spaceXS),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: isSelected ? 6 : 0,
                    height: isSelected ? 6 : 0,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  IconData _getHomeIcon() {
    return Icons.home_outlined;
  }

  IconData _getInsightsIcon() {
    return Icons.analytics_outlined;
  }

  IconData _getInfoIcon() {
    return Icons.info_outline;
  }

  IconData _getSettingsIcon() {
    return Icons.settings_outlined;
  }
}
