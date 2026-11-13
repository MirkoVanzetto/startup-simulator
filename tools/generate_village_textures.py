#!/usr/bin/env python3
"""Genera le texture tileable "dipinte a mano" (stile semi-cartoon) del Borgo San Carlo.

Tutte le texture sono 256x256 RGB, perfettamente tileable (rumore filtrato via FFT,
pattern con indici modulo). Il colore finale viene ulteriormente moltiplicato da
una tinta nello shader toon, quindi molte texture sono quasi neutre.
"""
import os
import numpy as np
from PIL import Image

OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "textures", "village")
S = 256
rng = np.random.default_rng(7)


def noise(beta=2.0, seed=None, size=S):
    r = np.random.default_rng(seed) if seed is not None else rng
    w = r.standard_normal((size, size))
    f = np.fft.fft2(w)
    fx = np.fft.fftfreq(size)[:, None]
    fy = np.fft.fftfreq(size)[None, :]
    d = np.sqrt(fx * fx + fy * fy)
    d[0, 0] = 1.0
    f = f / (d ** (beta / 2.0))
    f[0, 0] = 0
    n = np.real(np.fft.ifft2(f))
    n = (n - n.min()) / (n.max() - n.min() + 1e-9)
    return n


def to_img(a):
    a = np.clip(a, 0, 1)
    return Image.fromarray((a * 255).astype(np.uint8), "RGB")


def save(name, arr):
    os.makedirs(OUT, exist_ok=True)
    to_img(arr).save(os.path.join(OUT, name + ".png"), optimize=True)
    print("ok", name)


def col(hexs):
    h = hexs.lstrip("#")
    return np.array([int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4)])


def blend(base, c, m):
    return base * (1 - m[..., None]) + c * m[..., None]


def plaster(name, base, var=0.06, grain=0.03, seed=1):
    n = noise(2.4, seed)
    g = noise(0.8, seed + 50)
    img = np.ones((S, S, 3)) * col(base)
    img = img * (1.0 + (n[..., None] - 0.5) * var * 2) + (g[..., None] - 0.5) * grain
    save(name, img)


def grid_ids(cell_w, cell_h):
    ys, xs = np.mgrid[0:S, 0:S]
    return xs, ys


