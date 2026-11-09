#!/usr/bin/env python3
"""
tools/generate_pbr_pipeline.py
==============================
Procedural PBR Texture & Material Library Generator for Startup Simulator.
Synthesizes 17 high-resolution (1024x1024) seamless PBR material sets:
- Albedo (RGB)
- Tangent-Space Normal Map (RGB OpenGL: +Y Up, computed via periodic Sobel)
- Roughness (L / Grayscale)
- Ambient Occlusion (L / Grayscale)
- Metallic (L / Grayscale)
- ORM Packed Map (RGB: R=AO, G=Roughness, B=Metallic)
- Emissive Map (RGB, where applicable)

Also authors Godot 4.3 StandardMaterial3D (.tres) resource files with triplanar
mapping configuration and invokes Godot headless import pass.
"""

import os
import sys
import time
import math
import subprocess
import argparse
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

# ----------------------------------------------------------------------
# Paths & Environment Configuration
# ----------------------------------------------------------------------
PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
TEXTURES_DIR = os.path.join(PROJECT_ROOT, "assets", "textures", "pbr")
MATERIALS_DIR = os.path.join(PROJECT_ROOT, "assets", "materials")
GODOT_BIN = "/home/antigravity/bin/godot"

# ----------------------------------------------------------------------
# Mathematical & Image Processing Core
# ----------------------------------------------------------------------

def seamless_fbm_noise(size=1024, base_grid=8, octaves=5, persistence=0.5, seed=42):
    """
    Computes seamless periodic 2D Fractal Brownian Motion noise.
    Uses gradient vector lattice with periodic modular indexing and
    quintic Hermite polynomial interpolation for C1 continuity across borders.
    """
    rng = np.random.RandomState(seed)
    total = np.zeros((size, size), dtype=np.float32)
    amp = 1.0
    tot_amp = 0.0
    y_idx, x_idx = np.indices((size, size), dtype=np.float32)

    for o in range(octaves):
        freq = base_grid * (2 ** o)
        if freq >= size:
            break
        gx = rng.uniform(-1.0, 1.0, (freq, freq)).astype(np.float32)
        gy = rng.uniform(-1.0, 1.0, (freq, freq)).astype(np.float32)
        mag = np.sqrt(gx * gx + gy * gy) + 1e-6
        gx /= mag
        gy /= mag

        cell_size = size / freq
        gx0 = (x_idx / cell_size).astype(np.int32) % freq
        gy0 = (y_idx / cell_size).astype(np.int32) % freq
        gx1 = (gx0 + 1) % freq
        gy1 = (gy0 + 1) % freq

        tx = (x_idx / cell_size) - np.floor(x_idx / cell_size)
        ty = (y_idx / cell_size) - np.floor(y_idx / cell_size)

        # Quintic hermite curve: 6t^5 - 15t^4 + 10t^3
        sx = tx * tx * tx * (tx * (tx * 6.0 - 15.0) + 10.0)
        sy = ty * ty * ty * (ty * (ty * 6.0 - 15.0) + 10.0)

        d00 = gx[gy0, gx0] * tx + gy[gy0, gx0] * ty
        d10 = gx[gy0, gx1] * (tx - 1.0) + gy[gy0, gx1] * ty
        d01 = gx[gy1, gx0] * tx + gy[gy1, gx0] * (ty - 1.0)
        d11 = gx[gy1, gx1] * (tx - 1.0) + gy[gy1, gx1] * (ty - 1.0)

        nx0 = d00 * (1.0 - sx) + d10 * sx
        nx1 = d01 * (1.0 - sx) + d11 * sx
        total += (nx0 * (1.0 - sy) + nx1 * sy) * amp
        tot_amp += amp
        amp *= persistence

    total /= tot_amp
    return (total - total.min()) / (total.max() - total.min() + 1e-6)

def height_to_normal(heightmap, strength=4.0):
    """
    Computes a seamless tangent-space normal map from a heightmap using
    periodic Sobel convolutions (Godot OpenGL convention: +Y is UP, +X is RIGHT).
    """
    h = heightmap.astype(np.float32)
    h_top = np.roll(h, -1, axis=0)
    h_bot = np.roll(h, 1, axis=0)
    h_lef = np.roll(h, -1, axis=1)
    h_rig = np.roll(h, 1, axis=1)

    h_tl = np.roll(h_top, -1, axis=1)
    h_tr = np.roll(h_top, 1, axis=1)
    h_bl = np.roll(h_bot, -1, axis=1)
    h_br = np.roll(h_bot, 1, axis=1)

    dx = ((h_tr + 2.0 * h_rig + h_br) - (h_tl + 2.0 * h_lef + h_bl)) * strength
    dy = ((h_tl + 2.0 * h_top + h_tr) - (h_bl + 2.0 * h_bot + h_br)) * strength
    dz = np.ones_like(dx)

    mag = np.sqrt(dx * dx + dy * dy + dz * dz)
    nx = dx / mag
    ny = dy / mag
    nz = dz / mag

    r = ((nx * 0.5 + 0.5) * 255.0).clip(0, 255).astype(np.uint8)
    g = ((ny * 0.5 + 0.5) * 255.0).clip(0, 255).astype(np.uint8)
    b = ((nz * 0.5 + 0.5) * 255.0).clip(0, 255).astype(np.uint8)
    return np.stack([r, g, b], axis=-1)

def height_to_ao(heightmap, intensity=1.8, blur_radius=7):
    """
    Computes ambient occlusion by comparing the heightmap against its
    Gaussian-blurred neighborhood (simulates crevice cavity shadow).
    Uses toroidal wrap padding to guarantee seamless boundary continuity.
    """
    pad = int(blur_radius * 3)
    padded = np.pad(heightmap, pad, mode='wrap')
    im = Image.fromarray((padded * 255.0).astype(np.uint8))
    blurred_padded = np.array(im.filter(ImageFilter.GaussianBlur(radius=blur_radius)), dtype=np.float32) / 255.0
    blurred = blurred_padded[pad:-pad, pad:-pad]
    diff = blurred - heightmap
    ao = 1.0 - np.clip(diff * intensity, 0.0, 1.0)
    ao = np.power(ao, 1.3)
    return (ao * 255.0).clip(0, 255).astype(np.uint8)

def pack_orm(ao, roughness, metallic):
    """Packs Red=AO, Green=Roughness, Blue=Metallic for ORM workflows."""
    return np.stack([ao, roughness, metallic], axis=-1)

