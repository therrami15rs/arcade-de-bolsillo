# Bitácora del proyecto

Aquí se anota, en orden, lo que hizo cada agente (cada "ayudante" del equipo). Sirve para saber qué se hizo, por qué y qué falta.

---

## [2026-11-26 20:30] — Agente: Director

**Qué se le pidió:** Ramiro pidió: "Crea la app para estos juegos". Es decir, convertir en app instalable el "Arcade de bolsillo", un juego web hecho en un solo archivo HTML con 10 juegos (Asedio de Castillos con 20 niveles y multijugador local 2-4, Enjambre, Bloque Cósmico, Imperio de Fusión, Mazmorra de Cartas, Último Bastión, Torre Infinita, Serpiente, 2048, Vuelo del Búho). Usa canvas 2D, Web Audio sintetizado y localStorage.

**Qué decidió y por qué:**
- Preguntó a Ramiro y obtuvo estas respuestas:
  - Plataformas: **Android y Windows**.
  - Compilar con **GitHub Actions**, porque en el entorno de trabajo están bloqueados `storage.googleapis.com`, `dl.google.com`, `pub.dev` y `maven.google.com`, y así no se puede descargar Flutter ni el Android SDK.
  - Uso **solo personal/familiar**, sin Google Play.
- Plan aprobado (v1): 1) jugar sin internet, 2) pantalla completa y Asedio en horizontal, 3) guardar récords/monedas/niveles, 4) sonido/música/vibración, 5) icono y nombre propios, 6) GitHub Actions genera `.apk` y `.exe`.
- Opciones descartadas para v1: Play Store, multijugador en línea, cuentas de usuario (no hacen falta para uso familiar y agregan mucho trabajo).

**Archivos creados o cambiados:** Ninguno (solo planeación).

**Comandos ejecutados:** Ninguno.

**Versiones usadas:** No aplica.

**Resultado:** Plan aprobado. Repositorio privado definido: `arcade-de-bolsillo`.

**Pendiente:** Que el Arquitecto y el agente de Base de datos elijan las herramientas.

---

## [2026-11-26 20:30] — Agente: Arquitecto

**Qué se le pidió:** Elegir con qué herramientas se construye la app para Android y Windows, y cómo se compila en GitHub Actions.

**Qué decidió y por qué:**
- **Flutter** (canal stable, 3.50.x) con **flutter_inappwebview 6.1.5** para mostrar el HTML del juego dentro de la app. En Windows usa **WebView2** mediante **flutter_inappwebview_windows 0.6.0**. El juego se carga con `loadFile(assetFilePath: 'assets/web/index.html')`.
  - Por qué: una sola librería y una sola forma de programar para las dos plataformas.
- **Sin backend** (sin servidor): todo es local.
- Extras:
  - `SystemChrome` en modo `immersiveSticky` (pantalla completa).
  - `wakelock_plus 1.8.2` (que no se apague la pantalla).
  - `vibration 3.2.1`, con un puente: `navigator.vibrate` del juego → `callHandler('vibrar')` → Flutter vibra.
  - `flutter_launcher_icons 0.14.4` (solo desarrollo) para el icono.
  - Fuentes **Bungee** y **Rubik** empaquetadas (licencia OFL, incluir `OFL.txt`).
- CI (*integración continua*: compilación automática en GitHub Actions):
  - Acción `subosito/flutter-action@v2` (v2.23.0), `channel: stable`, Flutter 3.50.x.
  - Trabajo en `ubuntu-latest` + Java 17 → `flutter build apk --release`.
  - Trabajo en `windows-latest` → `flutter build windows --release` y se comprime en zip la carpeta `build/windows/x64/runner/Release`.
- Opciones descartadas:
  - `webview_flutter 4.14.1`: no soporta Windows.
  - `webview_flutter` + `webview_windows 0.4.0`: serían dos formas distintas de programar y `webview_windows` no recibe mantenimiento desde febrero de 2024.

**Archivos creados o cambiados:** Ninguno todavía (solo diseño).

**Comandos ejecutados:** Ninguno.

