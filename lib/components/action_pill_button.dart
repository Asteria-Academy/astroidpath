import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ActionPillButton extends StatelessWidget {
  const ActionPillButton({
    super.key,
    required this.label,
    required this.onTap,
    required this.icon,
    required this.accentColor,
    required this.buttonColor,
    this.height, // tinggi pasti (opsional)
    this.width, // lebar pasti (opsional)
    this.minWidth = 160, // kalau width null, pakai minWidth
    this.fontSize = 18,
  });

  final String label;
  final VoidCallback onTap;
  final IconData icon;
  final Color accentColor;
  final Color buttonColor;
  final double? height; // ex: 56
  final double? width; // ex: 200
  final double minWidth; // ex: 160
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final h = height ?? 56;
    final r = BorderRadius.circular(h * 0.45);

    final core = Material(
      color: buttonColor,
      elevation: 6,
      shadowColor: accentColor.withOpacity(0.35),
      borderRadius: r,
      child: InkWell(
        onTap: onTap,
        borderRadius: r,
        child: SizedBox(
          height: h,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: h * 0.4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: h * 0.6,
                  height: h * 0.6,
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: fontSize * 1.2),
                ),
                SizedBox(width: h * 0.3),
                Text(
                  label,
                  style: GoogleFonts.titanOne(
                    fontSize: fontSize,
                    color: accentColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // width pasti -> SizedBox(width: width)
    // width null -> hanya minWidth (bisa melebar sesuai konten/layout)
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: minWidth),
      child: width == null ? core : SizedBox(width: width, child: core),
    );
  }
}
