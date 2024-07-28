import 'package:flutter/material.dart';
import 'package:flutter_wizard/flutter_wizard.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
class RegisterScreen extends StatelessWidget {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController(); // Añadido el controlador para el número de teléfono
  Future<void> _register(BuildContext context) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      User? user = userCredential.user;

      if (user != null) {
        // Imprimir el UID del usuario recién registrado
        print('User registered with UID: ${user.uid}');

        // Obtener el ID token del usuario
        String? token = await user.getIdToken();
        print("User's ID Token: $token");

        // Aquí podrías enviar el token a tu servidor, por ejemplo:
        // final response = await http.post(
        //   'https://your-server-endpoint.com/api/verify-token',
        //   headers: <String, String>{
        //     'Authorization': 'Bearer $token',
        //   },
        // );
        // Si tu servidor devuelve un error, puedes manejarlo aquí.

        // Actualizar el displayName del usuario
        await user.updateDisplayName(_usernameController.text);
        await user.reload();
        user = FirebaseAuth.instance.currentUser;

        // Crear un nuevo documento para el usuario en Firestore con su información adicional
        CollectionReference users = FirebaseFirestore.instance.collection('users');
        await users.doc(user!.uid).set({
          'displayName': _usernameController.text,
          'email': _emailController.text,
          'phoneNumber': _phoneController.text,
          // ... cualquier otro campo que quieras almacenar
        });

        // Mostrar un mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Registrado exitosamente')));

        // Regresar a la página de login
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      // Manejar errores
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Ocurrió un error')));
    }
  }
  Future<void> getUserInfo(String uid) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        print('User data: $userData');
      } else {
        print('Usuario no existe!');
      }
    } catch (e) {
      print('Error getting user data: $e');
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffd6e2ea),
      appBar: AppBar(
        title: Text('Registrarse'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Stack(
        children: [
          Container(
            color: Color(0xFF68B8D5),// Fondo azul sólido
            width: double.infinity,
            height: double.infinity,
          ),
          SingleChildScrollView(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height / 6),
                  Text(
                    "CREA TU CUENTA",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 20),
                  SizedBox(height: MediaQuery.of(context).size.height / 16),
                  Container(
                    alignment: Alignment.center,
                    width: 400,
                    padding: const EdgeInsets.only(bottom: 15),
                    margin: const EdgeInsets.only(bottom: 15 * 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: Column(
                        children: [
                          const SizedBox(height: 15),
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(fontSize: 14),
                            cursorColor: const Color(0xffb04863),
                            decoration: const InputDecoration(
                              hintText: "Correo electrónico",
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(10)),
                              ),
                              focusColor: Color(0xffb04863),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Color(0xffb04863),
                                ),
                                borderRadius: BorderRadius.all(Radius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
                          TextField(
                            controller: _passwordController,
                            keyboardType: TextInputType.text,
                            obscureText: true,
                            style: const TextStyle(fontSize: 14),
                            cursorColor: const Color(0xffb04863),
                            decoration: const InputDecoration(
                              hintText: "Contraseña",
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(10)),
                              ),
                              focusColor: Color(0xffb04863),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Color(0xffb04863),
                                ),
                                borderRadius: BorderRadius.all(Radius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
                          TextField(
                            controller: _phoneController,  // Controlador para el número de teléfono
                            keyboardType: TextInputType.phone,
                            style: const TextStyle(fontSize: 14),
                            cursorColor: const Color(0xffb04863),
                            decoration: const InputDecoration(
                              hintText: "Número de teléfono",
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(10)),
                              ),
                              focusColor: Color(0xffb04863),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Color(0xffb04863),
                                ),
                                borderRadius: BorderRadius.all(Radius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
                          TextField(
                            controller: _usernameController,
                            style: const TextStyle(fontSize: 14),
                            cursorColor: const Color(0xffb04863),
                            decoration: const InputDecoration(
                              hintText: "Nombre de usuario",
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(10)),
                              ),
                              focusColor: Color(0xffb04863),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Color(0xffb04863),
                                ),
                                borderRadius: BorderRadius.all(Radius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
                          ElevatedButton(
                            onPressed: () async {
                              await _register(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A819A),
                            ),
                            child: const Text("Registrarme"),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}