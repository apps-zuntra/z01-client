import 'package:flutter/material.dart';

/// Draws a photography studio backdrop stand — a curved drape sheet
/// hanging from a horizontal crossbar supported by two upright stands with base feet.
class StudioBackdropPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  const StudioBackdropPainter({
    this.color = Colors.white,
    this.strokeWidth = 1.4,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final w = size.width;
    final h = size.height;

    // --- Crossbar (horizontal top rod) ---
    canvas.drawLine(Offset(w * 0.08, h * 0.12), Offset(w * 0.92, h * 0.12), paint);

    // --- Left upright stand ---
    canvas.drawLine(Offset(w * 0.18, h * 0.12), Offset(w * 0.18, h * 0.88), paint);

    // --- Right upright stand ---
    canvas.drawLine(Offset(w * 0.82, h * 0.12), Offset(w * 0.82, h * 0.88), paint);

    // --- Left base feet (Y shape) ---
    canvas.drawLine(Offset(w * 0.18, h * 0.88), Offset(w * 0.06, h * 0.97), paint);
    canvas.drawLine(Offset(w * 0.18, h * 0.88), Offset(w * 0.30, h * 0.97), paint);

    // --- Right base feet (Y shape) ---
    canvas.drawLine(Offset(w * 0.82, h * 0.88), Offset(w * 0.70, h * 0.97), paint);
    canvas.drawLine(Offset(w * 0.82, h * 0.88), Offset(w * 0.94, h * 0.97), paint);

    // --- Hanging drape sheet ---
    // Hangs from the crossbar with a gentle curve toward the bottom
    final drapePath = Path();
    drapePath.moveTo(w * 0.18, h * 0.12);  // Left attach point on crossbar
    drapePath.cubicTo(
      w * 0.18, h * 0.38,   // control 1: hangs straight down on left
      w * 0.10, h * 0.72,   // control 2: fans out at bottom
      w * 0.10, h * 0.85,   // bottom-left of drape
    );
    drapePath.lineTo(w * 0.90, h * 0.85);  // bottom of drape (flat bottom)
    drapePath.cubicTo(
      w * 0.90, h * 0.72,   // control 1: fans in from right bottom
      w * 0.82, h * 0.38,   // control 2: hangs straight down on right
      w * 0.82, h * 0.12,   // back to right attach point
    );
    canvas.drawPath(drapePath, paint);

    // --- Small rings/clips at attach points ---
    canvas.drawCircle(Offset(w * 0.18, h * 0.12), w * 0.018, paint);
    canvas.drawCircle(Offset(w * 0.82, h * 0.12), w * 0.018, paint);
  }

  @override
  bool shouldRepaint(covariant StudioBackdropPainter old) =>
      old.color != color || old.strokeWidth != strokeWidth;
}