**Versiones usadas:** Flutter 3.50.x stable; flutter_inappwebview 6.1.5; flutter_inappwebview_windows 0.6.0; wakelock_plus 1.8.2; vibration 3.2.1; flutter_launcher_icons 0.14.4; subosito/flutter-action v2.23.0; Java 17.

**Resultado:** Arquitectura definida.

**Pendiente / riesgos anotados:**
- Windows viejos pueden no tener **WebView2 Runtime** instalado.
- En Windows el audio puede no arrancar solo (*autoplay* bloqueado) hasta que el usuario toque algo.
- Rotación automática del teléfono (hay que forzar horizontal en Asedio).
- `flutter_inappwebview` lleva unos 2 años sin versión estable nueva; si falla, probar `6.2.0-beta`.
- La firma *debug* cambia en cada compilación de CI.

---

## [2026-11-26 20:30] — Agente: Base de datos

**Qué se le pidió:** Decidir cómo se guardan récords, monedas, niveles y ajustes.

**Qué decidió y por qué:**
- Usar el **localStorage** del WebView (lo que el juego ya usa) **más un respaldo** en **shared_preferences 2.5.6** de Flutter, comunicados por un canal JavaScript:
  - Un script inyectado (código que la app mete en la página) "envuelve" `localStorage.setItem` para las claves que empiezan con `arc_` y manda `{k, v}` (clave y valor) a Dart (el lenguaje de Flutter).
  - Al iniciar, Dart restaura todas las claves `arc_*` en localStorage.
  - Si Dart no tiene nada guardado, se hace una **migración**: se copian los datos que haya en localStorage.
  - Se guarda con un retraso de 1 a 2 segundos para no escribir a cada rato.
- Opciones descartadas:
  - Solo localStorage: se puede perder si cambia el origen/URL de la página.
  - SQLite / sqflite (base de datos completa): es demasiado para unas ~13 claves.

**Esquema (qué se guarda):**

| Clave | Tipo | Qué es |
|-------|------|--------|
| `arc_coins` | número | Monedas |
| `arc_mute` | sí/no (bool) | Sonido apagado |
| `arc_music` | sí/no (bool) | Música encendida |
| `arc_rec_<juego>` | número | Récord de cada juego: `enjambre`, `bloque`, `fusion`, `cartas`, `bastion`, `torre`, `asedio`, `serpiente`, `n2048`, `vuelo` |
| `arc_fusion` | objeto JSON `{c,m,b,max,t}` | Progreso de Imperio de Fusión |

No se guardan datos personales ni contraseñas.

**Archivos creados o cambiados:** Ninguno todavía (solo diseño).

**Comandos ejecutados:** Ninguno.

**Versiones usadas:** shared_preferences 2.5.6.

**Resultado:** Almacenamiento definido.

**Pendiente:** Implementarlo (agente Frontend/Backend).

---

## [2026-11-26 20:30] — Decisión de Ramiro: firma de la app

**Qué se le pidió:** Elegir si se crea una llave de firma propia para Android.

**Qué decidió y por qué:** "**Sin llave por ahora**".
- Riesgo aceptado: cada actualización obliga a desinstalar la app y se pierden los récords.
- Se puede agregar una llave después.

**Archivos creados o cambiados:** Ninguno.

**Comandos ejecutados:** Ninguno.

**Versiones usadas:** No aplica.

**Resultado:** Se compila con firma *debug*.

**Pendiente:** Revisar más adelante si se agrega llave de firma.

---

## [2026-11-26 20:30] — Agente: Documentador

**Qué se le pidió:** Crear la carpeta `docs/` con resumen, bitácora, guía para replicar, decisiones y seguridad.

**Qué decidió y por qué:** Escribir en español sencillo, explicando cada término técnico, sin copiar contraseñas, tokens ni llaves.

**Archivos creados o cambiados:**
- `docs/00-resumen.md`
- `docs/01-bitacora.md`
- `docs/02-como-replicar.md`
- `docs/03-decisiones.md`
- `docs/04-seguridad.md`

**Comandos ejecutados:**
```bash
mkdir -p /home/claude/arcade_app/docs
```

**Versiones usadas:** No aplica.

**Resultado:** Documentación inicial lista.

**Pendiente:** Actualizar los documentos conforme avancen los demás agentes.

---

