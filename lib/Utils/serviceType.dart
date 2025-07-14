import 'package:flutter/material.dart';


import '../ServiceResponse/requestCategory.dart';
import '../ServiceResponse/requestExpertise.dart';
import '../controllers/RegisController.dart';
import 'styles.dart';

class ServiceTypeListScreen extends StatefulWidget {
  final RegistrationController registrationController;
  final void Function() onNextStep;
  final Map<String, List<String>> categories;
  final void Function(
          List<Expertise> expertises, String? selectedExperienceLevel)
      onServiceTypesSelected;
  final Future<List<Category>> Function() fetchExpertises;

  ServiceTypeListScreen({
    required this.registrationController,
    required this.onNextStep,
    required this.onServiceTypesSelected,
    required this.categories,
    required this.fetchExpertises,
    required Null Function(dynamic serviceType) onServiceTypeSelected,
  });

  @override
  _ServiceTypeListScreenState createState() => _ServiceTypeListScreenState();
}

class _ServiceTypeListScreenState extends State<ServiceTypeListScreen> {
  List<String> selectedCategories = [];
  List<Expertise> selectedSubcategories = [];
  bool showCustomProfessionField = false;
  TextEditingController customProfessionController = TextEditingController();
  List<String> expLevel = ['0-3 años', '3-5 años', '5-7 años'];
  String? selectedExperienceLevel;
  List<Category>? fetchCategories;

  @override
  void initState() {
    super.initState();
    fetchCategories = null;
    widget.fetchExpertises().then((categories) {
      setState(() {
        fetchCategories = categories;
      });
    }).catchError((error) {
      print('Error fetching categories: $error');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          'Seleccione Profesiones',
          style: MyTextStyles.buttonTextStyle,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Row(
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
              SizedBox(height: 10),
              Row(
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
              if (selectedSubcategories.isNotEmpty)
                Column(
                  children: [
                    Text(
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
              if (selectedExperienceLevel != null)
                Column(
                  children: [
                    Text(
                      'Experiencia Laboral: $selectedExperienceLevel',
                      style: TextStyle(color: Color(0xFF830A09)),
                    ),
                    SizedBox(height: 10),
                  ],
                ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: selectedSubcategories.isNotEmpty &&
                        selectedExperienceLevel != null
                    ? () {
                        // Aquí puedes hacer el guardado de cambios si es necesario
                        widget.onServiceTypesSelected(
                            selectedSubcategories, selectedExperienceLevel);

                        // Regresar a la pantalla de edición
                        Navigator.pop(
                            context); // Esto regresa a la pantalla anterior
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF830A09),
                ),
                child: Text('Guardar', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildCategoryButton(String category, Color textColor) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          if (selectedCategories.contains(category)) {
            selectedCategories.remove(category);
            selectedSubcategories.removeWhere((subcategory) => fetchCategories!
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
    Set<Expertise> uniqueSubcategories = {};

    // Obtener las subcategorías de las categorías seleccionadas
    selectedCategories.forEach((categoryName) {
      final category = fetchCategories!.firstWhere(
        (cat) => cat.name == categoryName,
        orElse: () => Category(id: '', name: '', expertises: []),
      );
      uniqueSubcategories.addAll(category.expertises);
    });

    List<Expertise> allSubcategories = uniqueSubcategories.toList();
    allSubcategories.sort((a, b) => a.name.compareTo(b.name));

    return Wrap(
      spacing: 8.0, // Espaciado horizontal entre chips
      runSpacing: 4.0, // Espaciado vertical entre chips
      children: allSubcategories.map((expertise) {
        final isSelected = selectedSubcategories.contains(expertise);
        return ChoiceChip(
          label: Text(expertise.name),
          selected: isSelected,
          selectedColor: Color(0xFF830A09),
          backgroundColor: Colors.grey[200],
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
          ),
          onSelected: (selected) {
            setState(() {
              if (selected) {
                selectedSubcategories.add(expertise);
              } else {
                selectedSubcategories.remove(expertise);
              }
            });

            // Actualizar la selección en el callback
            widget.onServiceTypesSelected(
                selectedSubcategories, selectedExperienceLevel);
          },
        );
      }).toList(),
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
        List<String> expertiseIds =
            selectedSubcategories.map((expertise) => expertise.id).toList();

        // Llamar a onServiceTypesSelected con los ids de expertises
        widget.onServiceTypesSelected(
            selectedSubcategories, selectedExperienceLevel);

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
