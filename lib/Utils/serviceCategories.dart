class ServiceCategories {
  static final Map<String, List<String>> categories = {
    'Servicios Básicos': [
      'Albañileria', 'Canaletero', 'Mudanza', 'Carpinteria', 'Cerrajeria',
      'Técnicos Electrónicos', 'Limpieza', 'Modista/Coturero/A', 'Electricista', 'Jardineria',
      'Aire Acondicionado y Calefón', 'Plomero', 'Pintor', 'Zapatero',
    ],
    'Servicios Profesionales': [
      'Agente Inmobiliario', 'Arquitectura y Diseño Interiores y Exteriores', 'Asesor de Imagen', 'Eventos y Cocina', 'Diseñador/a Gráfico',
      'Gymnasio y Nutricion', 'Asistencia Auto/Moto', 'Medicina',
      'Belleza y Estética', 'Piloto', 'Educación/Profesor(a)', 'Servicios Informaticos',
      'Servicios Legales',
      'Veterinario/a',
    ],
  };

  static bool isValidCategory(String category) {
    return categories.containsKey(category);
  }

  static bool isValidExpertise(String category, String expertise) {
    final List<String>? expertises = categories[category];
    final formattedExpertise = _toTitleCase(expertise);
    return expertises != null && expertises.contains(formattedExpertise);
  }

  static String _toTitleCase(String text) {
    if (text.isEmpty) return text;
    return text.substring(0, 1).toUpperCase() + text.substring(1).toLowerCase();
  }
}