## [2026-11-26] — Agente: Frontend (paso 3)

**Qué se le pidió:** Crear el proyecto Flutter que muestra el juego HTML dentro de la app, con guardado de récords, vibración, pantalla completa, icono y la compilación automática en GitHub Actions.

**Qué decidió y por qué:**
- **No se guardan las carpetas `android/` ni `windows/`** en el proyecto. Se generan en GitHub Actions con:
  ```bash
  flutter create --platforms=android --project-name arcade_de_bolsillo --org com.ramiro .
  flutter create --platforms=windows --project-name arcade_de_bolsillo --org com.ramiro .
  ```
  Por qué: en el entorno de trabajo no se puede descargar Flutter, así que no se pueden generar aquí. (`flutter create` = comando de Flutter que crea los archivos propios de cada plataforma.)
- Como esas carpetas se crean "en blanco" cada vez, el script **`tool/parchar_plataformas.py`** les aplica los ajustes: nombre visible **"Arcade de bolsillo"**, permiso **VIBRATE** (vibrar), **minSdk 24** (Android 7.0 como mínimo) y el título de la ventana de Windows (además la abre maximizada). Se puede correr varias veces sin duplicar cambios.
- **Juego:** copia en `assets/web/index.html`. Se quitaron los enlaces a Google Fonts y se usan **fuentes locales Bungee y Rubik** (licencia OFL) descargadas de `github.com/google/fonts`, en `assets/web/fonts/` junto con `OFL-Bungee.txt` y `OFL-Rubik.txt`.
- **Iconos:** dibujados por código con `tool/generar_icono.py` (usa **Pillow**, una librería de Python para hacer imágenes): castillo con bala de cañón sobre fondo morado. Genera `assets/icon/icon.png` y `assets/icon/icon_fg.png` (primer plano del icono adaptativo de Android).
- **`lib/puente_progreso.dart`:** respaldo de las claves `arc_*` en shared_preferences con *debounce* de 1.5 s (*debounce* = esperar a que dejen de llegar cambios antes de escribir en disco). Valida que las claves midan 64 caracteres o menos y los valores 20000 o menos.
- **`lib/main.dart`:** WebView con el juego; modo `immersiveSticky` en Android (pantalla completa); *wakelock* (pantalla siempre encendida); el botón **atrás** de Android vuelve al menú del arcade y, si ya estás en el menú, cierra la app; en Windows la ventana abre maximizada. Al minimizar o cerrar, guarda de inmediato lo pendiente.
- **Pruebas:** archivo `test/puente_progreso_test.dart` (el reporte del agente decía 11 pruebas; al contarlas en el archivo hay 12).
- **Workflow** `.github/workflows/build.yml` con 3 trabajos (*jobs*): `android`, `windows` y `release` (este último solo corre cuando se sube una etiqueta que empieza con `v`, por ejemplo `v1.0.0`).

**Archivos creados o cambiados:**
- `pubspec.yaml`, `analysis_options.yaml`, `.gitignore`, `README.md`
- `lib/main.dart`, `lib/puente_progreso.dart`
- `test/puente_progreso_test.dart`
- `assets/web/index.html`, `assets/web/fonts/` (Bungee-Regular.ttf, Rubik.ttf, OFL-Bungee.txt, OFL-Rubik.txt)
- `assets/icon/icon.png`, `assets/icon/icon_fg.png`
- `tool/generar_icono.py`, `tool/parchar_plataformas.py`, `tool/iconos_windows.yaml`
- `.github/workflows/build.yml`

**Comandos ejecutados:**
```bash
python3 tool/generar_icono.py
node --check   # sobre el script del HTML
```

**Versiones usadas:** las del Arquitecto (flutter_inappwebview ^6.1.5, shared_preferences ^2.5.6, wakelock_plus ^1.8.2, vibration ^3.2.1, flutter_launcher_icons ^0.14.4) + flutter_lints ^5.0.0.

**Resultado:**
- Verificado: el YAML del workflow es válido; el código JavaScript del HTML es idéntico al original y pasa `node --check` (revisión de sintaxis); el script que se inyecta al juego se probó en Node con *mocks* (imitaciones de `localStorage` y del puente de Flutter).
- **No verificado:** la compilación real (no hay Flutter aquí). Se hará en GitHub Actions.

