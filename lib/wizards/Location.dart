import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:location/location.dart' as location;
import 'package:socio/controllers/RegisController.dart';
import 'package:socio/ServiceResponse/requestUserData.dart';
import 'package:socio/Utils/styles.dart';
import 'package:socio/Utils/cityDetection.dart';

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
  final Function(String, String)? onCitySelected; // Callback para seleccionar ciudad
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
    this.onCitySelected,
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
  
  // Variables para ciudad y región
  String? selectedCity;
  String? selectedRegion;
  List<Map<String, String>> availableCities = [];

  final LatLng santaCruzDefaultLocation = LatLng(-17.7833,
      -63.1821); // Coordenadas predeterminadas de Santa Cruz de la Sierra

  @override
  void initState() {
    super.initState();
    availableCities = CityDetectionService.getAvailableCities();
    _getCurrentLocation(); // Obtención de la ubicación actual cuando se inicializa el estado
  }

  // Verifica si la ubicación y los favoritos son válidos
  bool isLocationAndFavoritesValid() {
    return selectedLocation != null && selectedCity != null && selectedRegion != null;
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

    // Detectar ciudad automáticamente
    final cityInfo = CityDetectionService.detectCityFromCoordinates(loc);
    setState(() {
      selectedCity = cityInfo['city'];
      selectedRegion = cityInfo['region'];
    });

    // Notificar al callback de ciudad si está disponible
    if (widget.onCitySelected != null) {
      widget.onCitySelected!(selectedCity!, selectedRegion!);
    }

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
                                  }
                                } catch (e) {
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
    final screenWidth = MediaQuery.of(context).size.width;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: 10.0, left: 4.0),
            child: Text(
              'Paso 2: Coloque su ubicación en el mapa',
              style: MyTextStyles.drawerButtonTextStyle2.copyWith(fontSize: 22),
              textAlign: TextAlign.left,
            ),
          ),
          Card(
            elevation: 6.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: _showMapScreen,
                      icon: Icon(Icons.map, color: Colors.white),
                      label: Text('Seleccionar ubicación en el mapa', style: TextStyle(color: Colors.white, fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF830A09),
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 3,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    height: 180,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                      color: Colors.grey[200],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12.0),
                      child: mapSnapshot != null
                          ? Image.memory(
                              mapSnapshot!,
                              fit: BoxFit.cover,
                            )
                          : Image.asset(
                              'assets/map.jpg',
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: writtenLocationController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Ubicación seleccionada',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      prefixIcon: Icon(Icons.location_on, color: Color(0xFF830A09)),
                    ),
                  ),
                  SizedBox(height: 16),
                  // Selector de ciudad
                  DropdownButtonFormField<String>(
                    value: selectedCity,
                    decoration: InputDecoration(
                      labelText: 'Ciudad',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      prefixIcon: Icon(Icons.location_city, color: Color(0xFF830A09)),
                    ),
                    items: availableCities.map((city) {
                      return DropdownMenuItem<String>(
                        value: city['name'],
                        child: Text(city['name']!),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          selectedCity = newValue;
                          // Encontrar la región correspondiente
                          final cityData = availableCities.firstWhere(
                            (city) => city['name'] == newValue,
                            orElse: () => {'region': 'Santa Cruz'},
                          );
                          selectedRegion = cityData['region'];
                        });
                        
                        // Notificar al callback de ciudad si está disponible
                        if (widget.onCitySelected != null) {
                          widget.onCitySelected!(selectedCity!, selectedRegion!);
                        }
                      }
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor seleccione una ciudad';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  // Mostrar región seleccionada
                  if (selectedRegion != null)
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Color(0xFF830A09).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Color(0xFF830A09).withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.place, color: Color(0xFF830A09), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Región: $selectedRegion',
                            style: TextStyle(
                              color: Color(0xFF830A09),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          Padding(
            padding: EdgeInsets.only(left: 4.0, bottom: 8.0),
            child: Text(
              'Añadir información adicional',
              style: MyTextStyles.inputTextStyle3.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
              textAlign: TextAlign.left,
            ),
          ),
          Card(
            elevation: 3.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            margin: const EdgeInsets.only(bottom: 16.0),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextFormField(
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Añadir información adicional',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color.fromARGB(162, 0, 0, 0)),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF830A09)),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  labelStyle: MyTextStyles.formsdetails,
                  prefixIcon: Icon(Icons.info_outline, color: Color(0xFF830A09)),
                ),
                onChanged: (value) {},
              ),
            ),
          ),
        ],
      ),
    );
  }
}
