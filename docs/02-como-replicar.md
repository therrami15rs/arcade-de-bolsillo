# Cómo replicar el proyecto desde cero

Esta guía es para que cualquier persona, aunque esté empezando, pueda repetir el proyecto.
Donde dice **(se completará)** es porque ese paso todavía no se ha hecho.

> Nunca pegues contraseñas, tokens ni llaves en estos documentos ni en el código.

---

## Paso 1. Instalar Git

**Git** es un programa que guarda el historial de cambios de tu proyecto y lo sube a GitHub.

- **Windows:** descarga el instalador de <https://git-scm.com/download/win> y dale "Siguiente" a todo.
- **Linux (Ubuntu/Debian):**
  ```bash
  sudo apt update
  sudo apt install git
  ```

Comprueba que quedó instalado:
```bash
git --version
```

Configura tu nombre y correo (los que usas en GitHub):
```bash
git config --global user.name "Tu Nombre"
git config --global user.email "tu-correo@ejemplo.com"
```

## Paso 2. Crear una cuenta de GitHub

**GitHub** es una página donde se guardan proyectos (repositorios) y que además puede compilarlos con **GitHub Actions**.

1. Entra a <https://github.com> y elige **Sign up**.
2. Confirma tu correo.
3. (Recomendado) Activa la verificación en dos pasos en **Settings → Password and authentication**.

## Paso 3. Crear el repositorio privado

1. En GitHub, botón **New repository**.
2. Nombre: `arcade-de-bolsillo`.
3. Marca **Private** (privado: solo tú lo ves).
4. **Create repository**.

Clonarlo (descargarlo) a tu computadora:
```bash
git clone https://github.com/<tu-usuario>/arcade-de-bolsillo.git
cd arcade-de-bolsillo
```
(Cambia `<tu-usuario>` por tu nombre de usuario de GitHub.)

## Paso 4. Estructura del proyecto Flutter

Lo que ya se sabe:
- El juego HTML irá en `assets/web/index.html`.
- Las fuentes Bungee y Rubik irán empaquetadas junto con su licencia `OFL.txt`.

**Actualizado 2026-11-26.** Así quedó la estructura (las licencias quedaron como `OFL-Bungee.txt` y `OFL-Rubik.txt`):

```
arcade-de-bolsillo/
├── .github/workflows/build.yml   ← compilación automática en GitHub Actions
├── .gitignore                    ← lo que NO se sube (android/, windows/, build/, llaves...)
├── analysis_options.yaml         ← reglas de revisión del código (flutter analyze)
├── pubspec.yaml                  ← nombre, versión, paquetes, assets, iconos
├── README.md                     ← cómo descargar, instalar y compilar
├── assets/
│   ├── icon/icon.png             ← icono completo 1024x1024
│   ├── icon/icon_fg.png          ← primer plano del icono adaptativo de Android
│   └── web/
│       ├── index.html            ← el juego (copia con fuentes locales)
│       └── fonts/                ← Bungee-Regular.ttf, Rubik.ttf, OFL-Bungee.txt, OFL-Rubik.txt
├── lib/
│   ├── main.dart                 ← pantalla con el WebView
│   └── puente_progreso.dart      ← respaldo de récords y vibración
├── test/puente_progreso_test.dart← pruebas automáticas
├── tool/
│   ├── generar_icono.py          ← dibuja los iconos
│   ├── parchar_plataformas.py    ← ajustes a android/ y windows/
│   └── iconos_windows.yaml       ← config de iconos solo para Windows
└── docs/                         ← esta documentación
```

> **Importante:** las carpetas `android/` y `windows/` **no están** en el proyecto. Se crean con `flutter create` (ver Paso 8b). *Assets* = archivos que van empaquetados dentro de la app (HTML, fuentes, imágenes).

**Fuentes sin internet:** en `assets/web/index.html` se quitaron los `<link>` a `fonts.googleapis.com` y se dejó un bloque `@font-face` que apunta a `fonts/Bungee-Regular.ttf` y `fonts/Rubik.ttf`. Las fuentes se bajaron de `github.com/google/fonts` (licencia OFL). Si actualizas el juego, repite ese cambio.

## Paso 5. Dependencias (`pubspec.yaml`)

**Actualizado 2026-11-26.** En `pubspec.yaml` las versiones van con `^` (por ejemplo `^6.1.5`), que significa "esta versión o una más nueva compatible". Además se usa `flutter_lints ^5.0.0` (solo desarrollo, reglas de estilo). Para fijar versiones exactas se usará el `pubspec.lock` que genera GitHub Actions (artefacto `pubspec-lock`; pendiente subirlo al repo).

Versiones decididas:

| Paquete | Versión |
|---------|---------|
| flutter_inappwebview | 6.1.5 |
| wakelock_plus | 1.8.2 |
| vibration | 3.2.1 |
| shared_preferences | 2.5.6 |
| flutter_launcher_icons (solo desarrollo) | 0.14.4 |

