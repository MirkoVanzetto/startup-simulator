#!/usr/bin/env python3
"""Generatore texture PBR seamless 512x512 (Albedo + Normal/Roughness/AO impacchettati)
e carte alpha foliage per Borgo San Carlo / Parco Valentino / Officina Bellini.

Ogni materiale genera:
  - <nome>.png     (512x512 RGB albedo sRGB, seamless periodica)
  - <nome>_pbr.png (512x512 RGBA lineare: R=Nx, G=Ny, B=Roughness, A=AO_cavity)

Esegue in ~2-3s grazie a NumPy completamente vettorizzato (zero loop Python per pixel).
"""
import os
import numpy as np
from PIL import Image, ImageDraw

OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "textures", "village")
S = 512


def fbm(beta=2.0, seed=1, size=S):
    r = np.random.default_rng(seed)
    w = r.standard_normal((size, size))
    f = np.fft.fft2(w)
    fx = np.fft.fftfreq(size)[:, None]
    fy = np.fft.fftfreq(size)[None, :]
    d = np.sqrt(fx * fx + fy * fy)
    d[0, 0] = 1.0
    f = f / (d ** (beta / 2.0))
    f[0, 0] = 0.0
    n = np.real(np.fft.ifft2(f))
    n = (n - n.min()) / (n.max() - n.min() + 1e-9)
    return n.astype(np.float32)


def col(hexs):
    h = hexs.lstrip("#")
    return np.array([int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4)], dtype=np.float32)


def save_rgb(name, arr):
    os.makedirs(OUT, exist_ok=True)
    img = Image.fromarray((np.clip(arr, 0.0, 1.0) * 255.0).astype(np.uint8), "RGB")
    img.save(os.path.join(OUT, name + ".png"), optimize=False)


def save_rgba(name, arr):
    os.makedirs(OUT, exist_ok=True)
    img = Image.fromarray((np.clip(arr, 0.0, 1.0) * 255.0).astype(np.uint8), "RGBA")
    img.save(os.path.join(OUT, name + ".png"), optimize=False)


def height_to_pbr(height, rough, ao, strength=2.6):
    # Wrapped Sobel derivatives on periodic height field [0..1]
    h = height.astype(np.float32)
    gx = (
        np.roll(h, -1, axis=1) - np.roll(h, 1, axis=1)
        + 0.5 * (np.roll(np.roll(h, -1, axis=0), -1, axis=1) - np.roll(np.roll(h, -1, axis=0), 1, axis=1))
        + 0.5 * (np.roll(np.roll(h, 1, axis=0), -1, axis=1) - np.roll(np.roll(h, 1, axis=0), 1, axis=1))
    ) * 0.5
    gy = (
        np.roll(h, -1, axis=0) - np.roll(h, 1, axis=0)
        + 0.5 * (np.roll(np.roll(h, -1, axis=0), -1, axis=1) - np.roll(np.roll(h, 1, axis=0), -1, axis=1))
        + 0.5 * (np.roll(np.roll(h, -1, axis=0), 1, axis=1) - np.roll(np.roll(h, 1, axis=0), 1, axis=1))
    ) * 0.5
    nx = -gx * strength
    ny = -gy * strength
    nz = np.ones_like(nx)
    inv = 1.0 / np.sqrt(nx * nx + ny * ny + nz * nz + 1e-8)
    nx *= inv
    ny *= inv

    pbr = np.empty((S, S, 4), dtype=np.float32)
    pbr[..., 0] = np.clip(nx * 0.5 + 0.5, 0.0, 1.0)
    pbr[..., 1] = np.clip(ny * 0.5 + 0.5, 0.0, 1.0)
    pbr[..., 2] = np.clip(rough, 0.05, 1.0)
    pbr[..., 3] = np.clip(ao, 0.25, 1.0)
    return pbr


def save_mat(name, albedo, height, rough, ao, n_strength=2.6):
    save_rgb(name, albedo)
    save_rgba(name + "_pbr", height_to_pbr(height, rough, ao, n_strength))
    print("ok", name)


def _voronoi_periodic(pts_count, seed, jitter=0.82):
    r = np.random.default_rng(seed)
    grid = int(np.sqrt(pts_count))
    actual = grid * grid
    cell = S / grid
    px = []
    py = []
    for gy in range(grid):
        for gx in range(grid):
            px.append((gx + 0.5 + (r.random() - 0.5) * jitter) * cell)
            py.append((gy + 0.5 + (r.random() - 0.5) * jitter) * cell)
    px = np.array(px, dtype=np.float32) % S
    py = np.array(py, dtype=np.float32) % S

    ys, xs = np.mgrid[0:S, 0:S].astype(np.float32)
    best = np.full((S, S), 1e9, dtype=np.float32)
    second = np.full((S, S), 1e9, dtype=np.float32)
    idx = np.zeros((S, S), dtype=np.int32)

    # Chunk across points for low peak RAM and high NumPy vector speed
    for i in range(actual):
        dx = np.abs(xs - px[i])
        dx = np.minimum(dx, S - dx)
        dy = np.abs(ys - py[i])
        dy = np.minimum(dy, S - dy)
        d = np.sqrt(dx * dx + dy * dy)
        closer = d < best
        second = np.where(closer, best, np.minimum(second, d))
        idx = np.where(closer, i, idx)
        best = np.where(closer, d, best)
    return best, second, idx, actual


