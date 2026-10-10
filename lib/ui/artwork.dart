import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'local_image.dart' if (dart.library.io) 'local_image_io.dart';

/// Carátulas originales dibujadas localmente: no necesitan conexión a internet.
class CoverArt extends StatelessWidget {
  const CoverArt(
      {super.key,
      required this.variant,
      this.size,
      this.radius = 12,
      this.imageUrl = ''});
  final int variant;
  final double? size;
  final double radius;
  final String imageUrl;
  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: SizedBox(
            width: size,
            height: size,
            child: imageUrl.isNotEmpty
                ? Image(
                    image: localImage(imageUrl) ?? NetworkImage(imageUrl),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) => const ColoredBox(
                        color: Color(0xFF303030),
                        child: Center(
                            child: Icon(Icons.music_note_rounded,
                                color: Colors.white))),
                    loadingBuilder: (context, child, progress) =>
                        progress == null
                            ? child
                            : const ColoredBox(
                                color: Color(0xFF303030),
                                child: Center(
                                    child: Icon(Icons.music_note_rounded,
                                        color: Colors.white))),
                  )
                : CustomPaint(
                    painter: _CoverPainter(variant),
                    child: const SizedBox.expand())),
      );
}

class _CoverPainter extends CustomPainter {
  _CoverPainter(this.variant);
  final int variant;
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final palettes = [
      [
        const Color(0xFF251A52),
        const Color(0xFFB879AC),
        const Color(0xFFF0B595)
      ],
      [
        const Color(0xFF032A45),
        const Color(0xFF1F7A95),
        const Color(0xFFCEE0C9)
      ],
      [
        const Color(0xFF662E55),
        const Color(0xFFDA866F),
        const Color(0xFFFAD99C)
      ],
      [
        const Color(0xFF120F2D),
        const Color(0xFF514586),
        const Color(0xFFD4B2DA)
      ],
      [
        const Color(0xFF173E43),
        const Color(0xFF7CA6A2),
        const Color(0xFFF0DDC0)
      ],
      [
        const Color(0xFF182044),
        const Color(0xFF5874A2),
        const Color(0xFFBFB8D8)
      ],
    ];
    final colors = palettes[variant % palettes.length];
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: colors,
        stops: const [0, .65, 1],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, paint);
    final rng = math.Random(variant + 100);
    paint.shader = null;
    for (var i = 0; i < 65; i++) {
      paint.color = Colors.white.withValues(alpha: rng.nextDouble() * .6);
      canvas.drawCircle(
          Offset(rng.nextDouble() * w, rng.nextDouble() * h * .55),
          w * .002,
          paint);
    }
    paint.color = colors.last.withValues(alpha: .8);
    final sun = Offset(w * .66, h * .35);
    canvas.drawCircle(sun, w * (variant == 3 ? .21 : .12), paint);
    if (variant == 3) {
      paint.color = colors.first;
      canvas.drawCircle(sun.translate(w * .06, -h * .03), w * .20, paint);
      paint
        ..color = colors.last.withValues(alpha: .5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * .008;
      canvas.save();
      canvas.translate(sun.dx, sun.dy);
      canvas.rotate(-.4);
      canvas.drawOval(
          Rect.fromCenter(center: Offset.zero, width: w * .57, height: h * .14),
          paint);
      canvas.restore();
      paint.style = PaintingStyle.fill;
    }
    for (var layer = 0; layer < 4; layer++) {
      final path = Path()..moveTo(0, h);
      for (var x = 0.0; x <= w + w / 30; x += w / 30) {
        final y = h * (.55 + layer * .11) +
            math.sin(x / w * 5 + layer * 1.6 + variant) * h * .10 +
            math.cos(x / w * 11 + layer) * h * .025;
        path.lineTo(x, y);
      }
      path
        ..lineTo(w, h)
        ..close();
      paint.color = Color.lerp(colors[1], colors.first, .35 + layer * .18)!;
      canvas.drawPath(path, paint);
    }
    if (variant == 1 || variant == 5) {
      for (var i = 0; i < 11; i++) {
        final height = h * (.08 + rng.nextDouble() * .22);
        paint.color = colors.first.withValues(alpha: .7);
        canvas.drawRect(
            Rect.fromLTWH(
                i * w / 10, h * .8 - height, w * .07, height + h * .2),
            paint);
        paint.color = colors.last.withValues(alpha: .45);
        canvas.drawRect(
            Rect.fromLTWH(
                i * w / 10 + w * .02, h * .81 - height, w * .008, h * .01),
            paint);
      }
    }
    for (var i = 0; i < 1200; i++) {
      paint.color =
          (i.isEven ? Colors.white : Colors.black).withValues(alpha: .035);
      canvas.drawCircle(
          Offset(rng.nextDouble() * w, rng.nextDouble() * h), w * .002, paint);
    }
  }

  @override
  bool shouldRepaint(_CoverPainter oldDelegate) =>
      oldDelegate.variant != variant;
}