## Paso 6. Código de la app (`lib/main.dart`)

Lo que ya se sabe:
- Carga el juego con `loadFile(assetFilePath: 'assets/web/index.html')`.
- Pantalla completa con `SystemChrome` en modo `immersiveSticky`.
- Puente de vibración: `navigator.vibrate` → `callHandler('vibrar')`.
- Respaldo de datos `arc_*` en shared_preferences.

**Actualizado 2026-11-26.** Lo que hace el código real:

`lib/main.dart`
- Carga el juego con `initialFile: 'assets/web/index.html'` (equivale a `loadFile`, pero al crear el WebView).
- En Android activa `immersiveSticky` (las barras del sistema aparecen al deslizar y se ocultan solas).
- Activa *wakelock* (`WakelockPlus.enable()`): la pantalla no se apaga.
- Inyecta un script al inicio de la página (`UserScript`, `AT_DOCUMENT_START`) que genera `puente_progreso.dart`.
- Dos *handlers* (puertas por las que el JavaScript le habla a Dart): `guardar` y `vibrar`.
- Botón **atrás** de Android: si hay un juego abierto, vuelve al menú del arcade; si ya estás en el menú, guarda y cierra la app.
- Al minimizar, cambiar de app o cerrar: guarda de inmediato lo pendiente.
- Seguridad: solo deja navegar a direcciones `file` y `about`; niega cámara/micrófono; vibración de 1 a 1000 ms con pausa mínima de 80 ms.

`lib/puente_progreso.dart`
- Al abrir la app, lee las claves `arc_*` de shared_preferences y las mete en el localStorage del juego.
- Si no había nada guardado (primera vez), copia lo que ya tenga localStorage (migración).
- Cada vez que el juego guarda una clave `arc_*`, se manda a Dart y se escribe en disco tras **1.5 s** sin cambios (*debounce*).
- Valida: claves que empiecen con `arc_` y midan ≤ 64 caracteres; valores de texto ≤ 20000 caracteres; máximo 200 claves.
- Convierte `navigator.vibrate(...)` del juego en un aviso a Dart.

`test/puente_progreso_test.dart` — 12 pruebas: validación de claves/valores, filtro `arc_*`, que el script generado no se rompa con comillas o saltos de línea, y el guardado con *debounce*. Se corren con `flutter test`.

## Paso 7. Icono y nombre de la app

**Icono.** Lo dibuja un script de Python con **Pillow** (librería para crear imágenes). Para regenerarlo:

```bash
pip install pillow
python3 tool/generar_icono.py
```
(En Windows usa `python` en vez de `python3`.)

Crea:
- `assets/icon/icon.png` — 1024x1024, fondo morado, castillo y bala de cañón.
- `assets/icon/icon_fg.png` — solo el dibujo con fondo transparente, dentro del 66% central (Android recorta los iconos *adaptativos* en círculo o gota y así no se corta).

Luego, ya con la carpeta `android/` creada, se generan todos los tamaños con:
```bash
dart run flutter_launcher_icons
```
(La configuración está en `pubspec.yaml`: fondo `#140c2a`, `min_sdk_android: 24`.)
Para Windows solo (cuando no existe `android/`):
```bash
dart run flutter_launcher_icons -f tool/iconos_windows.yaml
```

**Nombre.** Lo pone `tool/parchar_plataformas.py` después de `flutter create`:
```bash
python3 tool/parchar_plataformas.py android   # nombre "Arcade de bolsillo", permiso VIBRATE, minSdk 24
python3 tool/parchar_plataformas.py windows   # título de ventana "Arcade de bolsillo" y ventana maximizada
```
Se puede correr varias veces sin duplicar cambios.

## Paso 8. Compilar con GitHub Actions

El proyecto **no se compila en tu computadora**: se compila en GitHub Actions con **Flutter 3.50 estable**.

Lo que ya se sabe:
- Se usa la acción `subosito/flutter-action@v2` (v2.23.0) con `channel: stable`.
- **Android:** máquina `ubuntu-latest` + Java 17 → `flutter build apk --release`.
- **Windows:** máquina `windows-latest` → `flutter build windows --release`, y se comprime en zip la carpeta `build/windows/x64/runner/Release`.

El archivo del flujo de trabajo (`.github/workflows/...yml`): **actualizado 2026-11-26** → es `.github/workflows/build.yml`.

Cuándo corre: al subir cambios a la rama `main`, al subir una etiqueta `v*` (por ejemplo `v1.0.0`) o a mano desde la pestaña **Actions** (botón *Run workflow*).

Tiene 3 trabajos (*jobs*):

