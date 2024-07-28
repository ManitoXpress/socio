import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class ServiceForm extends StatefulWidget {
  final Map<String, dynamic> initialData;

  ServiceForm({required this.initialData});

  @override
  _ServiceFormState createState() => _ServiceFormState();
}

class _ServiceFormState extends State<ServiceForm> {
  late TextEditingController serviceTypeController;
  late TextEditingController descriptionController;
  late TextEditingController imagesController;
  late TextEditingController offeredPriceController;
  late TextEditingController yourPriceController;
  late TextEditingController addressController; // Nuevo controlador para la dirección aleatoria
  late List<TextEditingController> imageControllers; // Controladores para las imágenes

  late double rating; // Controlador para la puntuación
  @override
  void initState() {
    super.initState();

    // Inicializa los controladores de texto con los valores iniciales proporcionados
    serviceTypeController = TextEditingController(text: widget.initialData['serviceType']);
    descriptionController = TextEditingController(text: widget.initialData['description']);
    imagesController = TextEditingController(text: widget.initialData['images'].toString());
    offeredPriceController = TextEditingController(text: widget.initialData['offeredPrice'].toString());
    yourPriceController = TextEditingController();

    // Genera una dirección aleatoria, puedes personalizar esto según tus necesidades
    final randomAddress = generateRandomAddress();
    addressController = TextEditingController(text: randomAddress);

    // Inicializa la puntuación
    rating = 0.0;
  }

  String generateRandomAddress() {
    final List<String> streets = ['123 Main St', '456 Elm St', '789 Oak St'];
    final List<String> cities = ['City A', 'City B', 'City C'];
    final List<String> states = ['State X', 'State Y', 'State Z'];
    final List<String> zipCodes = ['12345', '67890', '54321'];
    final int randomIndex = Random().nextInt(3);
    final String randomAddress = '${streets[randomIndex]}, ${cities[randomIndex]}, ${states[randomIndex]} ${zipCodes[randomIndex]}';
    return randomAddress;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Formulario de Servicio"),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextFormField(
              controller: serviceTypeController,
              decoration: InputDecoration(labelText: "Tipo de servicio"),
            ),
            TextFormField(
              controller: descriptionController,
              decoration: InputDecoration(labelText: "Descripción"),
            ),
            Text("Imágenes:"),
            Row(
              children: List.generate(3, (index) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextFormField(
                      controller: imagesController,
                      decoration: InputDecoration(labelText: "Imagen ${index + 1}"),
                    ),
                  ),
                );
              }),
            ),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: offeredPriceController,
                    decoration: InputDecoration(labelText: "Precio ofrecido"),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: yourPriceController,
                    decoration: InputDecoration(labelText: "Coloca tu precio"),
                  ),
                ),
              ],
            ),
            TextFormField(
              controller: addressController,
              decoration: InputDecoration(labelText: "Dirección"),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text("Puntuación"),
            ),
            RatingBar.builder(
              initialRating: rating,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: true,
              itemCount: 5,
              itemSize: 24,
              itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
              itemBuilder: (context, _) => Icon(
                Icons.star,
                color: Colors.amber,
              ),
              onRatingUpdate: (newRating) {
                setState(() {
                  rating = newRating;
                });
              },
            ),
          ],
        ),
      ),
        actions: [
          Wrap(
            alignment: WrapAlignment.center, // Alinea los elementos al centro
            spacing: 10, // Espacio entre los botones
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
                child: Text("Cancelar", style: TextStyle(color: Colors.white)),
              ),
              SizedBox(width: 10), // Espacio entre los botones
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
                child: Text("Aceptar", style: TextStyle(color: Colors.white)),
              ),
              SizedBox(width: 15), // Espacio entre los botones
              ElevatedButton(
                onPressed: () {
                  final formData = {
                    "serviceType": serviceTypeController.text,
                    "description": descriptionController.text,
                    "images": imagesController.text,
                    "offeredPrice": double.parse(offeredPriceController.text),
                    "yourPrice": double.parse(yourPriceController.text),
                    "address": addressController.text,
                    "rating": rating,
                  };
                  print(formData);
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
                child: Text("Enviar Oferta", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ]
    );
  }
}