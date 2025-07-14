import 'package:flutter/material.dart';

class WalletTotalsSummary extends StatelessWidget {
  final double adeudado;
  final double ingresos;
  final double pagado;

  const WalletTotalsSummary({
    Key? key,
    required this.adeudado,
    required this.ingresos,
    required this.pagado,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: _buildTotalCard(
                'Adeudado',
                '\Bs ${adeudado.toStringAsFixed(2)}',
                const Color(0xFF84090D),
                Icons.warning),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildTotalCard(
                'Ingresos',
                '\Bs ${ingresos.toStringAsFixed(2)}',
                Colors.black87,
                Icons.trending_up),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildTotalCard('Pagado', '\Bs ${pagado.toStringAsFixed(2)}',
                const Color(0xFF4CAF50), Icons.check_circle),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalCard(
      String label, String value, Color color, IconData icon) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      color: Colors.white,
      shadowColor: color.withOpacity(0.08),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: label == 'Adeudado'
                    ? const Color(0xFF84090D)
                    : (label == 'Pagado'
                        ? const Color(0xFF4CAF50)
                        : Colors.black87),
                size: 24),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    color: label == 'Adeudado'
                        ? const Color(0xFF84090D)
                        : (label == 'Pagado'
                            ? const Color(0xFF4CAF50)
                            : Colors.black87),
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: label == 'Adeudado'
                      ? const Color(0xFF84090D)
                      : (label == 'Pagado'
                          ? const Color(0xFF4CAF50)
                          : Colors.black87),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
