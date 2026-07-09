import 'dart:ui';
import 'package:flutter/material.dart';

/// Diálogo de aviso de mantenimiento con glassmorphism y animaciones.
///
/// Uso:
///   showDialog(
///     context: context,
///     barrierDismissible: true,
///     barrierColor: Colors.black.withOpacity(0.45),
///     builder: (_) => MaintenanceDialog(
///       primaryColor  : const Color(0xFF830A09),
///       darkTextColor : const Color(0xFF3A0505),
///       title         : 'Aviso importante',
///       body1         : '…',
///       body2         : '…',
///       footer        : 'Agradecemos su comprensión.',
///       badge         : 'En mantenimiento',
///       buttonLabel   : 'Entendido',
///     ),
///   );
class MaintenanceDialog extends StatefulWidget {
  /// Color principal de la app socio (rojo oscuro)
  final Color primaryColor;

  /// Color de texto oscuro
  final Color darkTextColor;

  final String title;
  final String body1;
  final String body2;
  final String footer;
  final String badge;
  final String buttonLabel;

  const MaintenanceDialog({
    super.key,
    required this.primaryColor,
    required this.darkTextColor,
    required this.title,
    required this.body1,
    required this.body2,
    required this.footer,
    required this.badge,
    required this.buttonLabel,
  });

  @override
  State<MaintenanceDialog> createState() => _MaintenanceDialogState();
}

class _MaintenanceDialogState extends State<MaintenanceDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double>  _fadeAnim;
  late Animation<double>  _scaleAnim;
  late Animation<Offset>  _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scaleAnim = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: ScaleTransition(
          scale: _scaleAnim,
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.82),
                        Colors.white.withOpacity(0.65),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.6),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.primaryColor.withOpacity(0.18),
                        blurRadius: 32,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── Ícono circular ─────────────────────────────────
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(colors: [
                            widget.primaryColor.withOpacity(0.15),
                            widget.primaryColor.withOpacity(0.05),
                          ]),
                          border: Border.all(
                            color: widget.primaryColor.withOpacity(0.25),
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          Icons.construction_rounded,
                          size: 36,
                          color: widget.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Badge de estado ────────────────────────────────
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          color: widget.primaryColor.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: widget.primaryColor.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: widget.primaryColor,
                              ),
                            ),
                            const SizedBox(width: 7),
                            Text(
                              widget.badge,
                              style: TextStyle(
                                color: widget.primaryColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // ── Título ─────────────────────────────────────────
                      Text(
                        widget.title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: widget.darkTextColor,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ── Divisor degradado ──────────────────────────────
                      Container(
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                            Colors.transparent,
                            widget.primaryColor.withOpacity(0.25),
                            Colors.transparent,
                          ]),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // ── Cuerpo ─────────────────────────────────────────
                      Text(
                        widget.body1,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: widget.darkTextColor.withOpacity(0.85),
                          fontSize: 14.5,
                          height: 1.55,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.body2,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: widget.darkTextColor.withOpacity(0.7),
                          fontSize: 13.5,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.footer,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: widget.primaryColor,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ── Botón ──────────────────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding:
                                const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            widget.buttonLabel,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