**Pendiente:** Que GitHub Actions compile y el Tester revise.

---

## [2026-11-26] — Agente: Backend

**Qué se le pidió:** Revisar si hace falta servidor.

**Qué decidió y por qué:** **No aplica.** La app no tiene servidor (backend): todo funciona dentro del aparato.

**Archivos creados o cambiados:** Ninguno.

**Comandos ejecutados:** Ninguno.

**Versiones usadas:** No aplica.

**Resultado:** Paso omitido.

**Pendiente:** Nada.

---

## [2026-11-27] — Agente: Auditor de seguridad (paso 5, primera vuelta)

**Qué se le pidió:** Revisar la seguridad del código creado.

**Qué decidió y por qué:** Calificación general **🟢 (bien) para uso familiar**. Hallazgos:
- 🟡1 **XSS guardado** en `renderMenu` (el récord se metía "crudo" en `innerHTML`). → **Corregido** con `${fmt(Number(S.get('rec_'+id,0))||0)}`. Detalle en `04-seguridad.md`.
- 🟡2 **Acciones de GitHub y dependencias sin fijar.** → Acciones fijadas por **SHA** (huella exacta de la versión), `persist-credentials: false`, y el `pubspec.lock` se sube como artefacto `pubspec-lock` para fijarlo después en el repositorio (**pendiente**).
- Mejoras aplicadas: navegación con lista blanca (solo `file` y `about`), `maxClaves = 200`, pausa mínima de 80 ms entre vibraciones, `SHA256SUMS.txt` en cada Release.
- Mejoras no aplicadas (con su razón): ver `04-seguridad.md`.

**Archivos creados o cambiados:** `assets/web/index.html`, `.github/workflows/build.yml`, `lib/main.dart`, `lib/puente_progreso.dart`.

**Comandos ejecutados:** (para obtener los SHA de cada acción)
```bash
git ls-remote --tags https://github.com/<repo>
```
(por ejemplo `git ls-remote --tags https://github.com/actions/checkout`)

**Versiones usadas:** actions/checkout v4.4.0, actions/setup-java v4.9.1, subosito/flutter-action v2.23.0, actions/upload-artifact v4.6.2, actions/download-artifact v4.3.0, softprops/action-gh-release v2.6.2.

**Resultado:** 🟢. Sin CVEs conocidos (fallas públicas registradas) en `flutter_inappwebview` de pub.dev. **Ojo:** en npm existe un paquete **malicioso** con el mismo nombre (MAL-2025-189): nunca usar npm para esto.

**Pendiente:** Fijar `pubspec.lock` en el repositorio tras la primera compilación.

---

## [2026-11-27] — Agente: Auditor de seguridad (segunda vuelta, solo cambios)

**Qué se le pidió:** Revisar únicamente las correcciones de la primera vuelta.

**Qué decidió y por qué:** **🟢**. Los 6 SHA se verificaron y las correcciones están bien hechas. Se aplicó además:
- Quitar `data` de la lista blanca de navegación (quedan solo `file` y `about`).
- Leer los récords con `Number(...)||0` también en `finish()` y en Asedio de Castillos.

**Archivos creados o cambiados:** `lib/main.dart`, `assets/web/index.html`.

**Comandos ejecutados:** Ninguno nuevo.

**Versiones usadas:** Las mismas.

**Resultado:** Aprobado.

**Pendiente:** Nada de seguridad, salvo fijar `pubspec.lock`.

---

## [2026-11-27] — Pendiente: Tester (paso 4) y Despliegue (paso 6)

**Qué falta:**
1. **Ramiro** debe crear el repositorio **privado y vacío** `therrami15rs/arcade-de-bolsillo` en <https://github.com/new> (el entorno de trabajo no tiene permiso para crear repositorios). Vacío = sin README, sin .gitignore, sin licencia.
2. Después se sube el código y corre GitHub Actions: `flutter analyze`, `flutter test`, compilación del APK y de Windows.
3. El **Tester** revisa los resultados.

**Archivos creados o cambiados:** Ninguno.

**Comandos ejecutados:** Ninguno.

**Resultado:** En espera de Ramiro.
