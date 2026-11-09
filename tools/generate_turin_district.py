#!/usr/bin/env python3
"""
tools/generate_turin_district.py
================================
Procedural 3D Architectural Kit Generator for Startup Simulator (Milestone 2).
Constructs the authentic Turin neoclassical urban environment:
1. turin_roadway_boulevard.glb: 10m wide asphalt roadway (X in [-5.0, +5.0]),
   2 travel lanes, embedded double tram rails, white dashed center line,
   lateral parking bays (X in [-4.6, -2.5] and [+2.5, +4.6]), granite curbstones,
   cast-iron storm drain grates, and Torino manholes.
2. turin_portico_module.glb: Symmetrical 4.6m deep monumental covered arcades
   (West: X in [-9.6, -5.0], East: X in [+5.0, +9.6]) at Y = +0.16m, with
   classical granite pillars (0.7m x 0.7m x 3.8m), semicircular stone arches,
   groin vaults (volta a crociera, Y=4.8m apex), and Luserna flagstone floor.
3. turin_palazzo_facades.glb: 4-story Neoclassical Savoy palazzi with rusticated
   bugnato base, tall French windows with classical triangular & segmental pediments,
   wrought-iron balconies, modillion cornices, and slate mansard roofs with dormers.
4. turin_cross_street.glb: Perpendicular cross streets (Via Bogino) at Z = 20m
   (width 8m) with river cobblestones, granite wheel runners, and chamfered corner palazzi.
5. turin_piazza_san_carlo.glb: Grand civic plaza (Z in [22.0, 45.0], width 32m
   from X = -16.0 to +16.0) with diamond Luserna flagstones, central Caval 'd Brôns
   monument pedestal, and outdoor dehors pergolas.
6. turin_lantern_classic.glb: Historic cast-iron Turin bracket lantern and streetlamp.
"""

import os
import sys
import math
import numpy as np
from PIL import Image
import trimesh
from trimesh.visual.material import PBRMaterial
from trimesh.visual import TextureVisuals

PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
TEXTURES_DIR = os.path.join(PROJECT_ROOT, "assets", "textures", "pbr")
OUTPUT_DIR = os.path.join(PROJECT_ROOT, "assets", "models", "turin")
os.makedirs(OUTPUT_DIR, exist_ok=True)

# ----------------------------------------------------------------------
# Material & Texture Helpers
# ----------------------------------------------------------------------
_material_cache = {}

def get_pbr_material(mat_name, base_color_rgba, roughness=0.8, metallic=0.0):
    """
    Returns a PBRMaterial with loaded albedo texture from assets/textures/pbr/ if available,
    falling back to solid baseColorFactor.
    """
    cache_key = f"{mat_name}_{roughness}_{metallic}"
    if cache_key in _material_cache:
        return _material_cache[cache_key]

    base_tex = None
    if mat_name:
        alb_path = os.path.join(TEXTURES_DIR, mat_name, f"{mat_name}_albedo.png")
        if os.path.isfile(alb_path):
            try:
                img = Image.open(alb_path).convert("RGB")
                if img.size[0] > 512:
                    img = img.resize((512, 512), Image.Resampling.BILINEAR)
                base_tex = img
            except Exception as e:
                print(f"Warning: Failed to load albedo {alb_path}: {e}")

    mat = PBRMaterial(
        name=mat_name or f"Mat_{base_color_rgba[0]}_{base_color_rgba[1]}_{base_color_rgba[2]}",
        baseColorFactor=[c / 255.0 for c in base_color_rgba],
        baseColorTexture=base_tex,
        roughnessFactor=float(roughness),
        metallicFactor=float(metallic),
        doubleSided=False
    )
    _material_cache[cache_key] = mat
    return mat

def compute_box_planar_uvs(mesh, scale=0.5):
    """Computes triplanar/box-projected UV coordinates for an unmerged mesh."""
    normals = mesh.face_normals
    vert_normals = np.repeat(normals, 3, axis=0)
    verts = mesh.vertices
    uvs = np.zeros((len(verts), 2), dtype=np.float32)

    abs_n = np.abs(vert_normals)
    x_dom = (abs_n[:, 0] >= abs_n[:, 1]) & (abs_n[:, 0] >= abs_n[:, 2])
    y_dom = (abs_n[:, 1] > abs_n[:, 0]) & (abs_n[:, 1] >= abs_n[:, 2])
    z_dom = (abs_n[:, 2] > abs_n[:, 0]) & (abs_n[:, 2] > abs_n[:, 1])

    uvs[x_dom, 0] = verts[x_dom, 2] * scale
    uvs[x_dom, 1] = verts[x_dom, 1] * scale

    uvs[y_dom, 0] = verts[y_dom, 0] * scale
    uvs[y_dom, 1] = verts[y_dom, 2] * scale

    uvs[z_dom, 0] = verts[z_dom, 0] * scale
    uvs[z_dom, 1] = verts[z_dom, 1] * scale

    return uvs

# ----------------------------------------------------------------------
# Geometry Primitives
# ----------------------------------------------------------------------
def create_box(extents, translation=[0, 0, 0]):
    mesh = trimesh.creation.box(extents=extents)
    mesh.unmerge_vertices()
    mesh.apply_translation(translation)
    return mesh

