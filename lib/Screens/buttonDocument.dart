import 'package:flutter/material.dart';
import 'package:socio/Screens/updaloadDocument.dart';
import 'package:socio/Utils/Colors.dart';
import 'package:socio/Utils/styles.dart';
import 'package:socio/menu/profilescreen.dart';
import 'package:socio/provider/providerRegistration.dart';
class DocumentsScreen extends StatelessWidget {
  final RegistrationProvider provider;
  final ProfileData profileData;
  final VoidCallback onSaved;

  const DocumentsScreen({
    Key? key,
    required this.provider,
    required this.profileData,
    required this.onSaved,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
  
      body: DocumentsDialog(
        provider: provider,
        profileData: profileData,
        onSaved: () {
          // Llamamos al callback padre
          onSaved();
          // Devolvemos 'true' al HomeScreen para que sepa que se subió con éxito
          Navigator.of(context).pop(true);
        },
      ),
    );
  }
}