| Trabajo | Máquina | Qué hace | Resultado |
|---------|---------|----------|-----------|
| `android` | ubuntu-latest + Java 17 | `flutter create` (android) → parche → `flutter pub get` → sube `pubspec.lock` → iconos → `flutter analyze --no-fatal-infos` → `flutter test` → `flutter build apk --release` | Artefacto `ArcadeDeBolsillo-Android` (`ArcadeDeBolsillo.apk`) |
| `windows` | windows-latest | `flutter create` (windows) → parche → `flutter pub get` → iconos Windows → analyze → test → `flutter build windows --release` → zip | Artefacto `ArcadeDeBolsillo-Windows` (`ArcadeDeBolsillo-Windows.zip`) |
| `release` | ubuntu-latest | Solo con etiqueta `v*`: junta APK y ZIP, crea `SHA256SUMS.txt` y publica un *Release* | Release en GitHub |

Las acciones están fijadas por SHA (ver `04-seguridad.md`). *Artefacto* = archivo que deja guardado una ejecución de Actions para descargarlo.

Para publicar una versión (Release):
```bash
git tag v1.0.0
git push origin v1.0.0
```

### Paso 8a. Subir el código por primera vez (pendiente)

1. **Ramiro** crea el repositorio **privado y vacío** `therrami15rs/arcade-de-bolsillo` en <https://github.com/new> (sin README, sin .gitignore, sin licencia). El entorno de trabajo de los agentes no tiene permiso para crear repositorios.
2. Se sube el código (desde la carpeta del proyecto):
   ```bash
   git init
   git add .
   git commit -m "Primera versión de Arcade de bolsillo"
   git branch -M main
   git remote add origin https://github.com/therrami15rs/arcade-de-bolsillo.git
   git push -u origin main
   ```
3. En la pestaña **Actions** se ve la compilación. Al terminar en verde, se descargan los artefactos.
4. Descargar el artefacto `pubspec-lock`, poner `pubspec.lock` en la raíz del proyecto y subirlo:
   ```bash
   git add pubspec.lock
   git commit -m "Fijar versiones de dependencias"
   git push
   ```

### Paso 8b. Compilar en una PC con Flutter (opcional)

Si algún día tienes Flutter instalado (canal stable; para Android también Android Studio con su SDK; para Windows, Visual Studio con "Desarrollo para el escritorio con C++"):

```bash
# 1) Crear la carpeta android/ (no está en git)
flutter create --platforms=android --project-name arcade_de_bolsillo --org com.ramiro .
rm test/widget_test.dart            # prueba de ejemplo que no sirve (PowerShell: Remove-Item test/widget_test.dart)

# 2) Ajustes: nombre, permiso de vibración, minSdk 24
python tool/parchar_plataformas.py android

# 3) Paquetes e iconos
flutter pub get
dart run flutter_launcher_icons

# 4) Pruebas
flutter test

# 5) Compilar el APK
flutter build apk --release
# Resultado: build/app/outputs/flutter-apk/app-release.apk
```

Para Windows es igual pero con `--platforms=windows`, `python tool/parchar_plataformas.py windows`, `dart run flutter_launcher_icons -f tool/iconos_windows.yaml` y `flutter build windows --release` (resultado en `build/windows/x64/runner/Release/`).

Para probar en un teléfono conectado por USB: `flutter run`.

## Paso 9. Descargar e instalar

**Actualizado 2026-11-26** (detalle completo en `README.md`):
- **Descargar:** pestaña **Actions** → última ejecución en verde → sección **Artifacts** (vienen en .zip; se borran a los 90 días). O en **Releases** si se publicó una etiqueta `v*`.
- **Android:** abrir `ArcadeDeBolsillo.apk`, permitir "Instalar apps desconocidas" y tocar **Instalar**. Requiere Android 7.0 o más nuevo.
- **Windows:** descomprimir `ArcadeDeBolsillo-Windows.zip` en una carpeta y abrir `arcade_de_bolsillo.exe`. Si SmartScreen avisa, **Más información → Ejecutar de todas formas** (la app no está firmada).

Notas que ya se saben:
- **Android:** como la app no tiene llave de firma propia, para actualizar hay que **desinstalar la versión anterior** (se pierden los récords).
- **Windows:** necesita **WebView2 Runtime** (ya viene en Windows 10/11 actualizados; en equipos viejos puede faltar).

## Paso 10. Problemas comunes

(se completará con lo que encuentre el Tester)

Ya conocidos:
- **Android: "La app no se instaló" / "conflicto con un paquete existente"** → desinstala la versión anterior (se pierden los récords; firma *debug*).
- **Windows: ventana en blanco** → instala Microsoft Edge WebView2 Runtime.
- **Windows: no suena al abrir** → toca o haz clic en el juego una vez (el navegador bloquea el audio hasta que el usuario interactúa).
- **`parchar_plataformas.py` dice "ERROR: no encontré..."** → la nueva versión de Flutter cambió el archivo generado; hay que ajustar el script.
- **Nunca** instales `flutter_inappwebview` con npm: hay un paquete malicioso con ese nombre. Solo `flutter pub get`.
