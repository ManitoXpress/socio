import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:socio/Metods/RegisController.dart';
import 'package:socio/Screens/Chatscreen.dart';
import 'package:socio/Utils/service_form.dart';
import '../ServiceResponse/get.dart';
import '../ServiceResponse/request.dart';
import '../Utils/cacheLocal.dart';
import '../Utils/styles.dart';
import '../Utils/statusUtils.dart';
import '../Utils/timeLines.dart';
import 'customtickets.dart';
class Historial extends StatefulWidget {
  final VoidCallback? onTabTapped;

  const Historial({Key? key, this.onTabTapped}) : super(key: key);

  @override
  _HistorialState createState() => _HistorialState();
}

class _HistorialState extends State<Historial> with SingleTickerProviderStateMixin {
  List<ServiceRequest> serviceRequests = [];
  List<String> statuses = [];
  late final UserData userData;
  int unreadMessagesCount = 0;
  late final RegistrationData registrationData;
  late TabController _tabController;
  List<String> workerExpertiseIds = [];
  String workerId = '';
  int offerServiceCount = 0;
  

  @override
  void initState() {
    super.initState();

    registrationData = RegistrationData(
      userId: '',
      displayName: '',
      phoneNumber: '',
      paymentType: '',
      selectedCountryCode: '',
      location: {},
      email: '',
      idCardNumber: '',
      imagePath: '',
      imagePathList: [],
      idDocumentImagePath: '',
      idDocumentImagePath2: '',
      criminalRecordImagePath: '',
      certificateImagePaths: [],
      expertises: [],
      expLevel: [],
    );

    userData = UserData(
      displayName: '',
      email: '',
      phoneNumber: '',
      userId: '',
      location: {},
      paymentType: '',
      selectedCountryCode: '',
      registrationData: registrationData,
      getToken: '',
      idCardNumber: '',
      imagePath: '',
      idDocumentImagePath: '',
      idDocumentImagePath2: '',
      criminalRecordImagePath: '',
      certificateImagePaths: [],
      expertises: [],
      expLevel: [],
      pdfPathController: '',
    );

    _tabController = TabController(length: 5, vsync: this);
    _initializeData();
    calculateUnreadMessagesCount();
}


  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  
  Future<List<String>> fetchWorkerExpertises() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        final workerDoc = await FirebaseFirestore.instance
            .collection('workers')
            .doc(user.uid)
            .get();

