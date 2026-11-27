# Arcade de bolsillo (app Android + Windows)

App que empaqueta el juego web **Arcade de bolsillo** (10 juegos en un solo
`index.html`) para que se instale como una aplicación normal en **Android** y
**Windows**. Funciona **sin internet**: el juego, las fuentes y los sonidos van
dentro de la app.

- Los récords se guardan dos veces: en el navegador interno (`localStorage`) y
  en el almacenamiento de la app (`SharedPreferences`), para que no se pierdan
  si se limpia la caché del WebView.
- En Android: pantalla completa, la pantalla no se apaga mientras juegas,
  vibración, y el botón **atrás** regresa al menú del arcade (y en el menú,
  cierra la app).

## Descargar la app ya compilada

La app se compila sola en GitHub cada vez que se sube un cambio a `main`.

**Opción A — pestaña Actions (cualquier versión):**

1. En GitHub abre el repositorio → pestaña **Actions**.
2. Entra a la última ejecución con palomita verde de **"Compilar Arcade de bolsillo"**.
3. Abajo, en **Artifacts**, descarga:
   - `ArcadeDeBolsillo-Android` (contiene `ArcadeDeBolsillo.apk`)
   - `ArcadeDeBolsillo-Windows` (contiene `ArcadeDeBolsillo-Windows.zip`)
4. GitHub los entrega dentro de un `.zip`; descomprímelo primero.

> Hay que haber iniciado sesión en GitHub para descargar artifacts, y se borran
> a los 90 días.

**Opción B — Releases (versiones oficiales):** si se publicó una etiqueta como
`v1.0.0`, ve a la sección **Releases** del repositorio y descarga los archivos
directamente.

Para publicar una versión nueva (quien mantiene el repo):

```bash
git tag v1.0.0
git push origin v1.0.0
```

## Instalar en Android

1. Copia `ArcadeDeBolsillo.apk` al teléfono (o descárgalo desde el teléfono).
2. Ábrelo. Android te pedirá permitir **"Instalar apps desconocidas"** para la
   app con la que lo abriste (Archivos, Chrome, etc.). Actívalo y regresa.
3. Toca **Instalar**. Requiere Android 7.0 o más nuevo.

### ⚠ Importante al actualizar

Esta app se firma con una llave de prueba que **cambia en cada compilación**.
Por eso, para instalar una versión nueva, Android puede decir *"La app no se
instaló"* o *"conflicto con un paquete existente"*. En ese caso hay que
**desinstalar la versión anterior primero**, y al desinstalar **se pierden los
récords**. Si más adelante quieres actualizar sin perder datos, hace falta
crear una llave de firma fija (keystore) y guardarla como *secret* de GitHub,
nunca dentro del código.

## Instalar en Windows

1. Descomprime `ArcadeDeBolsillo-Windows.zip` en una carpeta (por ejemplo
   `Documentos\ArcadeDeBolsillo`). No ejecutes el programa desde dentro del zip.
2. Abre `arcade_de_bolsillo.exe`.
3. Si Windows SmartScreen avisa "Windows protegió su PC", da clic en
   **Más información → Ejecutar de todas formas** (pasa porque la app no está
   firmada).
4. Si la ventana se abre en blanco o no abre, instala
   **Microsoft Edge WebView2 Runtime** (gratis, de Microsoft). En Windows 11 ya
   viene instalado.

## Compilar en tu propia PC

Necesitas [Flutter](https://docs.flutter.dev/get-started/install) (canal
stable) y, para Android, Android Studio con el SDK; para Windows, Visual Studio
con "Desarrollo para el escritorio con C++".

```bash
# 1) Generar las carpetas de plataforma (no están en git)
flutter create --platforms=android,windows --project-name arcade_de_bolsillo --org com.ramiro .
# flutter create agrega una prueba de ejemplo que no sirve aquí; bórrala
#   (Windows PowerShell: Remove-Item test/widget_test.dart)
rm test/widget_test.dart

# 2) Ajustes (nombre visible, permiso de vibración, minSdk 24, título de ventana)
python tool/parchar_plataformas.py android
python tool/parchar_plataformas.py windows

# 3) Dependencias e iconos
flutter pub get
dart run flutter_launcher_icons

# 4) Revisar y probar
flutter analyze
flutter test

# 5) Compilar
flutter build apk --release      # → build/app/outputs/flutter-apk/app-release.apk
flutter build windows --release  # → build/windows/x64/runner/Release/
```

Para probar en un teléfono conectado por USB: `flutter run`.

## Estructura

| Ruta | Para qué sirve |
|---|---|
| `lib/main.dart` | Pantalla con el WebView, botón atrás, vibración, pantalla completa |
| `lib/puente_progreso.dart` | Copia de los récords entre `localStorage` y la app |
| `assets/web/index.html` | El juego (copia del original con fuentes locales) |
| `assets/web/fonts/` | Fuentes Bungee y Rubik (licencia OFL, ver `OFL-*.txt`) |
| `assets/icon/` | Iconos de la app (se regeneran con `python tool/generar_icono.py`) |
| `tool/parchar_plataformas.py` | Ajustes a `android/` y `windows/` tras `flutter create` |
| `tool/iconos_windows.yaml` | Configuración de iconos que usa el CI de Windows |
| `test/` | Pruebas de la lógica de guardado |
| `.github/workflows/build.yml` | Compilación automática en GitHub |

## Actualizar el juego

Si cambias el juego original, copia el nuevo `index.html` a
`assets/web/index.html` y vuelve a hacer el cambio de fuentes: quitar los
`<link>` a `fonts.googleapis.com` y dejar el bloque `@font-face` que apunta a
`fonts/`. Así la app sigue funcionando sin internet.

## Licencias

Las fuentes **Bungee** y **Rubik** se distribuyen bajo la SIL Open Font
License 1.1 (archivos `assets/web/fonts/OFL-Bungee.txt` y `OFL-Rubik.txt`).
