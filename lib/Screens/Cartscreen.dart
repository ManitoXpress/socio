import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
class Historial extends StatefulWidget {
  final VoidCallback? onTabTapped;

  const Historial({Key? key, this.onTabTapped}) : super(key: key);

  @override
  _HistorialState createState() => _HistorialState();
}

class _HistorialState extends State<Historial>
    with SingleTickerProviderStateMixin {
  List<ServiceRequest> serviceRequests = [];
  List<Status> statuses = [];

  late final UserData userData;
  int unreadMessagesCount = 0;
  late final RegistrationData registrationData;
  late TabController _tabController;
  List<String> workerExpertiseIds = [];
  String workerId = '';
  int offerServiceCount = 0;
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  @override
  void initState() {
    super.initState();
    // Mostrar el diálogo al iniciar la clase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showWelcomeDialog();
    });

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
      expLevel: [], devicesId: '', fcmToken: '',
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

  // Método para mostrar el diálogo de bienvenida
  void _showWelcomeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          title: Text(
            '¡Bienvenido a ManitosXpress!',
            style: TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
              color: Color(0xFF84090D),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Gracias por unirte a ManitosXpress. Aquí podrás ofrecer tus habilidades y conectarte con clientes que necesitan tu ayuda.',
                style: TextStyle(
                  fontSize: 16.0,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              Icon(
                Icons.build_rounded,
                size: 60,
                color: Color(0xFF84090D),
              ),
              SizedBox(height: 20),
              Text(
                'Revisa los servicios disponibles y envía tus propuestas. ¡Tu próximo proyecto está a un clic de distancia!',
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: Color(0xFF84090D),
                backgroundColor: const Color(0xFFE8E8E8),
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                side: BorderSide(
                  color: const Color(0xFFE8E8E8),
                  width: 1,
                ),
              ),
              child: Text(
                "Comenzar",
                style: TextStyle(
                  fontSize: 18,
                ),
              ),
            ),
          ],
        );
      },
    );
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

          final List<dynamic> workerExpertises =
              workerDoc.data()?['expertises'] ?? [];
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

        // Verificar el tipo de offeredPrice y convertirlo a double si es necesario
        if (offeredPrice is String) {
          return double.tryParse(offeredPrice);
        } else if (offeredPrice is double) {
          return offeredPrice;
        } else {
          return null;
        }
      }
    } catch (e) {
      print('Error al obtener el precio ofertado: $e');
    }
    return null;
  }

  Future<void> fetchServicesByExpertises(
      List<String> workerExpertiseIds) async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        final token = await user.getIdToken();

        // Llamada al backend para obtener los servicios directamente, sin usar caché.
        final serviceResponse =
        await ApiService2().getAllServices(token!, "all", "", "");

        if (serviceResponse.statusCode == 200) {
          final List<dynamic> jsonDataList = json.decode(serviceResponse.body);

          final List<ServiceRequest> serviceRequestsList =
          jsonDataList.map((item) {
            final statusName = item['status'] as String? ?? '';
            final status = statusName.isNotEmpty
                ? Status(id: statusName, name: Status.getNameById(statusName))
                : Status(id: "unknown", name: 'Desconocido');

            final List<dynamic> expertisesArray =
                item['expertises'] as List<dynamic>? ?? [];
            final List<Expertises> expertisesList =
            expertisesArray.map((expertiseItem) {
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
                  return MapEntry(
                      key, value is int ? value.toDouble() : value);
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
              ),
              subcategoryName: item['subcategoryName'] ?? '',
            );
          }).toList();

          // Filtrar las solicitudes de servicio según las expertises del trabajador.
          final filteredServiceRequestsList =
          serviceRequestsList.where((serviceRequest) {
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
              statuses = filteredServiceRequestsList
                  .map((request) => request.status)
                  .toList();

            });

            print('Servicios cargados con éxito.');
          } else {
            print(
                'No se encontraron servicios que coincidan con las expertises del trabajador.');
          }
        } else {
          print(
              'Error al obtener datos del backend. Código de estado: ${serviceResponse.statusCode}');
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
    await LocalCacheService.clearCacheForUser(
        FirebaseAuth.instance.currentUser!.uid);
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


        bottom: PreferredSize(
          preferredSize: Size.fromHeight(50.0),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelPadding: EdgeInsets.symmetric(
                  horizontal: 8.0), // Ajuste de espacio entre tabs
              labelStyle: MyTextStyles.tabTextStyle,
              unselectedLabelStyle: MyTextStyles.unselectedTabTextStyle,
              indicator: UnderlineTabIndicator(
                // Línea fina como indicador
                borderSide: BorderSide(width: 3.0, color: Color(0xFF84090D)),
                insets: EdgeInsets.symmetric(
                    horizontal: 20.0), // Añade espacio en los extremos
              ),
              tabs: [
                Tab(
                  icon: Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Icon(Icons.task_alt, color: Colors.black),
                  ),
                  text: 'Disponibles',
                ),
                Tab(
                  child: Column(
                    mainAxisSize: MainAxisSize
                        .min, // Minimiza el espacio ocupado por la columna
                    children: [
                      Stack(
                        clipBehavior: Clip
                            .none, // Permite desbordar el badge de notificación
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4.0),
                            child: Icon(Icons.local_offer, color: Colors.black),
                          ),
                          if (offerServiceCount > 0)
                            Positioned(
                              top: -10, // Ajusta la posición del badge
                              right: -10,
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                constraints: BoxConstraints(
                                  minWidth: 20,
                                  minHeight: 20,
                                ),
                                child: Text(
                                  offerServiceCount.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(
                          height: 4.0), // Espacio entre el ícono y el texto
                      Text(
                        'Ofertados',
                        style: TextStyle(
                            fontSize: 12.0), // Ajuste de tamaño del texto
                      ),
                    ],
                  ),
                ),
                Tab(
                  icon: Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Icon(Icons.assignment_ind, color: Colors.black),
                  ),
                  text: 'Asignados',
                ),
                Tab(
                  icon: Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Icon(Icons.check_circle, color: Colors.black),
                  ),
                  text: 'Completados',
                ),
                Tab(
                  icon: Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Icon(Icons.cancel, color: Colors.black),
                  ),
                  text: 'Cancelados',
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(10.0),
            child: Row(
              children: [
                Text(
                  'Historial',
                  style: MyTextStyles.buttonTextStyle3,
                ),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.refresh, color: Color(0xFF84090D),),
                  onPressed: _refreshHistorial,
                ),
              ],
            ),
          ),
          SizedBox(height: 1.0),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildServiceListByStatus(
                    'available', screenWidth, screenHeight),
                _buildServiceListByStatus('offer', screenWidth, screenHeight),
                _buildServiceListByStatus('in_progress,pending_confirmation,pending_confirmation2',
                    screenWidth, screenHeight),
                _buildServiceListByStatus(
                    'completed', screenWidth, screenHeight),
                _buildServiceListByStatus(
                    'cancelled', screenWidth, screenHeight),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceListByStatus(
      String statusIds, double screenWidth, double screenHeight) {
    if (statusIds == 'offer') {
      return FutureBuilder<List<ServiceRequest>>(
        future: _fetchServicesWithOffers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("No hay servicios ofertados."));
          }

          final servicesWithOffers = snapshot.data!;
          return _buildServiceList(servicesWithOffers, screenWidth, screenHeight);
        },
      );
    } else if (statusIds == 'available') {
      return FutureBuilder<List<ServiceRequest>>(
        future: _fetchAvailableServicesWithoutOffers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("No hay servicios disponibles."));
          }

          final availableServices = snapshot.data!;
          return _buildServiceList(availableServices, screenWidth, screenHeight);
        },
      );
    } else {
      // Otros estados...
      return Container(); // Placeholder
    }
  }

  Widget _buildServiceList(
      List<ServiceRequest> services, double screenWidth, double screenHeight) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: ListView.builder(
        itemCount: services.length,
        itemBuilder: (context, index) {
          final service = services[index];

          return GestureDetector(
            onTap: () {
              // Aquí se navega a la pantalla ServiceFormWithTimeline
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ServiceFormWithTimeline(
                    serviceRequest: service,
                    initialStatus: statuses.isNotEmpty && index < statuses.length
                            ? statuses[index].id
                            : 'default_status', // Pasa el objeto Status aquí
                    onComplete: (status) {
                      setState(() {
                        if (statuses.length != services.length) {
                          // Asegúrate de que statuses tenga el mismo tamaño que services
                          statuses = List.generate(services.length, (index) => Status(id: '', name: ''));
                        }

                      });
                    },
                    onStatusChanged: (newStatus) {},
                    userData: userData, // Pasa la información del usuario
                    workerId: workerId, // Pasa el ID del trabajador
                    images: [], // Pasa las imágenes que quieras
                  ),
                ),
              );
            },
            child: Container(
              margin: EdgeInsets.only(bottom: screenHeight * 0.02),
              width: screenWidth,
              height: screenHeight * 0.24,
              child: CustomPaint(
                size: Size(screenWidth, screenHeight * 0.35),
                painter: CustomTicketShapePainter(
                  status: statuses[index], // Pasa el objeto Status correspondiente
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Contenido textual...
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 30),
                            Text(
                              'Categoría:',
                              style: MyTextStyles.drawerButtonTextStyle,
                            ),
                            Text(
                              truncateDescription(service.subcategoryName),
                              style: MyTextStyles.drawerButtonTextStyle5,
                              textAlign: TextAlign.left,
                            ),
                            SizedBox(height: screenHeight * 0.01),
                            Text(
                              'Servicio:',
                              style: MyTextStyles.drawerButtonTextStyle,
                            ),
                            Text(
                              truncateDescription(
                                service.expertises.map((e) => e.name).join(', '),
                              ),
                              style: MyTextStyles.drawerButtonTextStyle5,
                              textAlign: TextAlign.left,
                            ),
                            SizedBox(height: screenHeight * 0.01),
                            Text(
                              'Precio Ofertado: \$${service.offeredPrice.toStringAsFixed(2)}',
                              style: MyTextStyles.drawerButtonTextStyle,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 10),
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: Image.asset(
                          'assets/manito.png',
                          width: 64,
                          height: 64,
                          fit: BoxFit.contain,
                        ),
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


  Future<List<ServiceRequest>> _fetchServicesWithOffers() async {
    try {
      // Consulta los documentos en "offers" donde el worker ha hecho una oferta
      final offersSnapshot = await FirebaseFirestore.instance
          .collection('offers')
          .where('hasOffer', isEqualTo: true)
          .where('workerId', isEqualTo: workerId)
          .get();

      final offerServiceIds =
      offersSnapshot.docs.map((doc) => doc['serviceId'] as String).toList();

      if (offerServiceIds.isEmpty) {
        return [];
      }

      // Consulta los servicios correspondientes a esas ofertas
      final servicesSnapshot = await FirebaseFirestore.instance
          .collection('services')
          .where(FieldPath.documentId, whereIn: offerServiceIds)
          .get();

      return servicesSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Agrega el ID del documento al mapa
        return ServiceRequest.fromSnapshot(data);
      }).toList();
    } catch (e) {
      print('Error fetching services with offers: $e');
      return [];
    }
  }

  Future<List<ServiceRequest>> _fetchAvailableServicesWithoutOffers() async {
    try {
      // Consulta los documentos en "offers" donde el worker ha hecho una oferta
      final offersSnapshot = await FirebaseFirestore.instance
          .collection('offers')
          .where('workerId', isEqualTo: workerId)
          .get();

      final offerServiceIds =
      offersSnapshot.docs.map((doc) => doc['serviceId'] as String).toList();

      // Consulta los servicios disponibles excluyendo aquellos con ofertas del worker
      final servicesSnapshot = await FirebaseFirestore.instance
          .collection('services')
          .where('status', isEqualTo: 'available')
          .where(
        FieldPath.documentId,
        whereNotIn: offerServiceIds.isEmpty ? null : offerServiceIds,
      )
          .get();

      return servicesSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Agrega el ID del documento al mapa
        return ServiceRequest.fromSnapshot(data);
      }).toList();
    } catch (e) {
      print('Error fetching available services: $e');
      return [];
    }
  }


  String truncateDescription(String description) {
    final words = description.split(' ');
    if (words.length > 6) {
      return '${words.take(6).join(' ')}...';
    }
    return description;
  }
}