def create_cylinder(radius, height, sections=16, translation=[0, 0, 0], rotation=None):
    mesh = trimesh.creation.cylinder(radius=radius, height=height, sections=sections)
    mesh.unmerge_vertices()
    if rotation is not None:
        mesh.apply_transform(rotation)
    mesh.apply_translation(translation)
    return mesh

def create_semicircular_arch(inner_radius, outer_radius, depth, span_angle=math.pi, sections=16, translation=[0, 0, 0], rotation=None):
    verts = []
    faces = []
    half_d = depth * 0.5

    for i in range(sections + 1):
        th = math.pi - (i / float(sections)) * span_angle
        cos_th = math.cos(th)
        sin_th = math.sin(th)

        verts.append([inner_radius * cos_th, inner_radius * sin_th,  half_d])
        verts.append([outer_radius * cos_th, outer_radius * sin_th,  half_d])
        verts.append([inner_radius * cos_th, inner_radius * sin_th, -half_d])
        verts.append([outer_radius * cos_th, outer_radius * sin_th, -half_d])

    for i in range(sections):
        b = i * 4
        nb = (i + 1) * 4
        faces.append([b + 0, b + 1, nb + 1])
        faces.append([b + 0, nb + 1, nb + 0])
        faces.append([b + 2, nb + 3, b + 3])
        faces.append([b + 2, nb + 2, nb + 3])
        faces.append([b + 0, nb + 0, nb + 2])
        faces.append([b + 0, nb + 2, b + 2])
        faces.append([b + 1, b + 3, nb + 3])
        faces.append([b + 1, nb + 3, nb + 1])

    faces.append([0, 1, 3])
    faces.append([0, 3, 2])
    last = sections * 4
    faces.append([last + 0, last + 3, last + 1])
    faces.append([last + 0, last + 2, last + 3])

    mesh = trimesh.Trimesh(vertices=np.array(verts, dtype=np.float32), faces=np.array(faces, dtype=np.int32))
    mesh.unmerge_vertices()
    if rotation is not None:
        mesh.apply_transform(rotation)
    mesh.apply_translation(translation)
    return mesh

def create_groin_vault_bay(width_x, length_z, spring_h, apex_h, subdivisions=12, translation=[0, 0, 0]):
    verts = []
    faces = []
    half_w = width_x * 0.5
    half_l = length_z * 0.5
    rise = apex_h - spring_h

    grid_x = np.linspace(-half_w, half_w, subdivisions + 1)
    grid_z = np.linspace(-half_l, half_l, subdivisions + 1)

    for i in range(subdivisions + 1):
        for j in range(subdivisions + 1):
            x = grid_x[i]
            z = grid_z[j]
            rx = max(0.0, 1.0 - (x / half_w) ** 2)
            rz = max(0.0, 1.0 - (z / half_l) ** 2)
            h = spring_h + rise * min(math.sqrt(rx), math.sqrt(rz))
            verts.append([x, h, z])

    for i in range(subdivisions):
        for j in range(subdivisions):
            p00 = i * (subdivisions + 1) + j
            p01 = i * (subdivisions + 1) + (j + 1)
            p10 = (i + 1) * (subdivisions + 1) + j
            p11 = (i + 1) * (subdivisions + 1) + (j + 1)
            faces.append([p00, p01, p11])
            faces.append([p00, p11, p10])

    mesh = trimesh.Trimesh(vertices=np.array(verts, dtype=np.float32), faces=np.array(faces, dtype=np.int32))
    mesh.unmerge_vertices()
    mesh.apply_translation(translation)
    return mesh

# ----------------------------------------------------------------------
# Scene Exporter
# ----------------------------------------------------------------------
def export_scene_groups(groups, filepath):
    """
    Exports a dictionary of groups to a multi-node GLB scene.
    groups: dict of {name: (mesh_list, material, uv_scale)}
    """
    scene = trimesh.Scene()
    total_v = 0
    total_f = 0

    for name, (mesh_list, mat, uv_scale) in groups.items():
        valid = [m for m in mesh_list if m is not None and len(m.vertices) > 0]
        if not valid:
            continue
        combined = trimesh.util.concatenate(valid)
        combined.unmerge_vertices()
        uvs = compute_box_planar_uvs(combined, scale=uv_scale)
        combined.visual = TextureVisuals(uv=uvs, material=mat)
        scene.add_geometry(combined, node_name=name, geom_name=name)
        total_v += len(combined.vertices)
        total_f += len(combined.faces)

    glb_data = trimesh.exchange.gltf.export_glb(scene)
    os.makedirs(os.path.dirname(filepath), exist_ok=True)
    with open(filepath, "wb") as f:
        f.write(glb_data)
    print(f"✔ Exported Scene GLB: {os.path.basename(filepath)} ({len(scene.geometry)} groups, {total_v} verts, {total_f} faces, {len(glb_data)/1024:.1f} KB)")

