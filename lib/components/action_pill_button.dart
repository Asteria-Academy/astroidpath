import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ActionPillButton extends StatelessWidget {
  const ActionPillButton({
    super.key,
    required this.label,
    required this.icon,
    this.onTap,
    this.primaryColor = const Color(0xFF4B3D8A),
    this.isActive = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    this.fontSize = 18,
    this.gap = 10,
    this.width,
    this.elevation = 6,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final Color primaryColor;
  final bool isActive;
  final EdgeInsetsGeometry padding;
  final double fontSize;
  final double gap;
  final double? width;
  final double elevation;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final backgroundColor = isActive ? primaryColor : Colors.white;
    final contentColor = isActive ? Colors.white : primaryColor;
    final borderSide = isActive
        ? BorderSide.none
        : BorderSide(color: primaryColor, width: 2);
    final borderRadius = BorderRadius.circular(999);
    final iconSize = fontSize;
    final effectiveElevation = isActive ? elevation : 0.0;

    final core = Material(
      color: backgroundColor,
      elevation: enabled ? effectiveElevation : 0,
      shadowColor: primaryColor.withOpacity(isActive ? 0.35 : 0.2),
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
        side: borderSide,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: borderRadius,
        child: Padding(
          padding: padding,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: contentColor, size: iconSize),
              SizedBox(width: gap),
              Text(
                label,
                style: GoogleFonts.titanOne(
                  fontSize: fontSize,
                  color: contentColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final body = width == null ? core : SizedBox(width: width, child: core);
    final opacity = enabled ? 1.0 : 0.45;

    return Opacity(opacity: opacity, child: body);
  }
}
