import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:socio/Metods/RegisController.dart';
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

class _HistorialState extends State<Historial> {
  List<ServiceRequest> serviceRequests = [];
  List<String> statuses = [];
  late final UserData userData;

  @override
  void initState() {
    super.initState();
    userData = UserData(
      displayName: '',
      email: '',
      phoneNumber: '',
      userId: '',
      location: {},
      paymentType: '',
      selectedCountryCode: '',
      registrationData: RegistrationData(
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
      ),
      idCardNumber: '',
      expertises: [],
      expLevel: [],
      imagePath: '',
      pdfPathController: '',
      criminalRecordImagePath: '',
      certificateImagePaths: [],
      idDocumentImagePath: '',
      idDocumentImagePath2: '',
      getToken: '',
    );
    fetchDataForUserId();
  }

  Future<void> fetchDataForUserId() async {
    try {
      final user = firebase_auth.FirebaseAuth.instance.currentUser;

      if (user != null) {
        final userId = user.uid;
        final token = await user.getIdToken();

        final cachedRequest = await LocalCacheService.getCachedServiceRequest(userId);
        if (cachedRequest != null) {
          if (mounted) {
            setState(() {
              serviceRequests = [cachedRequest];
              statuses = [cachedRequest.status.name];
            });
          }
        } else {
          final column = "";
          final value = "";
          final type = "";

          final serviceResponse = await ApiService2().getByUserId(userId, token!, column, value, type);

          if (serviceResponse.statusCode == 200) {
            try {
              final List<dynamic> jsonDataList = json.decode(serviceResponse.body);

              final List<ServiceRequest> serviceRequestsList = jsonDataList.map((item) {
                final statusName = item['status'] as String? ?? '';
                final status = statusName != null
                    ? Status(id: statusName, name: Status.getNameById(statusName))
                    : Status(id: "unknown", name: 'Desconocido');

                return ServiceRequest(
                  expertises: item['expertises'],
                  id: item['id'],
                  serviceDateTime: item['serviceDateTime'],
                  description: item['description'],
                  images: List<String>.from(item['images']),
                  location: Map<String, double>.from(
                    item['location']?.map((key, value) {
                          if (value is int) {
                            return MapEntry(key, value.toDouble());
                          } else {
                            return MapEntry(key, value);
                          }
                        }) ??
                        {},
                  ),
                  offeredPrice: _parseOfferedPrice(item['offeredPrice']),
                  userId: item['userId'],
                  status: status,
                  isFavorite: item['isFavorite'] as bool? ?? false,
                  acceptedTerms: item['acceptedTerms'] as bool? ?? false,
                  serviceType: ServiceType(
                    name: item['serviceType'],
                    id: '',
                    selectedDate: '',
                    selectedTime: '',
                  ),
                );
              }).toList();

              if (mounted) {
                setState(() {
                  serviceRequests = serviceRequestsList;
                  statuses = serviceRequestsList.map((request) => request.status.name).toList();
                });
              }

              serviceRequests.forEach((request) {
                LocalCacheService.cacheServiceRequest(request);
              });
            } catch (e) {
              print('Error al decodificar la respuesta JSON: $e');
            }
          } else {
            print('Error al obtener datos del backend. Código de estado: ${serviceResponse.statusCode}');
          }
        }
      } else {
        print('Usuario no autenticado');
      }
    } catch (e) {
      print('Error en la solicitud HTTP: $e');
    }
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

  Future<String?> _getUserToken() async {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user != null) {
      final token = await user.getIdToken();
      return token;
    }
    return ''; 
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Historial',
          style: MyTextStyles.buttonTextStyle,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refreshHistorial,
          ),
        ],
      ),
      body: Container(
  color: Colors.white,
  padding: EdgeInsets.all(30.0),
  child: ListView.builder(
    itemCount: serviceRequests.length,
    itemBuilder: (context, index) {
      return GestureDetector(
        onTap: () {
          // No se realiza ninguna acción al tocar el cuadro
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 30.0),
          child: CustomPaint(
            painter: CustomTicketShapePainter(
              status: serviceRequests[index].status.name,
            ),
            child: Padding(
              padding: EdgeInsets.all(30.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: screenWidth * 0.3,
                    height: screenWidth * 0.3,
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: Image.asset(
                        'assets/manito.png',
                      ),
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.04),
                  Flexible(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          serviceRequests[index].status.name,
                          style: MyTextStyles.buttonTextStyle,
                        ),
                        SizedBox(height: 8.0),
                        Text(
                          'Categoría: ',
                          style: MyTextStyles.ButtonTextStyle,
                          textAlign: TextAlign.left,
                        ),
                        Text(
                          '${truncateDescription(serviceRequests[index].expertises)}',
                          style: MyTextStyles.drawerButtonTextStyle5,
                          textAlign: TextAlign.left,
                        ),
                        Text(
                          'Servicio: ',
                          style: MyTextStyles.ButtonTextStyle,
                          textAlign: TextAlign.left,
                        ),
                        Text(
                          '${serviceRequests[index].serviceType.name}',
                          style: MyTextStyles.drawerButtonTextStyle5,
                          textAlign: TextAlign.left,
                        ),
                      ],
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
),
);
}

  String truncateDescription(String description) {
    final words = description.split(' ');

    final firstWord = words.isNotEmpty ? words[0] : '';

    if (words.length > 1) {
      return '$firstWord...';
    } else {
      return firstWord;
    }
  }

  void _refreshHistorial() async {
    await fetchDataForUserId();
    setState(() {});
  }

  Widget _buildStatusCircle(String statusId) {
    final double circleSize = 16.0;

    return Container(
      width: circleSize,
      height: circleSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _getCircleColorByStatus(statusId),
      ),
    );
  }

  Color _getCircleColorByStatus(String statusId) {
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
        return Color(0xFFFF000A);
      default:
        return Colors.grey;
    }
  }
}