# ======================================================================
# 1. TURIN ROADWAY BOULEVARD (turin_roadway_boulevard.glb)
# ======================================================================
def generate_turin_roadway_boulevard():
    asphalt_parts = []
    rail_stone_parts = []
    rail_steel_parts = []
    centerline_parts = []
    parking_parts = []
    curb_parts = []
    drain_parts = []
    zebra_parts = []

    # Main Asphalt Slab (10.0m wide, 23.0m long)
    asphalt_parts.append(create_box([10.0, 0.20, 23.0], [0.0, -0.10, 8.5]))

    # Tram Rails (Double tracks at X = -1.2m and +1.2m)
    for rx in [-1.85, -0.55, 0.55, 1.85]:
        rail_stone_parts.append(create_box([0.28, 0.004, 23.0], [rx, 0.001, 8.5]))
        rail_steel_parts.append(create_box([0.08, 0.008, 23.0], [rx, 0.003, 8.5]))

    # White Dashed Center Line (X = 0.0)
    for z in range(-2, 20, 4):
        if (7 <= z <= 10) or (15 <= z <= 18):
            continue
        centerline_parts.append(create_box([0.18, 0.006, 2.2], [0.0, 0.003, float(z)]))

    # Curbside Parking Bays (West: X in [-4.65, -2.5], East: X in [+2.5, +4.65])
    for z in range(-2, 20, 5):
        if (7 <= z <= 10) or (15 <= z <= 18):
            continue
        parking_parts.append(create_box([0.14, 0.005, 3.8], [-2.50, 0.003, float(z)]))
        parking_parts.append(create_box([0.14, 0.005, 3.8], [ 2.50, 0.003, float(z)]))
        parking_parts.append(create_box([2.15, 0.005, 0.14], [-3.57, 0.003, float(z) - 1.9]))
        parking_parts.append(create_box([2.15, 0.005, 0.14], [ 3.57, 0.003, float(z) - 1.9]))

    # Beveled Granite Curbstones at X = -5.0 and +5.0
    curb_parts.append(create_box([0.35, 0.18, 23.0], [-4.825, 0.08, 8.5]))
    curb_parts.append(create_box([0.35, 0.18, 23.0], [ 4.825, 0.08, 8.5]))

    # Cast-Iron Drains & Manholes
    for gz in [3.5, 9.5, 15.5]:
        drain_parts.append(create_box([0.38, 0.015, 0.65], [-4.60, 0.004, gz]))
        drain_parts.append(create_box([0.38, 0.015, 0.65], [ 4.60, 0.004, gz]))
    drain_parts.append(create_cylinder(0.44, 0.012, 20, [ 0.85, 0.004,  5.0]))
    drain_parts.append(create_cylinder(0.44, 0.012, 20, [-0.85, 0.004, 12.0]))

    # Zebra Crossings at Z = 8.4 and Z = 16.5
    for x in np.linspace(-3.8, 3.8, 8):
        zebra_parts.append(create_box([0.55, 0.006, 2.5], [float(x), 0.004, 8.4]))
        zebra_parts.append(create_box([0.55, 0.006, 2.5], [float(x), 0.004, 16.5]))

    groups = {
        "BoulevardAsphalt": (asphalt_parts, get_pbr_material("turin_asphalt_avenue", [45, 48, 52, 255], 0.85, 0.0), 0.5),
        "GraniteCurbs":     (curb_parts, get_pbr_material("turin_granite_curb", [175, 172, 166, 255], 0.75, 0.0), 0.8),
        "TramRailSetts":    (rail_stone_parts, get_pbr_material("turin_granite_curb", [135, 132, 128, 255], 0.8, 0.0), 1.0),
        "TramRailSteel":    (rail_steel_parts, get_pbr_material(None, [68, 72, 80, 255], 0.35, 0.85), 1.0),
        "WhiteCenterLine":  (centerline_parts, get_pbr_material(None, [248, 248, 252, 255], 0.5, 0.0), 1.0),
        "ParkingMarkings":  (parking_parts, get_pbr_material(None, [238, 238, 242, 255], 0.5, 0.0), 1.0),
        "ZebraCrossings":   (zebra_parts, get_pbr_material(None, [250, 250, 255, 255], 0.45, 0.0), 1.0),
        "DrainGrates":      (drain_parts, get_pbr_material(None, [35, 38, 42, 255], 0.7, 0.75), 1.0),
    }
    export_scene_groups(groups, os.path.join(OUTPUT_DIR, "turin_roadway_boulevard.glb"))

