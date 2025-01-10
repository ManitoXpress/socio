import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:socio/Screens/Chatscreen.dart';
import 'package:socio/ServiceResponse/request.dart';
import 'package:socio/Utils/styles.dart';

class ServiceFormPage extends StatefulWidget {
  final ServiceRequest serviceRequest;

  ServiceFormPage({required this.serviceRequest});

  @override
  _ServiceFormPageState createState() => _ServiceFormPageState();
}

class _ServiceFormPageState extends State<ServiceFormPage> {
  late bool requireMaterials = false;

  get selectedService => null;

  set selectedDate(DateTime selectedDate) {}

  DateTime generateRandomDate() {
    var random = Random();
    int randomDays = random.nextInt(365) + 1;
    int randomHour = random.nextInt(24);
    int randomMinute = random.nextInt(60);

    DateTime randomDateTime = DateTime.now().add(
        Duration(days: randomDays, hours: randomHour, minutes: randomMinute));
    return randomDateTime;
  }

  void showImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: SizedBox(
          width: MediaQuery.of(context).size.width *
              0.7, // Aquí puedes ajustar el tamaño del diálogo a tus necesidades
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var random = Random();

    String randomName = 'Usuario ${random.nextInt(100)}';
    String randomEmail = 'correo${random.nextInt(100)}@example.com';
    int suggestedPrice = random.nextInt(900) + 100;

    DateTime randomDateTime = generateRandomDate();
    String randomDate = DateFormat('yyyy-MM-dd').format(randomDateTime);
    String randomTime = DateFormat('HH:mm').format(randomDateTime);

    List<String> imageUrls = [
      'https://via.placeholder.com/150',
      'https://via.placeholder.com/150',
      'https://via.placeholder.com/150',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Formulario de Servicio',
          style: MyTextStyles.buttonTextStyle,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 70.0, // Ajusta el ancho según tus necesidades
              height: 70.0, // Ajusta la altura según tus necesidades
              child: Image.network(
                'https://i.imgur.com/EcmcVKO.png',
                fit: BoxFit
                    .contain, // Puedes cambiar esto a BoxFit.fill, BoxFit.contain, etc. según tus necesidades
              ),
            ),
            const SizedBox(height: 8.0),
            Center(
              child: Text(
                randomName,
                style: const TextStyle(
                  color: Color(0xFF841813),
                  fontSize: 16,
                  fontFamily: 'Xpress Heavy', // Nombre de la fuente
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 8.0),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tipo de servicio: ${widget.serviceRequest.serviceType}',
                  style: const TextStyle(
                    color: Color(0xFF841813),
                    fontSize: 16,
                    fontFamily: 'Xpress Heavy', // Nombre de la fuente
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  'Precio Ofertado: $suggestedPrice Bs.',
                  style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'Xpress Heavy', // Nombre de la fuente
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 8.0),
                const Text(
                  'Ingrese su Oferta:',
                  style: TextStyle(
                    color: Color(0xFF841813),
                    fontSize: 16,
                    fontFamily: 'Xpress Heavy', // Nombre de la fuente
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 8.0),
                TextFormField(
                  maxLines: 1,
                  decoration: const InputDecoration(
                    hintText: 'Precio del trabajo',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      var additionalDetails = value;
                    });
                  },
                ),
                const SizedBox(height: 16.0),
                Text(
                  'Fecha: $randomDate',
                  style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'Xpress Heavy', // Nombre de la fuente
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  'Hora: $randomTime',
                  style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'Xpress Heavy', // Nombre de la fuente
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 16.0),
                const Text(
                  'Detalles del servicio:',
                  style: TextStyle(
                    color: Color(0xFF841813),
                    fontSize: 16,
                    fontFamily: 'Xpress Heavy', // Nombre de la fuente
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 8.0),
                Container(
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    border: Border.all(),
                  ),
                  child: const Text(
                    'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Praesent vehicula, mi at varius cursus, nunc mauris mollis magna, sed congue diam mauris nec arcu.',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Xpress Heavy', // Nombre de la fuente
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    GestureDetector(
                      onTap: () => showImage(context, imageUrls[0]),
                      child: Image.network(
                        'https://i.imgur.com/pz129gl.jpg', // Primera URL de la lista de imageUrls
                        width: MediaQuery.of(context).size.width *
                            0.28, // Ajusta el ancho a aproximadamente 1/3 del ancho de la pantalla
                        fit: BoxFit.cover,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => showImage(context, imageUrls[1]),
                      child: Image.network(
                        'https://i.imgur.com/sC3I32u.png', // Segunda URL de la lista de imageUrls
                        width: MediaQuery.of(context).size.width * 0.28,
                        fit: BoxFit.cover,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => showImage(context, imageUrls[2]),
                      child: Image.network(
                        'https://i.imgur.com/aIwbDOO.jpg', // Tercera URL de la lista de imageUrls
                        width: MediaQuery.of(context).size.width * 0.28,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),
              ],
            ),
            const SizedBox(height: 16.0),
            Row(
              children: [
                Checkbox(
                  value: false,
                  onChanged: (value) {},
                ),
                const Text('Acepto los Términos y Condiciones'),
              ],
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                // Envía el formulario
              },
              child: const Text('Enviar'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navegar hacia la pantalla de chat
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ChatScreen(chatId: '', userId: '', workerId: '',)),
          );
        },
        child: const Icon(Icons.chat),
        backgroundColor: Colors.amberAccent,
      ),
    );
  }
}
