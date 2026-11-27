# Compilar "Arcade de bolsillo" en tu PC (Windows)

Esta guía te lleva desde una PC sin Flutter hasta tener el **APK para tu celular** y el **programa para Windows**.
Todo lo pesado lo hace el script `compilar.ps1`; tú solo instalas las herramientas una vez.

> **Importante:** Visual Studio solo sirve para compilar la versión de **Windows**.
> Para el **APK de Android** necesitas además **Flutter** y **Android Studio** (que trae el "Android SDK", las herramientas de Google para armar apps de Android).

---

## Parte 1. Instalar las herramientas (solo la primera vez, ~1 hora)

### 1. Activar el "Modo de desarrollador" de Windows
Flutter lo necesita para enlazar los plugins.
1. Abre **Configuración → Sistema → Para programadores** (en Windows 10: *Actualización y seguridad → Para programadores*).
2. Activa **Modo de desarrollador**.

### 2. Visual Studio (para la versión de Windows)
1. Abre el **Visual Studio Installer**.
2. En tu Visual Studio da clic en **Modificar**.
3. Marca la carga de trabajo **"Desarrollo para el escritorio con C++"** (Desktop development with C++) y deja marcados sus componentes por defecto.
4. Clic en **Modificar** y espera.

### 3. Android Studio (para el APK)
1. Descárgalo de **https://developer.android.com/studio** e instálalo con las opciones por defecto.
2. Ábrelo una vez y deja que termine el asistente: descarga el **Android SDK**.
3. En Android Studio ve a **More Actions → SDK Manager → pestaña SDK Tools** y marca **Android SDK Command-line Tools (latest)**. Clic en **Apply**.

### 4. Flutter
1. Descarga Flutter **estable** desde **https://docs.flutter.dev/get-started/install/windows** (archivo .zip).
2. Descomprímelo en `C:\src\flutter` (evita rutas con espacios o acentos, como "Archivos de programa").
3. Agrégalo al PATH:
   - Busca en Windows **"Editar las variables de entorno de esta cuenta"**.
   - En **Path** → **Editar** → **Nuevo** → escribe `C:\src\flutter\bin` → **Aceptar**.
4. Abre una **nueva** ventana de PowerShell y escribe:
   ```powershell
   flutter doctor
   ```
5. Acepta las licencias de Android (escribe `y` a todo):
   ```powershell
   flutter doctor --android-licenses
   ```
6. Vuelve a correr `flutter doctor`. Debes ver ✓ en **Flutter**, **Android toolchain** y **Visual Studio**. Si algo sale con ✗, `flutter doctor` te dice qué falta.

---

## Parte 2. Compilar (cada vez que quieras una versión nueva, ~10 min la primera vez)

1. Descomprime `arcade-de-bolsillo.zip` en una carpeta sin espacios ni acentos, por ejemplo `C:\src\arcade-de-bolsillo`.
2. Abre **PowerShell** dentro de esa carpeta (en el Explorador: clic en la barra de dirección, escribe `powershell` y Enter).
3. Ejecuta **una** de estas opciones:

| Quiero… | Comando |
|---|---|
| APK y programa de Windows | `powershell -ExecutionPolicy Bypass -File .\compilar.ps1` |
| Solo el APK | `powershell -ExecutionPolicy Bypass -File .\compilar.ps1 android` |
| Solo Windows | `powershell -ExecutionPolicy Bypass -File .\compilar.ps1 windows` |
| APK e instalarlo en el celular por USB | `powershell -ExecutionPolicy Bypass -File .\compilar.ps1 instalar` |

(`-ExecutionPolicy Bypass` permite correr este script una vez sin cambiar la seguridad de tu PC.)

4. Al terminar, todo queda en la carpeta **`salida`**:
   - `salida\ArcadeDeBolsillo.apk` → para el celular.
   - `salida\ArcadeDeBolsillo-Windows\arcade_de_bolsillo.exe` → el juego en la PC (copia **toda** la carpeta si lo llevas a otra computadora).

### Qué hace el script, paso a paso
1. Revisa que Flutter esté instalado.
2. Genera las carpetas `android/` y `windows/` (`flutter create`).
3. Pone el nombre "Arcade de bolsillo", el permiso de vibración, Android 7.0 como mínimo y la ventana maximizada.
4. Descarga los paquetes (`flutter pub get`).
5. Aplica un ajuste de compatibilidad al paquete `flutter_inappwebview` (su regla de ProGuard es vieja para el Android nuevo).
6. Genera el icono, revisa el código (`flutter analyze`) y corre las 12 pruebas (`flutter test`).
7. Compila el APK y/o el programa de Windows (en Windows activa un ajuste para Visual Studio nuevo).

---

## Parte 3. Instalar en el celular

**Opción A – Copiar el archivo:** pasa `ArcadeDeBolsillo.apk` al celular (cable, WhatsApp a ti mismo, Drive…), ábrelo y acepta **"Permitir de esta fuente"**.

**Opción B – Por cable USB (comando `instalar`):**
1. En el celular: **Ajustes → Acerca del teléfono** → toca 7 veces **Número de compilación** (activa "Opciones de desarrollador").
2. **Ajustes → Opciones de desarrollador → Depuración USB**: actívala.
3. Conecta el cable y acepta **"Permitir depuración USB"** en el celular.
4. Corre `.\compilar.ps1 instalar`.

> Si ya tenías instalada una versión hecha en GitHub, **desinstálala primero**: cada computadora firma la app con una llave distinta y Android no deja instalar encima (se pierden los récords de esa instalación).

---

## Problemas comunes

| Mensaje | Solución |
|---|---|
| `No encuentro Flutter` | Revisa el PATH (Parte 1, paso 4) y abre una **nueva** ventana de PowerShell. |
| `Building with plugins requires symlink support` | Activa el **Modo de desarrollador** (Parte 1, paso 1). |
| `Android license status unknown` | Corre `flutter doctor --android-licenses` y acepta todo. |
| `Unable to find suitable Visual Studio toolchain` | Falta "Desarrollo para el escritorio con C++" en Visual Studio. |
| El .exe no abre en otra PC | Instala **Microsoft Edge WebView2 Runtime** desde la página de Microsoft. |
| `No connected devices` al instalar | Revisa la depuración USB y acepta el aviso en el celular. |
