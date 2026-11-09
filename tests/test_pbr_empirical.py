#!/usr/bin/env python3
"""
tests/test_pbr_empirical.py
===========================
Adversarial empirical stress-testing suite for Milestone 1 PBR Texture & Material Library.

Verifies:
1. Seamlessness: Image border continuity across horizontal (x=0 vs x=W-1) and
   vertical (y=0 vs y=H-1) seams across all texture maps.
2. Normal Map Vector Validity: Tangent-space normal vectors decode to unit vectors
   where X^2 + Y^2 + Z^2 ~= 1 and +Z > 0.
"""

import os
import sys
import glob
import numpy as np
from PIL import Image

PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
TEXTURES_DIR = os.path.join(PROJECT_ROOT, "assets", "textures", "pbr")
MATERIALS_DIR = os.path.join(PROJECT_ROOT, "assets", "materials")

MATERIALS = [
    "turin_cobblestone_river",
    "turin_luserna_flagstones",
    "turin_asphalt_avenue",
    "turin_granite_curb",
    "turin_portico_marble_floor",
    "turin_portico_column_fluted",
    "turin_facade_plaster_ochre",
    "turin_facade_plaster_cream",
    "turin_facade_plaster_terracotta",
    "turin_rustic_bugnato",
    "turin_window_shutter",
    "turin_storefront_wood",
    "turin_cafe_awning_striped",
    "startup_server_perforated_metal",
    "startup_brushed_dark_aluminum",
    "startup_desk_wood_veneer",
    "startup_screen_emissive",
]

# Materials configured with triplanar=true or designed for continuous UV tiling
TILING_MATERIALS = [
    "turin_cobblestone_river",
    "turin_luserna_flagstones",
    "turin_granite_curb",
    "turin_portico_marble_floor",
    "turin_portico_column_fluted",
    "turin_facade_plaster_ochre",
    "turin_facade_plaster_cream",
    "turin_facade_plaster_terracotta",
    "turin_rustic_bugnato",
    "turin_storefront_wood",
    "startup_server_perforated_metal",
    "startup_brushed_dark_aluminum",
    "startup_desk_wood_veneer",
]

# Non-tiling or 1D directional materials
NON_TRIPLANAR_MATERIALS = [
    "turin_asphalt_avenue",
    "turin_window_shutter",
    "turin_cafe_awning_striped",
    "startup_screen_emissive",
]


def test_seamlessness(mat_name: str, channel: str = "albedo"):
    """
    Empirically analyzes border continuity across horizontal and vertical seams.
    Returns a dict with seam delta stats and discontinuity ratios.
    """
    img_path = os.path.join(TEXTURES_DIR, mat_name, f"{mat_name}_{channel}.png")
    if not os.path.exists(img_path):
        return {"error": f"File not found: {img_path}"}

    img = Image.open(img_path)
    arr = np.array(img, dtype=np.float32)

    # Normalize to 2D or 3D float [0, 255]
    h, w = arr.shape[:2]

    # Horizontal seam: column 0 vs column w-1
    # Vertical seam: row 0 vs row h-1
    if arr.ndim == 3:
        # Multi-channel (e.g. RGB) -> Euclidean color delta
        seam_h_diff = np.linalg.norm(arr[:, 0, :] - arr[:, w - 1, :], axis=-1)
        seam_v_diff = np.linalg.norm(arr[0, :, :] - arr[h - 1, :, :], axis=-1)

        # Internal adjacent pixel diffs for baseline comparison
        internal_h_diff = np.linalg.norm(arr[:, 1:, :] - arr[:, :-1, :], axis=-1)
        internal_v_diff = np.linalg.norm(arr[1:, :, :] - arr[:-1, :, :], axis=-1)
    else:
        seam_h_diff = np.abs(arr[:, 0] - arr[:, w - 1])
        seam_v_diff = np.abs(arr[0, :] - arr[h - 1, :])

        internal_h_diff = np.abs(arr[:, 1:] - arr[:, :-1])
        internal_v_diff = np.abs(arr[1:, :] - arr[:-1, :])

    mean_seam_h = float(np.mean(seam_h_diff))
    max_seam_h = float(np.max(seam_h_diff))
    mean_int_h = float(np.mean(internal_h_diff))
    max_int_h = float(np.max(internal_h_diff))

    mean_seam_v = float(np.mean(seam_v_diff))
    max_seam_v = float(np.max(seam_v_diff))
    mean_int_v = float(np.mean(internal_v_diff))
    max_int_v = float(np.max(internal_v_diff))

    # Discontinuity ratio: seam step vs natural internal step
    ratio_h = mean_seam_h / max(mean_int_h, 1e-6)
    ratio_v = mean_seam_v / max(mean_int_v, 1e-6)

    return {
        "mean_seam_h": mean_seam_h,
        "max_seam_h": max_seam_h,
        "mean_int_h": mean_int_h,
        "max_int_h": max_int_h,
        "ratio_h": ratio_h,
        "mean_seam_v": mean_seam_v,
        "max_seam_v": max_seam_v,
        "mean_int_v": mean_int_v,
        "max_int_v": max_int_v,
        "ratio_v": ratio_v,
    }


