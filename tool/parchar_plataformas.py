"""Aplica ajustes a las carpetas android/ y windows/ que genera `flutter create`.

Como esas carpetas no se guardan en git (se generan en CI), los cambios
necesarios se aplican aquí, de forma repetible:

  python3 tool/parchar_plataformas.py android
  python3 tool/parchar_plataformas.py windows

Se puede ejecutar varias veces sin duplicar cambios.
"""
import pathlib
import re
import sys

NOMBRE_VISIBLE = "Arcade de bolsillo"
NOMBRE_PROYECTO = "arcade_de_bolsillo"
MIN_SDK = 24


def leer(ruta):
    return ruta.read_text(encoding="utf-8")


def escribir(ruta, texto):
    ruta.write_text(texto, encoding="utf-8")
    print("  parchado:", ruta)


def parchar_android(raiz):
    manifiesto = raiz / "android/app/src/main/AndroidManifest.xml"
    m = leer(manifiesto)
    # Nombre que se ve bajo el icono
    m = re.sub(r'android:label="[^"]*"', f'android:label="{NOMBRE_VISIBLE}"', m, count=1)
    # Permiso de vibración (el plugin también lo declara; así queda explícito)
    permiso = '<uses-permission android:name="android.permission.VIBRATE"/>'
    if "android.permission.VIBRATE" not in m:
        m = m.replace("<application", permiso + "\n    <application", 1)
    escribir(manifiesto, m)

    # minSdk = 24 (Android 7.0). Soporta build.gradle.kts y build.gradle.
    hecho = False
    for nombre in ("build.gradle.kts", "build.gradle"):
        gradle = raiz / "android/app" / nombre
        if not gradle.exists():
            continue
        g = leer(gradle)
        g2 = g.replace("minSdk = flutter.minSdkVersion", f"minSdk = {MIN_SDK}")
        g2 = g2.replace("minSdkVersion flutter.minSdkVersion", f"minSdkVersion {MIN_SDK}")
        if g2 != g:
            escribir(gradle, g2)
            hecho = True
        elif re.search(r"minSdk(Version)?\s*=?\s*%d" % MIN_SDK, g):
            hecho = True  # ya estaba parchado
    if not hecho:
        sys.exit("ERROR: no encontré la línea de minSdk en android/app/build.gradle(.kts)")


def parchar_windows(raiz):
    main_cpp = raiz / "windows/runner/main.cpp"
    c = leer(main_cpp)
    viejo = f'L"{NOMBRE_PROYECTO}"'
    if viejo in c:
        escribir(main_cpp, c.replace(viejo, f'L"{NOMBRE_VISIBLE}"'))
    elif f'L"{NOMBRE_VISIBLE}"' not in c:
        sys.exit("ERROR: no encontré el título de la ventana en windows/runner/main.cpp")

    # Opcional: abrir la ventana maximizada.
    win32 = raiz / "windows/runner/win32_window.cpp"
    if win32.exists():
        w = leer(win32)
        if "SW_SHOWNORMAL" in w:
            escribir(win32, w.replace("SW_SHOWNORMAL", "SW_SHOWMAXIMIZED"))
        elif "SW_SHOWMAXIMIZED" not in w:
            print("  aviso: no se encontró SW_SHOWNORMAL; la ventana no se maximiza")


def main():
    if len(sys.argv) != 2 or sys.argv[1] not in ("android", "windows"):
        sys.exit("Uso: python3 tool/parchar_plataformas.py android|windows")
    raiz = pathlib.Path(__file__).resolve().parent.parent
    print("Parchando", sys.argv[1])
    if sys.argv[1] == "android":
        parchar_android(raiz)
    else:
        parchar_windows(raiz)


if __name__ == "__main__":
    main()
