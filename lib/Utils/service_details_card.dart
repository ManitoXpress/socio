import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../Utils/styles.dart';

class ServiceDetailsCard extends StatelessWidget {
  final String status;
  final String date;
  final String time;
  final String? phone;
  final List<String> serviceTypes;
  final LatLng location;
  final String? address;
  const ServiceDetailsCard({
    Key? key,
    required this.status,
    required this.date,
    required this.time,
    this.phone,
    required this.serviceTypes,
    required this.location,
    this.address,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Estado
            Row(
              children: [
                Icon(Icons.info, color: Color(0xFF84090D)),
                const SizedBox(width: 8),
                Text(
                  'Estado:',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF84090D)),
                ),
                const SizedBox(width: 8),
                Text(
                  status,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _statusColor(status),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Fecha y hora
            Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.blueGrey, size: 20),
                const SizedBox(width: 8),
                Text('Fecha: $date', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(width: 16),
                Icon(Icons.access_time, color: Colors.blueGrey, size: 20),
                const SizedBox(width: 8),
                Text('Hora: $time', style: TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 12),
            // Teléfono (si hay)
            if (phone != null) ...[
              Row(
                children: [
                  Icon(Icons.phone, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Text('Teléfono: $phone', style: TextStyle(fontWeight: FontWeight.w500)),
                ],
              ),
              const SizedBox(height: 12),
            ],
            // Tipos de servicio
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.build, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Text('Tipo:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 2,
                    children: serviceTypes.map((type) => Chip(
                      label: Text(type, style: TextStyle(fontWeight: FontWeight.w500)),
                      backgroundColor: Color(0xFF84090D).withOpacity(0.08),
                      labelStyle: TextStyle(color: Color(0xFF84090D)),
                    )).toList(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Ubicación
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ubicación:', style: TextStyle(fontWeight: FontWeight.bold)),
                      if (address != null)
                        Text(address!, style: TextStyle(color: Colors.black87)),
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        height: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: location,
                              zoom: 14.0,
                            ),
                            markers: {
                              Marker(
                                markerId: const MarkerId('serviceLocation'),
                                position: location,
                              ),
                            },
                            zoomControlsEnabled: false,
                            scrollGesturesEnabled: false,
                            tiltGesturesEnabled: false,
                            rotateGesturesEnabled: false,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'disponible':
        return Colors.blue;
      case 'ofertado':
        return Colors.orange;
      case 'en curso':
        return Colors.amber;
      case 'completado':
        return Colors.green;
      case 'cancelado':
        return Colors.red;
      case 'bloqueado':
        return Colors.grey;
      default:
        return Color(0xFF84090D);
    }
  }
} 