import 'package:flutter/material.dart';
import 'package:socio/Metods/RegisController.dart';
import 'package:socio/ServiceResponse/request.dart';
import 'package:socio/Utils/styles.dart';

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
        title: Text('Seleccione Profesiones'),
        backgroundColor: Color(0xFF830A09),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTitle('Escoja una o varias profesiones'),
              _buildCategoryButtons(),
              if (selectedCategories.isNotEmpty) ...[
                _buildSubtitle('Categorías seleccionadas:'),
                _buildSelectedCategories(),
                _buildSubcategoryDropdown(),
              ],
              if (showCustomProfessionField) _buildCustomProfessionField(),
              if (selectedSubcategories.isNotEmpty)
                _buildSelectedSubcategories(),
              _buildSubtitle('Seleccione su experiencia laboral:'),
              _buildExperienceLevelDropdown(),
              _buildSummaryAndNextButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF830A09),
        ),
      ),
    );
  }

  Widget _buildSubtitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildCategoryButtons() {
    if (fetchCategories == null) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }

    final categories = fetchCategories!;
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: categories.map((category) {
        return ChoiceChip(
          label: Text(category.name),
          selected: selectedCategories.contains(category.name),
          onSelected: (selected) {
            setState(() {
              if (selected) {
                selectedCategories.add(category.name);
              } else {
                selectedCategories.remove(category.name);
                selectedSubcategories.removeWhere((sub) =>
                    category.expertises.map((e) => e.name).contains(sub.name));
              }
            });
          },
          selectedColor: Color(0xFF830A09),
          labelStyle: TextStyle(
            color: selectedCategories.contains(category.name)
                ? Colors.white
                : Colors.black,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSelectedCategories() {
    return Text(
      selectedCategories.join(', '),
      style: TextStyle(color: Color(0xFF830A09)),
    );
  }

  Widget _buildSubcategoryDropdown() {
    Set<Expertise> uniqueSubcategories = {};
    for (var categoryName in selectedCategories) {
      final category =
          fetchCategories?.firstWhere((c) => c.name == categoryName);
      if (category != null) {
        uniqueSubcategories.addAll(category.expertises);
      }
    }

    final sortedSubcategories = uniqueSubcategories.toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return DropdownButton<Expertise>(
      value: null,
      onChanged: (expertise) {
        if (expertise != null && !selectedSubcategories.contains(expertise)) {
          setState(() {
            selectedSubcategories.add(expertise);
          });
          widget.onServiceTypesSelected(
              selectedSubcategories, selectedExperienceLevel);
        }
      },
      items: sortedSubcategories.map((expertise) {
        return DropdownMenuItem(
          value: expertise,
          child: Text(expertise.name),
        );
      }).toList(),
    );
  }

  Widget _buildCustomProfessionField() {
    return Column(
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
            setState(() {
              selectedCategories.add(customProfessionController.text);
              selectedCategories.remove(customProfessionController.text);
              showCustomProfessionField = false;
              customProfessionController.clear();
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF830A09),
          ),
          child: Text('Aceptar', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildSelectedSubcategories() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Profesiones seleccionadas:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(
          selectedSubcategories.map((e) => e.name).join(', '),
          style: TextStyle(color: Color(0xFF830A09)),
        ),
      ],
    );
  }

  Widget _buildExperienceLevelDropdown() {
    return DropdownButton<String>(
      value: selectedExperienceLevel,
      onChanged: (level) {
        setState(() {
          selectedExperienceLevel = level;
        });
        widget.onServiceTypesSelected(
            selectedSubcategories, selectedExperienceLevel);
      },
      items: expLevel.map((level) {
        return DropdownMenuItem(
          value: level,
          child: Text(level),
        );
      }).toList(),
    );
  }

  Widget _buildSummaryAndNextButton() {
    return Column(
      children: [
        if (selectedExperienceLevel != null)
          Text(
            'Experiencia Laboral: $selectedExperienceLevel',
            style: TextStyle(color: Color(0xFF830A09)),
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
                  Navigator.pop(context); // Esto regresa a la pantalla anterior
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF830A09),
          ),
          child: Text('Continuar', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