/// Draws a three-cabinet speaker/sound system (center cabinet slightly elevated)
/// as clean, minimalist vector line art.
class SoundSystemPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  const SoundSystemPainter({
    this.color = Colors.white,
    this.strokeWidth = 1.4,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final w = size.width;
    final h = size.height;

    // ---- CENTER CABINET (tallest, slightly elevated) ----
    final cL = w * 0.32;
    final cR = w * 0.68;
    final cTop = h * 0.04;
    final cBot = h * 0.82;
    final cRad = 6.0;
    _drawRoundedRect(canvas, paint, cL, cTop, cR, cBot, cRad);

    // Center tweeter (top circle)
    final cMidX = w * 0.50;
    canvas.drawCircle(Offset(cMidX, h * 0.18), w * 0.08, paint);
    canvas.drawCircle(Offset(cMidX, h * 0.18), w * 0.04, paint);

    // Center woofer (large circle)
    canvas.drawCircle(Offset(cMidX, h * 0.50), w * 0.13, paint);
    canvas.drawCircle(Offset(cMidX, h * 0.50), w * 0.07, paint);

    // Center port slits
    canvas.drawLine(Offset(w * 0.36, h * 0.74), Offset(w * 0.64, h * 0.74), paint);
    canvas.drawLine(Offset(w * 0.36, h * 0.78), Offset(w * 0.64, h * 0.78), paint);

    // Center cabinet base leg
    canvas.drawLine(Offset(cMidX, cBot), Offset(cMidX, h * 0.92), paint);
    canvas.drawLine(Offset(w * 0.38, h * 0.92), Offset(w * 0.62, h * 0.92), paint);

    // ---- LEFT CABINET ----
    final lL = w * 0.02;
    final lR = w * 0.28;
    final lTop = h * 0.18;
    final lBot = h * 0.82;
    _drawRoundedRect(canvas, paint, lL, lTop, lR, lBot, cRad);

    final lMidX = (lL + lR) / 2;
    canvas.drawCircle(Offset(lMidX, h * 0.30), w * 0.06, paint);
    canvas.drawCircle(Offset(lMidX, h * 0.30), w * 0.03, paint);
    canvas.drawCircle(Offset(lMidX, h * 0.55), w * 0.10, paint);
    canvas.drawCircle(Offset(lMidX, h * 0.55), w * 0.055, paint);
    canvas.drawLine(Offset(w * 0.04, h * 0.73), Offset(w * 0.26, h * 0.73), paint);
    canvas.drawLine(Offset(w * 0.04, h * 0.77), Offset(w * 0.26, h * 0.77), paint);

    // ---- RIGHT CABINET ----
    final rL = w * 0.72;
    final rR = w * 0.98;
    final rTop = h * 0.18;
    final rBot = h * 0.82;
    _drawRoundedRect(canvas, paint, rL, rTop, rR, rBot, cRad);

    final rMidX = (rL + rR) / 2;
    canvas.drawCircle(Offset(rMidX, h * 0.30), w * 0.06, paint);
    canvas.drawCircle(Offset(rMidX, h * 0.30), w * 0.03, paint);
    canvas.drawCircle(Offset(rMidX, h * 0.55), w * 0.10, paint);
    canvas.drawCircle(Offset(rMidX, h * 0.55), w * 0.055, paint);
    canvas.drawLine(Offset(w * 0.74, h * 0.73), Offset(w * 0.96, h * 0.73), paint);
    canvas.drawLine(Offset(w * 0.74, h * 0.77), Offset(w * 0.96, h * 0.77), paint);
  }

  void _drawRoundedRect(Canvas canvas, Paint paint, double l, double t, double r, double b, double radius) {
    canvas.drawRRect(
      RRect.fromLTRBR(l, t, r, b, Radius.circular(radius)),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant SoundSystemPainter old) =>
      old.color != color || old.strokeWidth != strokeWidth;
}

/// Draws a camera body with lens — used as watermark for Cameras category.
class CameraBodyPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  const CameraBodyPainter({
    this.color = Colors.white,
    this.strokeWidth = 1.4,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final w = size.width;
    final h = size.height;

    // Camera body
    final bodyPath = Path();
    bodyPath.moveTo(w * 0.10, h * 0.35);
    bodyPath.lineTo(w * 0.10, h * 0.80);
    bodyPath.lineTo(w * 0.90, h * 0.80);
    bodyPath.lineTo(w * 0.90, h * 0.35);
    bodyPath.lineTo(w * 0.75, h * 0.35);
    bodyPath.lineTo(w * 0.70, h * 0.22);
    bodyPath.lineTo(w * 0.30, h * 0.22);
    bodyPath.lineTo(w * 0.25, h * 0.35);
    bodyPath.close();
    canvas.drawPath(bodyPath, paint);

    // Lens circle (outer)
    canvas.drawCircle(Offset(w * 0.50, h * 0.58), w * 0.20, paint);
    // Lens circle (inner)
    canvas.drawCircle(Offset(w * 0.50, h * 0.58), w * 0.11, paint);

    // Viewfinder rectangle (top right)
    canvas.drawRRect(
      RRect.fromLTRBR(w * 0.65, h * 0.28, w * 0.84, h * 0.42, const Radius.circular(3)),
      paint,
    );

    // Shutter button (top circle)
    canvas.drawCircle(Offset(w * 0.28, h * 0.26), w * 0.04, paint);
  }

  @override
  bool shouldRepaint(covariant CameraBodyPainter old) =>
      old.color != color || old.strokeWidth != strokeWidth;
}

/// Draws a drone with four rotor arms — used as watermark for Drones category.
class DronePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  const DronePainter({
    this.color = Colors.white,
    this.strokeWidth = 1.4,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final w = size.width;
    final h = size.height;
    final cx = w * 0.50;
    final cy = h * 0.50;

    // Center body (hexagon approximated as rounded rect)
    canvas.drawRRect(
      RRect.fromLTRBR(cx - w * 0.12, cy - h * 0.10, cx + w * 0.12, cy + h * 0.10, const Radius.circular(6)),
      paint,
    );

    // 4 diagonal arms
    canvas.drawLine(Offset(cx - w * 0.12, cy - h * 0.10), Offset(cx - w * 0.35, cy - h * 0.32), paint);
    canvas.drawLine(Offset(cx + w * 0.12, cy - h * 0.10), Offset(cx + w * 0.35, cy - h * 0.32), paint);
    canvas.drawLine(Offset(cx - w * 0.12, cy + h * 0.10), Offset(cx - w * 0.35, cy + h * 0.32), paint);
    canvas.drawLine(Offset(cx + w * 0.12, cy + h * 0.10), Offset(cx + w * 0.35, cy + h * 0.32), paint);

    // 4 rotors (ellipses at arm tips)
    for (final offset in [
      Offset(cx - w * 0.35, cy - h * 0.32),
      Offset(cx + w * 0.35, cy - h * 0.32),
      Offset(cx - w * 0.35, cy + h * 0.32),
      Offset(cx + w * 0.35, cy + h * 0.32),
    ]) {
      canvas.drawOval(
        Rect.fromCenter(center: offset, width: w * 0.22, height: h * 0.09),
        paint,
      );
    }

    // Camera gimbal dangling below center
    canvas.drawLine(Offset(cx, cy + h * 0.10), Offset(cx, cy + h * 0.22), paint);
    canvas.drawCircle(Offset(cx, cy + h * 0.28), w * 0.055, paint);
  }

  @override
  bool shouldRepaint(covariant DronePainter old) =>
      old.color != color || old.strokeWidth != strokeWidth;
}