# ======================================================================
# 2. MONUMENTAL TURIN PORTICO MODULE (turin_portico_module.glb)
# ======================================================================
def generate_turin_portico_module():
    floor_parts = []
    border_parts = []
    pillar_base_parts = []
    pillar_shaft_parts = []
    pillar_cap_parts = []
    arch_parts = []
    keystone_parts = []
    vault_parts = []
    entablature_parts = []
    shopfront_wood_parts = []
    shopfront_wall_parts = []
    shopfront_glass_parts = []
    lantern_boss_parts = []

    # Sidewalk Slabs at Y = +0.16m
    floor_parts.append(create_box([4.60, 0.16, 20.0], [-7.30, 0.08, 9.0]))
    floor_parts.append(create_box([4.60, 0.16, 20.0], [ 7.30, 0.08, 9.0]))

    # Border Bands
    for sign in [-1.0, 1.0]:
        border_parts.append(create_box([0.35, 0.005, 20.0], [sign * 5.175, 0.163, 9.0]))
        border_parts.append(create_box([0.35, 0.005, 20.0], [sign * 9.425, 0.163, 9.0]))

    # Pillars & Arches
    pillar_z_coords = [0.5, 4.7, 8.9, 13.1, 17.3]
    for sign in [-1.0, 1.0]:
        px = sign * 5.0
        for pz in pillar_z_coords:
            pillar_base_parts.append(create_box([0.76, 0.40, 0.76], [px, 0.36, pz]))
            pillar_shaft_parts.append(create_box([0.68, 3.04, 0.68], [px, 2.08, pz]))
            pillar_cap_parts.append(create_box([0.82, 0.20, 0.82], [px, 3.70, pz]))

        for i in range(len(pillar_z_coords) - 1):
            z_mid = (pillar_z_coords[i] + pillar_z_coords[i + 1]) * 0.5
            rot_mat = trimesh.transformations.rotation_matrix(math.pi * 0.5, [0, 1, 0])
            arch_parts.append(create_semicircular_arch(
                inner_radius=1.76, outer_radius=2.10, depth=0.72,
                sections=16, translation=[px, 3.80, z_mid], rotation=rot_mat
            ))
            keystone_parts.append(create_box([0.78, 0.38, 0.32], [px, 4.85, z_mid]))

            # Groin Vaults
            vault_cx = sign * 7.30
            bay_len = pillar_z_coords[i + 1] - pillar_z_coords[i]
            vault_parts.append(create_groin_vault_bay(4.60, bay_len, 3.80, 4.80, 12, [vault_cx, 0.0, z_mid]))
            entablature_parts.append(create_box([4.60, 0.35, 0.40], [vault_cx, 3.90, pillar_z_coords[i]]))
            lantern_boss_parts.append(create_cylinder(0.28, 0.04, 16, [vault_cx, 4.78, z_mid]))

        # Entablature
        entablature_parts.append(create_box([0.76, 0.40, 20.0], [px, 5.10, 9.0]))
        entablature_parts.append(create_box([0.92, 0.15, 20.0], [px, 5.32, 9.0]))

        # Rear Shopfronts
        rear_x = sign * 9.60
        shopfront_wood_parts.append(create_box([0.30, 0.94, 20.0], [rear_x, 0.63, 9.0]))
        shopfront_wall_parts.append(create_box([0.30, 3.70, 20.0], [rear_x, 2.95, 9.0]))
        for vz in [2.6, 6.8, 11.0, 15.2]:
            shopfront_wood_parts.append(create_box([0.08, 2.40, 2.80], [rear_x - sign * 0.12, 2.30, vz]))
            shopfront_glass_parts.append(create_box([0.04, 2.10, 2.50], [rear_x - sign * 0.14, 2.30, vz]))

    groups = {
        "PorticoFloors":     (floor_parts, get_pbr_material("turin_luserna_flagstones", [190, 186, 178, 255], 0.7, 0.0), 0.6),
        "GraniteBorders":    (border_parts, get_pbr_material("turin_granite_curb", [135, 130, 125, 255], 0.75, 0.0), 1.0),
        "PillarBases":       (pillar_base_parts, get_pbr_material("turin_granite_curb", [175, 170, 162, 255], 0.75, 0.0), 0.8),
        "PillarShafts":      (pillar_shaft_parts, get_pbr_material("turin_portico_column_fluted", [198, 194, 186, 255], 0.65, 0.0), 0.6),
        "PillarCapitals":    (pillar_cap_parts, get_pbr_material("turin_granite_curb", [180, 175, 168, 255], 0.75, 0.0), 1.0),
        "Arches":            (arch_parts, get_pbr_material("turin_granite_curb", [185, 180, 172, 255], 0.75, 0.0), 0.7),
        "Keystones":         (keystone_parts, get_pbr_material("turin_granite_curb", [165, 160, 152, 255], 0.75, 0.0), 1.0),
        "GroinVaultCeilings":(vault_parts, get_pbr_material("turin_facade_plaster_cream", [242, 238, 230, 255], 0.9, 0.0), 0.5),
        "Architraves":       (entablature_parts, get_pbr_material("turin_granite_curb", [185, 180, 172, 255], 0.75, 0.0), 0.6),
        "ShopfrontWood":     (shopfront_wood_parts, get_pbr_material("turin_storefront_wood", [82, 52, 34, 255], 0.6, 0.0), 0.8),
        "ShopfrontRustico":  (shopfront_wall_parts, get_pbr_material("turin_rustic_bugnato", [228, 222, 212, 255], 0.8, 0.0), 0.5),
        "ShopfrontGlass":    (shopfront_glass_parts, get_pbr_material(None, [170, 210, 230, 255], 0.15, 0.1), 1.0),
        "LanternBosses":     (lantern_boss_parts, get_pbr_material(None, [45, 48, 52, 255], 0.7, 0.8), 1.0),
    }
    export_scene_groups(groups, os.path.join(OUTPUT_DIR, "turin_portico_module.glb"))

