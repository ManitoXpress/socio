import 'package:flutter/material.dart';
import 'package:socio/Metods/RegisController.dart';
import 'package:socio/ServiceResponse/request.dart';
import 'package:socio/Utils/styles.dart';

class ServiceTypeSelection extends StatefulWidget {
  final RegistrationController registrationController;
  final void Function() onNextStep;
  final void Function(List<Expertises> expertises, String? selectedExperienceLevel) onServiceTypesSelected;


  final Future<List<Category>> Function() fetchExpertises; // Solo fetchExpertises

  ServiceTypeSelection({
    required this.registrationController,
    required this.onNextStep,
    required this.onServiceTypesSelected,
    required Null Function(dynamic serviceType) onServiceTypeSelected,
    required this.fetchExpertises, // Solo fetchExpertises
  });

  @override
  _ServiceTypeSelectionState createState() => _ServiceTypeSelectionState();
}

class _ServiceTypeSelectionState extends State<ServiceTypeSelection> {
  List<String> selectedCategories = [];
  List<Expertises> selectedSubcategories = [];
  bool showCustomProfessionField = false;
  TextEditingController customProfessionController = TextEditingController();
  List<String> expLevel = ['0-3 años', '3-5 años', '5-7 años'];
  String? selectedExperienceLevel;
  List<String> allSubcategories = [];
  List<Category>? fetchCategories = [];

  @override
  void initState() {
    super.initState();
    fetchCategories = null; // Inicializa como null

    // Llama a la función para obtener las categorías usando fetchExpertises
    widget.fetchExpertises().then((categories) {
      setState(() {
        fetchCategories = categories.cast<Category>();

        // Imprime las categorías para verificar cómo se cargan
        print('Categorías cargadas:');
        fetchCategories?.forEach((category) {
          print('Categoría: ${category.name}');
          category.expertises.forEach((expertise) {
            print(' - Especialidad: ${expertise.name}');
          });
        });
      });
    }).catchError((error) {
      print('Error fetching categories: $error');
    });
  }


  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            "Paso 4: Escoja una o varias profesiones",
            style: MyTextStyles.drawerButtonTextStyle2,
          ),
        ),
        // Primer grupo de botones (arriba)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0), // Espacio en los lados
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (fetchCategories != null)
                ...fetchCategories!
                    .take((fetchCategories!.length / 2).ceil())
                    .map((category) {
                  return Expanded(
                    child: buildCategoryButton(
                      category.name,
                      const Color(0xFF830A09),
                    ),
                  );
                }).toList(),
              if (fetchCategories == null)
                Center(
                  child: CircularProgressIndicator(),
                ),
            ],
          ),
        ),
        SizedBox(height: 10),

        // Segundo grupo de botones (abajo)
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0), // Espacio en los lados
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (fetchCategories != null)
                    ...fetchCategories!
                        .skip((fetchCategories!.length / 2).ceil())
                        .map((category) {
                      return Expanded(
                        child: buildCategoryButton(
                          category.name,
                          const Color(0xFF830A09),
                        ),
                      );
                    }).toList(),
                  if (fetchCategories == null)
                    Center(
                      child: CircularProgressIndicator(),
                    ),
                ],
            ),
        ),
        SizedBox(height: 10),
        if (selectedCategories.isNotEmpty)
          Column(
            children: [
              Text(
                'Categorías seleccionadas: ${selectedCategories.join(", ")}',
                style: TextStyle(color: Color(0xFF830A09)),
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
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8), backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
              side: BorderSide(
                color: Color(0xFF84090D),
              ),
            ),
          ),
          child: Text("No encuentro mi profesión",
            style: TextStyle(
              color: Color(0xFF84090D),
            ),
          ),
        ),

        if (showCustomProfessionField)
          Column(
            children: [
              TextField(
                controller: customProfessionController,
                decoration: InputDecoration(
                  hintText: 'Ingrese la profesión o servicio que desea ofertar',
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF830A09)),
                  ),
                ),
              ),

              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  // Aquí va la lógica de lo que deseas hacer al presionar el botón
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8), backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    side: BorderSide(
                      color: Color(0xFF84090D),
                    ),
                  ),
                ),
                child: Text("Aceptar",
                  style: TextStyle(
                    color: Color(0xFF84090D),
                  ),
                ),
              ),
            ],
          ),
        if (selectedSubcategories.isNotEmpty)
          Column(
            children: [
              Text(
                // Mapea la lista de Expertises a una lista de nombres (String) antes de unirlos
                'Profesiones seleccionadas: ${selectedSubcategories.map((e) => e.name).join(", ")}',
                style: TextStyle(color: Color(0xFF830A09)),
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
              style: TextStyle(color: Color(0xFF830A09)),
            ),
            SizedBox(height: 10),
          ],
        ),

        SizedBox(height: 20),
      ],
    );
  }

  Widget buildCategoryButton(String category, Color textColor) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          if (selectedCategories.contains(category)) {
            selectedCategories.remove(category);
            selectedSubcategories.removeWhere((subcategory) =>
                fetchCategories!
                    .firstWhere((cat) => cat.name == category)
                    .expertises
                    .map((expertise) => expertise.name)
                    .contains(subcategory));
          } else {
            selectedCategories.add(category);
          }
        });
      },
      style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          backgroundColor: Color.fromARGB(255, 255, 255, 255),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
            side: BorderSide(
              color: Color(0xFF84090D),
            ),
          ),
          ),
      child: Text(
        category,
        style: TextStyle(
          color: textColor,
        ),
      ),
    );
  }


  Widget buildSubcategoryDropdown() {
    Set<Expertises> uniqueSubcategories = {};

    selectedCategories.forEach((categoryName) {
      final category = fetchCategories!.firstWhere((cat) => cat.name == categoryName, orElse: () => Category(id: '', name: '', expertises: []));
      uniqueSubcategories.addAll(category.expertises);
    });

    List<Expertises> allSubcategories = uniqueSubcategories.toList();
    allSubcategories.sort((a, b) => a.name.compareTo(b.name));

    // Crear un mapa de nombre a id para los expertises
    Map<String, String> expertiseMap = {};
    allSubcategories.forEach((expertise) {
      expertiseMap[expertise.name] = expertise.id;
    });

    return DropdownButton<Expertises>(
      value: null,
      onChanged: (expertise) {
        if (expertise != null && !selectedSubcategories.contains(expertise)) {
          setState(() {
            selectedSubcategories.add(expertise);
          });
          // Obtener los nombres de las subcategorías seleccionadas
          List<String> selectedSubcategoryNames = selectedSubcategories.map((expertise) => expertise.name).toList();
          // Obtener los ids de las subcategorías seleccionadas
          List<String> selectedSubcategoryIds = selectedSubcategories.map((expertise) => expertise.id).toList();
          // Llama a la función onServiceTypesSelected con los nombres y los ids de las subcategorías
          widget.onServiceTypesSelected(selectedSubcategories, selectedExperienceLevel);
          selectedSubcategories.sort((a, b) => a.name.compareTo(b.name));
        }
      },
      items: allSubcategories
          .map((expertise) => DropdownMenuItem<Expertises>(
        value: expertise,
        child: Text(expertise.name),
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

        // Obtener los ids de los expertises seleccionados
        List<String> expertiseIds = selectedSubcategories.map((expertise) => expertise.id).toList();

        // Llamar a onServiceTypesSelected con los ids de expertises
        widget.onServiceTypesSelected(selectedSubcategories, selectedExperienceLevel);

        selectedSubcategories.sort((a, b) => a.name.compareTo(b.name));
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