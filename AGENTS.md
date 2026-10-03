# Instrucciones del repositorio

Esta aplicación Flutter ayuda a preparar el examen para obtener una licencia de conducir del MTC del Perú. Consulta [README.md](README.md) para conocer el producto y la configuración; verifica las funcionalidades recientes en `lib/`, ya que el inventario de arquitectura del README podría no estar actualizado.

## Estructura del proyecto

- `lib/models/`: modelos tipados de la aplicación y de la API.
- `lib/providers/`: estado con Riverpod y coordinación del acceso asíncrono a datos.
- `lib/services/`: operaciones HTTP, acceso a la API y almacenamiento local.
- `lib/screens/`: rutas y composición de pantallas.
- `lib/widgets/`, `lib/theme/`, `lib/utils/`: interfaz reutilizable, tokens de diseño y utilidades.

Respeta estos límites: las pantallas y los widgets presentan el estado y despachan acciones; los providers coordinan el estado; los servicios se encargan de la API y la persistencia. Antes de introducir una abstracción o dependencia, sigue el patrón de funcionalidad existente más parecido. Conserva los payloads de los endpoints y el comportamiento de autenticación y sesión, salvo que la tarea solicite cambiar esos contratos explícitamente.

## Convenciones de Flutter

- Usa los patrones existentes de Riverpod (`ref.watch` para el estado mostrado y `ref.read` para las acciones), además del tema y los tokens de Material 3 en `lib/theme/app_theme.dart`.
- Reutiliza los botones y widgets compartidos para estados de carga, error y vacío en `lib/widgets/` cuando corresponda.
- Mantén finitas las restricciones de diseño. En particular, no uses `Size.fromHeight(...)` como `minimumSize` del tema de botones: su ancho infinito puede romper botones dentro de `Row` y de las acciones de diálogos. Comprueba los estilos compartidos tanto en contenedores con ancho restringido como no restringido.
- Configura las URL de la API en el `.env` local (`API_URL`) y utiliza el flujo existente para almacenar y gestionar los tokens de sesión. Nunca incluyas secretos en el repositorio ni registres credenciales en logs.

## Verificación

Ejecuta estos comandos desde la raíz del repositorio:

```bash
flutter pub get
flutter analyze
flutter test
```

Mientras iteras, ejecuta la prueba más específica que corresponda; para cambios más amplios, ejecuta toda la suite. Usa `flutter run` para iniciar la aplicación. Las funcionalidades que usan la API local requieren configurar `.env` según se describe en [README.md](README.md).
