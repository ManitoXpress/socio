import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class WhatsAppUserContactScreen extends StatefulWidget {
  final String userId;

  WhatsAppUserContactScreen({required this.userId});

  @override
  _WhatsAppUserContactScreenState createState() =>
      _WhatsAppUserContactScreenState();
}

class _WhatsAppUserContactScreenState extends State<WhatsAppUserContactScreen> {
  String? phoneNumber;
  String? displayName;

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
  }

  Future<void> _fetchUserInfo() async {
    try {
      final workerDoc = await FirebaseFirestore.instance
          .collection('workers')
          .doc(widget.userId)
          .get();
      if (workerDoc.exists) {
        setState(() {
          displayName = workerDoc['displayName'];
          phoneNumber = workerDoc['phoneNumber'];
        });
      }
    } catch (e) {
      print('Error al obtener datos del trabajador: $e');
    }
  }

  void _openWhatsApp() async {
    if (phoneNumber == null) return;

    final whatsappUrl = Uri.parse(
        "https://wa.me/$phoneNumber?text=Hola $displayName, soy tu trabajador asignado desde la app.");
    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo abrir WhatsApp.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(displayName != null
            ? 'Contactar a $displayName'
            : 'Contacto por WhatsApp'),
      ),
      body: Center(
        child: phoneNumber == null
            ? CircularProgressIndicator()
            : ElevatedButton.icon(
                icon: FaIcon(FontAwesomeIcons.whatsapp),
                label: Text('Chatear con $displayName'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: _openWhatsApp,
              ),
      ),
    );
  }
}
