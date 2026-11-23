import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBack;
  final double height;
  final PreferredSizeWidget? bottom;

  const GlassAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.showBack = true,
    this.height = kToolbarHeight,
    this.bottom,
  });

  @override
  Size get preferredSize => Size.fromHeight(height + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surface.withOpacity(0.7),
            border: Border(
              bottom: BorderSide(
                color: AppTheme.glassBorder,
                width: 0.5,
              ),
            ),
          ),
          child: AppBar(
            title: Text(title),
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            leading: leading ??
                (showBack && Navigator.canPop(context)
                    ? IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 20,
                          color: AppTheme.textPrimary,
                        ),
                        onPressed: () => Navigator.pop(context),
                      )
                    : null),
            actions: actions,
            bottom: bottom,
          ),
        ),
      ),
    );
  }
}
