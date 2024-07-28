import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ServiceScreen extends StatefulWidget {
  @override
  _ServiceScreenState createState() => _ServiceScreenState();
}

class _ServiceScreenState extends State<ServiceScreen> {
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: const Color(0xffd6e2ea),
      appBar: AppBar(
        title: Row(
          children: [
            Flexible(
              child: Container(
                padding: EdgeInsets.all(screenWidth * 0.01),
                constraints: BoxConstraints(maxWidth: screenWidth * 0.2),
                child: Image.asset(
                  'assets/images/LOGO1_Blanco.png',
                  width: double.infinity,
                  height: screenWidth * 0.1,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            SizedBox(width: screenWidth * 0.02),
            Text(
              'ManitoXpress Socio',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Xpress Heavy',
                fontWeight: FontWeight.normal,
                fontStyle: FontStyle.italic,
                fontSize: screenHeight * 0.025,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: screenHeight * 0.1),
              // Espacio en blanco para separar del AppBar
              Image.asset(
                'assets/manito.png',
                // Reemplaza 'tu_imagen.png' con la ruta de tu imagen
                width: screenWidth *
                    0.8, // Ajusta el tamaño de la imagen según sea necesario
              ),
              SizedBox(height: screenHeight * 0.05),
              // Espacio en blanco entre la imagen y el texto
              Text(
                '¡Muy pronto llegarán solicitudes!',
                style: TextStyle(
                  color: Colors.red, // Cambia el color del texto a rojo
                  fontSize: screenHeight *
                      0.03, // Ajusta el tamaño del texto según sea necesario
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
