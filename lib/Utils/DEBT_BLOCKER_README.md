# Sistema de Bloqueo por Deudas - ManitosXpress

## Descripción General

El sistema de bloqueo por deudas es una funcionalidad que controla el acceso a la aplicación basándose en las deudas pendientes del usuario. El sistema funciona de la siguiente manera:

1. **Monitoreo Continuo**: Verifica constantemente si el usuario tiene deudas pendientes
2. **Advertencia**: Si tiene deudas con `paymentStatus` "debe" pero NO han vencido (menos de 3 días), muestra una advertencia
3. **Bloqueo**: Si han pasado 3 días DESDE `createdAt` Y el `paymentStatus` es "debe", bloquea completamente la aplicación
4. **Desbloqueo**: Solo se desbloquea cuando todas las deudas están pagadas (paymentStatus = "pagado")

## Criterios de Bloqueo

El sistema bloquea la aplicación cuando:

1. **Por tiempo Y estado**: Han pasado más de 3 días desde `createdAt` Y el `paymentStatus` del servicio es "debe"
2. **NO bloquea** si solo han pasado 3 días pero el `paymentStatus` NO es "debe"
3. **NO bloquea** si el `paymentStatus` es "debe" pero NO han pasado 3 días (solo muestra advertencia)

La aplicación se desbloquea automáticamente cuando:
- El `paymentStatus` cambia a "pagado"

## Componentes del Sistema

### 1. DebtBlockerService (`lib/Utils/debt_blocker_service.dart`)
Servicio principal que maneja toda la lógica de deudas:

- **getTotalDebt()**: Calcula el total de deudas pendientes
- **shouldShowDebtWarning()**: Verifica si debe mostrar advertencia (paymentStatus "debe" pero no vencidas)
- **shouldBlockApp()**: Verifica si debe bloquear la aplicación (3 días + paymentStatus "debe")
- **getDaysUntilBlock()**: Obtiene días restantes antes del bloqueo
- **startDebtMonitoring()**: Inicia el monitoreo continuo
- **getDebtDetailsForWhatsApp()**: Obtiene detalles para enviar por WhatsApp

### 2. DebtBlockerWrapper (`lib/Utils/debt_blocker_wrapper.dart`)
Widget wrapper que envuelve la aplicación y maneja el estado de bloqueo:

- Monitorea el estado de deudas
- Muestra pantallas de advertencia o bloqueo según corresponda
- Se integra automáticamente en el flujo de la aplicación

### 3. DebtWarningScreen (`lib/Screens/debt_warning_screen.dart`)
Pantalla de advertencia que se muestra cuando el usuario tiene deudas con `paymentStatus` "debe" pero no han vencido:

- Muestra el monto total adeudado
- Indica los días restantes para pagar
- Muestra el `paymentStatus` de cada deuda
- Botón para enviar detalles por WhatsApp
- Botón para continuar (no bloquea completamente)

### 4. DebtBlockScreen (`lib/Screens/debt_block_screen.dart`)
Pantalla de bloqueo que se muestra cuando han pasado 3 días Y el `paymentStatus` es "debe":

- Bloquea completamente el acceso a la aplicación
- Muestra el monto total adeudado
- Muestra el `paymentStatus` de cada deuda
- Botón para pagar deuda por WhatsApp
- Botón para contactar soporte

## Flujo de Funcionamiento

### 1. Verificación Inicial
```dart
// Al iniciar la aplicación
final shouldShowWarning = await _debtService.shouldShowDebtWarning();
if (shouldShowWarning) {
  // Mostrar pantalla de advertencia (paymentStatus "debe" pero no vencidas)
}
```

### 2. Monitoreo Continuo
```dart
// Cada 5 minutos verifica el estado
_debtService.startDebtMonitoring();
_debtService.blockStateStream.listen((isBlocked) {
  if (isBlocked) {
    // Mostrar pantalla de bloqueo (3 días + paymentStatus "debe")
  }
});
```

### 3. Cálculo de Deudas
```dart
// Suma todas las comisiones y costos extras de servicios completados no pagados
final adeudado = offers.where((doc) {
  final status = doc.data()['status']?.toString().trim().toLowerCase();
  final paymentStatus = doc.data()['paymentStatus']?.toString().trim().toLowerCase();
  return status == 'completed' && paymentStatus != 'pagado';
}).fold<double>(0.0, (sum, doc) {
  final commission = doc.data()['commission'] ?? 0.0;
  final extraCosts = doc.data()['extraCosts'] ?? 0.0;
  return sum + commission + extraCosts;
});
```

### 4. NUEVA Lógica de Bloqueo
```dart
// Verifica si debe bloquear por tiempo Y paymentStatus
final shouldBlockByStatus = paymentStatus == 'debe';
final shouldBlockByTime = isOverdue && shouldBlockByStatus;
final shouldShowWarning = shouldBlockByStatus && !isOverdue;

// Solo bloquear si han pasado 3 días Y paymentStatus es "debe"
final shouldBlock = shouldBlockByTime;

// Mostrar advertencia si paymentStatus es "debe" pero no han vencido
final shouldShowWarning = shouldShowWarning;
```

## Integración en la Aplicación