def test_normal_map_validity(mat_name: str):
    """
    Decodes the tangent-space normal map and verifies:
    1. Unit vector magnitude: X^2 + Y^2 + Z^2 ~= 1.0 (within 8-bit quantization tolerance).
    2. Tangent vector hemisphere: +Z > 0 for all pixels.
    """
    img_path = os.path.join(TEXTURES_DIR, mat_name, f"{mat_name}_normal.png")
    if not os.path.exists(img_path):
        return {"error": f"File not found: {img_path}"}

    img = Image.open(img_path).convert("RGB")
    arr = np.array(img, dtype=np.float32)

    # Standard GPU normal map decoding: [0, 255] -> [-1.0, 1.0]
    # In Godot / OpenGL: v = (color / 255.0) * 2.0 - 1.0
    v = (arr / 255.0) * 2.0 - 1.0
    x, y, z = v[:, :, 0], v[:, :, 1], v[:, :, 2]

    mag_sq = x * x + y * y + z * z
    mag = np.sqrt(mag_sq)

    # Unit vector deviation
    delta_mag_sq = np.abs(mag_sq - 1.0)
    max_delta = float(np.max(delta_mag_sq))
    mean_delta = float(np.mean(delta_mag_sq))
    p99_delta = float(np.percentile(delta_mag_sq, 99))

    # Quantization limits: 8-bit color gives step size 2.0 / 255 ~= 0.00784
    # Expected maximum error from quantization rounding alone: ~0.025
    # Check +Z hemisphere
    min_z = float(np.min(z))
    non_positive_z_count = int(np.sum(z <= 0.0))
    total_pixels = int(arr.shape[0] * arr.shape[1])

    # Pixels where unit length error exceeds 5%
    outlier_count = int(np.sum(delta_mag_sq > 0.05))

    return {
        "total_pixels": total_pixels,
        "mean_mag_sq": float(np.mean(mag_sq)),
        "min_mag_sq": float(np.min(mag_sq)),
        "max_mag_sq": float(np.max(mag_sq)),
        "mean_delta": mean_delta,
        "p99_delta": p99_delta,
        "max_delta": max_delta,
        "min_z": min_z,
        "non_positive_z_count": non_positive_z_count,
        "outlier_count": outlier_count,
        "pass_unit_vector": outlier_count == 0,
        "pass_positive_z": non_positive_z_count == 0 and min_z > 0.0,
    }


