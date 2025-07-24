import 'package:flutter/material.dart';

import 'package:socio/ServiceResponse/requestCategory.dart';
import 'package:socio/ServiceResponse/requestExpertise.dart';
import 'package:socio/Utils/styles.dart';

import '../controllers/RegisController.dart';
class ServiceTypeSelection extends StatefulWidget {
  final RegistrationController registrationController;
  final void Function() onNextStep;
  final void Function(
          List<Expertise> expertises, String? selectedExperienceLevel)
      onServiceTypesSelected;

  final Future<List<Category>> Function()
      fetchExpertises; // Solo fetchExpertises

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
  List<Expertise> selectedSubcategories = [];
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
    final screenWidth = MediaQuery.of(context).size.width;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              "Paso 4: Escoja una o varias profesiones",
              style: MyTextStyles.drawerButtonTextStyle2.copyWith(fontSize: 22),
            ),
          ),
          Text(
            "Seleccione una o varias categorías:",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          fetchCategories == null
              ? Center(child: CircularProgressIndicator())
              : Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: fetchCategories!.map((category) {
                    final isSelected = selectedCategories.contains(category.name);
                    return ChoiceChip(
                      label: Text(category.name),
                      selected: isSelected,
                      selectedColor: Color(0xFF830A09),
                      backgroundColor: Colors.grey[200],
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            selectedCategories.add(category.name);
                          } else {
                            selectedCategories.remove(category.name);
                            selectedSubcategories.removeWhere((sub) => category.expertises.contains(sub));
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
          if (selectedCategories.isNotEmpty) ...[
            SizedBox(height: 16),
            Text(
              'Categorías seleccionadas: ${selectedCategories.join(", ")}',
              style: TextStyle(color: Color(0xFF830A09)),
            ),
            SizedBox(height: 10),
            Text(
              'Seleccione una o varias profesiones:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            buildSubcategoryChips(),
          ],
          SizedBox(height: 16),
          Center(
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  showCustomProfessionField = true;
                });
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  side: BorderSide(
                    color: Color(0xFF84090D),
                  ),
                ),
              ),
              child: Text(
                "No encuentro mi profesión",
                style: TextStyle(
                  color: Color(0xFF84090D),
                ),
              ),
            ),
          ),
          if (showCustomProfessionField)
            Column(
              children: [
                SizedBox(height: 10),
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
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      side: BorderSide(
                        color: Color(0xFF84090D),
                      ),
                    ),
                  ),
                  child: Text(
                    "Aceptar",
                    style: TextStyle(
                      color: Color(0xFF84090D),
                    ),
                  ),
                ),
              ],
            ),
          if (selectedSubcategories.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 16),
                Text(
                  // Mapea la lista de Expertises a una lista de nombres (String) antes de unirlos
                  'Profesiones seleccionadas: ${selectedSubcategories.map((e) => e.name).join(", ")}',
                  style: TextStyle(color: Color(0xFF830A09)),
                ),
              ],
            ),
          SizedBox(height: 24),
          Text(
            'Seleccione su experiencia laboral:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          buildExperienceLevelDropdown(),
          SizedBox(height: 20),
          if (selectedExperienceLevel != null)
            Text(
              'Experiencia Laboral: $selectedExperienceLevel',
              style: TextStyle(color: Color(0xFF830A09)),
            ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget buildSubcategoryChips() {
    Set<Expertise> uniqueSubcategories = {};
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
      spacing: 8.0,
      runSpacing: 4.0,
      children: allSubcategories.map((expertise) {
        final isSelected = selectedSubcategories.contains(expertise);
        return ChoiceChip(
          label: Text(expertise.name),
          selected: isSelected,
          selectedColor: Color(0xFF830A09),
          backgroundColor: Colors.grey[200],
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          onSelected: (selected) {
            setState(() {
              if (selected) {
                selectedSubcategories.add(expertise);
              } else {
                selectedSubcategories.remove(expertise);
              }
            });
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