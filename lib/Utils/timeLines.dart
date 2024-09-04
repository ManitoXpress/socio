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
  final UserData userData;
  final String workerId;
  const ServiceFormWithTimeline({
    required this.serviceRequest,
    required this.initialStatus,
    required this.onComplete,
    required this.onStatusChanged,
    required this.userData,
    required this.workerId,
  });

  @override
  _ServiceFormWithTimelineState createState() =>
      _ServiceFormWithTimelineState();
}

class _ServiceFormWithTimelineState extends State<ServiceFormWithTimeline> {
  late String status;
  late TextEditingController _cancelReasonController;
  late TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    status = widget.initialStatus;
    _cancelReasonController = TextEditingController();
    _priceController = TextEditingController(text: widget.serviceRequest.offeredPrice.toString());
  }

  @override
  void dispose() {
    _cancelReasonController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Cancelar Trabajo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Coloque su motivo de cancelación de trabajo:'),
              SizedBox(height: 10),
              TextField(
                controller: _cancelReasonController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Escriba su motivo aquí',
                ),
              ),
              SizedBox(height: 10),
              Text('Ejemplos de cancelación de servicio:'),
              _buildCancelReasonButton('No puedo continuar con el trabajo'),
              _buildCancelReasonButton('Emergencia inesperada'),
              _buildCancelReasonButton('Otro motivo'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCancelReasonButton(String reason) {
    return ElevatedButton(
      onPressed: () {
        _cancelJobWithReason(reason);
      },
      child: Text(reason),
    );
  }

  void _cancelJobWithReason(String reason) async {
    try {
      final Status cancelledStatus = Status(id: 'cancelled', name: 'Cancelado');
      setState(() {
        status = cancelledStatus.name;
      });

      await ApiService().updateServiceStatus(
        widget.serviceRequest.id,
        cancelledStatus.id,
        widget.userData.getToken!,
      );

      widget.onComplete(cancelledStatus.id);
      Navigator.of(context).pop();
    } catch (e) {
      print('Error al cancelar el trabajo: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error al cancelar el trabajo'),
      ));
    }
  }

  void _showProposalDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
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
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Ingrese el precio ofertado',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: _sendProposal,
              child: Text('Enviar'),
            ),
          ],
        );
      },
    );
  }

  void _sendProposal() async {
    double newOfferedPrice = double.tryParse(_priceController.text) ?? 0.0;
    try {
      final apiService = ApiService();

      // Cambia el estado a "offer"
      final Status offerStatus = Status(id: 'offer', name: 'Ofertado');
      setState(() {
        status = offerStatus.name;
      });

      // Actualiza el estado en el backend
      await apiService.updateServiceStatus(
        widget.serviceRequest.id,
        offerStatus.id,
        widget.userData.getToken!,
      );

      // Envía la propuesta al backend
      await apiService.sendProposalToFirestore(
        widget.serviceRequest,
        widget.userData.getToken!,
        newOfferedPrice.toString(),
        widget.workerId,
      );

      setState(() {
        widget.serviceRequest.offeredPrice = newOfferedPrice;
      });
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Propuesta enviada con éxito'),
      ));
    } catch (error) {
      _showErrorSnackBar('Error al enviar la propuesta: $error');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Detalles del Servicio'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Fecha y Hora: ${widget.serviceRequest.serviceDateTime}',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Descripción: ${widget.serviceRequest.description}',
                style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            Container(
              height: 280,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Seguimiento del Servicio', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    Text('Estado: $status'),
                    SizedBox(height: 10),
                    Text(
                      'Precio Ofertado: ${widget.serviceRequest.offeredPrice > 0 ? widget.serviceRequest.offeredPrice.toString() : 'No especificado'}',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () => _showCancelDialog(context),
                      child: Text('Cancelar Trabajo'),
                    ),
                    ElevatedButton(
                      onPressed: () => _showProposalDialog(context),
                      child: Text('Enviar Propuesta'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
