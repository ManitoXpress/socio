import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../models/conversation_model.dart';
import '../provider/conversations_provider.dart';
import '../ServiceResponse/get.dart';
import 'chat_screen.dart';

class ConversationsInbox extends StatefulWidget {
  final String serviceId;

  const ConversationsInbox({Key? key, required this.serviceId})
      : super(key: key);

  @override
  _ConversationsInboxState createState() => _ConversationsInboxState();
}

class _ConversationsInboxState extends State<ConversationsInbox> {
  late ConversationsProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = ConversationsProvider(
      serviceId: widget.serviceId,
      apiService2: ApiService2(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F7),
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.white.withOpacity(0.85),
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon:
                const Icon(Icons.arrow_back_ios_new, color: Color(0xFF830A09)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'Mensajes',
            style: GoogleFonts.poppins(
              color: const Color(0xFF830A09),
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              height: 1,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Color(0xFF830A09),
                    Colors.transparent
                  ],
                ),
              ),
            ),
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF5F5F7), Color(0xFFEEE8E8)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Consumer<ConversationsProvider>(
            builder: (context, provider, child) {
              return StreamBuilder<List<ConversationModel>>(
                stream: provider.inboxStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFF830A09)),
                    );
                  }

                  if (snapshot.hasError) {
                    return _buildErrorState(snapshot.error.toString());
                  }

                  final conversations = snapshot.data ?? [];

                  if (conversations.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.builder(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top +
                          kToolbarHeight +
                          16,
                      left: 16,
                      right: 16,
                      bottom: 16,
                    ),
                    itemCount: conversations.length,
                    itemBuilder: (context, index) {
                      final conv = conversations[index];
                      return _buildConversationCard(context, conv, provider);
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    // Mensaje amigable sin mostrar el error técnico completo
    final isPermission =
        error.contains('permission') || error.contains('PERMISSION');
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFF830A09).withOpacity(0.15),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFF830A09).withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.chat_bubble_outline_rounded,
                      color: Color(0xFF830A09),
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    isPermission
                        ? 'Sin conversaciones aún'
                        : 'No se pudieron cargar\nlos mensajes',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isPermission
                        ? 'Cuando el cliente inicie una conversación contigo, aparecerá aquí.'
                        : 'Verifica tu conexión a internet e intenta de nuevo.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Color(0xFF830A09).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              size: 40,
              color: Color(0xFF830A09),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Sin mensajes',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No tienes mensajes para este servicio.',
            style: GoogleFonts.poppins(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationCard(BuildContext context, ConversationModel conv,
      ConversationsProvider provider) {
    final hasUnread = conv.unreadWorker > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                if (hasUnread) {
                  provider.markAsRead(conv.id);
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      conversation: conv,
                      provider: provider,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: const Color(0xFF830A09).withOpacity(0.1),
                      child: Text(
                        conv.clientName.isNotEmpty
                            ? conv.clientName[0].toUpperCase()
                            : 'C',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF830A09),
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  conv.clientName, // UI tweak here
                                  style: GoogleFonts.poppins(
                                    fontWeight: hasUnread
                                        ? FontWeight.bold
                                        : FontWeight.w600,
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (conv.lastAt != null)
                                Text(
                                  timeago.format(conv.lastAt!, locale: 'es'),
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: hasUnread
                                        ? const Color(0xFF830A09)
                                        : Colors.grey[500],
                                    fontWeight: hasUnread
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  conv.lastMessage.isNotEmpty
                                      ? conv.lastMessage
                                      : 'Comienza a chatear',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: hasUnread
                                        ? Colors.black87
                                        : Colors.grey[600],
                                    fontWeight: hasUnread
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (hasUnread)
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Colors.redAccent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    conv.unreadWorker
                                        .toString(), // UI tweak here
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
