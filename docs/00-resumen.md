# Arcade de bolsillo — Resumen del proyecto

> Última actualización: 2026-11-26

## 1. ¿Qué es este proyecto?

El **"Arcade de bolsillo"** es un juego web que ya existe y está hecho en **un solo archivo HTML**.
(HTML es el lenguaje con el que se escriben las páginas web; el navegador lo lee y lo muestra.)

Ese archivo trae **10 juegos**:

| # | Juego | Nota |
|---|-------|------|
| 1 | Asedio de Castillos | 20 niveles y multijugador local de 2 a 4 personas en el mismo aparato |
| 2 | Enjambre | |
| 3 | Bloque Cósmico | |
| 4 | Imperio de Fusión | |
| 5 | Mazmorra de Cartas | |
| 6 | Último Bastión | |
| 7 | Torre Infinita | |
| 8 | Serpiente | |
| 9 | 2048 | |
| 10 | Vuelo del Búho | |

Tecnologías que ya usa el juego web:

- **Canvas 2D**: es un "lienzo" de la página web donde el juego dibuja todo (personajes, fondos, etc.).
- **Web Audio sintetizado**: los sonidos y la música no son archivos de audio; el navegador los "fabrica" con código en el momento.
- **localStorage**: es una pequeña memoria del navegador donde se guardan datos (récords, monedas) aunque cierres la página.

**El pedido de Ramiro:** "Crea la app para estos juegos". Es decir: convertir ese archivo HTML en una **app instalable** (que se instala como cualquier otra aplicación).

## 2. Lo que respondió Ramiro (requisitos)

- **Plataformas:** Android (teléfonos/tabletas) y Windows (computadoras).
- **Cómo se compila:** con **GitHub Actions**.
  - *Compilar* = convertir el código en un archivo que se puede instalar (`.apk` en Android, `.exe` en Windows).
  - *GitHub Actions* = un servicio gratuito de GitHub que usa computadoras en internet para compilar tu proyecto automáticamente.
  - ¿Por qué? En el entorno de trabajo de los agentes **no se puede descargar** Flutter ni el Android SDK, porque estos sitios están bloqueados: `storage.googleapis.com`, `dl.google.com`, `pub.dev` y `maven.google.com`.
- **Uso:** solo personal / familiar. **No** se publicará en Google Play.
- **Repositorio:** privado, llamado `arcade-de-bolsillo`. (Un *repositorio* es una carpeta del proyecto guardada en GitHub, con historial de cambios.)

## 3. Plan aprobado (versión 1)

1. Jugar **sin internet**.
2. **Pantalla completa**, y el juego *Asedio de Castillos* en **horizontal**.
3. **Guardar** récords, monedas y niveles.
4. **Sonido, música y vibración**.
5. **Icono y nombre propios** de la app.
6. **GitHub Actions** genera el `.apk` (Android) y el `.exe` (Windows).

**Fuera de la versión 1** (no se hará por ahora):

- Publicar en Play Store.
- Multijugador en línea (por internet).
- Cuentas de usuario.

## 4. Stack (herramientas elegidas) y por qué

*Stack* = el conjunto de herramientas y librerías con las que se construye el proyecto.
*Librería* o *paquete* = código ya hecho por otras personas que podemos reutilizar.

| Pieza | Versión | ¿Para qué sirve? | ¿Por qué se eligió? |
|-------|---------|------------------|---------------------|
| **Flutter** (canal *stable*) | 3.50.x | Framework de Google para hacer apps para varias plataformas con un solo código. | Saca Android y Windows desde el mismo proyecto. |
| **flutter_inappwebview** | 6.1.5 | Un **WebView**: una "ventanita de navegador" dentro de la app que muestra el HTML del juego. | Funciona en Android **y** Windows con una sola forma de programar. |
| **flutter_inappwebview_windows** | 0.6.0 | La parte de Windows del anterior; usa **WebView2** (el motor de Microsoft Edge). | Viene incluida para soportar Windows. |
| **SystemChrome** (modo `immersiveSticky`) | incluido en Flutter | Oculta barras del sistema para pantalla completa. | Cumple el punto 2 del plan sin librerías extra. |
| **wakelock_plus** | 1.8.2 | Evita que la pantalla se apague mientras juegas. | Simple y mantenido. |
| **vibration** | 3.2.1 | Hace vibrar el teléfono. | El juego llama a `navigator.vibrate` y un "puente" lo pasa a Flutter (`callHandler('vibrar')`). |
| **shared_preferences** | 2.5.6 | Guarda datos pequeños en el aparato (clave = valor). | Respaldo de los récords por si se pierde el localStorage. |
| **flutter_launcher_icons** | 0.14.4 (solo desarrollo) | Genera los iconos de la app en todos los tamaños. | Cumple el punto 5 del plan. |
| **Fuentes Bungee y Rubik** | — | Tipos de letra del juego. | Se empaquetan dentro de la app para que se vean sin internet. Licencia OFL: hay que incluir el archivo `OFL.txt`. |
| **GitHub Actions** + `subosito/flutter-action@v2` (v2.23.0) | — | Instala Flutter en las computadoras de GitHub y compila. | No se puede compilar en el entorno de trabajo. |
| **Java** | 17 | Lo necesita Android para compilar. | Versión requerida por las herramientas actuales de Android. |

**Sin servidor (backend):** todo funciona dentro del aparato; no hay internet ni base de datos en línea.

## 5. Decisiones importantes del dueño

- **Firma de la app: "Sin llave por ahora".**
  *Firmar* una app es ponerle un "sello" digital que demuestra que es tuya. Sin una llave propia, GitHub Actions usa una firma de prueba (*debug*) que **cambia en cada compilación**.
  Consecuencia aceptada: en Android, **cada actualización obliga a desinstalar la versión anterior y se pierden los récords**. Se puede agregar una llave después.

## 6. Documentos de esta carpeta

- `00-resumen.md` — este archivo.
- `01-bitacora.md` — diario de lo que hizo cada agente.
- `02-como-replicar.md` — guía paso a paso para repetir el proyecto.
- `03-decisiones.md` — tabla de decisiones y alternativas.
- `04-seguridad.md` — revisión de seguridad (pendiente).
  - **Actualizado 2026-11-27:** ya auditado en 2 vueltas, calificación 🟢 para uso familiar.

## 7. Estado actual (2026-11-27)

- Código listo: proyecto Flutter, juego con fuentes locales, iconos, pruebas y workflow de GitHub Actions.
- Seguridad: 🟢 (2 auditorías).
- **Falta:** que Ramiro cree el repositorio privado vacío `therrami15rs/arcade-de-bolsillo` en github.com/new; luego se sube el código, compila GitHub Actions y el Tester revisa.
- La compilación real todavía **no** se ha probado.