def main():
    print("=" * 70)
    print("CHALLENGER 1: EMPIRICAL STRESS-TEST FOR PBR TEXTURE & MATERIAL PIPELINE")
    print("=" * 70)

    # -------------------------------------------------------------
    # SUITE 1: NORMAL MAP VECTOR VALIDITY ACROSS ALL 17 MATERIALS
    # -------------------------------------------------------------
    print("\n[SUITE 1] EMPIRICAL NORMAL MAP VECTOR VALIDITY (X^2 + Y^2 + Z^2 ~= 1, +Z > 0)")
    normal_all_passed = True
    normal_results = {}

    for mat in MATERIALS:
        res = test_normal_map_validity(mat)
        normal_results[mat] = res
        if "error" in res:
            print(f"  ✘ [FAIL] {mat:32s} | Error: {res['error']}")
            normal_all_passed = False
            continue

        is_unit = res["pass_unit_vector"]
        is_pos_z = res["pass_positive_z"]
        passed = is_unit and is_pos_z
        if not passed:
            normal_all_passed = False

        status = "✔ [PASS]" if passed else "✘ [FAIL]"
        print(f"  {status} {mat:32s} | |V|^2: {res['mean_mag_sq']:.4f} (range [{res['min_mag_sq']:.4f}, {res['max_mag_sq']:.4f}]) "
              f"| max_err: {res['max_delta']:.4f} | min_+Z: {res['min_z']:+.4f} | outliers: {res['outlier_count']}")

    print(f"\nSuite 1 Verdict: {'ALL 17 NORMAL MAPS VALID' if normal_all_passed else 'NORMAL MAP DEFECTS DETECTED'}")

    # -------------------------------------------------------------
    # SUITE 2: SEAMLESSNESS & BORDER CONTINUITY ACROSS ALL TEXTURES
    # -------------------------------------------------------------
    print("\n" + "=" * 70)
    print("[SUITE 2] EMPIRICAL BORDER SEAM CONTINUITY ANALYSIS")
    print("=" * 70)

    seamless_results = {}
    channels = ["albedo", "normal", "roughness", "ao"]

    print("\n--- A. TILING / TRIPLANAR MATERIALS (Must have seamless border continuity) ---")
    tiling_passed = True
    for mat in TILING_MATERIALS:
        for ch in channels:
            res = test_seamlessness(mat, ch)
            seamless_results[(mat, ch)] = res
            if "error" in res:
                print(f"  ✘ [FAIL] {mat:32s} ({ch:9s}) | {res['error']}")
                tiling_passed = False
                continue

            # In seamless textures, ratio of seam step to internal step should be <= 1.8
            # and max seam delta should not exceed 2.0x the max internal step.
            h_ok = res["ratio_h"] <= 1.8
            v_ok = res["ratio_v"] <= 1.8
            ch_passed = h_ok and v_ok
            if not ch_passed:
                tiling_passed = False

            status = "✔ [PASS]" if ch_passed else "✘ [FAIL]"
            print(f"  {status} {mat:32s} ({ch:9s}) | "
                  f"H-seam: {res['mean_seam_h']:.2f} (int {res['mean_int_h']:.2f}, r={res['ratio_h']:.2f}) | "
                  f"V-seam: {res['mean_seam_v']:.2f} (int {res['mean_int_v']:.2f}, r={res['ratio_v']:.2f})")

    print("\n--- B. DIRECTIONAL & NON-TRIPLANAR MATERIALS (Documented Seam Characteristics) ---")
    for mat in NON_TRIPLANAR_MATERIALS:
        for ch in ["albedo", "normal"]:
            res = test_seamlessness(mat, ch)
            if "error" in res:
                print(f"  [INFO] {mat:32s} ({ch:9s}) | {res['error']}")
                continue
            print(f"  [INFO] {mat:32s} ({ch:9s}) | "
                  f"H-seam: {res['mean_seam_h']:.2f} (r={res['ratio_h']:.2f}) | "
                  f"V-seam: {res['mean_seam_v']:.2f} (r={res['ratio_v']:.2f})")

    print("\n" + "=" * 70)
    print(f"PBR Textures Empirical Summary: Normal Maps: {'PASS' if normal_all_passed else 'FAIL'}, Tiling Seamlessness: {'PASS' if tiling_passed else 'FAIL'}")
    print("=" * 70)

    if not normal_all_passed or not tiling_passed:
        sys.exit(1)
    else:
        sys.exit(0)


if __name__ == "__main__":
    main()
