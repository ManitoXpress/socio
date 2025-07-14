import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../ServiceResponse/requestStatus.dart';


class LocationMapSection extends StatelessWidget {
  final LatLng location;
  final Status status;

  const LocationMapSection(
      {Key? key, required this.location, required this.status})
      : super(key: key);

  Future<void> _openGoogleMaps(LatLng location) async {
    final Uri url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${location.latitude},${location.longitude}');

    if (await canLaunchUrl(url)) {
      await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
    } else {
      throw 'No se pudo abrir Google Maps.';
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget mapWidget = GoogleMap(
      initialCameraPosition: CameraPosition(
        target: location,
        zoom: 15.0,
      ),
      // Sin marcadores
      zoomControlsEnabled: false,
      scrollGesturesEnabled: false,
      tiltGesturesEnabled: false,
      rotateGesturesEnabled: false,
      mapToolbarEnabled: false,
      myLocationButtonEnabled: false,
      compassEnabled: false,
    );

    if (status.id == 'in_progress') {
      mapWidget = Container(
        height: 240,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF830A09).withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Mapa de Google
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: location,
                  zoom: 15.0,
                ),
                markers: {
                  Marker(
                    markerId: const MarkerId('serviceLocation'),
                    position: location,
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueRed),
                    infoWindow: const InfoWindow(
                      title: 'Ubicación del trabajo',
                      snippet: 'Aquí se realizará el servicio',
                    ),
                  ),
                },
                zoomControlsEnabled: false,
                scrollGesturesEnabled: false,
                tiltGesturesEnabled: false,
                rotateGesturesEnabled: false,
                mapToolbarEnabled: false,
                myLocationButtonEnabled: false,
                compassEnabled: false,
              ),
              // Capa invisible que captura el tap
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      _openGoogleMaps(location);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
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
                  color: const Color(0xFF830A09)!.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Icon(
                  Icons.location_on,
                  color: const Color(0xFF830A09)!,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Ubicación del Trabajo',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF830A09),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 240,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF830A09), width: 2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF830A09).withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: mapWidget,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF830A09)!, width: 1),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: Color(0xFF830A09),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Esta es la ubicación exacta donde se realizará el trabajo',
                    style: GoogleFonts.karla(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF830A09),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
