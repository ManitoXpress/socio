import 'package:firebase_remote_config/firebase_remote_config.dart';

/// Servicio singleton para leer parámetros desde Firebase Remote Config.
///
/// Inicializar en main.dart DESPUÉS de Firebase.initializeApp():
///   await RemoteConfigService().initialize();
class RemoteConfigService {
  // ── Singleton ──────────────────────────────────────────────────────────────
  static final RemoteConfigService _instance = RemoteConfigService._internal();
  factory RemoteConfigService() => _instance;
  RemoteConfigService._internal();

  final FirebaseRemoteConfig _rc = FirebaseRemoteConfig.instance;

  // ── Claves (deben coincidir exactamente con Firebase Console) ──────────────
  // Switch propio de la app Socio → no afecta a la app Cliente
  static const String _keyEnabled = 'socio_maintenance_enabled';
  // Textos compartidos entre ambas apps (mismo mensaje de mantenimiento)
  static const String _keyTitle   = 'maintenance_title';
  static const String _keyBody1   = 'maintenance_body1';
  static const String _keyBody2   = 'maintenance_body2';
  static const String _keyFooter  = 'maintenance_footer';
  static const String _keyBadge   = 'maintenance_badge';
  static const String _keyButton  = 'maintenance_button';

  // ── Valores por defecto (si no hay conexión) ───────────────────────────────
  static const Map<String, dynamic> _defaults = {
    _keyEnabled: false,  // socio_maintenance_enabled
    _keyTitle:   'Aviso importante',
    _keyBody1:
        'Estimado usuario, estamos realizando trabajos de mantenimiento y '
        'actualización para mejorar su experiencia.',
    _keyBody2:   'La aplicación estará temporalmente fuera de servicio.',
    _keyFooter:  'Agradecemos su comprensión.',
    _keyBadge:   'En mantenimiento',
    _keyButton:  'Entendido',
  };

  /// Llama esto una sola vez en main(), después de Firebase.initializeApp().
  Future<void> initialize() async {
    await _rc.setDefaults(_defaults);
    await _rc.setConfigSettings(RemoteConfigSettings(
      fetchTimeout:          const Duration(seconds: 10),
      minimumFetchInterval:  const Duration(hours: 1),
    ));
    // Ignora errores de red: si falla, se usan los defaults.
    try {
      await _rc.fetchAndActivate();
    } catch (_) {}
  }

  // ── Getters ────────────────────────────────────────────────────────────────
  bool   get maintenanceEnabled => _rc.getBool(_keyEnabled);
  String get maintenanceTitle   => _rc.getString(_keyTitle);
  String get maintenanceBody1   => _rc.getString(_keyBody1);
  String get maintenanceBody2   => _rc.getString(_keyBody2);
  String get maintenanceFooter  => _rc.getString(_keyFooter);
  String get maintenanceBadge   => _rc.getString(_keyBadge);
  String get maintenanceButton  => _rc.getString(_keyButton);
}
