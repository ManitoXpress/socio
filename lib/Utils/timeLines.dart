import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:socio/ServiceResponse/post.dart';
import 'package:socio/ServiceResponse/request.dart';
import 'package:socio/Utils/statusUtils.dart';

import 'package:timeline_tile/timeline_tile.dart';
import 'dart:convert';

class ServiceFormWithTimeline extends StatefulWidget {
  final ServiceRequest serviceRequest;
  final String initialStatus;
  final ValueChanged<String> onComplete;
  final Function(String) onStatusChanged;
  final String token;
  final UserData userData;

  const ServiceFormWithTimeline({
    required this.serviceRequest,
    required this.initialStatus,
    required this.onComplete,
    required this.onStatusChanged,
    required this.userData,
    required this.token,
  });

  @override
  _ServiceFormWithTimelineState createState() => _ServiceFormWithTimelineState();
}

class _ServiceFormWithTimelineState extends State<ServiceFormWithTimeline> {
  late String status;
  final TextEditingController _cancelReasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    status = widget.initialStatus;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Detalles del Servicio'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fecha y Hora: ${widget.serviceRequest.serviceDateTime}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Descripción: ${widget.serviceRequest.description}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            TimelineTile(
              axis: TimelineAxis.vertical,
              alignment: TimelineAlign.start,
              indicatorStyle: IndicatorStyle(
                width: 40,
                color: _getTextColorByStatus(widget.serviceRequest.status.id),
              ),
              endChild: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Seguimiento del Servicio',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text('Estado: $status'),
                  SizedBox(height: 10),
                  Text(
                    'Precio Ofertado: ${widget.serviceRequest.offeredPrice > 0 ? widget.serviceRequest.offeredPrice.toString() : 'No especificado'}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _showProposalDialog,
                    child: Text('Aceptar Trabajo'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Cierra el cuadro de diálogo
          },
          child: Text('Cerrar'),
        ),
      ],
    );
  }

  void _showProposalDialog() {
    // Definir el controlador para el campo de texto
    final TextEditingController _priceController = TextEditingController(text: widget.serviceRequest.offeredPrice.toString());

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Enviar Propuesta'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Precio Ofertado:'),
                    SizedBox(height: 10),
                    TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number, // Teclado numérico para el precio
                      decoration: InputDecoration(
                        hintText: 'Ingrese el precio ofertado',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Cierra el cuadro de diálogo sin hacer nada
                  },
                  child: Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    double newOfferedPrice = double.tryParse(_priceController.text) ?? 0.0;

                    // Llama a la función para enviar la propuesta al backend
                    ApiService()
                        .sendProposalToBackend(
                            widget.serviceRequest, widget.token, newOfferedPrice.toString())
                        .then((response) {
                      if (response.statusCode == 200) {
                        print('Propuesta enviada con éxito');

                        setState(() {
                          widget.serviceRequest.offeredPrice = newOfferedPrice;
                        });
                      } else {
                        // Error: La solicitud falló
                        print('Error al enviar la propuesta: ${response.statusCode}');
                      }
                    }).catchError((error) {
                      // Maneja el error en caso de que ocurra
                      print('Error al enviar la propuesta: $error');
                    });

                    // Cierra el cuadro de diálogo
                    Navigator.of(context).pop();
                  },
                  child: Text('Enviar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Color _getTextColorByStatus(String statusId) {
    final status = StatusUtils.getStatusById(statusId);

    switch (status.id) {
      case "available":
        return Colors.green; // Color del texto para "Disponible"
      case "assigned":
        return Colors.orange; // Color del texto para "Asignado"
      case "in_progress":
        return Colors.black; // Color del texto para "En curso"
      case "completed":
        return Colors.blue; // Color del texto para "Completado"
      case "cancelled":
        return Color(0xFFFF070F); // Color del texto para "Cancelado"
      default:
        return Colors.grey; // Color del texto para cualquier otro estado
    }
  }
}
