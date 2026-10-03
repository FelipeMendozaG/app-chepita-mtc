# Instrucciones para agentes de IA

## Tech Stack & Flutter Version

- `pubspec.yaml` requiere Dart SDK `^3.11.4`. No fija una versión concreta de Flutter.
- Estado: `flutter_riverpod ^2.6.1` con `Provider`, `FutureProvider`, `StateNotifierProvider` y `AsyncValue`; `setState` se usa para estado local de widgets.
- Red: `http ^1.2.2`. Navegación: `Navigator` y `MaterialApp` de Flutter; no hay router externo.
- Persistencia: `shared_preferences ^2.3.3`. Configuración: `flutter_dotenv ^5.1.0`. No se detectó un contenedor DI independiente.
- No hay `build_runner`, `freezed` ni `json_serializable` configurados.

## Architecture & Directory Structure

La app usa una organización por capas dentro de `lib/`, no Clean Architecture con capas `domain/data` ni repositorios explícitos.

- `main.dart`: carga `.env`, configura `ProviderScope`, `MaterialApp` y `AuthGate`.
- `models/`: modelos de datos y conversión de respuestas JSON.
- `providers/`: estado y coordinación asíncrona con Riverpod.
- `services/`: clientes HTTP, operaciones de API y persistencia de sesión.
- `screens/`: pantallas, navegación y composición de la interfaz.
- `widgets/`: componentes reutilizables; `theme/` centraliza tema/tokens y `utils/` contiene utilidades.
- `android/` y `ios/`: proyectos anfitriones nativos de Flutter. No alteres sus archivos de plataforma salvo petición explícita.

Flujo habitual: pantalla/widget -> provider -> service -> API o almacenamiento; las respuestas se convierten en modelos y vuelven al estado de Riverpod.

## Dart & Flutter Coding Standards

- Usa constructores `const` para widgets siempre que sea posible; sigue `analysis_options.yaml` y `flutter_lints`.
- Prefiere modelos inmutables con campos `final`; no agregues generación de código sin que la tarea lo requiera.
- Maneja operaciones asíncronas explícitamente con `async`/`await` y representa carga, éxito y error con los patrones existentes (`AsyncValue` donde aplique).
- Mantén la lógica de negocio y las llamadas HTTP fuera de `build`; usa providers y services existentes.
- Reutiliza el tema y los widgets compartidos, y conserva los contratos de API y sesión.

## Execution, CodeGen & Test Commands

```bash
flutter pub get
flutter run
flutter test
flutter analyze
```

No hay codegen configurado actualmente. Si una tarea incorpora explícitamente `build_runner`, `freezed` o `json_serializable`, genera los archivos con `dart run build_runner build --delete-conflicting-outputs`.

## Critical Rules & Guardrails for AI

- Consulta antes de añadir o actualizar dependencias en `pubspec.yaml`.
- No edites a mano archivos generados (`*.g.dart`, `*.freezed.dart`); regénéralos con la herramienta correspondiente si el proyecto llega a usarlos.
- No modifiques Gradle, Podfile, `Info.plist`, `AndroidManifest.xml` ni otras configuraciones nativas salvo solicitud explícita.
- Usa `API_URL` para la URL configurada en `.env`. No leas ni compartas `.env`, tokens o credenciales; trabaja con `.env.example`.
- Evita dependencias o capas arquitectónicas nuevas si el patrón existente resuelve la tarea.