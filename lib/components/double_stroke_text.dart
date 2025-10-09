import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DoubleStrokeText extends StatelessWidget {
  final String text;
  final double fontSize;
  final double letterSpacing;
  final TextAlign textAlign;

  // warna & ketebalan bisa kamu sesuaikan
  final Color outerStrokeColor; // biru gelap
  final Color innerStrokeColor; // biru terang
  final Color fillColor; // putih
  final double outerStrokeWidth;
  final double innerStrokeWidth;

  const DoubleStrokeText({
    super.key,
    required this.text,
    this.fontSize = 32,
    this.letterSpacing = 0,
    this.textAlign = TextAlign.center,
    this.outerStrokeColor = const Color(0xFF0C2F66), // biru gelap
    this.innerStrokeColor = const Color(0xFF6EE7FF), // biru terang
    this.fillColor = const Color(0xFFFFFFFF),
    this.outerStrokeWidth = 4.0,
    this.innerStrokeWidth = 2.0,
  });

  Text _stroke(String t, Color c, double w) {
    return Text(
      t,
      textAlign: textAlign,
      style: GoogleFonts.titanOne(
        fontSize: fontSize,
        letterSpacing: letterSpacing,
        foreground: Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = w
          ..color = c,
      ),
    );
  }

  Text _fill(String t, Color c) {
    return Text(
      t,
      textAlign: textAlign,
      style: GoogleFonts.titanOne(
        fontSize: fontSize,
        letterSpacing: letterSpacing,
        color: c,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center, // pastikan layer pas tumpukannya
      children: [
        _stroke(text, innerStrokeColor, innerStrokeWidth),

        _stroke(text, outerStrokeColor, outerStrokeWidth),

        _fill(text, fillColor),
      ],
    );
  }
}
