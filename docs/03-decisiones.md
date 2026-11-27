# Decisiones del proyecto

| Decisión | Alternativas | Por qué |
|----------|--------------|---------|
| Plataformas: Android y Windows | Solo Android; también iOS/web | Lo pidió Ramiro para uso en casa. |
| Compilar en GitHub Actions | Compilar en el entorno de trabajo o en la PC | En el entorno están bloqueados `storage.googleapis.com`, `dl.google.com`, `pub.dev` y `maven.google.com`; no se puede bajar Flutter ni Android SDK. |
| Uso personal/familiar, sin Google Play | Publicar en Play Store | No hace falta para la familia; queda fuera de v1. |
| Fuera de v1: multijugador en línea y cuentas | Incluirlos | Agregan servidor y mucho trabajo; el juego ya tiene multijugador local. |
| Flutter 3.50.x (stable) | Otros frameworks | Un solo código para Android y Windows. |
| flutter_inappwebview 6.1.5 (+ flutter_inappwebview_windows 0.6.0 con WebView2) | webview_flutter 4.14.1; webview_flutter + webview_windows 0.4.0 | webview_flutter no soporta Windows; combinarlo con webview_windows daría dos APIs distintas y webview_windows no se mantiene desde feb-2024. |
| Cargar el juego con `loadFile(assetFilePath:'assets/web/index.html')` | Cargarlo desde internet | Debe funcionar sin internet. |
| Sin backend (todo local) | Servidor propio | No hay cuentas ni juego en línea en v1. |
| Pantalla completa con `SystemChrome` `immersiveSticky` | Librería externa | Ya viene en Flutter. |
| wakelock_plus 1.8.2 | No usar nada | Que la pantalla no se apague jugando. |
| vibration 3.2.1 con puente `navigator.vibrate` → `callHandler('vibrar')` | Sin vibración | El plan pide vibración y el WebView no siempre la soporta. |
| flutter_launcher_icons 0.14.4 (dev) | Hacer iconos a mano | Genera todos los tamaños automáticamente. |
| Fuentes Bungee y Rubik empaquetadas (OFL, incluir `OFL.txt`) | Cargarlas de Google Fonts | Sin internet no cargarían; la licencia OFL pide incluir su texto. |
| CI: `subosito/flutter-action@v2` (v2.23.0); ubuntu-latest + Java 17 para APK; windows-latest para EXE en zip | Instalar Flutter a mano en el CI | Acción conocida y sencilla. |
| Datos: localStorage + respaldo en shared_preferences 2.5.6 por canal JS (claves `arc_`, guardado con retraso 1-2 s, migración inicial) | Solo localStorage; SQLite/sqflite | Solo localStorage se puede perder si cambia el origen/URL; SQLite es exceso para ~13 claves. |
| Firma: "Sin llave por ahora" (firma debug) | Crear llave de firma propia | Decisión de Ramiro. Riesgo aceptado: cada actualización obliga a desinstalar y se pierden récords. Se puede agregar llave después. |
| Si flutter_inappwebview falla, probar 6.2.0-beta | Cambiar de librería | La versión estable lleva ~2 años sin actualización nueva. |
| No guardar `android/` ni `windows/` en git; generarlas en CI con `flutter create --platforms=android\|windows --project-name arcade_de_bolsillo --org com.ramiro .` | Generarlas aquí y subirlas | En el entorno de trabajo no se puede descargar Flutter, así que no se pueden generar. |
| Ajustes de plataforma con `tool/parchar_plataformas.py` (nombre "Arcade de bolsillo", permiso VIBRATE, minSdk 24, título de ventana, ventana maximizada) | Editar a mano después de cada `flutter create` | Las carpetas se crean nuevas en cada compilación; el script repite los cambios igual siempre y se puede correr varias veces. |
| minSdk 24 (Android 7.0 o más nuevo) | Usar el mínimo que trae Flutter | Mínimo fijo y conocido para la app y los iconos. |
| Fuentes Bungee y Rubik descargadas de `github.com/google/fonts` | Descargarlas de Google Fonts | `fonts.googleapis.com` no sirve sin internet y GitHub sí se pudo usar. |
| Iconos dibujados con código (`tool/generar_icono.py`, Pillow) | Diseñarlos a mano / imagen de internet | Se pueden regenerar igual siempre y no hay problemas de derechos. |
| Iconos de Windows con archivo aparte `tool/iconos_windows.yaml` | Usar solo la config de `pubspec.yaml` | En el trabajo de Windows no existe `android/` y la config de Android fallaría. |
| Debounce de 1.5 s y validación (claves ≤ 64, valores ≤ 20000, máximo 200 claves) en `lib/puente_progreso.dart` | Guardar en cada cambio sin límites | Menos escrituras en disco y protección contra datos raros o enormes. |
| Botón atrás de Android: vuelve al menú; en el menú cierra la app | Cerrar siempre la app | Más natural para los niños; no se sale del juego sin querer. |
| Workflow con 3 trabajos: `android`, `windows` y `release` (solo con etiqueta `v*`) | Un solo trabajo | Android necesita Linux y Windows necesita Windows; el Release solo se publica cuando se pide con una etiqueta. |
| Corregir XSS guardado en `renderMenu` con `Number(...)\|\|0` (y también en `finish()` y Asedio) | Dejarlo (es uso familiar) | Corrección pequeña que evita meter texto como HTML. |
| Fijar las 6 acciones de GitHub por SHA + `persist-credentials: false` | Usar etiquetas como `@v4` | Una etiqueta se puede mover; el SHA no. |
| Subir `pubspec.lock` como artefacto `pubspec-lock` para fijarlo luego en el repo | No fijar versiones | No se puede generar aquí sin Flutter; se obtiene de la primera compilación. Pendiente. |
| Lista blanca de navegación: solo `file` y `about` (se quitó `data` en la 2.ª auditoría) | Permitir cualquier dirección | El juego es local; no necesita abrir nada de fuera. |
| Pausa mínima de 80 ms entre vibraciones | Sin límite | Evita vibración continua. |
| `SHA256SUMS.txt` en cada Release | Sin huellas | Permite comprobar que el archivo descargado es el original. |
| NO aplicar por ahora: `allowFileAccess: false`, escape U+2028/2029, lista de orígenes para handlers | Aplicarlas ya | Hay que probar fuentes primero; riesgo mínimo; esperar `flutter_inappwebview` 6.2 estable. |
| Nunca instalar `flutter_inappwebview` desde npm | — | En npm hay un paquete malicioso con ese nombre (MAL-2025-189). Solo pub.dev vía `flutter pub get`. |
| Repositorio `therrami15rs/arcade-de-bolsillo` lo crea Ramiro en github.com/new | Que lo cree el agente | El entorno no tiene permiso para crear repositorios. |