def periodic_voronoi_cells(size=1024, num_cells=14, randomness=0.35, seed=101):
    """
    Computes periodic 2D Voronoi cellular distance fields for cobblestone & stone masonry.
    Evaluates 3x3 neighbor cell wraps to guarantee seamless tiling at borders.
    """
    rng = np.random.RandomState(seed)
    grid_size = num_cells
    cell_w = size / grid_size

    seeds_x = np.zeros((grid_size, grid_size), dtype=np.float32)
    seeds_y = np.zeros((grid_size, grid_size), dtype=np.float32)
    stone_heights = rng.uniform(0.70, 1.0, (grid_size, grid_size)).astype(np.float32)
    stone_tilts_x = rng.uniform(-0.15, 0.15, (grid_size, grid_size)).astype(np.float32)
    stone_tilts_y = rng.uniform(-0.15, 0.15, (grid_size, grid_size)).astype(np.float32)

    for i in range(grid_size):
        for j in range(grid_size):
            seeds_x[i, j] = (j + 0.5 + rng.uniform(-randomness, randomness)) * cell_w
            seeds_y[i, j] = (i + 0.5 + rng.uniform(-randomness, randomness)) * cell_w

    y_coords, x_coords = np.indices((size, size), dtype=np.float32)

    closest_dist = np.full((size, size), 1e9, dtype=np.float32)
    second_dist = np.full((size, size), 1e9, dtype=np.float32)
    cell_id_map = np.zeros((size, size), dtype=np.int32)
    stone_h_map = np.zeros((size, size), dtype=np.float32)
    tilt_map_x = np.zeros((size, size), dtype=np.float32)
    tilt_map_y = np.zeros((size, size), dtype=np.float32)
    rel_x_map = np.zeros((size, size), dtype=np.float32)
    rel_y_map = np.zeros((size, size), dtype=np.float32)

    for di in [-1, 0, 1]:
        for dj in [-1, 0, 1]:
            ci = np.floor(y_coords / cell_w).astype(np.int32) + di
            cj = np.floor(x_coords / cell_w).astype(np.int32) + dj

            wci = ci % grid_size
            wcj = cj % grid_size

            sx = seeds_x[wci, wcj] + ((cj - wcj) // grid_size) * size
            sy = seeds_y[wci, wcj] + ((ci - wci) // grid_size) * size

            dx = x_coords - sx
            dy = y_coords - sy
            d = np.sqrt(dx * dx + dy * dy)

            is_closer = d < closest_dist
            second_dist = np.where(is_closer, closest_dist, np.minimum(second_dist, d))
            closest_dist = np.where(is_closer, d, closest_dist)
            cell_id_map = np.where(is_closer, wci * grid_size + wcj, cell_id_map)
            stone_h_map = np.where(is_closer, stone_heights[wci, wcj], stone_h_map)
            tilt_map_x = np.where(is_closer, stone_tilts_x[wci, wcj], tilt_map_x)
            tilt_map_y = np.where(is_closer, stone_tilts_y[wci, wcj], tilt_map_y)
            rel_x_map = np.where(is_closer, dx, rel_x_map)
            rel_y_map = np.where(is_closer, dy, rel_y_map)

    edge_dist = (second_dist - closest_dist) / (cell_w * 0.5)
    mortar_width = 0.22
    grout_factor = np.clip((edge_dist - mortar_width * 0.5) / (mortar_width * 0.5), 0.0, 1.0)
    grout_factor = grout_factor * grout_factor * (3.0 - 2.0 * grout_factor)

    max_radius = cell_w * 0.45
    dome = np.clip(1.0 - (closest_dist / max_radius) ** 2, 0.0, 1.0)
    dome = np.power(dome, 0.65)

    height = (stone_h_map * 0.70 + dome * 0.30 + (rel_x_map * tilt_map_x + rel_y_map * tilt_map_y) / cell_w)
    height = height * (0.35 + 0.65 * grout_factor)
    height = np.clip(height, 0.0, 1.0)

    return height, grout_factor, cell_id_map

# ----------------------------------------------------------------------
# 17 PBR Material Generators
# ----------------------------------------------------------------------

def generate_turin_cobblestone_river(size=1024):
    """1. Turin River Cobblestone (ciottoli di fiume): rounded stones, tilt, mortar AO."""
    height, grout, cell_ids = periodic_voronoi_cells(size=size, num_cells=14, randomness=0.35, seed=12)
    grain = np.random.RandomState(45).uniform(-0.04, 0.04, (size, size)).astype(np.float32)
    height = np.clip(height + grain, 0.0, 1.0)

    normal = height_to_normal(height, strength=7.5)
    ao = (40 + 215 * np.power(grout, 0.8)).clip(0, 255).astype(np.uint8)

    mortar_col = np.array([75, 72, 68], dtype=np.float32)
    palette = [
        np.array([165, 168, 162], dtype=np.float32), # Luserna greenish grey
        np.array([182, 178, 170], dtype=np.float32), # Warm river pebble
        np.array([140, 145, 142], dtype=np.float32), # Dark schist
        np.array([195, 192, 188], dtype=np.float32), # Quartzite grey
        np.array([155, 150, 140], dtype=np.float32), # Earthy granite
    ]

    albedo = np.zeros((size, size, 3), dtype=np.uint8)
    num_p = len(palette)
    for c in range(3):
        stone_base = np.zeros((size, size), dtype=np.float32)
        for p_idx in range(num_p):
            mask = (cell_ids % num_p) == p_idx
            stone_base[mask] = palette[p_idx][c]
        stone_col = stone_base * (0.85 + 0.25 * height)
        final_c = mortar_col[c] * (1.0 - grout) + stone_col * grout
        albedo[:, :, c] = final_c.clip(0, 255).astype(np.uint8)

    roughness = (np.where(grout > 0.5, 165 + 30 * (1.0 - height), 245)).clip(0, 255).astype(np.uint8)
    metallic = np.zeros((size, size), dtype=np.uint8)
    return albedo, normal, roughness, ao, metallic

def generate_turin_luserna_flagstones(size=1024):
    """2. Pietra di Luserna schist slabs: staggered bond, cleavage, chiseled bevel."""
    nx, ny = 8, 8
    cw, ch = size / nx, size / ny
    y_idx, x_idx = np.indices((size, size), dtype=np.float32)

    row = np.floor((y_idx + 0.5) / ch).astype(np.int32)
    stagger = (row % 2) * (cw * 0.5)
    adj_x = (x_idx + stagger) % size

    dx_px = np.minimum(adj_x % cw, cw - (adj_x % cw))
    dy_px = np.minimum(y_idx % ch, ch - (y_idx % ch))
    d_px = np.minimum(dx_px, dy_px)

    flat_r = 2.0
    mortar_px = cw * 0.04
    grout = np.clip((d_px - flat_r) / (mortar_px - flat_r), 0.0, 1.0)
    grout = grout * grout * (3.0 - 2.0 * grout)

    slab_id = row * nx + (adj_x // cw).astype(np.int32)
    fbm = seamless_fbm_noise(size, base_grid=16, octaves=4, persistence=0.5, seed=54)
    freq_x = 2.0 * np.pi * 8.0 / size
    freq_y = 2.0 * np.pi * 3.0 / size
    schist_cleavage = np.sin(x_idx * freq_x + y_idx * freq_y + fbm * 4.0) * 0.06

    bevel_px = cw * 0.12
    bevel = np.clip((d_px - flat_r) / (bevel_px - flat_r), 0.0, 1.0) ** 0.5

    height = (0.70 + 0.20 * bevel + schist_cleavage) * (0.30 + 0.70 * grout)
    height = np.clip(height, 0.0, 1.0)

    normal = height_to_normal(height, strength=5.5)
    ao = height_to_ao(height, intensity=2.2, blur_radius=8)

    base_tones = [
        np.array([148, 155, 146], dtype=np.float32), # Classic Luserna grey-green
        np.array([162, 168, 160], dtype=np.float32), # Pale quartz-mica
        np.array([135, 140, 134], dtype=np.float32), # Darker schist
        np.array([155, 158, 148], dtype=np.float32), # Weathered greenish stone
    ]
    mortar_color = np.array([72, 70, 68], dtype=np.float32)

    albedo = np.zeros((size, size, 3), dtype=np.uint8)
    for c in range(3):
        slab_c = np.zeros((size, size), dtype=np.float32)
        for idx, col in enumerate(base_tones):
            mask = (slab_id % len(base_tones)) == idx
            slab_c[mask] = col[c]
        tone = slab_c * (0.85 + 0.30 * height)
        res = mortar_color[c] * (1.0 - grout) + tone * grout
        albedo[:, :, c] = res.clip(0, 255).astype(np.uint8)

    roughness = (np.where(grout > 0.5, 120 + 50 * (1.0 - schist_cleavage * 5.0), 245)).clip(0, 255).astype(np.uint8)
    metallic = np.zeros((size, size), dtype=np.uint8)
    return albedo, normal, roughness, ao, metallic

def generate_turin_asphalt_avenue(size=1024):
    """3. Wide asphalt road: bitumen gravel aggregate, thermoplastic lane lines & zebra stripes."""
    grain1 = seamless_fbm_noise(size, base_grid=32, octaves=5, persistence=0.6, seed=88)
    grain2 = np.random.RandomState(99).uniform(-0.06, 0.06, (size, size)).astype(np.float32)
    height = np.clip(grain1 * 0.80 + grain2, 0.0, 1.0)

    y_idx, x_idx = np.indices((size, size), dtype=np.float32)

    # Dashed center lane divider: width 44px, dash 250px, gap 150px
    center_dist = np.abs(x_idx - (size * 0.5))
    dash_cycle = y_idx % 400
    is_dash = (center_dist < 22) & (dash_cycle < 250)

    # Pedestrian crossing bars (strisce pedonali) in bottom quadrant (y: 720 to 980)
    # White bars 48px wide spaced every 48px across X
    zebra_band = (y_idx >= 720) & (y_idx <= 980)
    zebra_bars = ((x_idx % 96) < 48) & zebra_band

    is_paint = is_dash | zebra_bars

    # Thermoplastic paint is slightly elevated (+0.08)
    height = np.where(is_paint, np.clip(height + 0.08, 0.0, 1.0), height)

    normal = height_to_normal(height, strength=4.2)
    ao = height_to_ao(height, intensity=1.5, blur_radius=5)

    asphalt_dark = np.array([42, 45, 48], dtype=np.float32)
    asphalt_light = np.array([72, 75, 78], dtype=np.float32)

    albedo = np.zeros((size, size, 3), dtype=np.uint8)
    for c in range(3):
        base_asphalt = asphalt_dark[c] + (asphalt_light[c] - asphalt_dark[c]) * height
        paint_white = 242.0 - 25.0 * (1.0 - height)
        res = np.where(is_paint, paint_white, base_asphalt)
        albedo[:, :, c] = res.clip(0, 255).astype(np.uint8)

    roughness = np.where(is_paint, 115, (215 + 40 * (1.0 - height))).clip(0, 255).astype(np.uint8)
    metallic = np.zeros((size, size), dtype=np.uint8)
    return albedo, normal, roughness, ao, metallic

def generate_turin_granite_curb(size=1024):
    """4. Montorfano coarse granite curb: elongated slabs, beveled chamfer, crystalline grains."""
    # 4 elongated curb blocks (each 256 tall, 512 wide, staggered by 256)
    cw, ch = 512.0, 256.0
    y_idx, x_idx = np.indices((size, size), dtype=np.float32)

    row = np.floor((y_idx + 0.5) / ch).astype(np.int32)
    stagger = (row % 2) * (cw * 0.5)
    adj_x = (x_idx + stagger) % size

    dx_px = np.minimum(adj_x % cw, cw - (adj_x % cw))
    dy_px = np.minimum(y_idx % ch, ch - (y_idx % ch))
    d_px = np.minimum(dx_px, dy_px)

    flat_r = 2.0
    mortar_px = cw * 0.03 # ~15px
    grout = np.clip((d_px - flat_r) / (mortar_px - flat_r), 0.0, 1.0)
    grout = grout * grout * (3.0 - 2.0 * grout)

    # Curb top chamfer bevel: rounded edge on top part of each block
    sy = ((y_idx + 0.5) % ch) / ch
    chamfer = np.clip(sy / 0.25, 0.0, 1.0) ** 0.65

    # Bush-hammered chiseled stone surface
    fbm = seamless_fbm_noise(size, base_grid=24, octaves=4, persistence=0.55, seed=77)
    chisel_pits = np.random.RandomState(82).uniform(-0.08, 0.08, (size, size)).astype(np.float32)

    stone_h = 0.50 + 0.35 * chamfer + fbm * 0.15 + chisel_pits
    mortar_h = 0.35
    height = np.clip(mortar_h * (1.0 - grout) + stone_h * grout, 0.0, 1.0)

    normal = height_to_normal(height, strength=6.0)
    ao = height_to_ao(height, intensity=2.2, blur_radius=8)

    # Coarse Montorfano granite mineral speckle pattern
    rng_granite = np.random.RandomState(134)
    biotite_flecks = rng_granite.uniform(0.0, 1.0, (size, size)) < 0.14
    quartz_crystals = rng_granite.uniform(0.0, 1.0, (size, size)) < 0.28

    granite_feldspar = np.array([210, 208, 204], dtype=np.float32)
    granite_quartz = np.array([160, 162, 165], dtype=np.float32)
    granite_biotite = np.array([38, 36, 34], dtype=np.float32)
    mortar_col = np.array([68, 66, 64], dtype=np.float32)

    albedo = np.zeros((size, size, 3), dtype=np.uint8)
    for c in range(3):
        col = np.full((size, size), granite_feldspar[c], dtype=np.float32)
        col = np.where(quartz_crystals, granite_quartz[c], col)
        col = np.where(biotite_flecks, granite_biotite[c], col)
        stone_col = col * (0.80 + 0.30 * height)
        final_c = mortar_col[c] * (1.0 - grout) + stone_col * grout
        albedo[:, :, c] = final_c.clip(0, 255).astype(np.uint8)

    roughness = np.where(grout > 0.5, np.where(biotite_flecks, 130, 185 + 30 * (1.0 - height)), 245).clip(0, 255).astype(np.uint8)
    metallic = np.zeros((size, size), dtype=np.uint8)
    return albedo, normal, roughness, ao, metallic

def generate_turin_portico_marble_floor(size=1024):
    """5. Framed Carrara white marble & Baveno pink granite flagstone tiles with satin roughness."""
    tile_size = 256.0
    y_idx, x_idx = np.indices((size, size), dtype=np.float32)

    ti = np.floor((y_idx + 0.5) / tile_size).astype(np.int32)
    tj = np.floor((x_idx + 0.5) / tile_size).astype(np.int32)
    is_pink_granite = ((ti + tj) % 2) == 1

    # Within-tile coordinates & razor-thin micro-joint with flat bottom
    dx_px = np.minimum(x_idx % tile_size, tile_size - (x_idx % tile_size))
    dy_px = np.minimum(y_idx % tile_size, tile_size - (y_idx % tile_size))
    d_px = np.minimum(dx_px, dy_px)
    flat_r = 2.0
    joint_px = tile_size * 0.018 # ~4.6px
    joint = np.clip((d_px - flat_r) / (joint_px - flat_r), 0.0, 1.0)
    joint = joint * joint * (3.0 - 2.0 * joint)

    # Tile-to-tile subtle height variation (+/- 0.015)
    tile_offsets = np.random.RandomState(303).uniform(-0.015, 0.015, (4, 4)).astype(np.float32)
    tile_offset_map = tile_offsets[ti % 4, tj % 4]

    # Organic marble veining for Carrara tiles (integer harmonic wave numbers)
    fbm_vein = seamless_fbm_noise(size, base_grid=6, octaves=5, persistence=0.55, seed=404)
    freq_x = 2.0 * np.pi * 1.0 / size
    freq_y = 2.0 * np.pi * 1.0 / size
    vein_field = np.abs(np.sin(fbm_vein * 10.0 + x_idx * freq_x + y_idx * freq_y))
    vein_intensity = np.clip(1.0 - (vein_field / 0.12), 0.0, 1.0)

    # Crystalline texture for Baveno granite tiles
    rng_baveno = np.random.RandomState(505)
    pink_fleck = rng_baveno.uniform(0.0, 1.0, (size, size)) < 0.15

    height = (0.80 + tile_offset_map * joint - 0.02 * (1.0 - joint))
    height = np.clip(height, 0.0, 1.0)

    normal = height_to_normal(height, strength=4.0)
    ao = (180 + 75 * joint).clip(0, 255).astype(np.uint8)

    # Carrara White: creamy white with delicate grey-smoke veins
    carrara_base = np.array([242, 239, 234], dtype=np.float32)
    carrara_vein = np.array([175, 172, 168], dtype=np.float32)

    # Baveno Pink Granite: classic Piedmont pink feldspar with dark mineral grains
    baveno_base = np.array([205, 152, 142], dtype=np.float32)
    baveno_speck = np.array([72, 48, 44], dtype=np.float32)
    joint_col = np.array([95, 90, 85], dtype=np.float32)

    albedo = np.zeros((size, size, 3), dtype=np.uint8)
    for c in range(3):
        carrara_c = carrara_base[c] * (1.0 - vein_intensity * 0.45) + carrara_vein[c] * (vein_intensity * 0.45)
        baveno_c = np.where(pink_fleck, baveno_speck[c], baveno_base[c])
        tile_col = np.where(is_pink_granite, baveno_c, carrara_c)
        final_c = joint_col[c] * (1.0 - joint) + tile_col * joint
        albedo[:, :, c] = final_c.clip(0, 255).astype(np.uint8)

    # Satin polished marble finish: roughness 0.22 - 0.30, joints rougher
    roughness = np.where(joint > 0.5, (65 + 20 * (1.0 - height)), 210).clip(0, 255).astype(np.uint8)
    metallic = np.zeros((size, size), dtype=np.uint8)
    return albedo, normal, roughness, ao, metallic

def generate_turin_portico_column_fluted(size=1024):
    """6. Classical fluted column shaft: 16 rounded vertical channels, limestone marble veins."""
    y_idx, x_idx = np.indices((size, size), dtype=np.float32)
    num_flutes = 16
    channel = -np.cos(((x_idx + 0.5) / size) * num_flutes * 2.0 * np.pi)
    flute_profile = np.clip(channel, -0.65, 0.65) / 0.65

    marble_vein = seamless_fbm_noise(size, base_grid=8, octaves=5, persistence=0.55, seed=606)
    height = 0.50 + 0.38 * flute_profile + marble_vein * 0.12
    height = np.clip(height, 0.0, 1.0)

    normal = height_to_normal(height, strength=6.0)
    ao = height_to_ao(height, intensity=2.0, blur_radius=8)

    # Botticino / Carrara marble
    marble_white = np.array([238, 235, 230], dtype=np.float32)
    vein_grey = np.array([185, 180, 175], dtype=np.float32)

    albedo = np.zeros((size, size, 3), dtype=np.uint8)
    for c in range(3):
        albedo[:, :, c] = (vein_grey[c] + (marble_white[c] - vein_grey[c]) * marble_vein).clip(0, 255).astype(np.uint8)

    # Honed limestone satin finish (roughness 0.30 - 0.40)
    roughness = (75 + 35 * (1.0 - marble_vein)).clip(0, 255).astype(np.uint8)
    metallic = np.zeros((size, size), dtype=np.uint8)
    return albedo, normal, roughness, ao, metallic

def generate_turin_facade_plaster(size=1024, tint="ochre"):
    """7, 8, 9. Historic Savoy facade lime plaster with fine sand grain and trowel waves."""
    fbm = seamless_fbm_noise(size, base_grid=12, octaves=5, persistence=0.52, seed=707 if tint == "ochre" else (808 if tint == "cream" else 909))
    trowel = np.sin(fbm * 8.0) * 0.05
    height = np.clip(fbm * 0.90 + trowel, 0.0, 1.0)

    normal = height_to_normal(height, strength=3.0)
    ao = height_to_ao(height, intensity=1.2, blur_radius=6)

    if tint == "ochre": # Signature Giallo Torino #D9A74A / #E3A857
        col_dark = np.array([195, 142, 75], dtype=np.float32)
        col_light = np.array([228, 175, 95], dtype=np.float32)
    elif tint == "cream": # Crema Sabauda #E8DCB8 / #F4E8D1
        col_dark = np.array([215, 202, 175], dtype=np.float32)
        col_light = np.array([242, 232, 210], dtype=np.float32)
    else: # Terracotta #B86852 / #A54B37
        col_dark = np.array([165, 75, 55], dtype=np.float32)
        col_light = np.array([205, 105, 80], dtype=np.float32)

    albedo = np.zeros((size, size, 3), dtype=np.uint8)
    for c in range(3):
        albedo[:, :, c] = (col_dark[c] + (col_light[c] - col_dark[c]) * height).clip(0, 255).astype(np.uint8)

    roughness = (205 + 30 * (1.0 - height)).clip(0, 255).astype(np.uint8)
    metallic = np.zeros((size, size), dtype=np.uint8)
    return albedo, normal, roughness, ao, metallic

def generate_turin_rustic_bugnato(size=1024):
    """10. Piedmontese rustic ashlar blocks: deep V-groove channels, pillow convex relief."""
    nx, ny = 2, 4
    cw, ch = size / nx, size / ny
    y_idx, x_idx = np.indices((size, size), dtype=np.float32)

    row = (y_idx // ch).astype(np.int32)
    stagger = (row % 2) * (cw * 0.5)
    adj_x = (x_idx + stagger) % size

    dx_px = np.minimum(adj_x % cw, cw - (adj_x % cw))
    dy_px = np.minimum(y_idx % ch, ch - (y_idx % ch))
    d_px = np.minimum(dx_px, dy_px)

    flat_r = 2.0
    v_groove_w_px = cw * 0.08
    bevel = np.clip((d_px - flat_r) / (v_groove_w_px - flat_r), 0.0, 1.0)

    sx = (adj_x % cw) / cw
    sy = (y_idx % ch) / ch
    pillow = np.sin(np.pi * sx) * np.sin(np.pi * sy) * bevel
    stone_grain = seamless_fbm_noise(size, base_grid=24, octaves=4, persistence=0.5, seed=1010) * 0.15

    height = (0.20 + 0.60 * bevel + 0.20 * pillow + stone_grain)
    height = np.clip(height, 0.0, 1.0)

    normal = height_to_normal(height, strength=6.5)
    ao = (110 + 145 * np.power(bevel, 0.75)).clip(0, 255).astype(np.uint8)

    base_c = np.array([170, 165, 158], dtype=np.float32)
    albedo = np.zeros((size, size, 3), dtype=np.uint8)
    for c in range(3):
        albedo[:, :, c] = (base_c[c] * (0.65 + 0.45 * height)).clip(0, 255).astype(np.uint8)

    roughness = (195 + 45 * (1.0 - height)).clip(0, 255).astype(np.uint8)
    metallic = np.zeros((size, size), dtype=np.uint8)
    return albedo, normal, roughness, ao, metallic

def generate_turin_window_shutter(size=1024):
    """11. Traditional Savoy green wooden louver shutters: angled slats, frame borders, painted wood."""
    y_idx, x_idx = np.indices((size, size), dtype=np.float32)

    # Frame rails & stiles
    stile_w = 80.0
    rail_h = 70.0
    mid_rail_y = 512.0
    mid_rail_h = 60.0

    is_stile = (x_idx < stile_w) | (x_idx >= (size - stile_w))
    is_outer_rail = (y_idx < rail_h) | (y_idx >= (size - rail_h))
    is_mid_rail = np.abs(y_idx - mid_rail_y) < (mid_rail_h * 0.5)
    is_frame = is_stile | is_outer_rail | is_mid_rail

    # Louver slats inside panels: height 36px, angled downward ramp
    slat_h = 36.0
    slat_phase = (y_idx % slat_h) / slat_h
    # Sawtooth angled ramp
    slat_ramp = 0.35 + 0.45 * slat_phase

    # Wood grain underneath lacquer
    fbm_v = seamless_fbm_noise(size, base_grid=8, octaves=4, persistence=0.5, seed=1111)
    fbm_h = seamless_fbm_noise(size, base_grid=8, octaves=4, persistence=0.5, seed=1112)
    wood_grain = np.where(is_stile, fbm_v, fbm_h) * 0.08

    height = np.where(is_frame, 0.85 + wood_grain, slat_ramp + wood_grain)
    height = np.clip(height, 0.0, 1.0)

    normal = height_to_normal(height, strength=5.5)

    # AO shadow under each louver slat and inner frame
    slat_shadow = np.clip(slat_phase / 0.30, 0.0, 1.0)
    ao = np.where(is_frame, 235, (120 + 130 * slat_shadow)).clip(0, 255).astype(np.uint8)

    # Savoy Green: #1E3326 / #234E35
    green_dark = np.array([28, 48, 35], dtype=np.float32)
    green_light = np.array([42, 78, 54], dtype=np.float32)

    albedo = np.zeros((size, size, 3), dtype=np.uint8)
    for c in range(3):
        albedo[:, :, c] = (green_dark[c] + (green_light[c] - green_dark[c]) * height).clip(0, 255).astype(np.uint8)

    # Satin painted wood finish (roughness 0.45)
    roughness = (105 + 30 * (1.0 - height)).clip(0, 255).astype(np.uint8)
    metallic = np.zeros((size, size), dtype=np.uint8)
    return albedo, normal, roughness, ao, metallic

def generate_turin_storefront_wood(size=1024):
    """12. Polished Italian walnut boiserie: architectural frame, ogee moulding, flowing grain."""
    y_idx, x_idx = np.indices((size, size), dtype=np.float32)

    # Framed panel geometry (2 stacked vertical panels)
    frame_w = 90.0
    panel_h = (size - 3.0 * frame_w) / 2.0 # ~377px each

    in_panel1 = (x_idx >= frame_w) & (x_idx < (size - frame_w)) & (y_idx >= frame_w) & (y_idx < (frame_w + panel_h))
    in_panel2 = (x_idx >= frame_w) & (x_idx < (size - frame_w)) & (y_idx >= (2.0 * frame_w + panel_h)) & (y_idx < (size - frame_w))

    # Ogee moulding bevel into recessed panel
    def panel_dist(x, y, y_start, y_end):
        dx = np.minimum(x - frame_w, (size - frame_w) - x)
        dy = np.minimum(y - y_start, y_end - y)
        return np.minimum(dx, dy)

    d1 = np.where(in_panel1, panel_dist(x_idx, y_idx, frame_w, frame_w + panel_h), 0.0)
    d2 = np.where(in_panel2, panel_dist(x_idx, y_idx, 2.0 * frame_w + panel_h, size - frame_w), 0.0)
    d_moulding = np.maximum(d1, d2)
    moulding_w = 40.0
    moulding_t = np.clip(d_moulding / moulding_w, 0.0, 1.0)
    # S-curve cyma reversa moulding profile
    ogee = 0.5 - 0.5 * np.cos(np.pi * moulding_t)

    # Longitudinal flowing walnut wood grain (integer harmonic wave numbers)
    fbm = seamless_fbm_noise(size, base_grid=6, octaves=5, persistence=0.55, seed=1212)
    freq_y = 2.0 * np.pi * 10.0 / size
    freq_x = 2.0 * np.pi * 2.0 / size
    grain_waves = np.sin((y_idx * freq_y) + np.sin(x_idx * freq_x) * 6.0 + fbm * 8.0)
    pores = (np.random.RandomState(1213).uniform(0, 1, (size, size)) > 0.965) * 0.12

    # Panel recess depth
    is_panel = in_panel1 | in_panel2
    panel_depth = np.where(is_panel, 0.70 + 0.15 * ogee, 0.90)
    height = np.clip(panel_depth + 0.08 * grain_waves - pores, 0.0, 1.0)

    normal = height_to_normal(height, strength=4.5)
    ao = height_to_ao(height, intensity=2.0, blur_radius=8)

    # Deep Italian Walnut boiserie (#4A2518 / #3A1B10)
    walnut_dark = np.array([58, 28, 18], dtype=np.float32)
    walnut_light = np.array([105, 52, 28], dtype=np.float32)

    albedo = np.zeros((size, size, 3), dtype=np.uint8)
    for c in range(3):
        albedo[:, :, c] = (walnut_dark[c] + (walnut_light[c] - walnut_dark[c]) * height).clip(0, 255).astype(np.uint8)

    # Lustrous antique varnish satin finish (roughness 0.35)
    roughness = (85 + 35 * (1.0 - height)).clip(0, 255).astype(np.uint8)
    metallic = np.zeros((size, size), dtype=np.uint8)
    return albedo, normal, roughness, ao, metallic

def generate_turin_cafe_awning_striped(size=1024):
    """13. Turin outdoor cafe awning: bold Burgundy & Ivory stripes, textile canvas weave."""
    y_idx, x_idx = np.indices((size, size), dtype=np.float32)

    # Alternating 64px vertical stripes (16 stripes across 1024)
    stripe_w = 64.0
    stripe_idx = (x_idx // stripe_w).astype(np.int32)
    is_burgundy = (stripe_idx % 2) == 0

    # Cross-hatch textile canvas basketweave
    warp = np.sin((x_idx / 4.0) * np.pi)
    weft = np.sin((y_idx / 4.0) * np.pi)
    weave = (warp * weft) * 0.10

    # Gentle canvas drape / tension fold across X
    cloth_fold = np.sin((x_idx / size) * 4.0 * np.pi) * 0.05

    fbm_fabric = seamless_fbm_noise(size, base_grid=16, octaves=3, persistence=0.5, seed=1313) * 0.08
    height = 0.50 + cloth_fold + weave + fbm_fabric
    height = np.clip(height, 0.0, 1.0)

    normal = height_to_normal(height, strength=4.5)
    ao = (220 + 35 * (1.0 - np.abs(weave) * 5.0)).clip(0, 255).astype(np.uint8)

    # Burgundy (#7A1F2D) & Ivory (#F5F2EB)
    burgundy = np.array([122, 31, 45], dtype=np.float32)
    ivory = np.array([245, 242, 235], dtype=np.float32)

    albedo = np.zeros((size, size, 3), dtype=np.uint8)
    for c in range(3):
        stripe_c = np.where(is_burgundy, burgundy[c], ivory[c])
        shaded = stripe_c * (0.88 + 0.22 * height)
        albedo[:, :, c] = shaded.clip(0, 255).astype(np.uint8)

    # Matte textile canvas roughness (0.92)
    roughness = (230 + 20 * (1.0 - height)).clip(0, 255).astype(np.uint8)
    metallic = np.zeros((size, size), dtype=np.uint8)
    return albedo, normal, roughness, ao, metallic

def generate_startup_server_perforated_metal(size=1024):
    """14. 42U server rack perforated door: matte black steel, staggered hex hole mask, cavity AO."""
    pitch_x = size / 32.0 # 32.0
    pitch_y = size / 36.0 # 28.444444 (36 rows fit evenly into size with near-hexagonal 0.888 aspect ratio)
    radius = 11.0

    y_idx, x_idx = np.indices((size, size), dtype=np.float32)
    row = np.floor((y_idx + 0.5) / pitch_y).astype(np.int32)
    stagger = (row % 2) * (pitch_x * 0.5)

    cx = (x_idx + stagger + 0.5) % pitch_x - (pitch_x * 0.5)
    cy = ((y_idx + 0.5) % pitch_y) - (pitch_y * 0.5)
    dist = np.sqrt(cx * cx + cy * cy)

    hole_mask = np.clip((dist - radius) / 1.5, 0.0, 1.0)
    powder = np.random.RandomState(1414).uniform(-0.03, 0.03, (size, size)).astype(np.float32)
    height = np.clip(hole_mask * 0.90 + powder, 0.0, 1.0)

    normal = height_to_normal(height, strength=8.0)
    ao = (hole_mask * 230 + 25).clip(0, 255).astype(np.uint8)

    metal_dark = np.array([28, 30, 34], dtype=np.float32)
    albedo = np.zeros((size, size, 3), dtype=np.uint8)
    for c in range(3):
        albedo[:, :, c] = (metal_dark[c] * (0.80 + 0.20 * hole_mask)).clip(0, 255).astype(np.uint8)

    metallic = (hole_mask * 228).astype(np.uint8) # 0.89 metal
    roughness = np.where(hole_mask > 0.5, 95, 255).astype(np.uint8)
    return albedo, normal, roughness, ao, metallic

def generate_startup_brushed_dark_aluminum(size=1024):
    """15. Space-gray anodized aluminum: linear horizontal anisotropic brush lines."""
    y_idx, x_idx = np.indices((size, size), dtype=np.float32)
    rng = np.random.RandomState(1515)
    brush_y = np.zeros((size, 1), dtype=np.float32)
    for k in range(16, 256):
        phase = rng.uniform(0, 2.0 * np.pi)
        amp = 1.0 / (k ** 0.5)
        brush_y += amp * np.sin((y_idx[:, :1] / size) * (k * 2.0 * np.pi) + phase)
    brush_y = (brush_y - brush_y.min()) / (brush_y.max() - brush_y.min() + 1e-6)
    brush_lines = brush_y.repeat(size, axis=1)

    fbm = seamless_fbm_noise(size, base_grid=8, octaves=3, persistence=0.5, seed=1516)
    height = np.clip(brush_lines * 0.80 + fbm * 0.20, 0.0, 1.0)

    normal = height_to_normal(height, strength=3.5)
    ao = np.full((size, size), 250, dtype=np.uint8)

    base_al = np.array([52, 55, 62], dtype=np.float32)
    albedo = np.zeros((size, size, 3), dtype=np.uint8)
    for c in range(3):
        albedo[:, :, c] = (base_al[c] * (0.90 + 0.20 * height)).clip(0, 255).astype(np.uint8)

    metallic = np.full((size, size), 242, dtype=np.uint8) # 0.95
    roughness = (75 + 25 * height).clip(0, 255).astype(np.uint8) # 0.32
    return albedo, normal, roughness, ao, metallic

def generate_startup_desk_wood_veneer(size=1024):
    """16. Scandinavian honey oak standing desk veneer: flowing grain, polyurethane satin finish."""
    y_idx, x_idx = np.indices((size, size), dtype=np.float32)
    fbm = seamless_fbm_noise(size, base_grid=4, octaves=4, persistence=0.5, seed=1616)
    freq = 2.0 * np.pi * 10.0 / size
    grain_wave = np.sin((y_idx * freq) + fbm * 6.0)
    pores = np.random.RandomState(1617).uniform(0, 1, (size, size)) > 0.96

    height = 0.50 + 0.30 * grain_wave - pores * 0.15
    height = np.clip(height, 0.0, 1.0)

    normal = height_to_normal(height, strength=2.8)
    ao = height_to_ao(height, intensity=1.1, blur_radius=5)

    wood_dark = np.array([165, 112, 65], dtype=np.float32)
    wood_light = np.array([215, 165, 110], dtype=np.float32)

    albedo = np.zeros((size, size, 3), dtype=np.uint8)
    for c in range(3):
        albedo[:, :, c] = (wood_dark[c] + (wood_light[c] - wood_dark[c]) * height).clip(0, 255).astype(np.uint8)

    roughness = (90 + 35 * (1.0 - height) + pores * 50).clip(0, 255).astype(np.uint8) # 0.35 satin
    metallic = np.zeros((size, size), dtype=np.uint8)
    return albedo, normal, roughness, ao, metallic

def generate_startup_screen_emissive(size=1024):
    """17. Dual-monitor IDE code display & system telemetry: high-tech glowing emissive tokens."""
    albedo = np.zeros((size, size, 3), dtype=np.uint8)
    albedo[:] = [20, 22, 28]

    emission = np.zeros((size, size, 3), dtype=np.uint8)
    im_em = Image.fromarray(emission)
    draw = ImageDraw.Draw(im_em)

    # Top tab header bar
    draw.rectangle([0, 0, size, 45], fill=(35, 38, 48))
    draw.rectangle([20, 10, 220, 45], fill=(48, 52, 65))
    draw.rectangle([230, 10, 410, 45], fill=(38, 41, 52))

    # Left sidebar / tree
    draw.rectangle([0, 45, 180, size], fill=(28, 30, 38))
    # File tree item highlights
    for fy in range(65, 380, 26):
        draw.rectangle([24, fy + 4, 38, fy + 14], fill=(70, 130, 240)) # File icon
        draw.rectangle([46, fy + 6, np.random.randint(90, 160), fy + 14], fill=(160, 170, 185))

    # Code editor lines (VS Code / Dark+ syntax tokens)
    colors = [
        (80, 200, 255),  # Cyan functions
        (255, 205, 80),  # Yellow classes/strings
        (255, 110, 160), # Pink keywords
        (120, 230, 130), # Green numbers/vars
        (170, 175, 190), # White operators
        (100, 115, 130)  # Grey comments
    ]
    rng_code = np.random.RandomState(1717)
    for row_y in range(70, size - 180, 24):
        # Line number
        draw.rectangle([195, row_y + 4, 215, row_y + 12], fill=(65, 70, 85))
        cur_x = 230
        num_tokens = rng_code.randint(3, 8)
        for _ in range(num_tokens):
            w = rng_code.randint(25, 95)
            col = colors[rng_code.randint(0, len(colors))]
            draw.rectangle([cur_x, row_y + 2, cur_x + w, row_y + 14], fill=col)
            cur_x += w + 12
            if cur_x > size - 40:
                break

    # Terminal pane at bottom
    draw.rectangle([180, size - 170, size, size], fill=(15, 17, 22))
    draw.rectangle([180, size - 170, size, size - 168], fill=(0, 160, 230)) # Cyan accent border
    for ty in range(size - 145, size - 20, 22):
        draw.rectangle([200, ty + 2, 218, ty + 12], fill=(0, 230, 140)) # Green prompt
        draw.rectangle([228, ty + 2, rng_code.randint(350, 750), ty + 12], fill=(180, 190, 205))

    emission = np.array(im_em)
    albedo = np.clip(albedo.astype(np.int32) + (emission.astype(np.int32) * 0.40), 0, 255).astype(np.uint8)

    # Flat glass normal
    normal = np.zeros((size, size, 3), dtype=np.uint8)
    normal[:, :] = [128, 128, 255]

    roughness = np.full((size, size), 20, dtype=np.uint8) # Glossy smooth glass (0.08)
    ao = np.full((size, size), 255, dtype=np.uint8)
    metallic = np.zeros((size, size), dtype=np.uint8)
    return albedo, normal, roughness, ao, metallic, emission

# ----------------------------------------------------------------------
# Material Suite Registry & Godot .tres Serialization
# ----------------------------------------------------------------------

MATERIAL_REGISTRY = {
    "turin_cobblestone_river": {
        "gen_fn": generate_turin_cobblestone_river,
        "triplanar": True,
        "uv_scale": (2.0, 2.0, 2.0),
        "triplanar_sharpness": 4.0,
        "normal_scale": 1.0,
    },
    "turin_luserna_flagstones": {
        "gen_fn": generate_turin_luserna_flagstones,
        "triplanar": True,
        "uv_scale": (2.0, 2.0, 2.0),
        "triplanar_sharpness": 4.0,
        "normal_scale": 1.0,
    },
    "turin_asphalt_avenue": {
        "gen_fn": generate_turin_asphalt_avenue,
        "triplanar": False,
        "uv_scale": (1.0, 1.0, 1.0),
        "triplanar_sharpness": 1.0,
        "normal_scale": 1.0,
    },
    "turin_granite_curb": {
        "gen_fn": generate_turin_granite_curb,
        "triplanar": True,
        "uv_scale": (4.0, 4.0, 4.0),
        "triplanar_sharpness": 4.0,
        "normal_scale": 1.0,
    },
    "turin_portico_marble_floor": {
        "gen_fn": generate_turin_portico_marble_floor,
        "triplanar": True,
        "uv_scale": (2.0, 2.0, 2.0),
        "triplanar_sharpness": 4.0,
        "normal_scale": 1.0,
    },
    "turin_portico_column_fluted": {
        "gen_fn": generate_turin_portico_column_fluted,
        "triplanar": True,
        "uv_scale": (1.0, 3.0, 1.0),
        "triplanar_sharpness": 4.0,
        "normal_scale": 1.0,
    },
    "turin_facade_plaster_ochre": {
        "gen_fn": lambda s: generate_turin_facade_plaster(s, "ochre"),
        "triplanar": True,
        "uv_scale": (3.0, 3.0, 3.0),
        "triplanar_sharpness": 4.0,
        "normal_scale": 1.0,
    },
    "turin_facade_plaster_cream": {
        "gen_fn": lambda s: generate_turin_facade_plaster(s, "cream"),
        "triplanar": True,
        "uv_scale": (3.0, 3.0, 3.0),
        "triplanar_sharpness": 4.0,
        "normal_scale": 1.0,
    },
    "turin_facade_plaster_terracotta": {
        "gen_fn": lambda s: generate_turin_facade_plaster(s, "terracotta"),
        "triplanar": True,
        "uv_scale": (3.0, 3.0, 3.0),
        "triplanar_sharpness": 4.0,
        "normal_scale": 1.0,
    },
    "turin_rustic_bugnato": {
        "gen_fn": generate_turin_rustic_bugnato,
        "triplanar": True,
        "uv_scale": (2.0, 2.0, 2.0),
        "triplanar_sharpness": 4.0,
        "normal_scale": 1.0,
    },
    "turin_window_shutter": {
        "gen_fn": generate_turin_window_shutter,
        "triplanar": False,
        "uv_scale": (1.0, 1.0, 1.0),
        "triplanar_sharpness": 1.0,
        "normal_scale": 1.0,
    },
    "turin_storefront_wood": {
        "gen_fn": generate_turin_storefront_wood,
        "triplanar": True,
        "uv_scale": (2.0, 2.0, 2.0),
        "triplanar_sharpness": 4.0,
        "normal_scale": 1.0,
    },
    "turin_cafe_awning_striped": {
        "gen_fn": generate_turin_cafe_awning_striped,
        "triplanar": False,
        "uv_scale": (1.0, 1.0, 1.0),
        "triplanar_sharpness": 1.0,
        "normal_scale": 1.0,
    },
    "startup_server_perforated_metal": {
        "gen_fn": generate_startup_server_perforated_metal,
        "triplanar": True,
        "uv_scale": (4.0, 4.0, 4.0),
        "triplanar_sharpness": 4.0,
        "normal_scale": 1.0,
    },
    "startup_brushed_dark_aluminum": {
        "gen_fn": generate_startup_brushed_dark_aluminum,
        "triplanar": True,
        "uv_scale": (2.0, 2.0, 2.0),
        "triplanar_sharpness": 4.0,
        "normal_scale": 1.0,
    },
    "startup_desk_wood_veneer": {
        "gen_fn": generate_startup_desk_wood_veneer,
        "triplanar": True,
        "uv_scale": (2.0, 2.0, 2.0),
        "triplanar_sharpness": 4.0,
        "normal_scale": 1.0,
    },
    "startup_screen_emissive": {
        "gen_fn": generate_startup_screen_emissive,
        "triplanar": False,
        "uv_scale": (1.0, 1.0, 1.0),
        "triplanar_sharpness": 1.0,
        "normal_scale": 1.0,
        "has_emission": True,
        "emission_energy": 1.8,
    },
}

def generate_standard_material_tres(mat_name, config):
    """
    Constructs Godot 4.3 StandardMaterial3D (.tres) text resource.
    References textures under res://assets/textures/pbr/<mat_name>/...
    """
    has_emission = config.get("has_emission", False)
    triplanar = config.get("triplanar", False)
    uv_scale = config.get("uv_scale", (1.0, 1.0, 1.0))
    sharpness = config.get("triplanar_sharpness", 4.0)
    normal_scale = config.get("normal_scale", 1.0)
    emission_energy = config.get("emission_energy", 1.8)

    ext_resources = [
        ("res://assets/textures/pbr/{0}/{0}_albedo.png".format(mat_name), "1_alb"),
        ("res://assets/textures/pbr/{0}/{0}_normal.png".format(mat_name), "2_nrm"),
        ("res://assets/textures/pbr/{0}/{0}_roughness.png".format(mat_name), "3_rgh"),
        ("res://assets/textures/pbr/{0}/{0}_ao.png".format(mat_name), "4_ao"),
        ("res://assets/textures/pbr/{0}/{0}_metallic.png".format(mat_name), "5_met"),
    ]
    if has_emission:
        ext_resources.append(("res://assets/textures/pbr/{0}/{0}_emission.png".format(mat_name), "6_ems"))

    load_steps = len(ext_resources) + 1
    lines = [
        f'[gd_resource type="StandardMaterial3D" load_steps={load_steps} format=3]',
        ""
    ]
    for res_path, res_id in ext_resources:
        lines.append(f'[ext_resource type="Texture2D" path="{res_path}" id="{res_id}"]')

    lines.append("")
    lines.append("[resource]")
    lines.append(f'resource_name = "{mat_name}"')
    lines.append('albedo_texture = ExtResource("1_alb")')
    lines.append('metallic = 1.0')
    lines.append('metallic_texture = ExtResource("5_met")')
    lines.append('roughness = 1.0')
    lines.append('roughness_texture = ExtResource("3_rgh")')
    lines.append('normal_enabled = true')
    if normal_scale != 1.0:
        lines.append(f'normal_scale = {normal_scale:.2f}')
    lines.append('normal_texture = ExtResource("2_nrm")')
    lines.append('ao_enabled = true')
    lines.append('ao_light_affect = 0.5')
    lines.append('ao_texture = ExtResource("4_ao")')

    if has_emission:
        lines.append('emission_enabled = true')
        lines.append('emission = Color(1, 1, 1, 1)')
        lines.append(f'emission_energy_multiplier = {emission_energy:.2f}')
        lines.append('emission_texture = ExtResource("6_ems")')

    if uv_scale != (1.0, 1.0, 1.0):
        lines.append(f'uv1_scale = Vector3({uv_scale[0]}, {uv_scale[1]}, {uv_scale[2]})')

    if triplanar:
        lines.append('uv1_triplanar = true')
        if sharpness != 1.0:
            lines.append(f'uv1_triplanar_sharpness = {sharpness:.1f}')

    lines.append('texture_filter = 5')
    lines.append("")
    return "\n".join(lines)

# ----------------------------------------------------------------------
# Pipeline Execution & Headless Godot Pass
# ----------------------------------------------------------------------

def run_texture_pipeline(size=1024, skip_existing=False):
    """Generates all 17 high-resolution PBR texture sets."""
    os.makedirs(TEXTURES_DIR, exist_ok=True)
    os.makedirs(MATERIALS_DIR, exist_ok=True)

    print(f"============================================================")
    print(f"STARTING PROCEDURAL PBR TEXTURE GENERATION ({size}x{size})")
    print(f"Target Directory: {TEXTURES_DIR}")
    print(f"Total Materials: {len(MATERIAL_REGISTRY)}")
    print(f"============================================================")

    total_start = time.time()
    generated_count = 0

    for name, config in MATERIAL_REGISTRY.items():
        mat_dir = os.path.join(TEXTURES_DIR, name)
        os.makedirs(mat_dir, exist_ok=True)
        alb_path = os.path.join(mat_dir, f"{name}_albedo.png")

        if skip_existing and os.path.exists(alb_path):
            print(f"[SKIP] {name} already exists.")
            continue

        m_start = time.time()
        print(f"[*] Generating {name}...", end="", flush=True)

        res = config["gen_fn"](size)
        if len(res) == 6:
            albedo, normal, roughness, ao, metallic, emission = res
        else:
            albedo, normal, roughness, ao, metallic = res
            emission = None

        Image.fromarray(albedo).save(os.path.join(mat_dir, f"{name}_albedo.png"))
        Image.fromarray(normal).save(os.path.join(mat_dir, f"{name}_normal.png"))
        Image.fromarray(roughness).save(os.path.join(mat_dir, f"{name}_roughness.png"))
        Image.fromarray(ao).save(os.path.join(mat_dir, f"{name}_ao.png"))
        Image.fromarray(metallic).save(os.path.join(mat_dir, f"{name}_metallic.png"))

        orm = pack_orm(ao, roughness, metallic)
        Image.fromarray(orm).save(os.path.join(mat_dir, f"{name}_orm.png"))

        if emission is not None:
            Image.fromarray(emission).save(os.path.join(mat_dir, f"{name}_emission.png"))

        elapsed = time.time() - m_start
        print(f" done ({elapsed:.2f}s)")
        generated_count += 1

    total_elapsed = time.time() - total_start
    print(f"============================================================")
    print(f"Generated {generated_count} PBR texture sets in {total_elapsed:.2f}s!")
    print(f"============================================================")

def run_material_tres_generation():
    """Generates Godot StandardMaterial3D .tres files for all 17 materials."""
    os.makedirs(MATERIALS_DIR, exist_ok=True)
    print(f"Generating Godot StandardMaterial3D .tres files in {MATERIALS_DIR}...")
    for name, config in MATERIAL_REGISTRY.items():
        tres_content = generate_standard_material_tres(name, config)
        tres_path = os.path.join(MATERIALS_DIR, f"{name}.tres")
        with open(tres_path, "w", encoding="utf-8") as f:
            f.write(tres_content)
        print(f" -> Authored: {tres_path}")
    print(f"Authored all {len(MATERIAL_REGISTRY)} StandardMaterial3D .tres files.")

def run_godot_headless_import():
    """Executes Godot headless editor pass to import all textures and materials."""
    if not os.path.exists(GODOT_BIN):
        print(f"[WARN] Godot binary not found at {GODOT_BIN}. Skipping editor import pass.")
        return False

    print(f"\n============================================================")
    print(f"RUNNING GODOT HEADLESS EDITOR IMPORT PASS...")
    print(f"Command: {GODOT_BIN} --headless --editor --quit")
    print(f"============================================================")
    t0 = time.time()
    try:
        proc = subprocess.run(
            [GODOT_BIN, "--headless", "--editor", "--quit"],
            cwd=PROJECT_ROOT,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            timeout=60
        )
        print(f"Godot import pass finished with exit code {proc.returncode} in {time.time() - t0:.2f}s")
        if proc.stdout:
            print("Godot stdout:\n" + proc.stdout[:2000])
        if proc.stderr:
            print("Godot stderr:\n" + proc.stderr[:2000])
        return proc.returncode == 0
    except Exception as e:
        print(f"[ERROR] Godot import pass failed: {e}")
        return False

def main():
    parser = argparse.ArgumentParser(description="Procedural PBR Texture & Material Library Generator")
    parser.add_argument("--size", type=int, default=1024, help="Texture resolution (default: 1024)")
    parser.add_argument("--skip-existing", action="store_true", help="Skip existing texture sets")
    parser.add_argument("--skip-import", action="store_true", help="Skip Godot headless import pass")
    args = parser.parse_args()

    # Step 1: Generate textures
    run_texture_pipeline(size=args.size, skip_existing=args.skip_existing)

    # Step 2: Author StandardMaterial3D resources
    run_material_tres_generation()

    # Step 3: Headless Godot editor import
    if not args.skip_import:
        run_godot_headless_import()

if __name__ == "__main__":
    main()
