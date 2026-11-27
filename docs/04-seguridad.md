# Seguridad

**Estado: auditado (2 vueltas) — 🟢 bien para uso familiar.** (Antes decía: "pendiente de auditoría".)

Una *auditoría de seguridad* es una revisión para encontrar problemas que pongan en riesgo la app o los datos. La hará el agente de seguridad cuando exista el código.

Datos conocidos hasta ahora (para el auditor):
- La app no tiene servidor ni cuentas; todo es local.
- Solo guarda récords, monedas y ajustes (claves `arc_*`). No guarda datos personales ni contraseñas.
- Firma *debug* aceptada por Ramiro ("Sin llave por ahora").
- Nunca subir contraseñas, tokens ni llaves al repositorio.

Semáforo usado: 🟢 bien · 🟡 mejorable / riesgo medio · 🔴 grave.

---

## Auditoría 1 (2026-11-27, paso 5, primera vuelta)

**Calificación: 🟢 para uso familiar.**

### 🟡1 XSS guardado en `renderMenu` — CORREGIDO

- *XSS* (*cross-site scripting*) = cuando un texto que debería ser solo "datos" se mete en la página como si fuera código HTML, y así puede ejecutar código. "Guardado" = el texto malo viene de algo guardado (aquí, localStorage).
- **Problema:** en `assets/web/index.html`, la función `renderMenu` ponía el récord tal cual estaba guardado dentro de `innerHTML`. Si alguien alteraba el valor guardado, podía inyectar HTML.
- **Corrección:** convertir siempre a número antes de mostrarlo:
  ```js
  ${fmt(Number(S.get('rec_'+id,0))||0)}
  ```
  `Number(...)` convierte a número; si no es número da `NaN`, y `||0` lo cambia a 0. Así nunca entra texto.

### 🟡2 Acciones de GitHub y dependencias sin fijar — CORREGIDO (falta un paso)

- *Fijar por SHA* = en lugar de decir "usa la versión v4" (que el autor podría cambiar), se usa la huella exacta (SHA) de un *commit*. Si alguien cambiara la acción, la huella ya no coincidiría.
- Acciones fijadas en `.github/workflows/build.yml`:

| Acción | Versión | SHA |
|--------|---------|-----|
| actions/checkout | v4.4.0 | `11d5960a326750d5838078e36cf38b85af677262` |
| actions/setup-java | v4.9.1 | `cf277c60eb25467037889841efdb72551f06f6c3` |
| subosito/flutter-action | v2.23.0 | `1a449444c387b1966244ae4d4f8c696479add0b2` |
| actions/upload-artifact | v4.6.2 | `ea165f8d65b6e75b540449e92b4886f43607fa02` |
| actions/download-artifact | v4.3.0 | `d3f86a106a0bac45b974a628896c90dbdf5c8093` |
| softprops/action-gh-release | v2.6.2 | `3bb12739c298aeb8a4eeaf626c5b8d85266b0e65` |

- Cómo se obtienen los SHA (cambia `<repo>` por, por ejemplo, `actions/checkout`):
  ```bash
  git ls-remote --tags https://github.com/<repo>
  ```
- `persist-credentials: false` en `actions/checkout`: no deja guardada la credencial de GitHub dentro de la carpeta descargada.
- Permisos mínimos: el workflow tiene `contents: read`; solo el trabajo `release` tiene `contents: write`.
- **Dependencias de Dart:** el `pubspec.lock` (archivo que anota la versión exacta de cada paquete) se sube como artefacto `pubspec-lock`. **Pendiente:** descargarlo de Actions tras la primera compilación y subirlo al repositorio para fijar las versiones.

### Mejoras aplicadas

- **Lista blanca de navegación** (`shouldOverrideUrlLoading` en `lib/main.dart`): el WebView solo puede abrir direcciones `file` y `about`. Todo lo demás (`http`, `https`, `intent:`, `mailto:`...) se bloquea.
- **`maxClaves = 200`** en `lib/puente_progreso.dart`: no se respaldan más de 200 claves distintas (el juego usa ~15), para que nada llene el almacenamiento.
- **Pausa mínima de 80 ms entre vibraciones** y duración limitada a 1–1000 ms, para que no vibre sin parar.
- **`SHA256SUMS.txt` en cada Release**: lista de huellas SHA-256 del APK y del ZIP para comprobar que el archivo descargado es el original. Para comprobarlo:
  - Linux: `sha256sum -c SHA256SUMS.txt`
  - Windows (PowerShell): `Get-FileHash ArcadeDeBolsillo.apk -Algorithm SHA256` y comparar con el archivo.

### Mejoras NO aplicadas (y por qué)

| Mejora | Por qué no |
|--------|-----------|
| `allowFileAccess: false` | Hay que probar primero que las fuentes locales sigan cargando. |
| Escapar caracteres U+2028/U+2029 en el script inyectado | Riesgo mínimo (`jsonEncode` ya escapa comillas y saltos de línea). |
| Lista de orígenes permitidos para los *handlers* (puentes JS→Dart) | Esperar a que salga `flutter_inappwebview` 6.2 estable, que lo soporta mejor. |

### Otros hallazgos

- Sin CVEs conocidos (fallas de seguridad registradas públicamente) para `flutter_inappwebview` de **pub.dev**.
- ⚠ **Ojo:** existe un paquete **malicioso de npm** con el mismo nombre (`flutter_inappwebview`, aviso **MAL-2025-189**). **Nunca usar npm para esto**; el paquete correcto se instala solo con `flutter pub get` desde pub.dev.
- Ya estaban bien desde antes: permisos de cámara/micrófono se niegan (`onPermissionRequest` → DENY), `allowFileAccessFromFileURLs` y `allowUniversalAccessFromFileURLs` en `false`, inspector del WebView solo en modo debug, y las claves/valores del puente se validan (claves `arc_*` ≤ 64 caracteres, valores ≤ 20000).

---

## Auditoría 2 (2026-11-27, segunda vuelta, solo cambios)

**Calificación: 🟢.**

- Los 6 SHA de la tabla se verificaron y coinciden con sus versiones.
- Las correcciones de la vuelta 1 están bien hechas.
- Se aplicó además:
  - Se quitó `data` de la lista blanca de navegación (quedan solo `file` y `about`).
  - Los récords también se leen con `Number(...)||0` en `finish()` y en Asedio de Castillos (`start`, `picker`, `win`).

---

## Pendientes de seguridad

- [ ] Subir `pubspec.lock` al repositorio (descargándolo del artefacto `pubspec-lock`).
- [ ] Probar `allowFileAccess: false` con las fuentes.
- [ ] Revisar `flutter_inappwebview` 6.2 estable para limitar orígenes de los handlers.
- [ ] (Opcional) Llave de firma propia para Android, guardada como *secret* de GitHub, **nunca** en el código.
