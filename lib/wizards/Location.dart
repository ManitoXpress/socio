import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:location/location.dart' as location;

import 'package:socio/ServiceResponse/requestUserData.dart';
import 'package:socio/Utils/styles.dart';

import '../controllers/RegisController.dart';
class LocationAndFavoritesWizard extends StatefulWidget {
  final Function(LatLng)
  onLocationSelected; // Callback para seleccionar ubicación
  final Function(bool)
  onFavoritesSelected; // Callback para seleccionar favoritos
  final VoidCallback onNextStep; // Callback para avanzar al siguiente paso
  final Map<String, double>
  location; // Ubicación proporcionada como coordenadas
  final RegistrationController
  registrationController; // Controlador de registro
  final UserData userData; // Datos del usuario
  _LocationAndFavoritesWizardState? _locationAndFavoritesWizardState;

  // Método para verificar si la ubicación y favoritos son válidos
  bool? isLocationAndFavoritesValid() {
    return _locationAndFavoritesWizardState?.isLocationAndFavoritesValid();
  }

  LocationAndFavoritesWizard({
    required this.onLocationSelected,
    required this.onFavoritesSelected,
    required this.onNextStep,
    required this.location,
    required this.registrationController,
    required this.userData,
    required RegistrationData registrationData,
  });

  @override
  _LocationAndFavoritesWizardState createState() {
    _locationAndFavoritesWizardState = _LocationAndFavoritesWizardState();
    return _locationAndFavoritesWizardState!;
  }
}