### En main.dart
```dart
home: isLoading
    ? LoadingScreen()
    : isLoggedIn
        ? DebtBlockerWrapper(
            child: HomeScreen(
              userData: userData!, 
              registrationData: registrationData!
            ),
          )
        : LoginScreen(deviceId: widget.deviceId),
```

### Persistencia de Datos
El sistema usa `SharedPreferences` para almacenar:
- `debt_warning_shown`: Si ya se mostró la advertencia (para guardar fecha inicial)
- `debt_warning_date`: Fecha cuando se mostró la primera advertencia (para calcular 3 días)
- `debt_block_date`: Fecha cuando se bloqueó la aplicación

## Estados de PaymentStatus

### "pagado"
- ✅ No bloquea la aplicación
- ✅ Permite acceso normal
- ✅ No aparece en listas de deudas

### "debe" 
- ⚠️ Si NO han pasado 3 días: Muestra advertencia, permite usar la app
- ❌ Si han pasado 3 días: Bloquea la aplicación inmediatamente
- ❌ Requiere pago para desbloquear

### Otros estados (null, vacío, etc.)
- ⚠️ Se trata como "debe" (sigue la misma lógica)
- ⚠️ Requiere pago para desbloquear

## Configuración

### Días de Vencimiento
```dart
static const int _overdueDays = 3; // 3 días para producción
```

### Frecuencia de Monitoreo
```dart
Timer.periodic(const Duration(minutes: 5), (timer) async {
  // Verificación cada 5 minutos
});
```

### Número de WhatsApp para Pagos
```dart
const phoneNumber = '+59173666393'; // En las pantallas de deuda
```

## Mensajes de WhatsApp

### Advertencia de Deuda
```
Hola, tengo deudas pendientes y necesito realizar el pago:

Servicios: [lista de servicios]
Total de deudas: [número]
Detalle:
• [servicio]: Bs[total]
Total a pagar: Bs[total]

Por favor, envíame el código QR para realizar el pago.
```

### Bloqueo por Deuda
```
Hola, mi cuenta está bloqueada por deudas pendientes y necesito realizar el pago urgentemente:

Servicios: [lista de servicios]
Total de deudas: [número]
Detalle:
• [servicio]: Bs[total]
Total a pagar: Bs[total]

Por favor, envíame el código QR para realizar el pago y desbloquear mi cuenta.
```

## Casos de Uso

### 1. Usuario sin Deudas
- No se muestra ninguna pantalla especial
- Acceso normal a la aplicación

### 2. Usuario con Deudas (paymentStatus "debe" pero NO han vencido)
- Se muestra pantalla de advertencia **cada vez que inicia la app**
- Tiene **3 días** para pagar desde `createdAt`
- Puede continuar usando la aplicación normalmente

### 3. Usuario con Deudas (Han pasado 3 días Y paymentStatus "debe")
- Se bloquea completamente la aplicación
- Solo puede pagar la deuda
- No puede acceder a ningún servicio

### 4. Usuario con Deudas (Han pasado 3 días pero paymentStatus NO es "debe")
- NO se bloquea la aplicación
- Acceso normal a la aplicación
- No se muestran advertencias

### 5. Usuario que Paga sus Deudas (paymentStatus = "pagado")
- Se resetea automáticamente el estado
- Vuelve al acceso normal
- Se eliminan las fechas de advertencia/bloqueo

## Consideraciones Técnicas

### Rendimiento
- Monitoreo cada 5 minutos para no sobrecargar
- Uso de StreamController para actualizaciones en tiempo real
- Persistencia local para evitar verificaciones innecesarias

### Seguridad
- Verificación en el servidor (Firestore)
- No se puede evadir el bloqueo modificando datos locales
- Integración con el sistema de autenticación existente

### Experiencia de Usuario
- Mensajes claros y específicos
- Botones de acción directa (WhatsApp)
- Información detallada de deudas
- Opción de contactar soporte

## Mantenimiento

### Agregar Nuevos Tipos de Deuda
Modificar el método `getTotalDebt()` en `DebtBlockerService`:

```dart
// Agregar nuevos campos de deuda
final newDebt = (data['newDebtField'] ?? 0.0) as num;
totalDebt += newDebt;
```

### Cambiar Período de Vencimiento
Modificar la constante en `DebtBlockerService`:

```dart
static const int _overdueDays = 3; // 3 días para producción
```

### Cambiar Frecuencia de Monitoreo
Modificar en `DebtBlockerService`:

```dart
Timer.periodic(const Duration(minutes: 10), (timer) async {
  // Cambiar de 5 a 10 minutos
});
```

## Cambios Recientes

### Nueva Lógica de Bloqueo (v2.0)
- **Bloqueo**: Solo si han pasado 3 días Y paymentStatus es "debe"
- **Advertencia**: Solo si paymentStatus es "debe" pero NO han vencido
- **Acceso normal**: Si paymentStatus NO es "debe" o si han pasado 3 días pero paymentStatus NO es "debe"

### Campos Nuevos en las Deudas
- `shouldBlockByTime`: true si han pasado 3 días Y paymentStatus es "debe"
- `shouldShowWarning`: true si paymentStatus es "debe" pero NO han vencido
- `shouldBlockByStatus`: true si paymentStatus es "debe" (sin importar tiempo) 