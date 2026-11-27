"""Genera los iconos de la app (assets/icon/icon.png e icon_fg.png).

Uso (desde la raíz del proyecto):  python3 tool/generar_icono.py
Requiere Pillow (pip install pillow).

- icon.png: 1024x1024, fondo morado con degradado + castillo + bala de cañón.
- icon_fg.png: 1024x1024 transparente, solo el dibujo, dentro del 66% central
  (Android recorta los iconos adaptativos en círculo/gota, así no se corta).
"""
import math
import os
import random

from PIL import Image, ImageDraw, ImageFilter

TAM = 1024
SS = 4  # súper-muestreo: dibujamos a 4x y reducimos para bordes suaves
W = TAM * SS

FONDO_ARRIBA = (52, 30, 104)
FONDO_ABAJO = (20, 12, 42)  # #140c2a
AMARILLO = (255, 207, 74)  # #ffcf4a
MENTA = (62, 224, 181)
ROSA = (255, 107, 139)
PIEDRA = (196, 182, 240)
PIEDRA_SOMBRA = (140, 122, 200)
OSCURO = (30, 18, 62)


def s(v):
    """Escala una coordenada del espacio 1024 al lienzo súper-muestreado."""
    return int(round(v * SS))


def rect(d, x0, y0, x1, y1, color):
    d.rectangle([s(x0), s(y0), s(x1), s(y1)], fill=color)


def almenas(d, x0, x1, y, alto, n, color):
    """Dibuja n almenas (dientes) sobre una torre/muro entre x0 y x1."""
    ancho = (x1 - x0) / (2 * n - 1)
    for i in range(n):
        xa = x0 + i * 2 * ancho
        rect(d, xa, y - alto, xa + ancho, y, color)


def dibujar_figura():
    """Devuelve una capa RGBA (W x W) con castillo, estandarte y bala."""
    capa = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    d = ImageDraw.Draw(capa)

    suelo = 800
    # --- Estela de la bala (círculos que se desvanecen) ---
    # La bala vuela de abajo-izquierda hacia arriba-derecha.
    bx, by, br = 640, 215, 88
    for i in range(14, 0, -1):
        t = i / 14
        cx = bx - 300 * t
        cy = by + 150 * t
        r = br * (1 - 0.6 * t)
        alfa = int(230 * (1 - t) ** 0.7)
        col = (255, 140 + int(67 * (1 - t)), 60, alfa)
        d.ellipse([s(cx - r), s(cy - r), s(cx + r), s(cy + r)], fill=col)

    # --- Muro central ---
    rect(d, 300, 560, 724, suelo, PIEDRA)
    almenas(d, 300, 724, 560, 46, 5, PIEDRA)
    # --- Torres laterales (más altas) ---
    for x0 in (210, 664):
        x1 = x0 + 150
        rect(d, x0, 470, x1, suelo, PIEDRA)
        rect(d, x1 - 30, 470, x1, suelo, PIEDRA_SOMBRA)  # sombra lateral
        almenas(d, x0, x1, 470, 52, 3, PIEDRA)
        # ventana de la torre
        cxv = (x0 + x1) / 2
        d.rounded_rectangle([s(cxv - 18), s(560), s(cxv + 18), s(630)],
                            radius=s(18), fill=OSCURO)
    # --- Puerta en arco ---
    d.rectangle([s(450), s(680), s(574), s(suelo)], fill=OSCURO)
    d.ellipse([s(450), s(618), s(574), s(742)], fill=OSCURO)

    # --- Asta y estandarte sobre la torre izquierda ---
    ax = 285
    rect(d, ax - 7, 280, ax + 7, 420, (236, 230, 255))
    d.polygon([(s(ax + 7), s(288)), (s(ax + 150), s(318)),
               (s(ax + 7), s(352))], fill=ROSA)
    # --- Bandera menta en la torre derecha ---
    ax2 = 739
    rect(d, ax2 - 6, 330, ax2 + 6, 420, (236, 230, 255))
    d.polygon([(s(ax2 + 6), s(336)), (s(ax2 + 100), s(358)),
               (s(ax2 + 6), s(382))], fill=MENTA)

    # --- Bala de cañón amarilla con brillo ---
    d.ellipse([s(bx - br), s(by - br), s(bx + br), s(by + br)], fill=AMARILLO)
    d.ellipse([s(bx - br * 0.55), s(by - br * 0.6), s(bx - br * 0.05),
               s(by - br * 0.15)], fill=(255, 244, 196))
    # contorno oscuro para que se lea en tamaños pequeños
    d.ellipse([s(bx - br), s(by - br), s(bx + br), s(by + br)],
              outline=(120, 70, 10), width=s(8))
    return capa


def fondo():
    img = Image.new("RGBA", (W, W))
    d = ImageDraw.Draw(img)
    for y in range(W):
        t = y / (W - 1)
        col = tuple(int(FONDO_ARRIBA[i] + (FONDO_ABAJO[i] - FONDO_ARRIBA[i]) * t)
                    for i in range(3))
        d.line([(0, y), (W, y)], fill=col + (255,))
    # estrellitas fijas (semilla fija = siempre el mismo icono)
    rnd = random.Random(7)
    for _ in range(40):
        x, y = rnd.uniform(40, 984), rnd.uniform(40, 520)
        r = rnd.uniform(2, 5)
        d.ellipse([s(x - r), s(y - r), s(x + r), s(y + r)],
                  fill=(255, 255, 255, rnd.randint(90, 200)))
    # suelo/colina
    d.ellipse([s(-200), s(770), s(1224), s(1300)], fill=(46, 28, 96, 255))
    return img


def main():
    raiz = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    destino = os.path.join(raiz, "assets", "icon")
    os.makedirs(destino, exist_ok=True)

    figura = dibujar_figura()
    # sombra suave detrás de la figura
    sombra = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    sombra.paste((0, 0, 0, 140), mask=figura.split()[3])
    sombra = sombra.filter(ImageFilter.GaussianBlur(s(10)))

    # Icono completo: la figura ocupa casi todo, ligeramente escalada
    completo = fondo()
    completo.alpha_composite(sombra, (0, s(10)))
    completo.alpha_composite(figura)
    completo.convert("RGB").resize((TAM, TAM), Image.LANCZOS).save(
        os.path.join(destino, "icon.png"))

    # Primer plano adaptativo: el dibujo (bbox ~ 210..889 x 178..800)
    # se escala para caber dentro del 66% central (≈676 px).
    caja = figura.getbbox()
    recorte = figura.crop(caja)
    lado_max = 0.62 * W  # un poco menos del 66% por seguridad
    esc = lado_max / max(recorte.size)
    recorte = recorte.resize((int(recorte.width * esc), int(recorte.height * esc)),
                             Image.LANCZOS)
    fg = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    fg.alpha_composite(recorte, ((W - recorte.width) // 2, (W - recorte.height) // 2))
    fg.resize((TAM, TAM), Image.LANCZOS).save(os.path.join(destino, "icon_fg.png"))
    print("Iconos generados en", destino)


if __name__ == "__main__":
    main()
