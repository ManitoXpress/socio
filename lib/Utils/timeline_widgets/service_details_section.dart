import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ServiceDetailsSection extends StatelessWidget {
  final String status;
  final String date;
  final String time;
  final List<String> serviceTypes;
  final LatLng location;
  final String? address;

  const ServiceDetailsSection({
    Key? key,
    required this.status,
    required this.date,
    required this.time,
    required this.serviceTypes,
    required this.location,
    this.address,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
            color: const Color(0xFF84090D).withOpacity(0.1), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF84090D).withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Icon(
                  _getStatusIcon(status),
                  color: _getStatusColor(status),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ESTADO DEL SERVICIO',
                      style: GoogleFonts.karla(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      status,
                      style: GoogleFonts.karla(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(status),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.calendar_today,
                  iconColor: Colors.blue[600]!,
                  title: 'Fecha',
                  value: date,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.access_time,
                  iconColor: Colors.orange[600]!,
                  title: 'Hora',
                  value: time,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.build,
                    color: Colors.purple[600],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Tipos de Servicio',
                    style: GoogleFonts.karla(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: serviceTypes
                    .map((type) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF84090D).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF84090D).withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            type,
                            style: GoogleFonts.karla(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF84090D),
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.karla(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.karla(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'disponible':
        return Colors.blue[600]!;
      case 'ofertado':
        return Colors.orange[600]!;
      case 'en curso':
        return Colors.amber[600]!;
      case 'completado':
        return Colors.green[600]!;
      case 'cancelado':
        return Colors.red[600]!;
      case 'bloqueado':
        return Colors.grey[600]!;
      default:
        return const Color(0xFF84090D);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'disponible':
        return Icons.check_circle;
      case 'ofertado':
        return Icons.local_offer;
      case 'en curso':
        return Icons.work;
      case 'completado':
        return Icons.task_alt;
      case 'cancelado':
        return Icons.cancel;
      case 'bloqueado':
        return Icons.block;
      default:
        return Icons.info;
    }
  }
}
