import 'package:flutter/material.dart';
import 'package:socio/Screens/uploadDocument.dart';

import '../Utils/Colors.dart';
import '../Utils/styles.dart';
import '../menu/profilescreen.dart';
import '../provider/providerRegistration.dart';
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