        if (workerDoc.exists) {
          setState(() {
            workerId = workerDoc.id;
          });

          final List<dynamic> workerExpertises = workerDoc.data()?['expertises'] ?? [];
          return workerExpertises.map((expertise) {
            return expertise['id'] as String;
          }).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error al obtener los expertises del trabajador: $e');
      return [];
    }
  }

  Future<void> _initializeData() async {
    workerExpertiseIds = await fetchWorkerExpertises();
    await fetchServicesByExpertises(workerExpertiseIds);
  }
  Future<double?> fetchOfferedPrice(String serviceId) async {
  try {
    // Consultar Firestore en la colección 'offers'
    final querySnapshot = await FirebaseFirestore.instance
        .collection('offers')
        .where('serviceId', isEqualTo: serviceId)
        .limit(1)
        .get();
    
    if (querySnapshot.docs.isNotEmpty) {
      // Obtener el precio ofertado
      final offerData = querySnapshot.docs.first.data();
      final offeredPrice = offerData['offeredPrice'];

      // Verificar si el precio ofertado es válido
      return offeredPrice != null ? double.tryParse(offeredPrice) : null;
    }
  } catch (e) {
    print('Error al obtener el precio ofertado: $e');
  }
  return null;
}

  Future<void> fetchServicesByExpertises(List<String> workerExpertiseIds) async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        final token = await user.getIdToken();

        // Llamada al backend para obtener los servicios directamente, sin usar caché.
        final serviceResponse = await ApiService2().getAllServices(token!, "all", "", "");

        if (serviceResponse.statusCode == 200) {
          final List<dynamic> jsonDataList = json.decode(serviceResponse.body);

          final List<ServiceRequest> serviceRequestsList = jsonDataList.map((item) {
            final statusName = item['status'] as String? ?? '';
            final status = statusName.isNotEmpty
                ? Status(id: statusName, name: Status.getNameById(statusName))
                : Status(id: "unknown", name: 'Desconocido');

            final List<dynamic> expertisesArray = item['expertises'] as List<dynamic>? ?? [];
            final List<Expertises> expertisesList = expertisesArray.map((expertiseItem) {
              return Expertises(
                id: expertiseItem['id'] ?? '',
                name: expertiseItem['name'] ?? '',
              );
            }).toList();

            return ServiceRequest(
              expertises: expertisesList,
              id: item['id'] ?? '',
              serviceDateTime: item['serviceDateTime'] ?? '',
              description: item['description'] ?? '',
              images: (item['images'] as List<dynamic>?)
                      ?.map((image) => image ?? '')
                      .cast<String>()
                      .toList() ??
                  [],
              location: Map<String, double>.from(
                (item['location']?.map((key, value) {
                      return MapEntry(key, value is int ? value.toDouble() : value);
                    }) ??
                      {}),
              ),
              offeredPrice: _parseOfferedPrice(item['offeredPrice']),
              userId: item['userId'] ?? '',
              status: status,
              isFavorite: item['isFavorite'] as bool? ?? false,
              acceptedTerms: item['acceptedTerms'] as bool? ?? false,
              serviceType: ServiceType(
                name: item['serviceType'] ?? '',
                id: '',
                selectedDate: '',
                selectedTime: '',
              ),subcategoryName: item['subcategoryName'] ?? '',
            );
          }).toList();

          // Filtrar las solicitudes de servicio según las expertises del trabajador.
          final filteredServiceRequestsList = serviceRequestsList.where((serviceRequest) {
            // Comprobar si alguna de las expertises de la solicitud de servicio coincide con las expertises del trabajador.
            return serviceRequest.expertises.any((expertise) {
              return workerExpertiseIds.contains(expertise.id);
            });
          }).toList();

          // Verificar si la lista filtrada no está vacía
          if (filteredServiceRequestsList.isNotEmpty) {
            // Actualizar la interfaz de usuario con los datos filtrados.
            setState(() {
              serviceRequests = filteredServiceRequestsList;
              statuses = filteredServiceRequestsList.map((request) => request.status.name).toList();
            });

            print('Servicios cargados con éxito.');
          } else {
            print('No se encontraron servicios que coincidan con las expertises del trabajador.');
          }
        } else {
          print('Error al obtener datos del backend. Código de estado: ${serviceResponse.statusCode}');
        }
      } else {
        print('Usuario no autenticado');
      }
    } catch (e) {
      print('Error en la solicitud HTTP: $e');
    }
  }



  void calculateUnreadMessagesCount() async {
    int count = 0;
    for (var request in serviceRequests) {
      final messages = await FirebaseFirestore.instance
          .collection('chats')
          .doc(request.id)
          .collection('messages')
          .where('unread', isEqualTo: true)
          .get();
      count += messages.docs.length;
    }
    setState(() {
      unreadMessagesCount = count;
    });
  }

  double _parseOfferedPrice(dynamic value) {
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        print('Error al convertir el precio ofrecido a double: $e');
        return 0.0;
      }
    } else if (value is num) {
      return value.toDouble();
    }
    return 0.0;
  }

  void _openChatScreen() {
    if (serviceRequests.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No hay servicios disponibles para iniciar el chat.'),
        ),
      );
    }
  }

  Future<void> _refreshHistorial() async {
    await LocalCacheService.clearCacheForUser(FirebaseAuth.instance.currentUser!.uid);
    workerExpertiseIds = await fetchWorkerExpertises();
    await fetchServicesByExpertises(workerExpertiseIds);
    setState(() {});
  }


  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Historial',
          style: MyTextStyles.buttonTextStyle,
        ),
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshHistorial,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelStyle: MyTextStyles.tabTextStyle,
          unselectedLabelStyle: MyTextStyles.unselectedTabTextStyle,
          tabs: [
            Tab(text: 'Disponibles'),
            Tab(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Text('Ofertados'),
                  if (offerServiceCount > 0)
                    Positioned(
                      right: 7,
                      top: 4,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        child: Text(
                          offerServiceCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            Tab(text: 'Asignados'),
            Tab(text: 'Completados'),
            Tab(text: 'Cancelados'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildServiceListByStatus('available', screenWidth, screenHeight),
          _buildServiceListByStatus('offer', screenWidth, screenHeight),
          _buildServiceListByStatus('in_progress', screenWidth, screenHeight),
          _buildServiceListByStatus('completed', screenWidth, screenHeight),
          _buildServiceListByStatus('cancelled', screenWidth, screenHeight),
        ],
      ),
    );
  }

  Widget _buildServiceListByStatus(
    String statusId, double screenWidth, double screenHeight) {
  final filteredRequests = serviceRequests
      .where((request) => request.status.id == statusId)
      .toList();

  if (statusId == 'offer') {
    offerServiceCount = filteredRequests.length;
  }

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
    child: ListView.builder(
      itemCount: filteredRequests.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () async {
            final newStatus = await showDialog<String>(
              context: context,
              builder: (BuildContext context) {
                return ServiceFormWithTimeline(
                  serviceRequest: filteredRequests[index],
                  initialStatus: statuses[index],
                  onComplete: (status) {
                    setState(() {
                      statuses[index] = status;
                    });
                  },
                  userData: userData,
                  onStatusChanged: (newStatus) {},
                  workerId: workerId,
                );
              },
            );

            if (newStatus != null && newStatus != statuses[index]) {
              setState(() {
                statuses[index] = newStatus;
              });
            }
          },
          child: FutureBuilder<double?>(
            future: fetchOfferedPrice(filteredRequests[index].id),
            builder: (context, snapshot) {
              final offeredPrice = snapshot.data ?? 0.0;

              return Container(
                margin: EdgeInsets.only(bottom: screenHeight * 0.02),
                child: CustomPaint(
                  size: Size(screenWidth, screenHeight * 0.05),
                  painter: CustomTicketShapePainter(
                    status: filteredRequests[index].status.name,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 15), // Espacio para el título
                              Text(
                                'Categoría: ',
                                style: MyTextStyles.ButtonTextStyle,
                              ),
                              Text(
                                truncateDescription(
                                    filteredRequests[index].subcategoryName),
                                style: MyTextStyles.drawerButtonTextStyle5,
                                textAlign: TextAlign.left,
                              ),
                              SizedBox(height: screenHeight * 0.01),
                              Text(
                                'Servicio: ',
                                style: MyTextStyles.ButtonTextStyle,
                              ),
                              Text(
                                truncateDescription(
                                  filteredRequests[index]
                                      .expertises
                                      .map((e) => e.name)
                                      .join(', '),
                                ),
                                style: MyTextStyles.drawerButtonTextStyle5,
                                textAlign: TextAlign.left,
                              ),
                              SizedBox(height: screenHeight * 0.01),
                              Text(
                                'Precio Ofertado: \$${offeredPrice.toStringAsFixed(2)}',
                                style: MyTextStyles.drawerButtonTextStyle5,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 40), // Espacio entre la imagen y el texto
                          Image.asset(
                            'assets/manito.png',
                            width: 84,
                            height: 84,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    ),
  );
}


  String truncateDescription(String description) {
    final words = description.split(' ');
    if (words.length > 6) {
      return '${words.take(6).join(' ')}...';
    }
    return description;
  }
  Color _getTextColorByStatus(String statusId) {
    final status = StatusUtils.getStatusById(statusId);

    switch (status.id) {
      case "available":
        return Colors.green;
      case "assigned":
        return Colors.orange;
      case "in_progress":
        return Colors.black;
      case "completed":
        return Colors.blue;
      case "cancelled":
        return const Color(0xFF84090D);
      default:
        return Colors.grey;
    }
  }
}
