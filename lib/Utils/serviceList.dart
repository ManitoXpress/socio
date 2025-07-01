import 'package:flutter/material.dart';
import 'package:socio/Screens/customtickets.dart';
import 'package:socio/ServiceResponse/get.dart';
import 'package:socio/ServiceResponse/post.dart';
import 'package:socio/ServiceResponse/request.dart';
import 'package:socio/ServiceResponse/requestExpertise.dart';
import 'package:socio/ServiceResponse/requestServiceType.dart';
import 'package:socio/ServiceResponse/requestStatus.dart';
import 'package:socio/ServiceResponse/requestUserData.dart';
import 'package:socio/Utils/styles.dart';
import 'package:socio/Utils/timeLines.dart';
import 'package:socio/Utils/workerDetails.dart';
import 'package:socio/models/expertise_models.dart';
import 'package:socio/models/offer_models.dart';
import 'package:socio/models/serviceRequest_models.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:socio/provider/service_partner_provider.dart';
class ServiceListBuilder {
  /// Lista de servicios en estado "offer" (ofertas hechas por el socio).
  static Widget buildOfferList(
      List<ServiceRequest> services,
      List<Offer> offers,
      double screenWidth,
      double screenHeight,
      String userId,
      final UserData userData,
      final ApiService apiService,
      final ApiService2 apiService2,
      ) {
    final serviceDataFetcher = ServiceDataFetcher();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: ListView.builder(
        itemCount: offers.length,
        itemBuilder: (context, index) {
          final offer = offers[index];
          // Busca el ServiceRequest correspondiente a esta oferta
          final service = services.firstWhere(
                (s) => s.id == offer.serviceId,
            orElse: () => throw Exception(
                'Servicio no encontrado para oferta ${offer.id}'),
          );

          return GestureDetector(
            onTap: () async {
              // 1) Traemos detalles del trabajador
              final workerDetails =
              await serviceDataFetcher.fetchWorkerDetails(offer.workerId);
              if (workerDetails == null) return;

              // 2) Mapeamos ServiceRequest -> ServiceRequestModel
              final serviceModel = ServiceRequestModel(
                id: service.id,
                status: service.status.id,
                date: service.serviceType.selectedDate,
                time: service.serviceType.selectedTime,
                description: service.description,
                location: service.location,
                images: service.images,
                expertises: service.expertises
                    .map((e) => ExpertiseModel(id: e.id, name: e.name))
                    .toList(),
                rawOffers: [
                  {
                    'workerId': offer.workerId,
                    'offeredPrice': offer.offeredPrice,
                    'extraCosts': offer.extraCosts,
                    'totalPrice': offer.totalPrice,
                    'status': offer.status.id,
                    'id': offer.id,
                  }
                ],
                rawComments: [],
                userId: service.userId,
                workerId: offer.workerId,
                completionImageUrl: null,
              );

              // 3) Mapeamos Offer -> OfferModel
              final offerModel = OfferModel(
                id: offer.id,
                serviceId: offer.serviceId,
                workerId: offer.workerId,
                offeredPrice: offer.offeredPrice,
                status: offer.status.id,
                subcategoryName: offer.subcategoryName,
                expertises: offer.expertises
                    .map((e) => Expertise(id: e.id, name: e.name))
                    .toList(),
                clientNIT: '',
                extraCosts: offer.extraCosts,
                totalPrice: offer.totalPrice,
                paymentStatus: '',

              );

              // 4) Navegamos al timeline del socio, inyectando ServicePartnerProvider
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChangeNotifierProvider<ServicePartnerProvider>(
                    create: (_) {
                      final prov = ServicePartnerProvider(
                        serviceRequest: serviceModel,
                        offer: offerModel,
                        userData: userData,
                        workerId: offer.workerId,
                        offers: offers
                            .map((o) => OfferModel(
                          id: o.id,
                          serviceId: o.serviceId,
                          workerId: o.workerId,
                          offeredPrice: o.offeredPrice,
                          status: o.status.id,
                          subcategoryName: o.subcategoryName,
                          expertises: o.expertises
                              .map((e) => Expertise(id: e.id, name: e.name))
                              .toList(),
                          clientNIT: '',
                          extraCosts: o.extraCosts,
                          totalPrice: o.totalPrice,
                          paymentStatus: '',

                        ))
                            .toList(),
                        apiService: apiService,
                        apiService2: apiService2,
                        userId: service.userId,
                      );
                      return prov;
                    },
                    child: ServiceFormWithTimelineSocio(
                      serviceRequest: serviceModel,
                      offer: offerModel,
                      userData: userData,
                      workerId: offer.workerId,
                      offers: offers
                          .map((o) => OfferModel(
                        id: o.id,
                        serviceId: o.serviceId,
                        workerId: o.workerId,
                        offeredPrice: o.offeredPrice,
                        status: o.status.id,
                        subcategoryName: o.subcategoryName,
                        expertises: o.expertises
                            .map((e) =>
                            Expertise(id: e.id, name: e.name))
                            .toList(),
                        clientNIT: '',
                        extraCosts: o.extraCosts,
                        totalPrice: o.totalPrice,
                        paymentStatus: '',

                      ))
                          .toList(),
                      apiService: apiService,
                      apiService2: apiService2,
                      userId: service.userId,
                      displayName: userData.displayName,
                    ),
                  ),
                ),
              );
            },
            child: _buildOfferCard(service, offer, screenWidth, screenHeight),
          );
        },
      ),
    );
  }

  /// Lista de servicios en estado "in_progress" (socios que ya fueron aceptados).
  static Widget inProgressList(
      List<ServiceRequest> services,
      List<Offer> offers,
      double screenWidth,
      double screenHeight,
      String userId,
      final UserData userData,
      final ApiService apiService,
      final ApiService2 apiService2,
      ) {
    final serviceDataFetcher = ServiceDataFetcher();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: ListView.builder(
        itemCount: offers.length,
        itemBuilder: (context, index) {
          final offer = offers[index];
          final service = services.firstWhere(
                (s) => s.id == offer.serviceId,
            orElse: () => throw Exception(
                'Servicio no encontrado para oferta ${offer.id}'),
          );

          return GestureDetector(
            onTap: () async {
              // 1) Traemos detalles del trabajador
              final workerDetails =
              await serviceDataFetcher.fetchWorkerDetails(offer.workerId);
              if (workerDetails == null) return;

              // 2) Mapeamos ServiceRequest -> ServiceRequestModel
              final serviceModel = ServiceRequestModel(
                id: service.id,
                status: service.status.id,
                date: service.serviceType.selectedDate,
                time: service.serviceType.selectedTime,
                description: service.description,
                location: service.location,
                images: service.images,
                expertises: service.expertises
                    .map((e) => ExpertiseModel(id: e.id, name: e.name))
                    .toList(),
                rawOffers: [
                  {
                    'workerId': offer.workerId,
                    'offeredPrice': offer.offeredPrice,
                    'extraCosts': offer.extraCosts,
                    'totalPrice': offer.totalPrice,
                    'status': offer.status.id,
                    'id': offer.id,
                  }
                ],
                rawComments: [],
                userId: service.userId,
                workerId: offer.workerId,
                completionImageUrl: null,
              );

              // 3) Mapeamos Offer -> OfferModel
              final offerModel = OfferModel(
                id: offer.id,
                serviceId: offer.serviceId,
                workerId: offer.workerId,
                offeredPrice: offer.offeredPrice,
                status: offer.status.id,
                subcategoryName: offer.subcategoryName,
                expertises: offer.expertises
                    .map((e) => Expertise(id: e.id, name: e.name))
                    .toList(),
                clientNIT: '',
                extraCosts: offer.extraCosts,
                totalPrice: offer.totalPrice,
                paymentStatus: '',

              );

              // 4) Navegamos al timeline del socio
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChangeNotifierProvider<ServicePartnerProvider>(
                    create: (_) {
                      final prov = ServicePartnerProvider(
                        serviceRequest: serviceModel,
                        offer: offerModel,
                        userData: userData,
                        workerId: offer.workerId,
                        offers: offers
                            .map((o) => OfferModel(
                          id: o.id,
                          serviceId: o.serviceId,
                          workerId: o.workerId,
                          offeredPrice: o.offeredPrice,
                          status: o.status.id,
                          subcategoryName: o.subcategoryName,
                          expertises: o.expertises
                              .map((e) =>
                              Expertise(id: e.id, name: e.name))
                              .toList(),
                          clientNIT: '',
                          extraCosts: o.extraCosts,
                          totalPrice: o.totalPrice,
                          paymentStatus: '',

                        ))
                            .toList(),
                        apiService: apiService,
                        apiService2: apiService2,
                        userId: service.userId,
                      );
                      return prov;
                    },
                    child: ServiceFormWithTimelineSocio(
                      serviceRequest: serviceModel,
                      offer: offerModel,
                      userData: userData,
                      workerId: offer.workerId,
                      offers: offers
                          .map((o) => OfferModel(
                        id: o.id,
                        serviceId: o.serviceId,
                        workerId: o.workerId,
                        offeredPrice: o.offeredPrice,
                        status: o.status.id,
                        subcategoryName: o.subcategoryName,
                        expertises: o.expertises
                            .map((e) =>
                            Expertise(id: e.id, name: e.name))
                            .toList(),
                        clientNIT: '',
                        extraCosts: o.extraCosts,
                        totalPrice: o.totalPrice,
                        paymentStatus: '',

                      ))
                          .toList(),
                      apiService: apiService,
                      apiService2: apiService2,
                      userId: service.userId,
                      displayName: userData.displayName,
                    ),
                  ),
                ),
              );
            },
            child: _buildOfferCard(service, offer, screenWidth, screenHeight),
          );
        },
      ),
    );
  }

  /// Lista de servicios "available" (sin ofertas aún).
  static Widget buildServiceListAvailable(
      List<ServiceRequest> services,
      List<Offer> allOffers,
      double screenWidth,
      double screenHeight,
      String userId,           // este es tu userId (el socio que navega)
      dynamic userData,        // tu UserData del socio
      final ApiService apiService,
      final ApiService2 apiService2,
      ) {
    final serviceDataFetcher = ServiceDataFetcher();
    // Filtramos servicios que no tengan ninguna oferta
    final offeredIds = allOffers.map((o) => o.serviceId).toSet();
    final availableServices =
    services.where((s) => !offeredIds.contains(s.id)).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: ListView.builder(
        itemCount: availableServices.length,
        itemBuilder: (context, index) {
          final service = availableServices[index];

          // Creamos un Offer "dummy" para poder navegar, aunque no exista oferta real
          // Importante: aquí ponemos workerId = userData.userId, para que el provider
          // reciba siempre un workerId válido.
          final dummyOffer = OfferModel(
            id: '',
            serviceId: service.id,
            workerId: userData.userId,    // <--- pongo el ID del socio actual
            offeredPrice: 0.0,
            status: '',
            subcategoryName: '',
            expertises: service.expertises
                .map((e) => Expertise(id: e.id, name: e.name))
                .toList(),
            clientNIT: '',
            extraCosts: 0.0,
            totalPrice: 0.0,
            paymentStatus: '',
          );

          return GestureDetector(
            onTap: () async {
              // 1) Traemos detalles del trabajador (opcional, puede ser nulo si aún no hay oferta)
              final workerDetails =
              await serviceDataFetcher.fetchWorkerDetails(userData.userId);
              // <-- aquí pedimos los detalles de MI perfil de trabajador

              // 2) Mapeamos ServiceRequest -> ServiceRequestModel
              final serviceModel = ServiceRequestModel(
                id: service.id,
                status: service.status.id,
                date: service.serviceType.selectedDate,
                time: service.serviceType.selectedTime,
                description: service.description,
                location: service.location,
                images: service.images,
                expertises: service.expertises
                    .map((e) => ExpertiseModel(id: e.id, name: e.name))
                    .toList(),
                rawOffers: [], // Servicios disponibles no tienen ofertas aún
                rawComments: [],
                userId: service.userId,
                workerId: userData.userId,   // <--- repito mi userId del socio
                completionImageUrl: null,
              );

              // 3) Navegamos al formulario con provider. Fíjate que pasamos workerId=userData.userId
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ChangeNotifierProvider<ServicePartnerProvider>(
                        create: (_) {
                          final prov = ServicePartnerProvider(
                            serviceRequest: serviceModel,
                            offer: dummyOffer,
                            userData: userData,
                            workerId: userData.userId,    // <--- ID del socio que oferta
                            offers: allOffers
                                .map((o) => OfferModel(
                              id: o.id,
                              serviceId: o.serviceId,
                              workerId: o.workerId,
                              offeredPrice: o.offeredPrice,
                              status: o.status.id,
                              subcategoryName: o.subcategoryName,
                              expertises: o.expertises
                                  .map((e) =>
                                  Expertise(id: e.id, name: e.name))
                                  .toList(),
                              clientNIT: '',
                              extraCosts: o.extraCosts,
                              totalPrice: o.totalPrice,
                              paymentStatus: '',
                            ))
                                .toList(),
                            apiService: apiService,
                            apiService2: apiService2,
                            userId: service.userId,
                          );
                          return prov;
                        },
                        child: ServiceFormWithTimelineSocio(
                          serviceRequest: serviceModel,
                          offer: dummyOffer,
                          userData: userData,
                          workerId: userData.userId,   // <--- paso el mismo workerId aquí
                          offers: allOffers
                              .map((o) => OfferModel(
                            id: o.id,
                            serviceId: o.serviceId,
                            workerId: o.workerId,
                            offeredPrice: o.offeredPrice,
                            status: o.status.id,
                            subcategoryName: o.subcategoryName,
                            expertises: o.expertises
                                .map((e) =>
                                Expertise(id: e.id, name: e.name))
                                .toList(),
                            clientNIT: '',
                            extraCosts: o.extraCosts,
                            totalPrice: o.totalPrice,
                            paymentStatus: '',
                          ))
                              .toList(),
                          apiService: apiService,
                          apiService2: apiService2,
                          userId: service.userId,
                          displayName: userData.displayName,
                        ),
                      ),
                ),
              );
            },
            child: _buildServiceCard(service, screenWidth, screenHeight),
          );
        },
      ),
    );
  }


  /// Lista de servicios "completed" (completados).
  static Widget buildServiceListComplete(
      List<ServiceRequest> services,
      List<Offer> offers,
      double screenWidth,
      double screenHeight,
      String userId,
      final UserData userData,
      final ApiService apiService,
      final ApiService2 apiService2,
      ) {
    final serviceDataFetcher = ServiceDataFetcher();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: ListView.builder(
        itemCount: offers.length,
        itemBuilder: (context, index) {
          final offer = offers[index];
          final service = services.firstWhere(
                (s) => s.id == offer.serviceId,
            orElse: () => throw Exception(
                'Servicio no encontrado para oferta ${offer.id}'),
          );

          return GestureDetector(
            onTap: () async {
              // 1) Traemos detalles del trabajador
              final workerDetails =
              await serviceDataFetcher.fetchWorkerDetails(offer.workerId);
              if (workerDetails == null) return;

              // 2) Mapeamos ServiceRequest -> ServiceRequestModel
              final serviceModel = ServiceRequestModel(
                id: service.id,
                status: service.status.id,
                date: service.serviceType.selectedDate,
                time: service.serviceType.selectedTime,
                description: service.description,
                location: service.location,
                images: service.images,
                expertises: service.expertises
                    .map((e) => ExpertiseModel(id: e.id, name: e.name))
                    .toList(),
                rawOffers: [
                  {
                    'workerId': offer.workerId,
                    'offeredPrice': offer.offeredPrice,
                    'extraCosts': offer.extraCosts,
                    'totalPrice': offer.totalPrice,
                    'status': offer.status.id,
                    'id': offer.id,
                  }
                ],
                rawComments: [],
                userId: service.userId,
                workerId: offer.workerId,
                completionImageUrl: null,
              );

              // 3) Mapeamos Offer -> OfferModel
              final offerModel = OfferModel(
                id: offer.id,
                serviceId: offer.serviceId,
                workerId: offer.workerId,
                offeredPrice: offer.offeredPrice,
                status: offer.status.id,
                subcategoryName: offer.subcategoryName,
                expertises: offer.expertises
                    .map((e) => Expertise(id: e.id, name: e.name))
                    .toList(),
                clientNIT: '',
                extraCosts: offer.extraCosts,
                totalPrice: offer.totalPrice,
                paymentStatus: '',

              );

              // 4) Navegamos al timeline del socio
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChangeNotifierProvider<ServicePartnerProvider>(
                    create: (_) {
                      final prov = ServicePartnerProvider(
                        serviceRequest: serviceModel,
                        offer: offerModel,
                        userData: userData,
                        workerId: offer.workerId,
                        offers: offers
                            .map((o) => OfferModel(
                          id: o.id,
                          serviceId: o.serviceId,
                          workerId: o.workerId,
                          offeredPrice: o.offeredPrice,
                          status: o.status.id,
                          subcategoryName: o.subcategoryName,
                          expertises: o.expertises
                              .map((e) =>
                              Expertise(id: e.id, name: e.name))
                              .toList(),
                          clientNIT: '',
                          extraCosts: o.extraCosts,
                          totalPrice: o.totalPrice,
                          paymentStatus: '',

                        ))
                            .toList(),
                        apiService: apiService,
                        apiService2: apiService2,
                        userId: service.userId,
                      );
                      return prov;
                    },
                    child: ServiceFormWithTimelineSocio(
                      serviceRequest: serviceModel,
                      offer: offerModel,
                      userData: userData,
                      workerId: offer.workerId,
                      offers: offers
                          .map((o) => OfferModel(
                        id: o.id,
                        serviceId: o.serviceId,
                        workerId: o.workerId,
                        offeredPrice: o.offeredPrice,
                        status: o.status.id,
                        subcategoryName: o.subcategoryName,
                        expertises: o.expertises
                            .map((e) =>
                            Expertise(id: e.id, name: e.name))
                            .toList(),
                        clientNIT: '',
                        extraCosts: o.extraCosts,
                        totalPrice: o.totalPrice,
                        paymentStatus: '',

                      ))
                          .toList(),
                      apiService: apiService,
                      apiService2: apiService2,
                      userId: service.userId,
                      displayName: userData.displayName,
                    ),
                  ),
                ),
              );
            },
            child: _buildOfferCard(service, offer, screenWidth, screenHeight),
          );
        },
      ),
    );
  }

  /// Lista de servicios "cancelled" (cancelados).
  static Widget buildServiceListCancelled(
      List<ServiceRequest> services,
      double screenWidth,
      double screenHeight,
      String userId,
      dynamic userData,
      final ApiService apiService,
      final ApiService2 apiService2,
      ) {
    final serviceDataFetcher = ServiceDataFetcher();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: ListView.builder(
        itemCount: services.length,
        itemBuilder: (context, index) {
          final service = services[index];
          // Creamos un OfferModel "dummy" para la navegación
          final dummyOffer = OfferModel(
            id: '',
            serviceId: service.id,
            workerId: service.workerId,
            offeredPrice: service.offeredPrice,
            status: service.status.id,
            subcategoryName: service.subcategoryName,
            expertises: service.expertises
                .map((e) => Expertise(id: e.id, name: e.name))
                .toList(),
            clientNIT: '',
            extraCosts: 0.0,
            totalPrice: 0.0,
            paymentStatus: '',

          );

          return GestureDetector(
            onTap: () async {
              // 1) Traemos detalles del trabajador
              final workerDetails =
              await serviceDataFetcher.fetchWorkerDetails(service.workerId);
              if (workerDetails == null) return;

              // 2) Mapeamos ServiceRequest -> ServiceRequestModel
              final serviceModel = ServiceRequestModel(
                id: service.id,
                status: service.status.id,
                date: service.serviceType.selectedDate,
                time: service.serviceType.selectedTime,
                description: service.description,
                location: service.location,
                images: service.images,
                expertises: service.expertises
                    .map((e) => ExpertiseModel(id: e.id, name: e.name))
                    .toList(),
                rawOffers: [],
                rawComments: [],
                userId: service.userId,
                workerId: service.workerId,
                completionImageUrl: null,
              );

              // 3) Navegamos al timeline del socio
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChangeNotifierProvider<ServicePartnerProvider>(
                    create: (_) {
                      final prov = ServicePartnerProvider(
                        serviceRequest: serviceModel,
                        offer: dummyOffer,
                        userData: userData,
                        workerId: service.workerId,
                        offers: [dummyOffer],
                        apiService: apiService,
                        apiService2: apiService2,
                        userId: service.userId,
                      );
                      return prov;
                    },
                    child: ServiceFormWithTimelineSocio(
                      serviceRequest: serviceModel,
                      offer: dummyOffer,
                      userData: userData,
                      workerId: service.workerId,
                      offers: [dummyOffer],
                      apiService: apiService,
                      apiService2: apiService2,
                      userId: service.userId,
                      displayName: userData.displayName,
                    ),
                  ),
                ),
              );
            },
            child: _buildServiceCard(service, screenWidth, screenHeight),
          );
        },
      ),
    );
  }

  /// Constructor general si queremos una lista de servicios/​ofertas combinada.
  static Widget buildServiceList(
      List<ServiceRequest> services,
      List<Offer> offers,
      double screenWidth,
      double screenHeight,
      String userId,
      dynamic userData,
      final ApiService apiService,
      final ApiService2 apiService2,
      ) {
    final serviceDataFetcher = ServiceDataFetcher();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: ListView.builder(
        itemCount: offers.length,
        itemBuilder: (context, index) {
          final offer = offers[index];
          final service = services.firstWhere(
                (s) => s.id == offer.serviceId,
            orElse: () => throw Exception(
                'Servicio no encontrado para oferta ${offer.id}'),
          );

          return GestureDetector(
            onTap: () async {
              // 1) Traemos detalles del trabajador
              final workerDetails =
              await serviceDataFetcher.fetchWorkerDetails(service.workerId);
              if (workerDetails == null) return;

              // 2) Mapeamos ServiceRequest -> ServiceRequestModel
              final serviceModel = ServiceRequestModel(
                id: service.id,
                status: service.status.id,
                date: service.serviceType.selectedDate,
                time: service.serviceType.selectedTime,
                description: service.description,
                location: service.location,
                images: service.images,
                expertises: service.expertises
                    .map((e) => ExpertiseModel(id: e.id, name: e.name))
                    .toList(),
                rawOffers: [
                  {
                    'workerId': offer.workerId,
                    'offeredPrice': offer.offeredPrice,
                    'extraCosts': offer.extraCosts,
                    'totalPrice': offer.totalPrice,
                    'status': offer.status.id,
                    'id': offer.id,
                  }
                ],
                rawComments: [],
                userId: service.userId,
                workerId: offer.workerId,
                completionImageUrl: null,
              );

              // 3) Mapeamos Offer -> OfferModel
              final offerModel = OfferModel(
                id: offer.id,
                serviceId: offer.serviceId,
                workerId: offer.workerId,
                offeredPrice: offer.offeredPrice,
                status: offer.status.id,
                subcategoryName: offer.subcategoryName,
                expertises: offer.expertises
                    .map((e) => Expertise(id: e.id, name: e.name))
                    .toList(),
                clientNIT: '',
                extraCosts: offer.extraCosts,
                totalPrice: offer.totalPrice,
                paymentStatus: '',

              );

              // 4) Navegamos al timeline
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChangeNotifierProvider<ServicePartnerProvider>(
                    create: (_) {
                      final prov = ServicePartnerProvider(
                        serviceRequest: serviceModel,
                        offer: offerModel,
                        userData: userData,
                        workerId: service.workerId,
                        offers: offers
                            .map((o) => OfferModel(
                          id: o.id,
                          serviceId: o.serviceId,
                          workerId: o.workerId,
                          offeredPrice: o.offeredPrice,
                          status: o.status.id,
                          subcategoryName: o.subcategoryName,
                          expertises: o.expertises
                              .map((e) =>
                              Expertise(id: e.id, name: e.name))
                              .toList(),
                          clientNIT: '',
                          extraCosts: o.extraCosts,
                          totalPrice: o.totalPrice,
                          paymentStatus: '',

                        ))
                            .toList(),
                        apiService: apiService,
                        apiService2: apiService2,
                        userId: service.userId,
                      );
                      return prov;
                    },
                    child: ServiceFormWithTimelineSocio(
                      serviceRequest: serviceModel,
                      offer: offerModel,
                      userData: userData,
                      workerId: service.workerId,
                      offers: offers
                          .map((o) => OfferModel(
                        id: o.id,
                        serviceId: o.serviceId,
                        workerId: o.workerId,
                        offeredPrice: o.offeredPrice,
                        status: o.status.id,
                        subcategoryName: o.subcategoryName,
                        expertises: o.expertises
                            .map((e) =>
                            Expertise(id: e.id, name: e.name))
                            .toList(),
                        clientNIT: '',
                        extraCosts: o.extraCosts,
                        totalPrice: o.totalPrice,
                        paymentStatus: '',

                      ))
                          .toList(),
                      apiService: apiService,
                      apiService2: apiService2,
                      userId: service.userId,
                      displayName: userData.displayName,
                    ),
                  ),
                ),
              );
            },
            child: _buildOfferCard(service, offer, screenWidth, screenHeight),
          );
        },
      ),
    );
  }

  static Widget _buildOfferCard(
      ServiceRequest service, Offer offer,
      double screenWidth, double screenHeight) {
    return Container(
      margin: EdgeInsets.only(bottom: screenHeight * 0.02),
      width: screenWidth,
      height: screenHeight * 0.24,
      child: CustomPaint(
        size: Size(screenWidth, screenHeight * 0.35),
        painter: CustomTicketShapePainter(status: service.status),
        child: _buildCardContent(
            service.subcategoryName,
            service.expertises.map((e) => e.name).join(', '),
            offer.offeredPrice,
            screenHeight),
      ),
    );
  }

  static Widget _buildServiceCard(
      ServiceRequest service, double screenWidth, double screenHeight) {
    return Stack(
      children: [
        Container(
          margin: EdgeInsets.only(bottom: screenHeight * 0.02),
          width: screenWidth,
          height: screenHeight * 0.24,
          child: CustomPaint(
            size: Size(screenWidth, screenHeight * 0.35),
            painter: CustomTicketShapePainter(status: service.status),
            child: _buildCardContent(
                service.subcategoryName,
                service.expertises.map((e) => e.name).join(', '),
                service.offeredPrice,
                screenHeight),
          ),
        ),
        if (service.isNew == true)
          Positioned(
            top: 10,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.shade700,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Text(
                'Nuevo',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
      ],
    );
  }

  static Widget _buildCardContent(
      String category, String expertise, double price, double screenHeight) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // El contenido textual ahora es flexible y responsive
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 20),
                Text('Categoría:', style: MyTextStyles.drawerButtonTextStyle),
                Text(
                  category,
                  style: MyTextStyles.drawerButtonTextStyle8,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: screenHeight * 0.01),
                Text('Servicio:', style: MyTextStyles.drawerButtonTextStyle),
                Text(
                  expertise,
                  style: MyTextStyles.drawerButtonTextStyle8,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: screenHeight * 0.01),
                Text(
                  'Precio Ofertado: \Bs ${price.toStringAsFixed(2)}',
                  style: MyTextStyles.drawerButtonTextStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Imagen ajustada y alineada
          Align(
            alignment: Alignment.bottomLeft,
            child: Image.asset(
              'assets/manito.png',
              width: screenHeight * 0.07, // Responsive
              height: screenHeight * 0.07,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}