# ======================================================================
# 3. 4-STORY NEOCLASSICAL PALAZZO FACADES (turin_palazzo_facades.glb)
# ======================================================================
def generate_turin_palazzo_facades():
    floor1_parts = []
    floor2_parts = []
    cornice_parts = []
    window_frame_parts = []
    window_glass_parts = []
    pediment_parts = []
    shutter_parts = []
    balcony_parts = []
    roof_parts = []
    dormer_parts = []
    chimney_parts = []

    window_z_coords = [2.6, 6.8, 11.0, 15.2]

    for sign in [-1.0, 1.0]:
        fx = sign * 5.0
        # Floor 1 (Ochre)
        floor1_parts.append(create_box([0.55, 3.20, 20.0], [fx, 6.90, 9.0]))
        # Floor 2 (Terracotta)
        floor2_parts.append(create_box([0.55, 2.80, 20.0], [fx, 10.10, 9.0]))
        # Stringcourses
        cornice_parts.append(create_box([0.72, 0.22, 20.0], [fx, 8.61, 9.0]))
        cornice_parts.append(create_box([0.72, 0.22, 20.0], [fx, 11.61, 9.0]))
        cornice_parts.append(create_box([1.05, 0.35, 20.0], [fx - sign * 0.15, 11.90, 9.0]))

        for bz in np.linspace(0.0, 18.0, 23):
            cornice_parts.append(create_box([0.35, 0.28, 0.20], [fx - sign * 0.35, 11.74, float(bz)]))

        for wz in window_z_coords:
            # Floor 1 Windows
            window_glass_parts.append(create_box([0.08, 2.20, 1.20], [fx - sign * 0.26, 6.60, wz]))
            window_frame_parts.append(create_box([0.12, 2.36, 1.36], [fx - sign * 0.24, 6.60, wz]))
            pediment_parts.append(create_box([0.24, 0.12, 1.56], [fx - sign * 0.28, 7.84, wz]))
            pediment_parts.append(create_box([0.20, 0.50, 1.40], [fx - sign * 0.26, 8.14, wz]))
            shutter_parts.append(create_box([0.06, 2.20, 0.45], [fx - sign * 0.27, 6.60, wz - 0.85]))
            shutter_parts.append(create_box([0.06, 2.20, 0.45], [fx - sign * 0.27, 6.60, wz + 0.85]))

            # Floor 2 Windows & Balconies
            window_glass_parts.append(create_box([0.08, 1.90, 1.10], [fx - sign * 0.26, 9.85, wz]))
            window_frame_parts.append(create_box([0.12, 2.06, 1.26], [fx - sign * 0.24, 9.85, wz]))
            arch_rot = trimesh.transformations.rotation_matrix(math.pi * 0.5, [0, 1, 0])
            pediment_parts.append(create_semicircular_arch(0.68, 0.82, 0.20, math.pi * 0.65, 10, [fx - sign * 0.26, 10.95, wz], arch_rot))

            balcony_parts.append(create_box([0.75, 0.16, 1.70], [fx - sign * 0.45, 8.80, wz])) # stone base
            balcony_parts.append(create_box([0.05, 0.88, 1.66], [fx - sign * 0.80, 9.32, wz])) # front railing
            balcony_parts.append(create_box([0.65, 0.88, 0.05], [fx - sign * 0.50, 9.32, wz - 0.81]))
            balcony_parts.append(create_box([0.65, 0.88, 0.05], [fx - sign * 0.50, 9.32, wz + 0.81]))
            balcony_parts.append(create_box([0.08, 0.06, 1.70], [fx - sign * 0.80, 9.78, wz])) # brass rail

            shutter_parts.append(create_box([0.06, 1.90, 0.42], [fx - sign * 0.27, 9.85, wz - 0.78]))
            shutter_parts.append(create_box([0.06, 1.90, 0.42], [fx - sign * 0.27, 9.85, wz + 0.78]))

            # Floor 3 Dormers
            dormer_x = fx - sign * 0.15
            dormer_parts.append(create_box([1.10, 1.40, 1.05], [dormer_x, 13.00, wz]))
            window_glass_parts.append(create_box([0.08, 0.95, 0.75], [dormer_x - sign * 0.52, 12.95, wz]))
            dormer_parts.append(create_box([1.25, 0.22, 1.15], [dormer_x, 13.78, wz]))
            dormer_parts.append(create_cylinder(0.04, 0.35, 8, [dormer_x - sign * 0.35, 14.05, wz]))

        # Mansard Roof Slab
        mansard_slab = create_box([2.20, 2.60, 20.0], [fx + sign * 0.90, 13.20, 9.0])
        roof_tilt = trimesh.transformations.rotation_matrix(sign * math.radians(28), [0, 0, 1])
        mansard_slab.apply_transform(roof_tilt)
        roof_parts.append(mansard_slab)

        # Chimneys
        for cz in [4.0, 14.0]:
            chimney_parts.append(create_box([0.70, 1.60, 0.70], [fx + sign * 1.80, 14.50, cz]))
            chimney_parts.append(create_box([0.85, 0.18, 0.85], [fx + sign * 1.80, 15.35, cz]))

    groups = {
        "PalazzoFloor1Ochre":  (floor1_parts, get_pbr_material("turin_facade_plaster_ochre", [217, 167, 74, 255], 0.8, 0.0), 0.5),
        "PalazzoFloor2Rose":   (floor2_parts, get_pbr_material("turin_facade_plaster_terracotta", [184, 104, 82, 255], 0.8, 0.0), 0.5),
        "PalazzoCornices":     (cornice_parts, get_pbr_material("turin_granite_curb", [195, 190, 182, 255], 0.75, 0.0), 0.8),
        "WindowFrames":        (window_frame_parts, get_pbr_material("turin_granite_curb", [225, 220, 210, 255], 0.75, 0.0), 1.0),
        "Pediments":           (pediment_parts, get_pbr_material("turin_granite_curb", [210, 205, 196, 255], 0.75, 0.0), 1.0),
        "WindowShutters":      (shutter_parts, get_pbr_material("turin_window_shutter", [30, 52, 38, 255], 0.7, 0.0), 0.8),
        "Balconies":           (balcony_parts, get_pbr_material(None, [45, 48, 52, 255], 0.5, 0.7), 1.0),
        "WindowGlazing":       (window_glass_parts, get_pbr_material(None, [180, 215, 235, 255], 0.15, 0.1), 1.0),
        "MansardSlateRoof":    (roof_parts, get_pbr_material("turin_cobblestone_river", [52, 56, 64, 255], 0.9, 0.0), 0.5),
        "DormersZinc":         (dormer_parts, get_pbr_material(None, [175, 180, 188, 255], 0.45, 0.6), 1.0),
        "ChimneysBrick":       (chimney_parts, get_pbr_material("turin_facade_plaster_terracotta", [165, 75, 52, 255], 0.85, 0.0), 0.8),
    }
    export_scene_groups(groups, os.path.join(OUTPUT_DIR, "turin_palazzo_facades.glb"))