def brick():
    bw, bh, mortar = 64, 32, 3
    img = np.zeros((S, S, 3))
    ys, xs = np.mgrid[0:S, 0:S]
    row = ys // bh
    off = (row % 2) * (bw // 2)
    cx = (xs + off) % bw
    cy = ys % bh
    is_mortar = (cx < mortar) | (cy < mortar)
    bid = (((xs + off) // bw) + row * 7) % 13
    palette = [col(c) for c in ["#b5533c", "#a64832", "#c0614a", "#9a4230", "#b85c45", "#a94f3a"]]
    n = noise(1.8, 3)
    for y in range(S):
        for x in range(S):
            if is_mortar[y, x]:
                img[y, x] = col("#cdbfa8") * (0.95 + n[y, x] * 0.1)
            else:
                c = palette[int(bid[y, x]) % len(palette)]
                shade = 0.9 + n[y, x] * 0.2
                edge = min(cx[y, x] - mortar, cy[y, x] - mortar, 4)
                shade *= 0.92 + 0.02 * edge
                img[y, x] = c * shade
    save("brick", img)


def ashlar():
    bw, bh, m = 64, 42, 3
    ys, xs = np.mgrid[0:S, 0:S]
    row = ys // bh
    off = (row % 2) * (bw // 2) + (row % 3) * 11
    cx = (xs + off) % bw
    cy = ys % bh
    bid = (((xs + off) // bw) * 5 + row * 3) % 7
    n = noise(2.0, 11)
    tones = [0.80, 0.86, 0.92, 0.84, 0.95, 0.88, 0.82]
    img = np.zeros((S, S, 3))
    base = col("#c9bda6")
    for y in range(S):
        for x in range(S):
            if cx[y, x] < m or cy[y, x] < m:
                img[y, x] = col("#7d7466") * (0.9 + n[y, x] * 0.2)
            else:
                img[y, x] = base * tones[int(bid[y, x])] * (0.93 + n[y, x] * 0.14)
    save("ashlar", img)


def cobble():
    # voronoi periodico per ciottoli
    pts = 90
    r = np.random.default_rng(21)
    px = r.random(pts) * S
    py = r.random(pts) * S
    ys, xs = np.mgrid[0:S, 0:S]
    best = np.full((S, S), 1e9)
    second = np.full((S, S), 1e9)
    idx = np.zeros((S, S), dtype=int)
    for i in range(pts):
        dx = np.abs(xs - px[i])
        dx = np.minimum(dx, S - dx)
        dy = np.abs(ys - py[i])
        dy = np.minimum(dy, S - dy)
        d = np.sqrt(dx * dx + dy * dy)
        closer = d < best
        second = np.where(closer, best, np.minimum(second, d))
        idx = np.where(closer, i, idx)
        best = np.where(closer, d, best)
    edge = np.clip((second - best) / 7.0, 0, 1)
    tones = r.random(pts) * 0.25 + 0.72
    warm = r.random(pts)
    base_a = col("#a29684")
    base_b = col("#8d8576")
    n = noise(1.5, 5)
    img = np.zeros((S, S, 3))
    for c in range(3):
        img[..., c] = (base_a[c] * warm[idx] + base_b[c] * (1 - warm[idx])) * tones[idx]
    img *= (0.5 + 0.5 * edge[..., None])
    img *= 0.94 + n[..., None] * 0.12
    save("cobble", img)


def asphalt():
    n = noise(1.2, 8)
    g = noise(0.4, 9)
    base = col("#4d4f55")
    img = base * (0.88 + n[..., None] * 0.22) + (g[..., None] - 0.5) * 0.07
    # crepe sottili
    c = noise(3.0, 10)
    mask = (np.abs(c - 0.5) < 0.006).astype(float)
    img = img * (1 - mask[..., None] * 0.35)
    save("asphalt", img)


def slabs():
    sz = 64
    ys, xs = np.mgrid[0:S, 0:S]
    cx, cy = xs % sz, ys % sz
    tid = (xs // sz) * 3 + (ys // sz) * 5
    n = noise(2.0, 12)
    base = col("#b9b4aa")
    img = np.zeros((S, S, 3))
    for c in range(3):
        img[..., c] = base[c] * (0.92 + ((tid % 5) * 0.025)) * (0.95 + n * 0.1)
    joint = ((cx < 2) | (cy < 2))
    img[joint] = col("#7c7870")
    save("slabs", img)


def grass():
    n1 = noise(2.6, 13)
    n2 = noise(1.0, 14)
    a, b = col("#6fae45"), col("#8cc457")
    img = np.zeros((S, S, 3))
    for c in range(3):
        img[..., c] = a[c] * (1 - n1) + b[c] * n1
    img *= 0.9 + n2[..., None] * 0.18
    # ciuffi
    r = np.random.default_rng(15)
    for _ in range(900):
        x, y = r.integers(0, S, 2)
        l = r.integers(2, 5)
        shade = r.choice([0.82, 1.12])
        for k in range(l):
            img[(y - k) % S, x % S] *= shade
    # fiorellini
    for _ in range(26):
        x, y = r.integers(0, S, 2)
        c = col(r.choice(["#fff3b0", "#ffffff", "#f7a8c4", "#ffd34d"]))
        img[y % S, x % S] = c
        img[y % S, (x + 1) % S] = c
    save("grass", img)


def roof_tile(name, base_hex, seed):
    tw, th = 32, 24
    ys, xs = np.mgrid[0:S, 0:S]
    row = ys // th
    off = (row % 2) * (tw // 2)
    cx = (xs + off) % tw
    cy = ys % th
    n = noise(1.8, seed)
    base = col(base_hex)
    tid = ((xs + off) // tw * 3 + row * 5) % 7
    shade_t = np.array([0.88, 0.95, 1.0, 0.92, 1.06, 0.98, 0.9])
    img = np.zeros((S, S, 3))
    for c in range(3):
        img[..., c] = base[c] * shade_t[tid] * (0.92 + n * 0.16)
    # arco inferiore scuro (ombra della tegola)
    shade = np.clip((cy - (th - 7)) / 7.0, 0, 1)
    img *= (1 - shade[..., None] * 0.35)
    # scanalatura verticale
    g = np.abs(cx - tw / 2) / (tw / 2)
    img *= (0.88 + 0.12 * (1 - g[..., None] ** 2))
    img[cx < 1] *= 0.7
    save(name, img)


def planks(name, base_hex, horizontal=True, seed=30, plank=32):
    n = noise(0.9, seed)
    fine = noise(0.3, seed + 1)
    ys, xs = np.mgrid[0:S, 0:S]
    major = ys if horizontal else xs
    minor = xs if horizontal else ys
    pid = major // plank
    cm = major % plank
    base = col(base_hex)
    r = np.random.default_rng(seed)
    tones = r.random(S // plank + 1) * 0.22 + 0.86
    shifts = r.integers(0, S, S // plank + 1)
    img = np.zeros((S, S, 3))
    # venature allungate
    grain = noise(2.2, seed + 2)
    for y in range(S):
        for x in range(S):
            p = int(pid[y, x])
            m = int(minor[y, x])
            gx = (m + shifts[p]) % S
            g = grain[(p * 17) % S, gx] if horizontal else grain[gx, (p * 17) % S]
            if cm[y, x] < 2:
                img[y, x] = base * 0.45
            else:
                img[y, x] = base * tones[p] * (0.9 + g * 0.2)
            # giunti di testa
            if (m + shifts[p]) % 128 < 2:
                img[y, x] = base * 0.5
    img *= 0.96 + fine[..., None] * 0.08
    save(name, img)


def checker(name, c1, c2, cells=4, grout="#d9d2c3"):
    cell = S // cells
    ys, xs = np.mgrid[0:S, 0:S]
    k = ((xs // cell) + (ys // cell)) % 2
    n = noise(1.6, 40)
    img = np.zeros((S, S, 3))
    a, b = col(c1), col(c2)
    for c in range(3):
        img[..., c] = np.where(k == 1, a[c], b[c])
    img *= 0.94 + n[..., None] * 0.1
    cx, cy = xs % cell, ys % cell
    j = (cx < 2) | (cy < 2)
    img[j] = col(grout)
    save(name, img)


def awning(name, c1, c2="#f6f1e6"):
    ys, xs = np.mgrid[0:S, 0:S]
    k = (xs // 32) % 2
    a, b = col(c1), col(c2)
    n = noise(1.0, 50)
    img = np.zeros((S, S, 3))
    for c in range(3):
        img[..., c] = np.where(k == 0, a[c], b[c])
    img *= 0.95 + n[..., None] * 0.07
    save(name, img)


def gravel():
    n = noise(0.6, 60)
    m = noise(1.8, 61)
    base = col("#c2ae8c")
    img = base * (0.82 + n[..., None] * 0.3) * (0.94 + m[..., None] * 0.1)
    save("gravel", img)


def fabric():
    ys, xs = np.mgrid[0:S, 0:S]
    w = ((xs % 4 < 2) ^ (ys % 4 < 2)).astype(float)
    n = noise(1.0, 70)
    img = np.ones((S, S, 3)) * (0.88 + w[..., None] * 0.08) * (0.95 + n[..., None] * 0.08)
    save("fabric", img)


def leaves():
    n1 = noise(2.0, 80)
    n2 = noise(1.0, 81)
    a, b = col("#4f9a3c"), col("#8cc44f")
    img = np.zeros((S, S, 3))
    for c in range(3):
        img[..., c] = a[c] * (1 - n1) + b[c] * n1
    img *= 0.85 + n2[..., None] * 0.3
    save("leaves", img)


def bark():
    n = noise(2.6, 90)
    ys, xs = np.mgrid[0:S, 0:S]
    stripes = (np.sin(xs * 2 * np.pi / 16 * 2 + n * 6) * 0.5 + 0.5)
    base = col("#7a5a3f")
    img = base * (0.7 + stripes[..., None] * 0.4)
    save("bark", img)


if __name__ == "__main__":
    plaster("plaster", "#ffffff", 0.07, 0.025, 1)
    plaster("plaster_rough", "#f4f1ea", 0.12, 0.07, 2)
    brick()
    ashlar()
    cobble()
    asphalt()
    slabs()
    grass()
    roof_tile("roof_terracotta", "#d1673f", 100)
    roof_tile("roof_slate", "#6d7a8c", 101)
    planks("planks_light", "#e2b57c", True, 30)
    planks("planks_dark", "#8a5a36", True, 31)
    checker("tile_check_rc", "#c2362f", "#f4eadb", 4)
    checker("tile_check_gray", "#8a96a3", "#e9edf0", 4, "#f3f3f3")
    checker("tile_check_cafe", "#2f3f4f", "#e8dcc4", 4, "#cfc6b5")
    awning("awning_red", "#c93a34")
    awning("awning_green", "#2f8f5a")
    awning("awning_blue", "#2f6aa8")
    awning("awning_yellow", "#e5a823")
    gravel()
    fabric()
    leaves()
    bark()
