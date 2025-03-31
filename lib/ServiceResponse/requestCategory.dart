

import 'package:socio/ServiceResponse/requestExpertise.dart';

class Category {
  final String id;
  final String name;
  final List<Expertise> expertises;

  Category({required this.id, required this.name, required this.expertises});

  factory Category.fromJson(Map<String, dynamic> json) {
    List<dynamic> expertisesData = json['expertises'];
    List<Expertise> expertises =
    expertisesData.map((e) => Expertise.fromMap(e)).toList();
    return Category(
      id: json['id'],
      name: json['name'],
      expertises: expertises,
    );
  }
}