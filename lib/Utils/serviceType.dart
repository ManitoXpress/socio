import 'package:flutter/material.dart';
import 'package:socio/Metods/RegisController.dart';
import 'package:socio/Utils/styles.dart';

class ServiceTypeListScreen extends StatefulWidget {
  final RegistrationController registrationController;
  final void Function() onNextStep;
  final void Function(
          List<String> serviceTypes, String? selectedExperienceLevel)
      onServiceTypesSelected;
  final Map<String, List<String>> categories;

  ServiceTypeListScreen({
    required this.registrationController,
    required this.onNextStep,
    required this.onServiceTypesSelected,
    required this.categories,
    required Null Function(dynamic serviceType) onServiceTypeSelected,
  });

  @override
  _ServiceTypeListScreenState createState() => _ServiceTypeListScreenState();
}

class _ServiceTypeListScreenState extends State<ServiceTypeListScreen> {
  List<String> selectedCategories = [];
  List<String> selectedSubcategories = [];
  bool showCustomProfessionField = false;
  TextEditingController customProfessionController = TextEditingController();
  List<String> expLevel = ['0-3 años', '3-5 años', '5-7 años'];
  String? selectedExperienceLevel;
  List<String> allSubcategories = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffd6e2ea),
      appBar: AppBar(
        title: Row(
          children: [
            Flexible(
              child: Container(
                padding:
                    EdgeInsets.all(MediaQuery.of(context).size.width * 0.01),
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.2,
                ),
                child: Image.asset(
                  'assets/images/LOGO1_Blanco.png',
                  width: double.infinity,
                  height: MediaQuery.of(context).size.width * 0.1,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            SizedBox(width: MediaQuery.of(context).size.width * 0.02),
            Text(
              'ManitoXpress Socio',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Xpress Heavy',
                fontWeight: FontWeight.normal,
                fontStyle: FontStyle.italic,
                fontSize: MediaQuery.of(context).size.height * 0.025,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Row(
              children: [
                buildCategoryButton(
                    'Servicios Básicos', const Color(0xFFF6E44D), 150.0),
                SizedBox(width: 10), // Añade un espacio horizontal de 10 puntos
                buildCategoryButton(
                    'Servicios Profesionales', const Color(0xFFF6E44D), 160.0),
              ],
            ),
            SizedBox(height: 10),
            if (selectedCategories.isNotEmpty)
              Column(
                children: [
                  Text(
                    'Categorías seleccionadas: ${selectedCategories.join(", ")}',
                    style: TextStyle(color: Colors.red),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Seleccione una o varias profesiones:',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 10),
                  buildSubcategoryDropdown(),
                ],
              ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  showCustomProfessionField = true;
                });
              },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
                backgroundColor: Color(0xFF84090D),
                minimumSize: Size(double.infinity, 50),
              ),
              child: Text(
                "No encuentro mi profesión",
                style: MyTextStyles.serviceTitleTextStyle,
              ),
            ),
            if (showCustomProfessionField)
              Column(
                children: [
                  TextField(
                    controller: customProfessionController,
                    decoration: InputDecoration(
                      hintText:
                          'Ingrese la profesión o servicio que desea ofertar',
                    ),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      String customProfession = customProfessionController.text;

                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text("Gracias por su colaboración"),
                            content: Text(
                              "En Manitos Xpress nos preocupamos por nuestros usuarios y cada día estamos trabajando para mejorar y ofrecerles una experiencia de calidad. Actualizaremos nuestras profesiones ofertadas tomando en cuenta la suya. PRONTO NOS PONDREMOS EN CONTACTO CON USTED.",
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  // Comunicar los cambios al widget padre (EditProfileDialog)
                                  widget.onServiceTypesSelected(
                                      selectedSubcategories,
                                      selectedExperienceLevel);
                                },
                                child: Text("Aceptar"),
                              ),
                            ],
                          );
                        },
                      );

                      setState(() {
                        showCustomProfessionField = false;
                        customProfessionController.clear();
                      });
                    },
                    child: Text("Aceptar"),
                  ),
                ],
              ),
            if (selectedSubcategories.isNotEmpty)
              Column(
                children: [
                  Text(
                    'Profesiones seleccionadas: ${selectedSubcategories.join(", ")}',
                    style: TextStyle(color: Colors.blue),
                  ),
                  SizedBox(height: 10),
                ],
              ),
            SizedBox(height: 20),
            Text(
              'Seleccione su experiencia laboral:',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 10),
            buildExperienceLevelDropdown(),
            SizedBox(height: 20),
            Column(
              children: [
                Text(
                  'Experiencia Laboral: ${selectedExperienceLevel}',
                  style: TextStyle(color: Colors.blue),
                ),
                SizedBox(height: 10),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Lógica para guardar cambios
                List<String> newExpertises = selectedSubcategories;
                String? newExpLevel = selectedExperienceLevel;
                // Otra lógica necesaria...
                Navigator.pop(
                    context); // Cerrar la ventana de diálogo después de guardar
                widget.onServiceTypesSelected(newExpertises, newExpLevel);
              },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
                backgroundColor: Color(0xFF84090D),
                minimumSize: Size(double.infinity, 50),
              ),
              child: Text(
                "Guardar Cambios",
                style: MyTextStyles.serviceTitleTextStyle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildCategoryButton(String category, Color textColor, double width) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          if (selectedCategories.contains(category)) {
            selectedCategories.remove(category);
            selectedSubcategories.removeWhere(
              (subcategory) =>
                  widget.categories[category]?.contains(subcategory) ?? false,
            );
          } else {
            selectedCategories.add(category);
          }
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor:
            selectedCategories.contains(category) ? Colors.red : null,
        fixedSize: Size(width, 36.0),
      ),
      child: Center(
        // Centra el contenido del botón
        child: Text(
          category,
          style: TextStyle(
            color: textColor,
          ),
        ),
      ),
    );
  }

  Widget buildSubcategoryDropdown() {
    List<String> allSubcategories = [];
    selectedCategories.forEach((category) {
      allSubcategories.addAll(widget.categories[category] ?? []);
    });

    allSubcategories.sort();

    return DropdownButton<String>(
      value: null,
      onChanged: (subcategory) {
        if (subcategory != null &&
            !selectedSubcategories.contains(subcategory)) {
          setState(() {
            selectedSubcategories.add(subcategory);
          });
          widget.onServiceTypesSelected(
              selectedSubcategories, selectedExperienceLevel);
          selectedSubcategories.sort();
        }
      },
      items: allSubcategories
          .map((subcategory) => DropdownMenuItem<String>(
                value: subcategory,
                child: Text(subcategory),
              ))
          .toList(),
    );
  }

  Widget buildExperienceLevelDropdown() {
    return DropdownButton<String>(
      value: selectedExperienceLevel,
      onChanged: (experienceLevel) {
        setState(() {
          selectedExperienceLevel = experienceLevel;
        });
        widget.onServiceTypesSelected(
            selectedSubcategories, selectedExperienceLevel);
      },
      items: expLevel
          .map((level) => DropdownMenuItem<String>(
                value: level,
                child: Text(level),
              ))
          .toList(),
    );
  }
}