# ======================================================================
# 4. CROSS STREET & CORNER PALAZZI (turin_cross_street.glb)
# ======================================================================
def generate_turin_cross_street():
    cobble_parts = []
    runners_parts = []
    sidewalk_parts = []
    curb_parts = []
    bldg_parts = []
    balcony_parts = []
    sign_parts = []

    for sign in [-1.0, 1.0]:
        arm_cx = sign * 12.5
        cobble_parts.append(create_box([15.0, 0.20, 8.0], [arm_cx, -0.10, 20.0]))
        runners_parts.append(create_box([15.0, 0.006, 0.45], [arm_cx, 0.003, 18.6]))
        runners_parts.append(create_box([15.0, 0.006, 0.45], [arm_cx, 0.003, 21.4]))
        sidewalk_parts.append(create_box([15.0, 0.16, 1.50], [arm_cx, 0.08, 15.25]))
        sidewalk_parts.append(create_box([15.0, 0.16, 1.50], [arm_cx, 0.08, 24.75]))
        curb_parts.append(create_box([15.0, 0.18, 0.25], [arm_cx, 0.09, 16.125]))
        curb_parts.append(create_box([15.0, 0.18, 0.25], [arm_cx, 0.09, 23.875]))

    corners = [
        {"x": -10.5, "z": 14.5, "rot":  45, "sign_x": -1.0},
        {"x": -10.5, "z": 25.5, "rot": -45, "sign_x": -1.0},
        {"x":  10.5, "z": 14.5, "rot": -45, "sign_x":  1.0},
        {"x":  10.5, "z": 25.5, "rot":  45, "sign_x":  1.0},
    ]
    for c in corners:
        bldg_parts.append(create_box([5.0, 14.0, 5.0], [c["x"], 7.0, c["z"]]))
        rot_mat = trimesh.transformations.rotation_matrix(math.radians(c["rot"]), [0, 1, 0])
        bev = create_box([2.4, 14.0, 0.4], [c["x"], 7.0, c["z"]])
        bev.apply_transform(rot_mat)
        bldg_parts.append(bev)
        balcony_parts.append(create_cylinder(1.20, 0.20, 12, [c["x"], 8.50, c["z"]]))
        balcony_parts.append(create_cylinder(1.18, 0.85, 12, [c["x"], 9.00, c["z"]]))
        sign_parts.append(create_box([0.10, 0.35, 0.90], [c["x"] - c["sign_x"] * 2.2, 3.2, c["z"]]))

    groups = {
        "RiverCobblestones": (cobble_parts, get_pbr_material("turin_cobblestone_river", [98, 92, 85, 255], 0.85, 0.0), 0.5),
        "WheelRunners":      (runners_parts, get_pbr_material("turin_granite_curb", [185, 180, 175, 255], 0.75, 0.0), 1.0),
        "CrossSidewalks":    (sidewalk_parts, get_pbr_material("turin_luserna_flagstones", [180, 176, 170, 255], 0.7, 0.0), 0.8),
        "CrossCurbs":        (curb_parts, get_pbr_material("turin_granite_curb", [160, 156, 150, 255], 0.75, 0.0), 0.8),
        "CornerPalazzi":     (bldg_parts, get_pbr_material("turin_facade_plaster_cream", [220, 214, 202, 255], 0.8, 0.0), 0.5),
        "CornerBalconies":   (balcony_parts, get_pbr_material(None, [45, 48, 52, 255], 0.5, 0.7), 1.0),
        "BlueStreetSigns":   (sign_parts, get_pbr_material(None, [18, 38, 92, 255], 0.4, 0.1), 1.0),
    }
    export_scene_groups(groups, os.path.join(OUTPUT_DIR, "turin_cross_street.glb"))