# ---------------------------------------------------------------------- Intonaci & Cemento
def make_plaster(name, base_hex, var=0.10, grain=0.04, seed=1, n_str=1.6, rough_base=0.86):
    n_low = fbm(2.5, seed)
    n_mid = fbm(1.6, seed + 17)
    n_fine = fbm(0.7, seed + 37)
    img = np.ones((S, S, 3), dtype=np.float32) * col(base_hex)
    shade = 1.0 + (n_low - 0.5) * var * 2.0 + (n_mid - 0.5) * var * 1.1 + (n_fine - 0.5) * grain * 2.0
    img *= shade[..., None]
    height = 0.55 * n_mid + 0.45 * n_fine
    rough = np.clip(rough_base + (n_low - 0.5) * 0.14 - (n_mid - 0.5) * 0.06, 0.55, 0.98)
    ao = np.clip(0.84 + 0.16 * n_low, 0.68, 1.0)
    save_mat(name, img, height, rough, ao, n_str)


# ---------------------------------------------------------------------- Mattoni & Muri Giardino
def _brick_fields(bw=128, bh=56, mortar=5, seed=3):
    # Ensure exact tiling: 512 / 128 = 4 cols, adjust row height close to S divisor -> 64 (8 rows)!
    ys, xs = np.mgrid[0:S, 0:S]
    row = ys // bh
    off = (row % 2) * (bw // 2)
    cx = (xs + off) % bw
    cy = ys % bh
    n_edge = fbm(1.3, seed + 5)
    warp = (n_edge - 0.5) * 2.6
    is_mortar = (cx + warp < mortar) | (cy + warp < mortar) | (cx + warp > bw - 1.5) | (cy + warp > bh - 1.5)
    bid = ((xs + off) // bw) * 13 + row * 29

    dist_x = np.minimum(cx - mortar, bw - 1.5 - cx)
    dist_y = np.minimum(cy - mortar, bh - 1.5 - cy)
    bevel = np.clip(np.minimum(dist_x, dist_y) / 6.0, 0.0, 1.0)
    n_tex = fbm(1.7, seed)
    n_fine = fbm(0.6, seed + 12)

    palette = np.array([
        col("#9a4c3a"), col("#8a4131"), col("#a75743"),
        col("#7e392b"), col("#9e4f3c"), col("#8f4635"), col("#ad5f4a")
    ], dtype=np.float32)
    r = np.random.default_rng(seed + 99)
    tone_lut = r.uniform(0.86, 1.12, 512).astype(np.float32)
    bcol = palette[bid % len(palette)] * tone_lut[bid % 512][..., None]
    bcol *= (0.86 + 0.24 * n_tex + 0.10 * n_fine)[..., None]

    mortar_col = col("#b4a892") * (0.86 + 0.22 * n_fine[..., None])
    albedo = np.where(is_mortar[..., None], mortar_col, bcol * (0.88 + 0.12 * bevel[..., None]))
    height = np.where(is_mortar, 0.18 + 0.14 * n_fine, 0.55 + 0.28 * bevel + 0.15 * n_tex)
    rough = np.where(is_mortar, 0.96, 0.86 + (n_fine - 0.5) * 0.10)
    ao = np.where(is_mortar, 0.52 + 0.18 * n_fine, 0.72 + 0.28 * bevel)
    return albedo, height, rough, ao


def make_brick():
    albedo, height, rough, ao = _brick_fields(128, 64, 5, seed=3)
    save_mat("brick", albedo, height, rough, ao, 3.4)


def make_wall_garden():
    # Muro piemontese consumato: intonaco chiaro scrostato su mattoni a vista (Ref 1 e Ref 5!)
    b_alb, b_h, b_r, b_ao = _brick_fields(128, 64, 5, seed=31)
    n_mask = fbm(2.3, 404)
    n_detail = fbm(1.1, 405)
    n_damp = fbm(2.7, 406)

    plaster_mask = np.clip((n_mask * 0.76 + n_detail * 0.24 - 0.35) * 5.0, 0.0, 1.0)
    rim_crack = np.clip(1.0 - np.abs(plaster_mask - 0.5) * 2.3, 0.0, 1.0)

    plaster_col = col("#c8bda8") * (0.86 + 0.22 * n_detail + 0.10 * n_damp)[..., None]
    plaster_col *= (1.0 - rim_crack[..., None] * 0.18)

    albedo = b_alb * (1.0 - plaster_mask[..., None]) + plaster_col * plaster_mask[..., None]
    height = b_h * (1.0 - plaster_mask) + (0.76 + 0.18 * n_detail) * plaster_mask
    height -= rim_crack * 0.12
    rough = b_r * (1.0 - plaster_mask) + 0.90 * plaster_mask
    ao = np.clip(b_ao * (1.0 - plaster_mask) + (0.86 - 0.25 * rim_crack + 0.12 * n_damp) * plaster_mask, 0.38, 1.0)
    save_mat("wall_garden", albedo, height, rough, ao, 3.3)


def make_ashlar():
    bw, bh, m = 128, 64, 4
    ys, xs = np.mgrid[0:S, 0:S]
    row = ys // bh
    off = (row % 2) * (bw // 2)
    cx = (xs + off) % bw
    cy = ys % bh
    bid = ((xs + off) // bw) * 7 + row * 11
    n = fbm(1.9, 11)
    nf = fbm(0.6, 12)
    is_mortar = (cx < m) | (cy < m) | (cx > bw - 2) | (cy > bh - 2)
    dist = np.minimum(np.minimum(cx - m, bw - 2 - cx), np.minimum(cy - m, bh - 2 - cy))
    bevel = np.clip(dist / 8.0, 0.0, 1.0)

    tones = np.array([0.84, 0.91, 0.97, 0.87, 1.0, 0.93, 0.86], dtype=np.float32)
    base = col("#bfb39d")
    stone = base * tones[bid % 7][..., None] * (0.90 + n * 0.16 + (nf - 0.5) * 0.08)[..., None]
    mortar = col("#6d6559") * (0.88 + nf[..., None] * 0.22)
    albedo = np.where(is_mortar[..., None], mortar, stone * (0.90 + 0.10 * bevel[..., None]))
    height = np.where(is_mortar, 0.16, 0.56 + 0.28 * bevel + 0.14 * n)
    rough = np.where(is_mortar, 0.95, 0.80 + (nf - 0.5) * 0.10)
    ao = np.where(is_mortar, 0.45, 0.72 + 0.28 * bevel)
    save_mat("ashlar", albedo, height, rough, ao, 3.0)


# ---------------------------------------------------------------------- Strade, Ciottoli, Lastre & Asfalto
def make_cobble():
    # Ciottoli San Carlo realistici stile Ref 4: pietre irregolari calde/grigie, fughe morbide
    best, second, idx, actual = _voronoi_periodic(169, seed=21, jitter=0.78)
    edge_dist = second - best
    joint = 1.0 - np.clip(edge_dist / 5.2, 0.0, 1.0)
    dome = np.clip(edge_dist / 12.5, 0.0, 1.0) ** 0.55

    r = np.random.default_rng(22)
    tones = r.uniform(0.76, 1.06, actual).astype(np.float32)
    warm = r.uniform(0.0, 1.0, actual).astype(np.float32)

    col_warm = col("#988b78")
    col_cool = col("#7f786e")
    col_slate = col("#706b64")
    stone_col = np.empty((actual, 3), dtype=np.float32)
    for k in range(actual):
        mix_w = warm[k]
        base = col_warm * mix_w + col_cool * (1.0 - mix_w)
        if k % 5 == 0:
            base = base * 0.6 + col_slate * 0.4
        stone_col[k] = base * tones[k]

    n = fbm(1.5, 25)
    nf = fbm(0.6, 26)
    n_moss = fbm(2.2, 27)
    albedo = stone_col[idx] * (0.86 + 0.22 * n + (nf - 0.5) * 0.10)[..., None]

    grout_col = col("#49443c") * (0.84 + nf[..., None] * 0.28)
    moss_mask = np.clip((joint - 0.45) * 1.8, 0.0, 1.0) * np.clip((n_moss - 0.55) * 3.5, 0.0, 1.0)
    grout_col = grout_col * (1.0 - moss_mask[..., None]) + col("#536835") * moss_mask[..., None]

    albedo = albedo * (1.0 - joint[..., None] * 0.78) + grout_col * (joint[..., None] * 0.78)
    height = (1.0 - joint) * (0.45 + 0.42 * dome + 0.12 * nf)
    rough = np.where(joint > 0.5, 0.95, 0.74 + (1.0 - dome) * 0.14 + (nf - 0.5) * 0.08)
    ao = np.clip(0.40 + 0.60 * (1.0 - joint) * (0.65 + 0.35 * dome), 0.35, 1.0)
    save_mat("cobble", albedo, height, rough, ao, 3.6)


def make_slabs():
    # Lastre Pietra di Luserna / Cordoli in granito smussati (Ref 5)
    sz = 128
    ys, xs = np.mgrid[0:S, 0:S]
    cx, cy = xs % sz, ys % sz
    tid = (xs // sz) * 5 + (ys // sz) * 7
    n = fbm(1.8, 12)
    nf = fbm(0.6, 13)
    r = np.random.default_rng(14)
    tones = r.uniform(0.88, 1.06, 64).astype(np.float32)

    dist = np.minimum(np.minimum(cx, sz - 1 - cx), np.minimum(cy, sz - 1 - cy))
    joint = (cx < 3) | (cy < 3)
    chamfer = np.clip((dist - 2.0) / 7.0, 0.0, 1.0)

    stone = col("#a39c92") * tones[tid % 64][..., None] * (0.90 + n * 0.15 + (nf - 0.5) * 0.09)[..., None]
    albedo = np.where(joint[..., None], col("#56524b"), stone * (0.91 + 0.09 * chamfer[..., None]))
    height = np.where(joint, 0.26, 0.64 + 0.20 * chamfer + 0.06 * nf)
    rough = np.where(joint, 0.94, 0.80 + (nf - 0.5) * 0.06)
    ao = np.where(joint, 0.48, 0.78 + 0.22 * chamfer)
    save_mat("slabs", albedo, height, rough, ao, 1.35)


def make_asphalt():
    # Asfalto urbano naturale e regolare senza aliasing a bassa inclinazione
    n_macro = fbm(2.2, 8)
    n_grit = fbm(0.85, 9)
    n_pebble = fbm(0.55, 19)
    base = col("#44474d")
    albedo = base * (0.88 + 0.16 * n_macro + (n_grit - 0.5) * 0.12)[..., None]
    speck = (n_pebble > 0.78).astype(np.float32) * 0.06
    albedo += speck[..., None]

    c1 = fbm(2.9, 10)
    c2 = fbm(2.8, 11)
    crack = np.clip(1.0 - np.abs(c1 - 0.50) / 0.011, 0.0, 1.0)
    crack = np.maximum(crack, np.clip(1.0 - np.abs(c2 - 0.48) / 0.008, 0.0, 1.0) * 0.65)
    albedo = albedo * (1.0 - crack[..., None] * 0.36)

    height = 0.55 + (n_macro - 0.5) * 0.14 + (n_grit - 0.5) * 0.08 - crack * 0.22
    rough = np.clip(0.88 + (n_macro - 0.5) * 0.08 + crack * 0.08, 0.76, 0.98)
    ao = np.clip(0.90 - crack * 0.32 + (n_grit - 0.5) * 0.08, 0.48, 1.0)
    save_mat("asphalt", albedo, height, rough, ao, 0.95)


def make_gravel():
    # Ghiaietto spezzato chiaro e terra battuta calda stile Parco Valentino (rilievo profondo v1.4)
    best, second, idx, actual = _voronoi_periodic(625, seed=64, jitter=0.90)
    r = np.random.default_rng(65)
    tone = r.uniform(0.72, 1.22, actual).astype(np.float32)
    cool_mix = r.uniform(0.0, 1.0, actual).astype(np.float32)
    peb_lut = np.empty((actual, 3), dtype=np.float32)
    c_warm, c_cool, c_slate = col("#b4a38c"), col("#8f877b"), col("#776e62")
    for k in range(actual):
        base = c_warm * cool_mix[k] + c_cool * (1.0 - cool_mix[k])
        if k % 6 == 0:
            base = base * 0.65 + c_slate * 0.35
        peb_lut[k] = base * tone[k]

    n_low = fbm(2.2, 60)
    n_mid = fbm(0.75, 61)
    n_fine = fbm(0.45, 62)
    edge = np.clip((second - best) / 5.4, 0.0, 1.0)
    dome = edge ** 0.62
    soil = col("#826d51") * (0.82 + 0.28 * n_low[..., None])
    peb = peb_lut[idx] * (0.86 + 0.22 * n_mid + (n_fine - 0.5) * 0.10)[..., None]
    peb_blend = np.clip(0.38 + dome * 0.62, 0.0, 1.0)[..., None]

    albedo = soil * (1.0 - peb_blend * 0.78) + peb * (peb_blend * 0.78)
    height = 0.24 + 0.56 * dome + (n_mid - 0.5) * 0.14
    rough = np.clip(0.92 + (1.0 - dome) * 0.06, 0.80, 0.98)
    ao = np.clip(0.50 + 0.50 * dome, 0.38, 1.0)
    save_mat("gravel", albedo, height, rough, ao, 2.2)


def make_grass():
    # Prato naturale italiano uniforme e privo di righe di Moire a lunga distanza
    n1 = fbm(2.3, 13)
    n2 = fbm(1.1, 14)
    n3 = fbm(0.65, 15)
    c_deep = col("#375222")
    c_warm = col("#536e2f")
    c_dry = col("#6b7039")
    img = c_deep * (1.0 - n1[..., None]) + c_warm * n1[..., None]
    dry_m = np.clip((n2 - 0.58) * 2.1, 0.0, 0.42)[..., None]
    img = img * (1.0 - dry_m) + c_dry * dry_m
    img *= (0.86 + 0.26 * n3)[..., None]

    height = 0.42 + 0.36 * n1 + 0.18 * n2
    rough = np.clip(0.94 + (n2 - 0.5) * 0.04, 0.86, 0.99)
    ao = np.clip(0.76 + 0.24 * n2, 0.62, 1.0)
    save_mat("grass", img, height, rough, ao, 0.75)


# ---------------------------------------------------------------------- Tetti (Coppi e Lose)
def make_roof_tile(name, base_hex, dark_hex, seed):
    tw, th = 64, 64
    ys, xs = np.mgrid[0:S, 0:S]
    row = ys // th
    off = (row % 2) * (tw // 2)
    cx = (xs + off) % tw
    cy = ys % th
    tid = ((xs + off) // tw * 3 + row * 7) % 11
    n = fbm(1.7, seed)
    nf = fbm(0.6, seed + 1)

    r = np.random.default_rng(seed + 5)
    shades = r.uniform(0.82, 1.12, 11).astype(np.float32)
    base = col(base_hex)
    dark = col(dark_hex)
    tile = base * shades[tid][..., None] * (0.88 + 0.20 * n + (nf - 0.5) * 0.10)[..., None]

    curve = 1.0 - ((cx - tw * 0.5) / (tw * 0.5)) ** 2
    lip = np.clip((cy - (th - 12)) / 12.0, 0.0, 1.0)
    seam = (cx < 2) | (cy > th - 3)
    albedo = np.where(seam[..., None], dark * 0.75, tile * (0.82 + 0.18 * curve[..., None]) * (1.0 - lip[..., None] * 0.35))
    height = np.where(seam, 0.14, 0.40 + 0.45 * curve * (1.0 - 0.35 * lip))
    rough = np.clip(0.82 + (nf - 0.5) * 0.10, 0.65, 0.95)
    ao = np.clip(0.45 + 0.55 * (1.0 - lip) * (0.55 + 0.45 * curve), 0.35, 1.0)
    save_mat(name, albedo, height, rough, ao, 3.6)


# ---------------------------------------------------------------------- Legno & Pavimenti Interni
def make_planks(name, base_hex, dark_hex, seed=30, plank=32, seam_w=2):
    ys, xs = np.mgrid[0:S, 0:S]
    pid = ys // plank
    cm = ys % plank
    r = np.random.default_rng(seed)
    tones = r.uniform(0.88, 1.12, S // plank + 2).astype(np.float32)
    shifts = r.integers(0, S, S // plank + 2)
    head_off = r.integers(48, S - 48, S // plank + 2)

    # Venatura lunga continua lungo X (asse assi in rovere/noce, zero effetto mattoni!)
    g_raw = fbm(2.3, seed + 2)
    fine = fbm(0.6, seed + 3)
    x_shift = (xs + shifts[pid]) % S
    y_band = (pid * 29 + cm) % S
    grain_v = g_raw[y_band, x_shift]
    cathedral = np.sin(grain_v * 14.0 + cm * 0.32) * 0.5 + 0.5

    head_joint = ((xs + head_off[pid]) % 512) < seam_w
    side_joint = (cm < seam_w)
    is_joint = side_joint | head_joint
    dist_y = np.minimum(cm - seam_w, plank - 1 - cm)
    bevel = np.clip(dist_y / 3.5, 0.0, 1.0)

    base = col(base_hex)
    seam_c = col(dark_hex)
    wood = base * tones[pid][..., None] * (0.88 + 0.16 * cathedral + (fine - 0.5) * 0.07)[..., None]
    albedo = np.where(is_joint[..., None], seam_c, wood * (0.94 + 0.06 * bevel[..., None]))
    height = np.where(is_joint, 0.38, 0.68 + 0.18 * bevel + 0.08 * cathedral)
    rough = np.where(is_joint, 0.88, 0.56 + (1.0 - cathedral) * 0.14)
    ao = np.where(is_joint, 0.62, 0.86 + 0.14 * bevel)
    save_mat(name, albedo, height, rough, ao, 1.45)


def make_marble_dark():
    # Piano banco Forno Bruno: marmo antracite scuro venato (Ref 3!)
    n1 = fbm(2.4, 71)
    n2 = fbm(1.6, 72)
    nf = fbm(0.8, 73)
    vein1 = np.clip(1.0 - np.abs(np.sin(n1 * 12.0 + n2 * 5.0)) / 0.16, 0.0, 1.0) ** 2.2
    vein2 = np.clip(1.0 - np.abs(np.sin(n2 * 16.0 - n1 * 4.0)) / 0.12, 0.0, 1.0) ** 3.0

    base = col("#282c30") * (0.86 + 0.26 * n1 + (nf - 0.5) * 0.08)[..., None]
    vcol = col("#b8b3aa")
    albedo = base * (1.0 - vein1[..., None] * 0.58) + vcol * (vein1[..., None] * 0.58)
    albedo = albedo * (1.0 - vein2[..., None] * 0.35) + col("#d8d2c7") * (vein2[..., None] * 0.35)

    height = 0.72 + 0.10 * nf - vein1 * 0.08
    rough = np.clip(0.24 + (n2 - 0.5) * 0.08 + vein1 * 0.05, 0.14, 0.42)
    ao = np.clip(0.90 + 0.10 * nf, 0.80, 1.0)
    save_mat("marble_dark", albedo, height, rough, ao, 1.2)


def make_checker(name, c1_hex, c2_hex, cells=4, grout_hex="#c8c2b8", scuff=0.06, seed=40):
    cell = S // cells
    ys, xs = np.mgrid[0:S, 0:S]
    k = ((xs // cell) + (ys // cell)) % 2
    cx, cy = xs % cell, ys % cell
    tid = (xs // cell) * 3 + (ys // cell) * 5
    n = fbm(1.8, seed)
    nf = fbm(0.9, seed + 1)
    n_scuff = fbm(1.4, seed + 2)

    r = np.random.default_rng(seed + 5)
    t_var = r.uniform(0.95, 1.04, 64).astype(np.float32)

    a, b = col(c1_hex), col(c2_hex)
    tile = np.where(k[..., None] == 1, a, b) * t_var[tid % 64][..., None]
    tile *= (0.94 + 0.08 * n + (n_scuff - 0.5) * scuff)[..., None]

    dist = np.minimum(np.minimum(cx, cell - 1 - cx), np.minimum(cy, cell - 1 - cy))
    joint = (cx < 4) | (cy < 4)
    chamfer = np.clip((dist - 3.0) / 7.0, 0.0, 1.0)

    albedo = np.where(joint[..., None], col(grout_hex) * (0.88 + 0.18 * nf[..., None]), tile)
    height = np.where(joint, 0.38, 0.74 + 0.12 * chamfer)
    rough = np.where(joint, 0.90, np.clip(0.58 + (n_scuff - 0.5) * 0.10 + (1.0 - chamfer) * 0.12, 0.48, 0.78))
    ao = np.where(joint, 0.64, 0.88 + 0.12 * chamfer)
    save_mat(name, albedo, height, rough, ao, 1.15)


def make_concrete_ogr():
    # Calcestruzzo industriale levigato a grandi lastre con giunti morbidi (zero aliasing da riflessi!)
    sz = 256
    ys, xs = np.mgrid[0:S, 0:S]
    cx, cy = xs % sz, ys % sz
    tid = (xs // sz) * 5 + (ys // sz) * 7
    n_trowel = fbm(2.3, 140)
    n_mid = fbm(1.3, 141)
    n_fine = fbm(0.75, 142)
    n_sheen = fbm(2.7, 143)

    r = np.random.default_rng(144)
    tones = r.uniform(0.94, 1.04, 16).astype(np.float32)

    dist = np.minimum(np.minimum(cx, sz - 1 - cx), np.minimum(cy, sz - 1 - cy))
    joint = (cx < 4) | (cy < 4)
    chamfer = np.clip((dist - 3.0) / 6.0, 0.0, 1.0)

    base = col("#9ba0a6") * tones[tid % 16][..., None]
    base *= (0.88 + 0.16 * n_trowel + 0.06 * n_mid + (n_fine - 0.5) * 0.08)[..., None]
    speck = (n_fine > 0.78).astype(np.float32) * 0.035 - (n_fine < 0.22).astype(np.float32) * 0.035
    base = np.clip(base + speck[..., None], 0.14, 0.96)

    joint_col = col("#5a6067") * (0.90 + 0.14 * n_fine[..., None])
    albedo = np.where(joint[..., None], joint_col, base * (0.95 + 0.05 * chamfer[..., None]))
    height = np.where(joint, 0.34, 0.66 + 0.14 * chamfer + (n_trowel - 0.5) * 0.08)
    slab_rough = np.clip(0.56 + (n_sheen - 0.5) * 0.18 + (1.0 - chamfer) * 0.10, 0.44, 0.78)
    rough = np.where(joint, 0.92, slab_rough)
    ao = np.where(joint, 0.56, 0.84 + 0.16 * chamfer)
    save_mat("concrete_ogr", albedo, height, rough, ao, 1.15)


def make_corrugated_metal():
    ys, xs = np.mgrid[0:S, 0:S]
    wave = np.sin(xs * 2.0 * np.pi / 32.0) * 0.5 + 0.5
    n = fbm(1.5, 91)
    nf = fbm(0.6, 92)
    albedo = col("#9aa2aa") * (0.84 + 0.22 * wave + (n - 0.5) * 0.14)[..., None]
    height = 0.25 + 0.65 * wave + (nf - 0.5) * 0.08
    rough = np.clip(0.36 + (n - 0.5) * 0.14, 0.22, 0.58)
    ao = np.clip(0.62 + 0.38 * wave, 0.50, 1.0)
    save_mat("corrugated_metal", albedo, height, rough, ao, 3.0)


# ---------------------------------------------------------------------- Tessuti, Corteccia, Pane, Cesti
def make_awning(name, c1_hex, c2_hex="#f3ecde", seed=50):
    ys, xs = np.mgrid[0:S, 0:S]
    k = (xs // 64) % 2
    cx = xs % 64
    seam = (cx < 2) | (cx > 62)
    weave = ((xs % 4 < 2) ^ (ys % 4 < 2)).astype(np.float32)
    n = fbm(1.4, seed)
    a, b = col(c1_hex), col(c2_hex)
    albedo = np.where(k[..., None] == 0, a, b) * (0.90 + 0.07 * weave + 0.08 * n)[..., None]
    albedo = np.where(seam[..., None], albedo * 0.78, albedo)
    height = 0.60 + 0.18 * weave - seam.astype(np.float32) * 0.25
    rough = np.full((S, S), 0.86, dtype=np.float32)
    ao = np.where(seam, 0.62, 0.90 + 0.10 * weave)
    save_mat(name, albedo, height, rough, ao, 1.6)


def make_fabric(name, base_hex="#f2f0ec", weave_step=4, seed=70):
    ys, xs = np.mgrid[0:S, 0:S]
    w = ((xs % weave_step < weave_step // 2) ^ (ys % weave_step < weave_step // 2)).astype(np.float32)
    n = fbm(1.4, seed)
    nf = fbm(0.5, seed + 1)
    albedo = col(base_hex) * (0.86 + 0.10 * w + (n - 0.5) * 0.14 + (nf - 0.5) * 0.08)[..., None]
    height = 0.50 + 0.26 * w + (nf - 0.5) * 0.14
    rough = np.clip(0.88 + (n - 0.5) * 0.08, 0.75, 0.98)
    ao = np.clip(0.82 + 0.18 * w, 0.70, 1.0)
    save_mat(name, albedo, height, rough, ao, 1.8)


def make_wicker():
    ys, xs = np.mgrid[0:S, 0:S]
    cw, ch = 32, 16
    cell_x, cell_y = xs // cw, ys // ch
    in_x, in_y = xs % cw, ys % ch
    horiz = ((cell_x + cell_y) % 2) == 0
    arc_h = np.sin(in_x * np.pi / cw) * (1.0 - np.abs(in_y - ch * 0.5) / (ch * 0.52))
    arc_v = np.sin(in_y * np.pi / ch) * (1.0 - np.abs(in_x - cw * 0.5) / (cw * 0.52))
    arc = np.clip(np.where(horiz, arc_h, arc_v), 0.0, 1.0)
    n = fbm(1.2, 85)
    albedo = col("#9e6e3e") * (0.62 + 0.54 * arc + (n - 0.5) * 0.14)[..., None]
    height = 0.22 + 0.75 * arc
    rough = np.clip(0.82 - arc * 0.10, 0.65, 0.95)
    ao = np.clip(0.42 + 0.58 * arc, 0.35, 1.0)
    save_mat("wicker", albedo, height, rough, ao, 3.2)


def make_bark():
    ys, xs = np.mgrid[0:S, 0:S]
    n_low = fbm(2.5, 90)
    n_fine = fbm(0.8, 91)
    ridge = np.sin(xs * 2.0 * np.pi / 28.0 + n_low * 9.0 + np.sin(ys * 2.0 * np.pi / 128.0) * 1.4)
    ridge = np.clip(ridge * 0.5 + 0.5, 0.0, 1.0) ** 1.3
    c_crevice = col("#38291d")
    c_outer = col("#6b523b")
    albedo = c_crevice * (1.0 - ridge[..., None]) + c_outer * ridge[..., None]
    albedo *= (0.86 + 0.24 * n_fine)[..., None]
    height = 0.20 + 0.65 * ridge + 0.14 * n_fine
    rough = np.full((S, S), 0.92, dtype=np.float32)
    ao = np.clip(0.38 + 0.62 * ridge, 0.30, 1.0)
    save_mat("bark", albedo, height, rough, ao, 3.6)


def make_bread_crust():
    n_low = fbm(2.1, 95)
    n_mid = fbm(1.2, 97)
    n_fine = fbm(0.6, 96)
    c_bake = col("#c47c32")
    c_dark = col("#7f4216")
    c_flour = col("#ede3ce")
    albedo = c_dark * (1.0 - n_low[..., None]) + c_bake * n_low[..., None]
    # Piccoli rilievi dorati e lieve spolverata naturale di farina sulle spalle della pagnotta
    blister = np.clip((n_mid - 0.64) * 3.0, 0.0, 0.22)[..., None]
    albedo = albedo * (1.0 - blister) + col("#6c340f") * blister
    flour = np.clip((n_low * 0.55 + n_fine * 0.45 - 0.60) * 3.4, 0.0, 0.64)[..., None]
    albedo = albedo * (1.0 - flour) + c_flour * flour
    height = 0.46 + 0.32 * n_low + 0.20 * n_fine
    rough = np.clip(0.72 + flour[..., 0] * 0.24, 0.62, 0.96)
    ao = np.clip(0.72 + 0.28 * n_low, 0.56, 1.0)
    save_mat("bread_crust", albedo, height, rough, ao, 2.2)


def make_leaves_bg():
    # Fallback canopy base texture
    n1 = fbm(2.0, 80)
    n2 = fbm(1.0, 81)
    a, b = col("#3f6e29"), col("#739c3b")
    albedo = a * (1.0 - n1[..., None]) + b * n1[..., None]
    albedo *= (0.84 + 0.28 * n2)[..., None]
    save_mat("leaves", albedo, 0.5 * n1 + 0.5 * n2, np.full((S, S), 0.72), 0.72 + 0.28 * n1, 1.8)


# ---------------------------------------------------------------------- Carte Alpha Foliage (Alberi & Erba/Fiori)
def _dilate_rgb_into_transparent(rgba):
    # Pre-dilata i pixel opachi verso quelli trasparenti per eliminare aloni scuri nei mipmap
    a = rgba[..., 3]
    rgb = rgba[..., :3].copy()
    mask = a > 16
    for _ in range(10):
        empty = ~mask
        if not np.any(empty):
            break
        acc = np.zeros_like(rgb, dtype=np.float32)
        cnt = np.zeros((rgb.shape[0], rgb.shape[1]), dtype=np.float32)
        for dy, dx in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
            m_n = np.roll(np.roll(mask, dy, axis=0), dx, axis=1)
            r_n = np.roll(np.roll(rgb, dy, axis=0), dx, axis=1).astype(np.float32)
            acc += r_n * m_n[..., None]
            cnt += m_n
        fill = empty & (cnt > 0)
        if not np.any(fill):
            break
        rgb[fill] = (acc[fill] / cnt[fill, None]).astype(np.uint8)
        mask = mask | fill
    out = rgba.copy()
    out[..., :3] = rgb
    return out


def make_leaf_cluster():
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    r = np.random.default_rng(301)

    # Rametti scuri nascosti tra le foglie
    stems = [
        [(256, 465), (256, 260), (256, 145)],
        [(256, 355), (175, 265), (128, 210)],
        [(256, 335), (338, 245), (384, 198)],
        [(256, 240), (195, 165), (165, 130)],
        [(256, 225), (320, 158), (350, 126)],
    ]
    for st in stems:
        draw.line(st, fill=(76, 56, 38, 255), width=7)

    # 68 foglie realistiche stratificate (ombra profonda -> medio -> cime soleggiate)
    centers = []
    for _ in range(74):
        cx = int(r.normal(256, 86))
        cy = int(r.normal(246, 86))
        if 44 < cx < S - 44 and 44 < cy < S - 44:
            centers.append((cx, cy))

    for idx, (cx, cy) in enumerate(centers):
        ang = r.uniform(-np.pi, np.pi)
        length = r.uniform(44, 76)
        width = length * r.uniform(0.46, 0.62)
        tone = idx / max(1, len(centers))
        # Tavolozza foglie mediterranee realistiche: verde bosco profondo -> oliva chiaro dorato
        if tone < 0.34:
            leaf_col = (int(r.integers(52, 72)), int(r.integers(88, 114)), int(r.integers(32, 48)), 255)
        elif tone < 0.72:
            leaf_col = (int(r.integers(74, 102)), int(r.integers(120, 152)), int(r.integers(40, 60)), 255)
        else:
            leaf_col = (int(r.integers(106, 138)), int(r.integers(150, 178)), int(r.integers(50, 72)), 255)
        vein_col = (min(255, leaf_col[0] + 22), min(255, leaf_col[1] + 20), min(255, leaf_col[2] + 10), 255)

        ca, sa = np.cos(ang), np.sin(ang)
        pts = []
        for t in np.linspace(0.0, 1.0, 14):
            lx = (t - 0.35) * length
            w_p = np.sin(t * np.pi) ** 0.75 * width * (1.0 - 0.25 * t)
            pts.append((cx + lx * ca - w_p * sa, cy + lx * sa + w_p * ca))
        for t in np.linspace(1.0, 0.0, 14):
            lx = (t - 0.35) * length
            w_p = -np.sin(t * np.pi) ** 0.75 * width * (1.0 - 0.25 * t)
            pts.append((cx + lx * ca - w_p * sa, cy + lx * sa + w_p * ca))
        draw.polygon(pts, fill=leaf_col)
        p0 = (cx - 0.32 * length * ca, cy - 0.32 * length * sa)
        p1 = (cx + 0.56 * length * ca, cy + 0.56 * length * sa)
        draw.line([p0, p1], fill=vein_col, width=2)

    arr = _dilate_rgb_into_transparent(np.array(img, dtype=np.uint8))
    Image.fromarray(arr, "RGBA").save(os.path.join(OUT, "leaf_cluster.png"))
    print("ok leaf_cluster")


def make_grass_tuft():
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    r = np.random.default_rng(302)

    # Fitti steli d'erba ad arco dalla base inferiore (Y=510 -> alto)
    for i in range(62):
        bx = int(r.uniform(36, S - 36))
        by = S - 4
        h = r.uniform(160, 410)
        lean = (bx - 256) * r.uniform(0.35, 0.85) + r.uniform(-55, 55)
        bw = r.uniform(7, 15)
        shade = r.uniform(0.65, 1.15)
        g_col = (
            int(np.clip(78 * shade, 38, 130)),
            int(np.clip(118 * shade, 60, 165)),
            int(np.clip(42 * shade, 24, 72)),
            255,
        )
        mid_x = bx + lean * 0.42
        mid_y = by - h * 0.55
        tip_x = bx + lean
        tip_y = by - h
        poly = [
            (bx - bw * 0.5, by),
            (mid_x - bw * 0.32, mid_y),
            (tip_x, tip_y),
            (mid_x + bw * 0.32, mid_y),
            (bx + bw * 0.5, by),
        ]
        draw.polygon(poly, fill=g_col)

    # Fiori di campo delicati tra l'erba (margherite bianche, roselline rosa/giallo caldo come Ref 1)
    flower_cols = [(245, 242, 228, 255), (242, 162, 168, 255), (244, 214, 96, 255)]
    for fi in range(14):
        fx = int(r.uniform(72, S - 72))
        fy = int(r.uniform(170, S - 110))
        rad = r.uniform(9, 15)
        fc = flower_cols[fi % len(flower_cols)]
        # Picciolo
        draw.line([(fx, fy), (fx + r.integers(-14, 15), S - 6)], fill=(68, 102, 38, 255), width=4)
        for p in range(5):
            pa = p * (2.0 * np.pi) / 5.0
            px = fx + np.cos(pa) * rad
            py = fy + np.sin(pa) * rad
            draw.ellipse([px - rad * 0.48, py - rad * 0.48, px + rad * 0.48, py + rad * 0.48], fill=fc)
        draw.ellipse([fx - rad * 0.35, fy - rad * 0.35, fx + rad * 0.35, fy + rad * 0.35], fill=(235, 190, 62, 255))

    arr = _dilate_rgb_into_transparent(np.array(img, dtype=np.uint8))
    Image.fromarray(arr, "RGBA").save(os.path.join(OUT, "grass_tuft.png"))
    print("ok grass_tuft")


def make_water_normal():
    h1 = fbm(2.2, 501)
    h2 = fbm(1.5, 502)
    ys, xs = np.mgrid[0:S, 0:S].astype(np.float32)
    rings = np.sin(xs * 2.0 * np.pi / 64.0 + h1 * 4.0) * 0.25 + np.cos(ys * 2.0 * np.pi / 64.0 + h2 * 4.0) * 0.25
    h = 0.55 * h1 + 0.25 * h2 + 0.20 * rings
    pbr = height_to_pbr(h, np.full((S, S), 0.12), np.ones((S, S)), strength=2.0)
    nrm = np.empty((S, S, 3), dtype=np.float32)
    nrm[..., 0] = pbr[..., 0]
    nrm[..., 1] = pbr[..., 1]
    nrm[..., 2] = 0.94
    save_rgb("water_nrm", nrm)
    print("ok water_nrm")


if __name__ == "__main__":
    make_plaster("plaster", "#ffffff", var=0.085, grain=0.036, seed=1, n_str=1.65, rough_base=0.84)
    make_plaster("plaster_rough", "#dfdbd2", var=0.16, grain=0.085, seed=2, n_str=2.75, rough_base=0.90)
    make_brick()
    make_wall_garden()
    make_ashlar()
    make_cobble()
    make_slabs()
    make_asphalt()
    make_gravel()
    make_grass()
    make_roof_tile("roof_terracotta", "#c6633e", "#6d3420", 100)
    make_roof_tile("roof_slate", "#667180", "#3a404a", 101)
    make_planks("planks_light", "#c99654", "#6b4724", seed=30, plank=32, seam_w=2)
    make_planks("planks_dark", "#5d3d26", "#2a1a0f", seed=31, plank=32, seam_w=1)
    make_marble_dark()
    make_checker("tile_check_rc", "#b54238", "#e5dac8", cells=4, grout_hex="#7c7369", scuff=0.07, seed=40)
    make_checker("tile_check_bw", "#33689c", "#ede8de", cells=4, grout_hex="#737d89", scuff=0.06, seed=43)
    make_checker("tile_check_gray", "#6f8091", "#dee2e6", cells=4, grout_hex="#7b838c", scuff=0.10, seed=41)
    make_checker("tile_check_cafe", "#364454", "#e3d6c0", cells=4, grout_hex="#6d685e", scuff=0.06, seed=42)
    make_concrete_ogr()
    make_corrugated_metal()
    make_awning("awning_red", "#b53c34")
    make_awning("awning_green", "#337c52")
    make_awning("awning_blue", "#356599")
    make_awning("awning_yellow", "#d49b2d")
    make_fabric("fabric", "#f4f1ea", weave_step=4, seed=70)
    make_fabric("burlap", "#aa8f68", weave_step=6, seed=72)
    make_wicker()
    make_bark()
    make_bread_crust()
    make_leaves_bg()
    make_leaf_cluster()
    make_grass_tuft()
    make_water_normal()

