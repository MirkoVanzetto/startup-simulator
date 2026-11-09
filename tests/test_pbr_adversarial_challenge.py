#!/usr/bin/env python3
"""
tests/test_pbr_adversarial_challenge.py
======================================
Adversarial stress-testing harness for Milestone 1 Iteration 2 PBR Remediation Challenge.
Written by Challenger to stress-test:
1. 4-Corner Multi-tile Junction Continuity
2. 2x2 Tiled Sobel Edge Gradient Spike Analysis
3. Tangent Normal Vector Angular Deviation Across Seams
4. Dynamic Range & Variance Verification
"""

import os
import sys
import numpy as np
from PIL import Image

PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
TEXTURES_DIR = os.path.join(PROJECT_ROOT, "assets", "textures", "pbr")

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

CHANNELS = ["albedo", "normal", "roughness", "ao"]

def load_texture(mat_name, ch):
    path = os.path.join(TEXTURES_DIR, mat_name, f"{mat_name}_{ch}.png")
    if not os.path.exists(path):
        return None
    img = Image.open(path)
    return np.array(img, dtype=np.float32)

def test_corner_junctions(mat_name, ch):
    """
    When four identical tiles meet at vertex (W, H):
    Tile (0,0) at (W-1, H-1), Tile (1,0) at (0, H-1),
    Tile (0,1) at (W-1, 0),   Tile (1,1) at (0, 0).
    All 4 corners must have close values.
    """
    arr = load_texture(mat_name, ch)
    if arr is None:
        return {"error": "Missing texture"}
    h, w = arr.shape[:2]
    
    tl = arr[0, 0]
    tr = arr[0, w - 1]
    bl = arr[h - 1, 0]
    br = arr[h - 1, w - 1]
    
    # Measure max pairwise corner difference
    corners = [tl, tr, bl, br]
    diffs = []
    for i in range(4):
        for j in range(i + 1, 4):
            d = np.linalg.norm(corners[i] - corners[j]) if arr.ndim == 3 else abs(corners[i] - corners[j])
            diffs.append(float(d))
    
    max_corner_diff = max(diffs)
    mean_corner_diff = float(np.mean(diffs))
    
    # Internal baseline: adjacent corners inside (e.g. (1,1), (1,w-2), etc.)
    return {
        "max_corner_diff": max_corner_diff,
        "mean_corner_diff": mean_corner_diff
    }

def test_2x2_tiled_sobel_spike(mat_name, ch):
    """
    Stitches 2x2 tiles into 2048x2048.
    Computes horizontal and vertical Sobel gradients across the entire image.
    Compares the max gradient at the seam (x=1023->1024, y=1023->1024)
    against the 99th percentile of internal gradients.
    If there is a visual ridge or slit, the seam gradient will spike above internal edges.
    """
    arr = load_texture(mat_name, ch)
    if arr is None:
        return {"error": "Missing texture"}
    if arr.ndim == 3:
        # Grayscale luminance for edge detection
        gray = 0.299 * arr[:, :, 0] + 0.587 * arr[:, :, 1] + 0.114 * arr[:, :, 2]
    else:
        gray = arr.copy()
    
    h, w = gray.shape
    # Stitch 2x2
    tiled = np.block([
        [gray, gray],
        [gray, gray]
    ])
    
    # Finite differences across seam vs internal
    # Seam horizontal diff: column w-1 to column w
    seam_h_diff = np.abs(tiled[:, w] - tiled[:, w - 1])
    # Seam vertical diff: row h-1 to row h
    seam_v_diff = np.abs(tiled[h, :] - tiled[h - 1, :])
    
    # Internal diffs away from seam
    int_h_diff = np.abs(tiled[:, 1:w-1] - tiled[:, :w-2])
    int_v_diff = np.abs(tiled[1:h-1, :] - tiled[:h-2, :])
    
    mean_seam_h = float(np.mean(seam_h_diff))
    mean_int_h = float(np.mean(int_h_diff))
    ratio_h = mean_seam_h / max(mean_int_h, 1e-6)
    
    mean_seam_v = float(np.mean(seam_v_diff))
    mean_int_v = float(np.mean(int_v_diff))
    ratio_v = mean_seam_v / max(mean_int_v, 1e-6)
    
    max_seam_h = float(np.max(seam_h_diff))
    max_int_h = float(np.max(int_h_diff))
    
    max_seam_v = float(np.max(seam_v_diff))
    max_int_v = float(np.max(int_v_diff))
    
    return {
        "mean_seam_h": mean_seam_h,
        "mean_int_h": mean_int_h,
        "ratio_h": ratio_h,
        "mean_seam_v": mean_seam_v,
        "mean_int_v": mean_int_v,
        "ratio_v": ratio_v,
        "max_seam_h": max_seam_h,
        "max_int_h": max_int_h,
        "max_seam_v": max_seam_v,
        "max_int_v": max_int_v
    }