# ======================================================================
# 5. GRAND PIAZZA SAN CARLO (turin_piazza_san_carlo.glb)
# ======================================================================
def generate_turin_piazza_san_carlo():
    paving_parts = []
    accent_parts = []
    colonnade_walk_parts = []
    colonnade_pillar_parts = []
    colonnade_beam_parts = []
    pedestal_plinth_parts = []
    pedestal_marble_parts = []
    statue_bronze_parts = []
    bollard_parts = []
    pergola_frame_parts = []
    pergola_canopy_parts = []
    dining_parts = []
    topiary_parts = []

    # Plaza Paving (32m x 23m at Y = +0.16m)
    paving_parts.append(create_box([32.0, 0.16, 23.0], [0.0, 0.08, 33.5]))

    # Dark Diorite Lozenge Accents
    for x in np.linspace(-12.0, 12.0, 7):
        for z in np.linspace(24.0, 42.0, 7):
            rot_mat = trimesh.transformations.rotation_matrix(math.radians(45), [0, 1, 0])
            lozenge = create_box([1.10, 0.005, 1.10], [float(x), 0.163, float(z)])
            lozenge.apply_transform(rot_mat)
            accent_parts.append(lozenge)

    # Colonnade Wings at X = +/-14.0
    for sign in [-1.0, 1.0]:
        px = sign * 14.0
        colonnade_walk_parts.append(create_box([4.0, 0.18, 23.0], [px, 0.09, 33.5]))
        for pz in np.linspace(23.5, 43.5, 6):
            colonnade_pillar_parts.append(create_box([0.80, 0.40, 0.80], [px, 0.36, float(pz)]))
            colonnade_pillar_parts.append(create_box([0.72, 3.60, 0.72], [px, 2.36, float(pz)]))
            colonnade_pillar_parts.append(create_box([0.86, 0.24, 0.86], [px, 4.28, float(pz)]))
        colonnade_beam_parts.append(create_box([0.85, 0.50, 23.0], [px, 4.65, 33.5]))
        colonnade_beam_parts.append(create_box([0.85, 0.85, 23.0], [px, 5.32, 33.5]))

    # Caval 'd Brôns Monument at (0, 0.16, 32.0)
    mon_x, mon_z = 0.0, 32.0
    pedestal_plinth_parts.append(create_box([4.60, 0.35, 3.40], [mon_x, 0.335, mon_z]))
    pedestal_plinth_parts.append(create_box([3.80, 0.35, 2.60], [mon_x, 0.685, mon_z]))
    pedestal_marble_parts.append(create_box([2.80, 1.40, 1.70], [mon_x, 1.56, mon_z]))
    statue_bronze_parts.append(create_box([2.84, 0.90, 0.10], [mon_x, 1.56, mon_z - 0.82]))
    statue_bronze_parts.append(create_box([2.84, 0.90, 0.10], [mon_x, 1.56, mon_z + 0.82]))
    pedestal_marble_parts.append(create_box([3.10, 0.19, 1.95], [mon_x, 2.355, mon_z]))

    # Bronze Equestrian Statue
    statue_bronze_parts.append(create_box([1.10, 1.10, 2.20], [mon_x, 3.20, mon_z]))
    statue_bronze_parts.append(create_box([0.55, 1.10, 0.70], [mon_x, 3.90, mon_z - 0.90]))
    statue_bronze_parts.append(create_box([0.45, 0.50, 0.65], [mon_x, 4.30, mon_z - 1.30]))
    statue_bronze_parts.append(create_cylinder(0.12, 1.40, 10, [mon_x - 0.38, 2.50, mon_z - 0.75]))
    statue_bronze_parts.append(create_cylinder(0.12, 1.40, 10, [mon_x + 0.38, 2.50, mon_z - 0.75]))
    statue_bronze_parts.append(create_cylinder(0.12, 1.40, 10, [mon_x - 0.38, 2.50, mon_z + 0.75]))
    statue_bronze_parts.append(create_cylinder(0.12, 1.40, 10, [mon_x + 0.38, 2.50, mon_z + 0.75]))
    statue_bronze_parts.append(create_box([0.65, 0.95, 0.55], [mon_x, 4.20, mon_z]))
    statue_bronze_parts.append(create_cylinder(0.18, 0.45, 10, [mon_x, 4.85, mon_z]))
    statue_bronze_parts.append(create_box([0.08, 0.35, 0.40], [mon_x, 5.20, mon_z]))
    statue_bronze_parts.append(create_box([0.06, 0.06, 1.10], [mon_x - 0.42, 3.95, mon_z + 0.20]))

    # Bollards
    for bx, bz in [(-2.6, 29.5), (0.0, 29.5), (2.6, 29.5), (-2.6, 34.5), (0.0, 34.5), (2.6, 34.5), (-2.6, 32.0), (2.6, 32.0)]:
        bollard_parts.append(create_cylinder(0.14, 0.85, 12, [bx, 0.58, bz]))

    # Outdoor Dehors Pergolas
    for sign in [-1.0, 1.0]:
        dx, dz = sign * 7.5, 27.5
        pergola_frame_parts.append(create_box([4.2, 0.10, 5.2], [dx, 2.80, dz]))
        for px in [dx - 2.0, dx + 2.0]:
            for pz in [dz - 2.5, dz + 2.5]:
                pergola_frame_parts.append(create_cylinder(0.06, 2.70, 8, [px, 1.45, pz]))
        pergola_canopy_parts.append(create_box([4.1, 0.05, 5.1], [dx, 2.85, dz]))
        pergola_canopy_parts.append(create_box([4.15, 0.25, 0.04], [dx, 2.70, dz - 2.55]))
        pergola_canopy_parts.append(create_box([4.15, 0.25, 0.04], [dx, 2.70, dz + 2.55]))

        for tz in [dz - 1.4, dz + 1.4]:
            for tx in [dx - 1.1, dx + 1.1]:
                dining_parts.append(create_cylinder(0.45, 0.72, 12, [tx, 0.52, tz]))
                dining_parts.append(create_cylinder(0.04, 0.70, 8,  [tx, 0.51, tz]))
                dining_parts.append(create_box([0.38, 0.44, 0.38], [tx, 0.38, tz - 0.65]))
                dining_parts.append(create_box([0.38, 0.44, 0.38], [tx, 0.38, tz + 0.65]))

        for lx in [dx - 2.1, dx + 2.1]:
            topiary_parts.append(create_cylinder(0.35, 0.55, 12, [lx, 0.435, dz - 2.6]))
            topiary_parts.append(create_cylinder(0.42, 0.65, 10, [lx, 0.95, dz - 2.6]))

    groups = {
        "PiazzaLusernaPaving": (paving_parts, get_pbr_material("turin_luserna_flagstones", [194, 190, 182, 255], 0.7, 0.0), 0.4),
        "DioriteLozenges":     (accent_parts, get_pbr_material(None, [72, 75, 82, 255], 0.65, 0.0), 1.0),
        "ColonnadeWalkways":   (colonnade_walk_parts, get_pbr_material("turin_luserna_flagstones", [180, 175, 168, 255], 0.7, 0.0), 0.6),
        "ColonnadePillars":    (colonnade_pillar_parts, get_pbr_material("turin_portico_column_fluted", [195, 190, 182, 255], 0.7, 0.0), 0.6),
        "ColonnadeEntablature":(colonnade_beam_parts, get_pbr_material("turin_granite_curb", [185, 180, 172, 255], 0.75, 0.0), 0.6),
        "PedestalBavenoPink":  (pedestal_plinth_parts, get_pbr_material("turin_granite_curb", [185, 135, 128, 255], 0.75, 0.0), 0.8),
        "PedestalMarbleWhite": (pedestal_marble_parts, get_pbr_material("turin_facade_plaster_cream", [230, 226, 218, 255], 0.6, 0.0), 0.6),
        "BronzeEquestrian":    (statue_bronze_parts, get_pbr_material(None, [52, 46, 40, 255], 0.45, 0.8), 1.0),
        "PlazaBollards":       (bollard_parts, get_pbr_material(None, [38, 40, 44, 255], 0.6, 0.8), 1.0),
        "DehorsIronFrames":    (pergola_frame_parts, get_pbr_material(None, [45, 48, 52, 255], 0.6, 0.7), 1.0),
        "DehorsCanopies":      (pergola_canopy_parts, get_pbr_material("turin_cafe_awning_striped", [245, 240, 230, 255], 0.9, 0.0), 0.6),
        "DehorsDiningSets":    (dining_parts, get_pbr_material(None, [235, 230, 222, 255], 0.7, 0.0), 1.0),
        "LaurelTopiaries":     (topiary_parts, get_pbr_material(None, [38, 72, 45, 255], 0.9, 0.0), 1.0),
    }
    export_scene_groups(groups, os.path.join(OUTPUT_DIR, "turin_piazza_san_carlo.glb"))