class _LocationAndFavoritesWizardState
    extends State<LocationAndFavoritesWizard> {
  LatLng? selectedLocation; // Ubicación seleccionada
  bool isFavorite = false; // Indica si es favorito
  late GoogleMapController mapController; // Controlador del mapa de Google
  Set<Marker> markers = {}; // Conjunto de marcadores para el mapa
  TextEditingController locationController =
  TextEditingController(); // Controlador de texto para la ubicación
  TextEditingController writtenLocationController =
  TextEditingController(); // Controlador de texto para la dirección escrita
  Uint8List? mapSnapshot; // Instantánea del mapa
  TextEditingController additionalInfoController =
  TextEditingController(); // Controlador para la información adicional
  Completer<GoogleMapController> _controller =
  Completer<GoogleMapController>(); // Controlador asíncrono del mapa

  final LatLng santaCruzDefaultLocation = LatLng(-17.7833,
      -63.1821); // Coordenadas predeterminadas de Santa Cruz de la Sierra

  @override
  void initState() {
    super.initState();
    _getCurrentLocation(); // Obtención de la ubicación actual cuando se inicializa el estado
  }

  // Verifica si la ubicación y los favoritos son válidos
  bool isLocationAndFavoritesValid() {
    return selectedLocation != null;
  }

  // Función para obtener la ubicación actual del dispositivo
  Future<void> _getCurrentLocation() async {
    try {
      location.Location loc = location.Location();

      bool serviceEnabled = await loc.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await loc.requestService();
        if (!serviceEnabled) {
          return;
        }
      }

      location.PermissionStatus permissionGranted = await loc.hasPermission();
      if (permissionGranted == location.PermissionStatus.denied) {
        permissionGranted = await loc.requestPermission();
        if (permissionGranted != location.PermissionStatus.granted) {
          return;
        }
      }

      location.LocationData locationData = await loc.getLocation();
      LatLng currentLocation =
      LatLng(locationData.latitude!, locationData.longitude!);

      setState(() {
        selectedLocation = currentLocation;
        markers.clear();
        markers.add(
          Marker(
            markerId: MarkerId(currentLocation.toString()),
            position: currentLocation,
            icon:
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          ),
        );
      });

      if (_controller.isCompleted) {
        final GoogleMapController controller = await _controller.future;
        controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: currentLocation,
              zoom: 14.0,
            ),
          ),
        );
      }

      _handleTap(currentLocation);
    } catch (e) {
      print("Error obteniendo la ubicación actual: $e");

      setState(() {
        selectedLocation = santaCruzDefaultLocation;
        markers.clear();
        markers.add(
          Marker(
            markerId: MarkerId(santaCruzDefaultLocation.toString()),
            position: santaCruzDefaultLocation,
            icon:
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          ),
        );
      });

      if (_controller.isCompleted) {
        final GoogleMapController controller = await _controller.future;
        controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: santaCruzDefaultLocation,
              zoom: 14.0,
            ),
          ),
        );
      }

      _handleTap(santaCruzDefaultLocation);
    }
  }

  // Función para capturar y guardar una instantánea del mapa
  Future<void> _captureAndSaveMapSnapshot() async {
    final Uint8List? snapshotBytes = await mapController.takeSnapshot();
    setState(() {
      mapSnapshot = snapshotBytes;
    });
  }

  // Función que se llama cuando se crea el mapa
  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    print("Mapa creado correctamente");
  }

  // Maneja el toque en el mapa para actualizar la ubicación seleccionada
  void _handleTap(LatLng loc) async {
    widget.onLocationSelected(
        loc); // Llama al callback para pasar la ubicación seleccionada

    setState(() {
      selectedLocation = loc;
      markers.clear();
      markers.add(Marker(
        markerId: MarkerId(loc.toString()),
        position: loc,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ));
    });

    try {
      // Obtener la dirección basada en las coordenadas
      List<Placemark> placemarks =
      await placemarkFromCoordinates(loc.latitude, loc.longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address =
            "${place.street}, ${place.subLocality}, ${place.locality}, ${place.country}";
        writtenLocationController.text = address;
      } else {
        writtenLocationController.text = "Dirección no encontrada";
      }
    } catch (e) {
      print("Error obteniendo dirección: $e");
      writtenLocationController.text = "Error obteniendo dirección";
    }
  }

  // Muestra la pantalla del mapa para que el usuario seleccione una ubicación
  Future<void> _showMapScreen() async {
    TextEditingController searchController = TextEditingController();

    // Obtener la ubicación actual del usuario
    Position position;
    try {
      position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print("Error obteniendo la ubicación actual: $e");
      position = Position(
        latitude: santaCruzDefaultLocation.latitude,
        longitude: santaCruzDefaultLocation.longitude,
        timestamp: DateTime.now(),
        accuracy: 1.0,
        altitude: 0.0,
        heading: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        altitudeAccuracy: 1.0,
        headingAccuracy: 1.0,
      );
    }

    // Navegar a la pantalla del mapa
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            iconTheme: IconThemeData(color: Colors.white),
            title: Text(
              'Seleccionar Ubicación',
              style: MyTextStyles.buttonTextStyle,
            ),
          ),
          body: StatefulBuilder(
            builder: (BuildContext context, StateSetter setStateDialog) {
              return Stack(
                children: [
                  Column(
                    children: [
                      TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          labelText: 'Buscar dirección',
                          suffixIcon: IconButton(
                            icon: Icon(Icons.search),
                            onPressed: () async {
                              final query = searchController.text;
                              if (query.isNotEmpty) {
                                try {
                                  final locations =
                                  await locationFromAddress(query);
                                  if (locations.isNotEmpty) {
                                    final location = locations.first;
                                    setStateDialog(() {
                                      _handleTap(LatLng(location.latitude,
                                          location.longitude));
                                    });
                                  } else {
                                    print("No se encontró la dirección");
                                  }
                                } catch (e) {
                                  print("Error buscando dirección: $e");
                                }
                              }
                            },
                          ),
                        ),
                      ),
                      Expanded(
                        child: GoogleMap(
                          onMapCreated: (controller) {
                            _onMapCreated(controller);
                            _controller.complete(controller);
                            // Establecer la posición inicial del mapa con la ubicación del usuario
                            setStateDialog(() {
                              _handleTap(LatLng(
                                  position.latitude, position.longitude));
                            });
                          },
                          onTap: (LatLng loc) {
                            setStateDialog(() {
                              _handleTap(loc);
                            });
                          },
                          initialCameraPosition: CameraPosition(
                            target:
                            LatLng(position.latitude, position.longitude),
                            zoom: 14.0,
                          ),
                          markers: markers,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                'Volver',
                                style: MyTextStyles.drawerButtonLabelTextStyle,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF830A09),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              if (selectedLocation != null) {
                                widget.onLocationSelected(selectedLocation!);
                                Navigator.pop(context);
                              } else {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                  content: Text(
                                      'Por favor, selecciona una ubicación.'),
                                ));
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                'Aceptar',
                                style: MyTextStyles.drawerButtonLabelTextStyle,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF830A09),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Positioned(
                    bottom: 160,
                    right: 10,
                    child: FloatingActionButton(
                      onPressed: () async {
                        try {
                          final currentPosition =
                          await Geolocator.getCurrentPosition(
                            desiredAccuracy: LocationAccuracy.high,
                          );
                          setStateDialog(() {
                            _handleTap(LatLng(currentPosition.latitude,
                                currentPosition.longitude));
                          });
                        } catch (e) {
                          print("Error obteniendo la ubicación actual: $e");
                        }
                      },
                      child: Icon(Icons.gps_fixed),
                      tooltip: "Ir a mi ubicación",
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
    await _captureAndSaveMapSnapshot(); // Captura una instantánea después de seleccionar la ubicación
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: 10.0, left: 20.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Paso 2: Coloque su ubicación en el mapa',
              style: MyTextStyles.drawerButtonTextStyle2,
              textAlign: TextAlign.left,
            ),
          ),
        ),
        Card(
          elevation: 5.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          margin: const EdgeInsets.all(8.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _showMapScreen,
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.0),
                      color: Colors.grey[200],
                    ),
                    child: mapSnapshot != null
                        ? Image.memory(
                      mapSnapshot!,
                      fit: BoxFit.cover,
                    )
                        : Image.asset(
                      'assets/map.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: writtenLocationController,
                  decoration: InputDecoration(
                    labelText: 'Ubicación seleccionada',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(bottom: 10.0, left: 20.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Añadir información adicional',
              style: MyTextStyles.inputTextStyle3,
              textAlign: TextAlign.left,
            ),
          ),
        ),
        TextFormField(
          maxLines: 2,
          decoration: InputDecoration(
            labelText: 'Añadir información adicional',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color.fromARGB(162, 0, 0, 0)),
              borderRadius: BorderRadius.circular(20.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF830A09)),
              borderRadius: BorderRadius.circular(20.0),
            ),
            labelStyle: MyTextStyles.formsdetails,
          ),
          onChanged: (value) {},
        ),
      ],
    );
  }
}