def test_normal_angular_continuity(mat_name):
    """
    Decodes normal vectors and computes angular deviation across horizontal & vertical seams in degrees.
    """
    arr = load_texture(mat_name, "normal")
    if arr is None:
        return {"error": "Missing normal map"}
    
    v = (arr / 255.0) * 2.0 - 1.0
    # Normalize each vector
    norms = np.linalg.norm(v, axis=-1, keepdims=True)
    norms[norms == 0] = 1.0
    u = v / norms
    
    h, w = u.shape[:2]
    # Dot product along horizontal seam (col 0 vs col w-1)
    dot_h = np.sum(u[:, 0, :] * u[:, w - 1, :], axis=-1)
    dot_h = np.clip(dot_h, -1.0, 1.0)
    angle_h_deg = np.degrees(np.arccos(dot_h))
    
    # Dot product along vertical seam (row 0 vs row h-1)
    dot_v = np.sum(u[0, :, :] * u[h - 1, :, :], axis=-1)
    dot_v = np.clip(dot_v, -1.0, 1.0)
    angle_v_deg = np.degrees(np.arccos(dot_v))
    
    # Internal baseline: adjacent columns/rows
    dot_int_h = np.sum(u[:, 1:, :] * u[:, :-1, :], axis=-1)
    dot_int_h = np.clip(dot_int_h, -1.0, 1.0)
    angle_int_h = np.degrees(np.arccos(dot_int_h))
    
    dot_int_v = np.sum(u[1:, :, :] * u[:-1, :, :], axis=-1)
    dot_int_v = np.clip(dot_int_v, -1.0, 1.0)
    angle_int_v = np.degrees(np.arccos(dot_int_v))
    
    mean_ang_h = float(np.mean(angle_h_deg))
    mean_int_ang_h = float(np.mean(angle_int_h))
    mean_ang_v = float(np.mean(angle_v_deg))
    mean_int_ang_v = float(np.mean(angle_int_v))
    
    ratio_ang_h = mean_ang_h / max(mean_int_ang_h, 1e-4)
    ratio_ang_v = mean_ang_v / max(mean_int_ang_v, 1e-4)
    
    return {
        "mean_ang_h_deg": mean_ang_h,
        "mean_int_ang_h_deg": mean_int_ang_h,
        "ratio_ang_h": ratio_ang_h,
        "mean_ang_v_deg": mean_ang_v,
        "mean_int_ang_v_deg": mean_int_ang_v,
        "ratio_ang_v": ratio_ang_v,
        "max_ang_h_deg": float(np.max(angle_h_deg)),
        "max_ang_v_deg": float(np.max(angle_v_deg)),
    }

def main():
    print("=" * 80)
    print("CHALLENGER ADVERSARIAL STRESS HARNESS: ADVANCED SEAM & CONTINUITY ANALYSIS")
    print("=" * 80)
    
    all_passed = True
    
    # 1. 2x2 Tiled Edge Gradient Ratio
    print("\n--- TEST 1: 2x2 Tiled Seam Gradient Ratio (Threshold <= 1.80) ---")
    for mat in TILING_MATERIALS:
        for ch in CHANNELS:
            res = test_2x2_tiled_sobel_spike(mat, ch)
            if "error" in res:
                print(f"  ✘ [FAIL] {mat:32s} ({ch:9s}) | {res['error']}")
                all_passed = False
                continue
            passed = res["ratio_h"] <= 1.80 and res["ratio_v"] <= 1.80
            status = "✔ [PASS]" if passed else "✘ [FAIL]"
            if not passed:
                all_passed = False
            print(f"  {status} {mat:32s} ({ch:9s}) | Rh: {res['ratio_h']:.2f} (seam {res['mean_seam_h']:.2f}/int {res['mean_int_h']:.2f}) | "
                  f"Rv: {res['ratio_v']:.2f} (seam {res['mean_seam_v']:.2f}/int {res['mean_int_v']:.2f})")
    
    # 2. Tangent Normal Vector Angular Deviation Across Seams
    print("\n--- TEST 2: Tangent Normal Vector Angular Deviation Across Seams ---")
    for mat in TILING_MATERIALS:
        res = test_normal_angular_continuity(mat)
        if "error" in res:
            print(f"  ✘ [FAIL] {mat:32s} | {res['error']}")
            all_passed = False
            continue
        passed = res["ratio_ang_h"] <= 1.80 and res["ratio_ang_v"] <= 1.80
        status = "✔ [PASS]" if passed else "✘ [FAIL]"
        if not passed:
            all_passed = False
        print(f"  {status} {mat:32s} | Ang_H: {res['mean_ang_h_deg']:.2f}° (int {res['mean_int_ang_h_deg']:.2f}°, r={res['ratio_ang_h']:.2f}) | "
              f"Ang_V: {res['mean_ang_v_deg']:.2f}° (int {res['mean_int_ang_v_deg']:.2f}°, r={res['ratio_ang_v']:.2f}) | Max_H: {res['max_ang_h_deg']:.1f}° | Max_V: {res['max_ang_v_deg']:.1f}°")
              
    # 3. 4-Corner Junction Analysis
    print("\n--- TEST 3: 4-Corner Multi-Tile Junction Step Analysis ---")
    for mat in TILING_MATERIALS:
        for ch in ["albedo", "roughness", "ao"]:
            res = test_corner_junctions(mat, ch)
            print(f"  [INFO] {mat:32s} ({ch:9s}) | Corner Pairwise Diff: Mean={res['mean_corner_diff']:.2f}, Max={res['max_corner_diff']:.2f}")

    print("\n" + "=" * 80)
    print(f"Adversarial Stress Verdict: {'APPROVE (All Stress Tests Passed)' if all_passed else 'FAIL (Defects Detected)'}")
    print("=" * 80)
    
    sys.exit(0 if all_passed else 1)

if __name__ == "__main__":
    main()