# ======================================================================
# 6. HISTORIC TURIN CAST-IRON LANTERN (turin_lantern_classic.glb)
# ======================================================================
def generate_turin_lantern_classic():
    iron_parts = []
    glass_parts = []
    brass_parts = []

    iron_parts.append(create_cylinder(0.26, 0.35, 12, [0, 0.175, 0]))
    iron_parts.append(create_cylinder(0.20, 0.35, 12, [0, 0.525, 0]))
    iron_parts.append(create_cylinder(0.09, 2.50, 12, [0, 1.95, 0]))
    iron_parts.append(create_cylinder(0.18, 0.20, 12, [0, 3.30, 0]))
    iron_parts.append(create_box([0.70, 0.08, 0.12], [0, 3.42, 0]))

    glass_parts.append(create_cylinder(0.28, 0.55, 6, [0, 3.75, 0]))
    iron_parts.append(create_cylinder(0.29, 0.06, 6, [0, 3.48, 0]))
    iron_parts.append(create_cylinder(0.31, 0.06, 6, [0, 4.02, 0]))
    iron_parts.append(create_cylinder(0.33, 0.22, 6, [0, 4.14, 0]))
    brass_parts.append(create_cylinder(0.04, 0.35, 8, [0, 4.38, 0]))

    groups = {
        "LanternCastIron": (iron_parts, get_pbr_material(None, [42, 45, 48, 255], 0.6, 0.8), 1.0),
        "LanternGlass":    (glass_parts, get_pbr_material(None, [255, 235, 175, 255], 0.2, 0.0), 1.0),
        "LanternBrass":    (brass_parts, get_pbr_material(None, [210, 175, 60, 255], 0.35, 0.85), 1.0),
    }
    export_scene_groups(groups, os.path.join(OUTPUT_DIR, "turin_lantern_classic.glb"))

# ======================================================================
# MAIN GENERATION PIPELINE
# ======================================================================
def main():
    print("=" * 70)
    print("TURIN ARCHITECTURAL DISTRICT GENERATOR (Milestone 2 Modular Overhaul)")
    print("=" * 70)

    generate_turin_roadway_boulevard()
    generate_turin_portico_module()
    generate_turin_palazzo_facades()
    generate_turin_cross_street()
    generate_turin_piazza_san_carlo()
    generate_turin_lantern_classic()

    print("\n" + "=" * 70)
    print("All Turin District Modular Assets Generated Successfully!")
    print("=" * 70)

if __name__ == "__main__":
    main()
