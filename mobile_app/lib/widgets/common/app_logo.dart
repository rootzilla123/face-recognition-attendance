import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final Color? color;

  const AppLogo({
    super.key,
    this.size = 40,
    this.showText = true,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = color ?? Colors.white;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: LogoPainter(color: themeColor),
          ),
        ),
        if (showText) ...[
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ShadomFacePro',
                style: TextStyle(
                  color: themeColor,
                  fontSize: size * 0.45,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.8,
                  height: 1,
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.only(bottom: 2),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: themeColor, width: 1.5)),
                ),
                child: Text(
                  'SMART ATTENDANCE REDEFINED',
                  style: TextStyle(
                    color: themeColor.withOpacity(0.8),
                    fontSize: size * 0.12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    height: 1,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class LogoPainter extends CustomPainter {
  final Color color;

  LogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width * 0.5, size.height * 0.45);
    final hubRadius = size.width * 0.1;

    // Nodes relative positions (0-1 range)
    final nodes = [
      {'pos': Offset(size.width * 0.25, size.height * 0.25), 'r': 0.05}, // NW
      {'pos': Offset(size.width * 0.80, size.height * 0.20), 'r': 0.08}, // NE
      {'pos': Offset(size.width * 0.85, size.height * 0.60), 'r': 0.06}, // ESE
      {'pos': Offset(size.width * 0.40, size.height * 0.85), 'r': 0.06}, // S
      {'pos': Offset(size.width * 0.15, size.height * 0.75), 'r': 0.09}, // SW
    ];

    // Draw lines first
    for (var node in nodes) {
      canvas.drawLine(center, node['pos'] as Offset, linePaint);
    }

    // Draw central hub
    canvas.drawCircle(center, hubRadius, paint);

    // Draw nodes
    for (var node in nodes) {
      canvas.drawCircle(node['pos'] as Offset, size.width * (node['r'] as double), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
