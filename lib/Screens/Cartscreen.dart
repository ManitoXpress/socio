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
  final workerExpertiseIds = await fetchWorkerExpertises();
  await fetchServicesByExpertises(workerExpertiseIds);
}


Future<void> fetchServicesByExpertises(List<String> workerExpertiseIds) async {
  try {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final userId = user.uid;
      final token = await user.getIdToken();

      // Obtener los datos del caché si están disponibles
      final cachedRequest = await LocalCacheService.getCachedServiceRequest(userId);
      if (cachedRequest != null) {
        print('Datos del caché encontrados. Mostrando datos del caché...');
        setState(() {
          serviceRequests = [cachedRequest];
          statuses = [cachedRequest.status.name];
        });
        return; // Terminar si ya hay datos en caché
      }

      // Realizar la solicitud al backend
      final column = "expertises"; // Puedes ajustar según la estructura de tu backend
      final value = workerExpertiseIds.join(','); // Unir los IDs de expertises en un solo string
      final type = ""; // Si necesitas un tipo específico, ajusta aquí

      final serviceResponse = await ApiService2().getByUserId(userId, token!, column, value, type);

      print('Respuesta del servidor: ${serviceResponse.body}');

      if (serviceResponse.statusCode == 200) {
        try {
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
                  .toList() ?? [],
              location: Map<String, double>.from(
                (item['location']?.map((key, value) {
                  if (value is int) {
                    return MapEntry(key, value.toDouble());
                  } else {
                    return MapEntry(key, value);
                  }
                }) ?? {}),
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
              ),
            );
          }).toList();

          // Filtrar los servicios que coinciden con los expertises del trabajador
          final filteredServiceRequestsList = serviceRequestsList.where((serviceRequest) {
            return serviceRequest.expertises.any((expertise) {
              return workerExpertiseIds.contains(expertise.id);
            });
          }).toList();

          setState(() {
            serviceRequests = filteredServiceRequestsList;
            statuses = filteredServiceRequestsList.map((request) => request.status.name).toList();
          });

          // Guardar en caché los servicios filtrados
          filteredServiceRequestsList.forEach((request) {
            LocalCacheService.cacheServiceRequest(request);
          });

          print('Servicios cargados con éxito. Total de servicios obtenidos del backend: ${filteredServiceRequestsList.length}');
        } catch (e) {
          print('Error al decodificar la respuesta JSON: $e');
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

  void _refreshHistorial() async {
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
        title: const Text('Historial', style: MyTextStyles.buttonTextStyle),
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
          tabs: const [
            Tab(text: 'Disponible'),
            Tab(text: 'Asignado'),
            Tab(text: 'En curso'),
            Tab(text: 'Completado'),
            Tab(text: 'Cancelado'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildServiceListByStatus('available', screenWidth, screenHeight),
          _buildServiceListByStatus('assigned', screenWidth, screenHeight),
          _buildServiceListByStatus('in_progress', screenWidth, screenHeight),
          _buildServiceListByStatus('completed', screenWidth, screenHeight),
          _buildServiceListByStatus('cancelled', screenWidth, screenHeight),
        ],
      ),
    );
  }

  Widget _buildServiceListByStatus(String statusId, double screenWidth, double screenHeight) {
    final filteredRequests = serviceRequests.where((request) => request.status.id == statusId).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                    initialStatus: filteredRequests[index].status.id,
                    onComplete: (status) {
                      setState(() {
                        filteredRequests[index].status.id = status;
                      });
                    },
                    userData: userData,
                    onStatusChanged: (newStatus) {}, 
                    token: '',
                  );
                },
              );

              if (newStatus != null && newStatus != filteredRequests[index].status.id) {
                setState(() {
                  filteredRequests[index].status.id = newStatus;
                });
              }
            },
            child: Container(
              margin: EdgeInsets.only(bottom: screenHeight * 0.05),
              child: CustomPaint(
                size: Size(screenWidth, screenHeight * 0.05),
                painter: CustomTicketShapePainter(status: filteredRequests[index].status.name),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 15),
                            const Text('Categoría:', style: MyTextStyles.ButtonTextStyle),
                            Text(
                              truncateDescription(filteredRequests[index].expertises.map((e) => e.name).join(', ')),
                              style: MyTextStyles.drawerButtonTextStyle5,
                              textAlign: TextAlign.left,
                            ),
                            SizedBox(height: screenHeight * 0.01),
                            const Text('Servicio:', style: MyTextStyles.ButtonTextStyle),
                            Text(
                              filteredRequests[index].description,
                              style: MyTextStyles.drawerButtonTextStyle5,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(filteredRequests[index].status.name),
                          const SizedBox(height: 16),
                          Text('\$${filteredRequests[index].offeredPrice.toStringAsFixed(2)}'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String truncateDescription(String description) {
    const maxLength = 60;
    return description.length > maxLength ? '${description.substring(0, maxLength)}...' : description;
  }
}
