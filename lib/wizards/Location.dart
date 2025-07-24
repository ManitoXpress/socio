import 'dart:async';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:location/location.dart' as location;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:socio/ServiceResponse/requestUserData.dart';
import 'package:socio/Utils/styles.dart';

import '../controllers/RegisController.dart';
class FavoriteLocation {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final DateTime createdAt;
  final String? icon;

  FavoriteLocation({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
    this.icon,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'createdAt': createdAt.toIso8601String(),
        'icon': icon,
      };

  factory FavoriteLocation.fromJson(Map<String, dynamic> json) =>
      FavoriteLocation(
        id: json['id'],
        name: json['name'],
        address: json['address'],
        latitude: json['latitude'],
        longitude: json['longitude'],
        createdAt: DateTime.parse(json['createdAt']),
        icon: json['icon'],
      );
}

class LocationAndFavoritesWizard extends StatefulWidget {
  final Map<String, double> location;
  final Function(LatLng selectedLocation) onLocationSelected;
  final Function(bool isFavorite) onFavoritesSelected;
  final Function onNextStep;

  const LocationAndFavoritesWizard({
    required this.location,
    required this.onLocationSelected,
    required this.onFavoritesSelected,
    required this.onNextStep,
    Key? key,
  }) : super(key: key);

  @override
  _LocationAndFavoritesWizardState createState() =>
      _LocationAndFavoritesWizardState();
}

class _LocationAndFavoritesWizardState extends State<LocationAndFavoritesWizard>
    with TickerProviderStateMixin {
  LatLng? selectedLocation;
  bool isFavorite = false;
  GoogleMapController? mapController;
  Set<Marker> markers = {};
  final TextEditingController writtenLocationController =
      TextEditingController();
  final TextEditingController additionalInfoController =
      TextEditingController();
  final Completer<GoogleMapController> _controller = Completer();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final LatLng santaCruzDefaultLocation = LatLng(-17.7833, -63.1821);
  final LatLng _initialPosition = LatLng(-17.7833, -63.1833);

  // Mapa de iconos para favoritos
  static const Map<String, IconData> _iconMap = {
    'home': Icons.home,
    'work': Icons.work,
    'fitness_center': Icons.fitness_center,
    'shopping_cart': Icons.shopping_cart,
    'local_hospital': Icons.local_hospital,
    'school': Icons.school,
    'location_on': Icons.location_on,
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
            .animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _getCurrentLocation();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final loc = location.Location();
      if (!await loc.serviceEnabled() && !(await loc.requestService())) {
        return;
      }
      var perm = await loc.hasPermission();
      if (perm == location.PermissionStatus.denied &&
          await loc.requestPermission() != location.PermissionStatus.granted) {
        return;
      }
      final data = await loc.getLocation();
      final curr = LatLng(data.latitude!, data.longitude!);
      _updateSelectedLocation(curr);
      (await _controller.future).animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: curr, zoom: 14),
        ),
      );
    } catch (_) {
      _updateSelectedLocation(santaCruzDefaultLocation);
      (await _controller.future).animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: santaCruzDefaultLocation, zoom: 14),
        ),
      );
    }
  }

  Future<void> _updateSelectedLocation(LatLng loc) async {
    widget.onLocationSelected(loc);
    final address = await _getAddressFromLatLng(loc);
    setState(() {
      selectedLocation = loc;
      markers = {
        Marker(
          markerId: MarkerId(loc.toString()),
          position: loc,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        )
      };
      writtenLocationController.text = address;
    });
    if (mapController != null) {
      mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: loc, zoom: 14),
        ),
      );
    }
  }

  Future<String> _getAddressFromLatLng(LatLng latLng) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latLng.latitude, latLng.longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        return "${place.street}, ${place.locality}, ${place.country}";
      }
    } catch (_) {}
    return "Ubicación desconocida";
  }

  // --- Favoritos: guardar, cargar, eliminar, UI ---
  // (El código de favoritos avanzado que ya tienes, adaptado al color 0xFF830A09 y animaciones)
  // ... (el resto del código de favoritos y UI avanzada, igual al ejemplo que diste, pero con color 0xFF830A09 en todos los elementos visuales) ...

  // Cargar ubicaciones favoritas
  Future<List<FavoriteLocation>> _loadFavoriteLocations() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'favoriteLocations_v2';
    final jsonString = prefs.getString(key);
    if (jsonString == null || jsonString.isEmpty) return [];
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((item) => FavoriteLocation.fromJson(item)).toList();
  }

  // Eliminar ubicación favorita
  Future<void> _deleteFavoriteLocation(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'favoriteLocations_v2';
    final favorites = await _loadFavoriteLocations();
    favorites.removeWhere((favorite) => favorite.id == id);
    final updatedJson = json.encode(favorites.map((f) => f.toJson()).toList());
    await prefs.setString(key, updatedJson);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ubicación eliminada de favoritos'),
        backgroundColor: Color(0xFF830A09),
      ),
    );
  }

  // Guardar ubicación favorita
  Future<void> _saveFavoriteLocation(
      LatLng location, String name, String icon) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'favoriteLocations_v2';
    final existingJson = prefs.getString(key) ?? '[]';
    final List<dynamic> existingList = json.decode(existingJson);
    final List<FavoriteLocation> favorites =
        existingList.map((item) => FavoriteLocation.fromJson(item)).toList();
    final address = await _getAddressFromLatLng(location);
    final newFavorite = FavoriteLocation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      address: address,
      latitude: location.latitude,
      longitude: location.longitude,
      createdAt: DateTime.now(),
      icon: icon,
    );
    favorites.add(newFavorite);
    final updatedJson = json.encode(favorites.map((f) => f.toJson()).toList());
    await prefs.setString(key, updatedJson);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.favorite, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text('Ubicación "$name" guardada en favoritos')),
          ],
        ),
        backgroundColor: const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildLocationCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: selectedLocation != null
            ? const LinearGradient(
                colors: [Color(0xFF830A09), Color(0xFF5A0707)],
              )
            : null,
        color: selectedLocation != null ? null : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: selectedLocation != null
                ? const Color(0xFF830A09).withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: selectedLocation != null ? 12 : 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: selectedLocation != null
            ? null
            : Border.all(
                color: Colors.grey[300]!,
                width: 1,
              ),
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: selectedLocation != null
                  ? Colors.white.withOpacity(0.2)
                  : const Color(0xFF830A09).withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(
              Icons.location_on,
              color: selectedLocation != null
                  ? Colors.white
                  : const Color(0xFF830A09),
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Ubicación del domicilio',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: selectedLocation != null
                  ? Colors.white
                  : const Color(0xFF830A09),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            selectedLocation != null
                ? writtenLocationController.text
                : 'Toca para seleccionar ubicación',
            style: TextStyle(
              fontSize: 12,
              color: selectedLocation != null
                  ? Colors.white.withOpacity(0.9)
                  : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Muestra la pantalla del mapa para que el usuario seleccione una ubicación y gestione favoritos
  Future<void> _showMapScreen() async {
    LatLng? tempSelected = selectedLocation;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            elevation: 0,
            backgroundColor: const Color(0xFF830A09),
            iconTheme: const IconThemeData(color: Colors.white),
            title: const Text(
              'Seleccionar Ubicación',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
          body: StatefulBuilder(
            builder: (context, setStateDialog) {
              return Stack(
                children: [
                  Column(
                    children: [
                      Expanded(
                        child: GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: tempSelected ?? _initialPosition,
                            zoom: 14,
                          ),
                          onMapCreated: (controller) {
                            mapController = controller;
                          },
                          onTap: (loc) {
                            setStateDialog(() {
                              tempSelected = loc;
                            });
                          },
                          markers: tempSelected != null
                              ? {
                                  Marker(
                                    markerId: MarkerId(tempSelected.toString()),
                                    position: tempSelected!,
                                    icon: BitmapDescriptor.defaultMarkerWithHue(
                                        BitmapDescriptor.hueRed),
                                  )
                                }
                              : {},
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF830A09),
                                  side: const BorderSide(
                                      color: Color(0xFF830A09)),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Cancelar',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                onPressed: () async {
                                  if (tempSelected != null) {
                                    await _updateSelectedLocation(
                                        tempSelected!);
                                    Navigator.pop(context);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Por favor selecciona una ubicación'),
                                        backgroundColor: Color(0xFF830A09),
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF830A09),
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  'Confirmar Ubicación',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Botón flotante de favoritos
                  Positioned(
                    top: 20,
                    left: 20,
                    child: FloatingActionButton(
                      onPressed: () async {
                        await _showFavoriteLocationsDialog((LatLng loc) {
                          setStateDialog(() {
                            tempSelected = loc;
                          });
                        });
                      },
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      elevation: 8,
                      child: const Icon(Icons.favorite),
                    ),
                  ),
                  // Botón flotante para agregar favorito
                  Positioned(
                    top: 90,
                    left: 20,
                    child: FloatingActionButton(
                      onPressed: () async {
                        if (tempSelected != null) {
                          await _showAddFavoriteDialog(tempSelected!);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Primero selecciona una ubicación en el mapa'),
                              backgroundColor: Color(0xFF830A09),
                            ),
                          );
                        }
                      },
                      backgroundColor: const Color(0xFFFF9800),
                      foregroundColor: Colors.white,
                      elevation: 8,
                      child: const Icon(Icons.add_location),
                    ),
                  ),
                  // Botón flotante para seleccionar mi ubicación actual
                  Positioned(
                    top: 20,
                    right: 20,
                    child: FloatingActionButton(
                      onPressed: () async {
                        try {
                          final position = await Geolocator.getCurrentPosition(
                              desiredAccuracy: LocationAccuracy.high);
                          final currentLoc =
                              LatLng(position.latitude, position.longitude);
                          setStateDialog(() {
                            tempSelected = currentLoc;
                          });
                          if (mapController != null) {
                            mapController!.animateCamera(
                              CameraUpdate.newCameraPosition(
                                CameraPosition(target: currentLoc, zoom: 16),
                              ),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'No se pudo obtener la ubicación actual'),
                              backgroundColor: Color(0xFF830A09),
                            ),
                          );
                        }
                      },
                      backgroundColor: const Color(0xFF830A09),
                      foregroundColor: Colors.white,
                      elevation: 8,
                      child: const Icon(Icons.my_location, color: Colors.white),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // Diálogo de ubicaciones favoritas
  Future<void> _showFavoriteLocationsDialog(
      Function(LatLng) onSelectFavorite) async {
    final favorites = await _loadFavoriteLocations();
    if (favorites.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay ubicaciones favoritas guardadas'),
          backgroundColor: Color(0xFF830A09),
        ),
      );
      return;
    }
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Icon(Icons.favorite,
                        color: Colors.white, size: 30),
                  ),
                  const SizedBox(height: 16),
                  const Text('Ubicaciones Favoritas',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4CAF50))),
                  const SizedBox(height: 8),
                  const Text('Selecciona una ubicación guardada',
                      style: TextStyle(fontSize: 14, color: Colors.grey)),
                  const SizedBox(height: 20),
                  ListView.builder(
                    shrinkWrap: true,
                    itemCount: favorites.length,
                    itemBuilder: (context, index) {
                      final favorite = favorites[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[200]!),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Icono grande a la izquierda
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4CAF50),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Icon(
                                  _iconMap[favorite.icon ?? 'location_on'] ??
                                      Icons.location_on,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Info principal
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      favorite.name,
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      favorite.address,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Guardado el ${favorite.createdAt.day}/${favorite.createdAt.month}/${favorite.createdAt.year}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[400],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Acciones
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.red[50],
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: IconButton(
                                      icon: Icon(Icons.delete_outline,
                                          color: Colors.red[400], size: 20),
                                      onPressed: () async {
                                        await _deleteFavoriteLocation(
                                            favorite.id);
                                        Navigator.of(context).pop();
                                        _showFavoriteLocationsDialog(
                                            onSelectFavorite);
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF4CAF50),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.check,
                                          color: Colors.white, size: 20),
                                      onPressed: () {
                                        final selectedLoc = LatLng(
                                            favorite.latitude,
                                            favorite.longitude);
                                        Navigator.of(context).pop();
                                        onSelectFavorite(selectedLoc);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Row(
                                              children: [
                                                const Icon(Icons.check_circle,
                                                    color: Colors.white),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                    child: Text(
                                                        'Ubicación "${favorite.name}" seleccionada')),
                                              ],
                                            ),
                                            backgroundColor:
                                                const Color(0xFF830A09),
                                            behavior: SnackBarBehavior.floating,
                                            duration:
                                                const Duration(seconds: 2),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        if (selectedLocation != null) {
                          _showAddFavoriteDialog(selectedLocation!);
                        }
                      },
                      icon: const Icon(Icons.add_location),
                      label: const Text('Agregar Nueva Ubicación'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF4CAF50),
                        side: const BorderSide(color: Color(0xFF4CAF50)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Diálogo para agregar favorito
  Future<void> _showAddFavoriteDialog(LatLng location) async {
    final TextEditingController nameController = TextEditingController();
    String selectedIcon = 'location_on';
    final List<Map<String, dynamic>> iconOptions = [
      {'icon': 'home', 'label': 'Casa'},
      {'icon': 'work', 'label': 'Trabajo'},
      {'icon': 'fitness_center', 'label': 'Gimnasio'},
      {'icon': 'shopping_cart', 'label': 'Supermercado'},
      {'icon': 'local_hospital', 'label': 'Hospital'},
      {'icon': 'school', 'label': 'Escuela'},
      {'icon': 'location_on', 'label': 'Otro'},
    ];
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: const Color(0xFF830A09),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Icon(Icons.favorite,
                            color: Colors.white, size: 30),
                      ),
                      const SizedBox(height: 16),
                      const Text('Guardar Ubicación Favorita',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF830A09)),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 8),
                      const Text('Dale un nombre a esta ubicación',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 24),
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: 'Nombre de la ubicación',
                          hintText: 'Ej: Casa, Trabajo, Gimnasio...',
                          prefixIcon: const Icon(Icons.edit_location,
                              color: Color(0xFF830A09)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: Color(0xFF830A09), width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 20),
                      const Text('Selecciona un ícono',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF830A09)),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 80,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: iconOptions.length,
                          itemBuilder: (context, index) {
                            final option = iconOptions[index];
                            final isSelected = selectedIcon == option['icon'];
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedIcon = option['icon'];
                                });
                              },
                              child: Container(
                                width: 70,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF830A09)
                                      : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF830A09)
                                        : Colors.grey[300]!,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                        _iconMap[option['icon']] ??
                                            Icons.location_on,
                                        color: isSelected
                                            ? Colors.white
                                            : const Color(0xFF830A09),
                                        size: 24),
                                    const SizedBox(height: 4),
                                    Text(option['label'],
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: isSelected
                                                ? Colors.white
                                                : Color(0xFF830A09),
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.normal),
                                        textAlign: TextAlign.center),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF830A09),
                                side:
                                    const BorderSide(color: Color(0xFF830A09)),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Cancelar'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: () async {
                                if (nameController.text.trim().isNotEmpty) {
                                  Navigator.of(context).pop();
                                  await _saveFavoriteLocation(location,
                                      nameController.text.trim(), selectedIcon);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Por favor ingresa un nombre para la ubicación'),
                                      backgroundColor: Color(0xFF830A09),
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF830A09),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              child: const Text('Guardar Favorito'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF830A09), Color(0xFF5A0707)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF830A09).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Ubicación del domicilio',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Selector de ubicación
              GestureDetector(
                onTap: _showMapScreen,
                child: _buildLocationCard(),
              ),
              const SizedBox(height: 24),
              // Resumen de selección
              if (selectedLocation != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.green[200]!,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green[600],
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ubicación seleccionada',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.green[700],
                              ),
                            ),
                            Text(
                              writtenLocationController.text,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
