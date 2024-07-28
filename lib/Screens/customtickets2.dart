import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
class CustomTicketShapePainter2 extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();

    // Dibuja el fondo del ticket
    final backgroundPaint = Paint()..color = Color(0xFFFC3543);
    path.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(8),
      ),
    );

    // Calcula el punto vertical de división
    final divisionX = size.width / 2;

    path.moveTo(divisionX, 0);
    path.lineTo(divisionX, size.height);

    path.addOval(
      Rect.fromCircle(
        center: Offset(0, size.height - 80),
        radius: 25,
      ),
    );
    path.addOval(
      Rect.fromCircle(
        center: Offset(size.width, size.height - 80),
        radius: 25,
      ),
    );

    path.fillType = PathFillType.evenOdd;

    // Dibuja el fondo del ticket
    canvas.drawPath(path, backgroundPaint);

    // Dibuja la línea punteada blanca en el centro del ticket
    final linePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final double dashWidth = 5;
    final double dashSpace = 5;
    double currentX = 0;
    bool draw = true;
    while (currentX < size.height) {
      if (draw) {
        canvas.drawLine(Offset(divisionX, currentX), Offset(divisionX, currentX + dashWidth), linePaint);
      }
      currentX += dashWidth + dashSpace;
      draw = !draw;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
