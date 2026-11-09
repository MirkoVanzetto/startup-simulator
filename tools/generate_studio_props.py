#!/usr/bin/env python3
"""
tools/generate_studio_props.py
==============================
Procedural High-Tech Startup Studio 3D Asset Generator for Startup Simulator (Milestone 3).
Constructs modern, professional tech assets with PBR textures and clean geometry:
1. assets/models/hardware/server_rack.glb (42U Enterprise Server Rack)
2. assets/models/hardware/dual_monitors_arm.glb (Dual 27" monitors with emissive IDE code)
3. assets/models/hardware/pc_tower_rgb.glb (Mid-tower PC with intake fans and RGB lighting)
4. assets/models/furniture/desk_modern_tech.glb (Workstation desk with oak veneer and dark aluminum legs)
5. assets/models/furniture/whiteboard_tech.glb (Architecture whiteboard with system diagrams & sticky notes)
6. assets/models/furniture/mechanical_keyboard.glb (75% mechanical keyboard, deskmat, ergonomic mouse)
7. assets/models/furniture/cable_spine.glb (Articulated cable organizer and floor power strip)
8. assets/models/furniture/task_lamp_arm.glb (Modern articulated architect task lamp)
"""

import os
import sys
import math
import numpy as np
from PIL import Image, ImageDraw, ImageFont
import trimesh
from trimesh.visual.material import PBRMaterial
from trimesh.visual import TextureVisuals

PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
TEXTURES_DIR = os.path.join(PROJECT_ROOT, "assets", "textures", "pbr")
HARDWARE_DIR = os.path.join(PROJECT_ROOT, "assets", "models", "hardware")
FURNITURE_DIR = os.path.join(PROJECT_ROOT, "assets", "models", "furniture")
PROPS_DIR = os.path.join(PROJECT_ROOT, "assets", "props")

os.makedirs(HARDWARE_DIR, exist_ok=True)
os.makedirs(FURNITURE_DIR, exist_ok=True)
os.makedirs(PROPS_DIR, exist_ok=True)

# ----------------------------------------------------------------------
# Material Helpers
# ----------------------------------------------------------------------
_material_cache = {}

def get_pbr_material(mat_name, base_color_rgba, roughness=0.5, metallic=0.0):
    cache_key = f"{mat_name}_{roughness}_{metallic}_{base_color_rgba}"
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

def compute_box_planar_uvs(mesh, scale=1.0):
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

def make_trimesh_node(geom_list, mat, uv_scale=1.0):
    if not geom_list:
        return None
    merged = trimesh.util.concatenate(geom_list)
    merged.unmerge_vertices()
    uvs = compute_box_planar_uvs(merged, scale=uv_scale)
    merged.visual = TextureVisuals(uv=uvs, material=mat)
    return merged

# ----------------------------------------------------------------------
# 1. 42U Enterprise Server Rack
# ----------------------------------------------------------------------
def build_server_rack_42u():
    scene = trimesh.Scene()
    mat_metal = get_pbr_material("startup_brushed_dark_aluminum", [30, 32, 36, 255], roughness=0.35, metallic=0.85)
    mat_perf = get_pbr_material("startup_server_perforated_metal", [22, 24, 28, 255], roughness=0.6, metallic=0.7)
    mat_server_face = get_pbr_material("startup_brushed_dark_aluminum", [50, 54, 60, 255], roughness=0.4, metallic=0.8)
    mat_led_green = get_pbr_material(None, [40, 255, 120, 255], roughness=0.1, metallic=0.0)
    mat_led_blue = get_pbr_material(None, [40, 160, 255, 255], roughness=0.1, metallic=0.0)
    mat_led_amber = get_pbr_material(None, [255, 180, 30, 255], roughness=0.1, metallic=0.0)
    mat_cables_cyan = get_pbr_material(None, [20, 180, 220, 255], roughness=0.5, metallic=0.0)
    mat_cables_orange = get_pbr_material(None, [240, 100, 25, 255], roughness=0.5, metallic=0.0)

    # Frame dimensions: W=0.8m, H=2.0m, D=0.9m
    # 4 Vertical corner posts (aluminum extrusions)
    f_parts = []
    post_w = 0.06
    w2 = 0.40 - post_w/2
    d2 = 0.45 - post_w/2
    for sx in [-w2, w2]:
        for sz in [-d2, d2]:
            f_parts.append(create_box([post_w, 2.0, post_w], [sx, 1.0, sz]))
    # Top and bottom caps
    f_parts.append(create_box([0.80, 0.08, 0.90], [0, 0.04, 0]))
    f_parts.append(create_box([0.80, 0.08, 0.90], [0, 1.96, 0]))
    # Side panels (solid dark steel)
    f_parts.append(create_box([0.02, 1.84, 0.82], [-0.39, 1.0, 0]))
    f_parts.append(create_box([0.02, 1.84, 0.82], [ 0.39, 1.0, 0]))
    # Rear door
    f_parts.append(create_box([0.74, 1.84, 0.02], [0, 1.0, -0.44]))
    scene.add_geometry(make_trimesh_node(f_parts, mat_metal, uv_scale=1.5), node_name="RackFrame")

    # Front Perforated Hexagonal Door (slightly recessed)
    door_parts = [create_box([0.72, 1.84, 0.015], [0, 1.0, 0.44])]
    scene.add_geometry(make_trimesh_node(door_parts, mat_perf, uv_scale=4.0), node_name="PerforatedDoor")

    # Internal 1U/2U Servers, Switches, and Patch Panels
    srv_parts = []
    led_g_parts = []
    led_b_parts = []
    led_a_parts = []
    cable_c_parts = []
    cable_o_parts = []

    # Stack of servers from Y=0.25 to Y=1.75
    # Unit height ~0.08m
    unit_y = [0.25, 0.35, 0.45, 0.58, 0.70, 0.82, 0.98, 1.12, 1.28, 1.45, 1.60, 1.72]
    for i, y in enumerate(unit_y):
        h = 0.075 if i % 3 != 0 else 0.12
        srv_parts.append(create_box([0.68, h, 0.75], [0, y, 0]))
        # Front face detail
        srv_parts.append(create_box([0.66, h - 0.01, 0.02], [0, y, 0.39]))
        # LED indicators on front bezel
        led_g_parts.append(create_box([0.012, 0.012, 0.01], [-0.28, y + 0.01, 0.405]))
        led_g_parts.append(create_box([0.012, 0.012, 0.01], [-0.25, y + 0.01, 0.405]))
        if i % 2 == 0:
            led_b_parts.append(create_box([0.012, 0.012, 0.01], [-0.22, y + 0.01, 0.405]))
            led_a_parts.append(create_box([0.012, 0.012, 0.01], [-0.19, y + 0.01, 0.405]))
        else:
            led_a_parts.append(create_box([0.012, 0.012, 0.01], [-0.22, y + 0.01, 0.405]))
            led_b_parts.append(create_box([0.012, 0.012, 0.01], [-0.19, y + 0.01, 0.405]))

        # Patch cables curving into cable management ducts
        for cx in np.linspace(-0.10, 0.25, 6):
            target_mat = cable_c_parts if (int(cx * 100) % 2 == 0) else cable_o_parts
            target_mat.append(create_box([0.008, 0.008, 0.04], [cx, y, 0.41]))

    # Top-of-rack Ethernet switches at Y=1.82
    srv_parts.append(create_box([0.68, 0.045, 0.45], [0, 1.82, 0.1]))
    for port_x in np.linspace(-0.25, 0.25, 16):
        led_g_parts.append(create_box([0.006, 0.006, 0.005], [port_x, 1.83, 0.405]))

    scene.add_geometry(make_trimesh_node(srv_parts, mat_server_face, uv_scale=2.0), node_name="Servers")
    scene.add_geometry(make_trimesh_node(led_g_parts, mat_led_green), node_name="LEDsGreen")
    scene.add_geometry(make_trimesh_node(led_b_parts, mat_led_blue), node_name="LEDsBlue")
    scene.add_geometry(make_trimesh_node(led_a_parts, mat_led_amber), node_name="LEDsAmber")
    scene.add_geometry(make_trimesh_node(cable_c_parts, mat_cables_cyan), node_name="CablesCyan")
    scene.add_geometry(make_trimesh_node(cable_o_parts, mat_cables_orange), node_name="CablesOrange")

    return scene

# ----------------------------------------------------------------------
# 2. Dual 27" Monitors on Articulated Heavy-Duty Arm
# ----------------------------------------------------------------------
def build_dual_monitors_arm():
    scene = trimesh.Scene()
    mat_arm = get_pbr_material("startup_brushed_dark_aluminum", [35, 38, 42, 255], roughness=0.3, metallic=0.9)
    mat_screen = get_pbr_material("startup_screen_emissive", [20, 22, 28, 255], roughness=0.15, metallic=0.0)
    mat_bezel = get_pbr_material(None, [25, 26, 30, 255], roughness=0.5, metallic=0.5)

    # Desk edge clamp and vertical pole at (0, 0, 0)
    arm_parts = []
    arm_parts.append(create_box([0.12, 0.04, 0.12], [0, 0.02, 0])) # Base clamp
    arm_parts.append(create_cylinder(0.022, 0.45, 16, [0, 0.22, 0])) # Main post

    # Dual gas-spring articulated arms
    for sign, angle in [(-1, math.radians(-16)), (1, math.radians(16))]:
        # Lower arm segment
        arm_parts.append(create_box([0.03, 0.04, 0.22], [sign * 0.11, 0.30, 0.08]))
        # Upper arm segment angled forward
        arm_parts.append(create_box([0.03, 0.04, 0.18], [sign * 0.24, 0.38, 0.02]))
        # VESA bracket knuckle
        arm_parts.append(create_box([0.08, 0.08, 0.03], [sign * 0.34, 0.38, -0.06]))

    scene.add_geometry(make_trimesh_node(arm_parts, mat_arm, uv_scale=2.0), node_name="MonitorArm")

    # Left and Right 27" Frameless Displays (16:9 ratio, ~0.61m x 0.35m)
    # Tilted slightly inward (15 deg)
    b_parts = []
    s_parts = []
    for sign, angle_deg in [(-1, 14.0), (1, -14.0)]:
        theta = math.radians(angle_deg)
        rot_y = trimesh.transformations.rotation_matrix(theta, [0, 1, 0])
        cx = sign * 0.33
        cz = -0.09 + (0.04 if sign == -1 else 0.04)
        cy = 0.38

        # Frame backing
        frame = trimesh.creation.box(extents=[0.62, 0.36, 0.02])
        frame.unmerge_vertices()
        frame.apply_transform(rot_y)
        frame.apply_translation([cx, cy, cz])
        b_parts.append(frame)

        # Emissive screen panel (facing -Z / toward player desk chair)
        # In this scene, desk is at -1.5, player looks toward -Z, so front face faces +Z (toward player)
        screen = trimesh.creation.box(extents=[0.60, 0.34, 0.005])
        screen.unmerge_vertices()
        screen.apply_transform(rot_y)
        screen.apply_translation([cx, cy, cz + 0.012])
        s_parts.append(screen)

    scene.add_geometry(make_trimesh_node(b_parts, mat_bezel, uv_scale=2.0), node_name="MonitorBezels")
    scene.add_geometry(make_trimesh_node(s_parts, mat_screen, uv_scale=1.0), node_name="EmissivePanels")

    return scene

# ----------------------------------------------------------------------
# 3. High-End Mid-Tower ATX PC with RGB Intake Fans & Glass Side Panel
# ----------------------------------------------------------------------
def build_pc_tower_rgb():
    scene = trimesh.Scene()
    mat_chassis = get_pbr_material("startup_brushed_dark_aluminum", [25, 27, 30, 255], roughness=0.35, metallic=0.9)
    mat_glass = get_pbr_material(None, [35, 45, 55, 180], roughness=0.08, metallic=0.1)
    mat_mesh = get_pbr_material("startup_server_perforated_metal", [30, 32, 35, 255], roughness=0.7, metallic=0.6)
    mat_rgb_ring = get_pbr_material(None, [0, 240, 255, 255], roughness=0.1, metallic=0.0)
    mat_rgb_ram = get_pbr_material(None, [255, 50, 150, 255], roughness=0.1, metallic=0.0)
    mat_gpu = get_pbr_material("startup_brushed_dark_aluminum", [60, 65, 75, 255], roughness=0.4, metallic=0.85)

    # Chassis dimensions: W=0.22m, H=0.46m, D=0.45m
    ch_parts = []
    # Solid bottom, top, back, right panels
    ch_parts.append(create_box([0.22, 0.02, 0.45], [0, 0.01, 0])) # Bottom plate
    ch_parts.append(create_box([0.22, 0.02, 0.45], [0, 0.45, 0])) # Top plate
    ch_parts.append(create_box([0.015, 0.44, 0.45], [0.105, 0.23, 0])) # Right steel side
    ch_parts.append(create_box([0.20, 0.44, 0.015], [0, 0.23, -0.22])) # Rear I/O frame
    # 4 Rubber feet
    for fx in [-0.08, 0.08]:
        for fz in [-0.18, 0.18]:
            ch_parts.append(create_cylinder(0.015, 0.02, 12, [fx, 0.01, fz]))

    scene.add_geometry(make_trimesh_node(ch_parts, mat_chassis, uv_scale=2.0), node_name="Chassis")

    # Front Mesh Panel
    mesh_parts = [create_box([0.20, 0.42, 0.015], [0, 0.23, 0.22])]
    scene.add_geometry(make_trimesh_node(mesh_parts, mat_mesh, uv_scale=3.0), node_name="FrontMesh")

    # 3x 120mm RGB Intake Fan Rings behind mesh
    fan_rings = []
    for fy in [0.11, 0.23, 0.35]:
        fan_rings.append(create_cylinder(0.055, 0.01, 16, [0, fy, 0.20], rotation=trimesh.transformations.rotation_matrix(math.pi/2, [1, 0, 0])))
    scene.add_geometry(make_trimesh_node(fan_rings, mat_rgb_ring), node_name="RGBFans")

    # Left Tempered Glass Side Panel
    glass_parts = [create_box([0.008, 0.42, 0.43], [-0.105, 0.23, 0])]
    scene.add_geometry(make_trimesh_node(glass_parts, mat_glass, uv_scale=1.0), node_name="GlassSide")

    # Internal Components visible through glass
    gpu_parts = []
    # Dedicated Triple-Fan High-End GPU mounted horizontally
    gpu_parts.append(create_box([0.05, 0.10, 0.28], [-0.04, 0.18, -0.02]))
    # Backplate with illuminated GeForce/Radeon logo
    gpu_parts.append(create_box([0.045, 0.005, 0.27], [-0.04, 0.232, -0.02]))
    scene.add_geometry(make_trimesh_node(gpu_parts, mat_gpu, uv_scale=2.0), node_name="GPU")

    # RGB DDR5 RAM sticks (glowing pink/magenta)
    ram_parts = [
        create_box([0.01, 0.04, 0.08], [0.03, 0.29, -0.04]),
        create_box([0.01, 0.04, 0.08], [0.05, 0.29, -0.04])
    ]
    scene.add_geometry(make_trimesh_node(ram_parts, mat_rgb_ram), node_name="RGBRam")

    return scene

# ----------------------------------------------------------------------
# 4. Modern Tech Workstation Desk
# ----------------------------------------------------------------------
def build_desk_modern_tech():
    scene = trimesh.Scene()
    mat_wood = get_pbr_material("startup_desk_wood_veneer", [190, 140, 95, 255], roughness=0.35, metallic=0.0)
    mat_metal = get_pbr_material("startup_brushed_dark_aluminum", [35, 38, 42, 255], roughness=0.4, metallic=0.85)

    # Desktop: W=1.55m, D=0.85m, Thickness=0.045m at Y=0.74m
    top_parts = [create_box([1.55, 0.045, 0.85], [0, 0.72, 0])]
    scene.add_geometry(make_trimesh_node(top_parts, mat_wood, uv_scale=1.0), node_name="DesktopOak")

    # Heavy-duty dark metal frame: 4 square legs (0.05m x 0.05m) & cross rails
    frame_parts = []
    lx = 0.70
    lz = 0.36
    for sx in [-lx, lx]:
        for sz in [-lz, lz]:
            frame_parts.append(create_box([0.05, 0.69, 0.05], [sx, 0.35, sz]))
    # Top perimeter steel subframe
    frame_parts.append(create_box([1.42, 0.04, 0.04], [0, 0.68, -lz]))
    frame_parts.append(create_box([1.42, 0.04, 0.04], [0, 0.68,  lz]))
    frame_parts.append(create_box([0.04, 0.04, 0.68], [-lx, 0.68, 0]))
    frame_parts.append(create_box([0.04, 0.04, 0.68], [ lx, 0.68, 0]))
    # Under-desk cable management channel
    frame_parts.append(create_box([1.10, 0.06, 0.16], [0, 0.64, -0.15]))

    scene.add_geometry(make_trimesh_node(frame_parts, mat_metal, uv_scale=2.0), node_name="SteelFrame")

    return scene

# ----------------------------------------------------------------------
# 5. Startup Architecture Whiteboard
# ----------------------------------------------------------------------
def build_whiteboard_tech():
    scene = trimesh.Scene()
    mat_frame = get_pbr_material("startup_brushed_dark_aluminum", [180, 185, 195, 255], roughness=0.3, metallic=0.8)

    # Procedural Whiteboard Texture (1024x576) with architecture diagrams and sprint notes
    wb_w, wb_h = 1024, 576
    img = Image.new("RGB", (wb_w, wb_h), (250, 252, 255))
    draw = ImageDraw.Draw(img)

    # Grid dots (subtle dot grid paper pattern)
    for gx in range(40, wb_w - 40, 32):
        for gy in range(40, wb_h - 40, 32):
            draw.point((gx, gy), fill=(215, 222, 230))

    # Architecture Header
    draw.rectangle([50, 30, wb_w - 50, 60], fill=(230, 238, 248), outline=(100, 140, 180), width=2)
    # Architecture Boxes & Arrows
    # 1. Client App
    draw.rounded_rectangle([70, 90, 240, 170], radius=8, fill=(240, 245, 255), outline=(30, 100, 220), width=3)
    # 2. NetShield Firewall
    draw.rounded_rectangle([300, 90, 480, 170], radius=8, fill=(255, 245, 240), outline=(220, 80, 30), width=3)
    # 3. WebForge API Gateway
    draw.rounded_rectangle([540, 90, 720, 170], radius=8, fill=(240, 255, 245), outline=(30, 180, 80), width=3)
    # 4. Postgres DB Cluster
    draw.rounded_rectangle([780, 90, 950, 170], radius=8, fill=(250, 240, 255), outline=(140, 40, 200), width=3)

    # Connecting Flow Arrows
    for ax in [245, 485, 725]:
        draw.line([(ax, 130), (ax + 50, 130)], fill=(40, 45, 55), width=4)
        draw.polygon([(ax + 50, 125), (ax + 55, 130), (ax + 50, 135)], fill=(40, 45, 55))

    # Sprint Kanban Board in lower half (Y=210 to Y=530)
    col_w = (wb_w - 120) // 3
    cols = ["BACKLOG / IDEE", "IN SVILUPPO (SPRINT 4)", "COMPLETATO (PROD)"]
    for c_idx, title in enumerate(cols):
        cx0 = 60 + c_idx * (col_w + 10)
        cx1 = cx0 + col_w
        draw.rectangle([cx0, 210, cx1, 520], outline=(170, 180, 195), width=2)
        draw.rectangle([cx0, 210, cx1, 245], fill=(235, 240, 248), outline=(170, 180, 195), width=2)

        # Sticky Notes
        note_colors = [(255, 245, 130), (140, 240, 170), (255, 180, 200), (180, 220, 255)]
        for r_idx in range(3):
            ny0 = 260 + r_idx * 80
            draw.rectangle([cx0 + 15, ny0, cx1 - 15, ny0 + 65], fill=note_colors[(c_idx + r_idx) % 4], outline=(120, 120, 120), width=1)
            # Simulated handwritten note lines
            draw.line([(cx0 + 25, ny0 + 18), (cx1 - 25, ny0 + 18)], fill=(50, 50, 60), width=2)
            draw.line([(cx0 + 25, ny0 + 34), (cx1 - 40, ny0 + 34)], fill=(60, 60, 70), width=2)
            draw.line([(cx0 + 25, ny0 + 50), (cx1 - 60, ny0 + 50)], fill=(70, 70, 80), width=2)

    mat_board = PBRMaterial(
        name="Mat_Whiteboard_Diagram",
        baseColorFactor=[1.0, 1.0, 1.0, 1.0],
        baseColorTexture=img,
        roughnessFactor=0.15,
        metallicFactor=0.0,
        doubleSided=False
    )

    # Frame geometry (1.8m x 1.05m x 0.03m)
    f_parts = []
    # Outer frame rim
    f_parts.append(create_box([1.84, 0.03, 0.04], [0, 0.525, 0]))
    f_parts.append(create_box([1.84, 0.03, 0.04], [0, -0.525, 0]))
    f_parts.append(create_box([0.03, 1.08, 0.04], [-0.91, 0, 0]))
    f_parts.append(create_box([0.03, 1.08, 0.04], [ 0.91, 0, 0]))
    # Marker tray at bottom
    f_parts.append(create_box([1.20, 0.02, 0.08], [0, -0.53, 0.03]))
    scene.add_geometry(make_trimesh_node(f_parts, mat_frame, uv_scale=2.0), node_name="Frame")

    # Front whiteboard panel with diagram texture
    # UV mapping aligned to 0..1
    board_mesh = trimesh.creation.box(extents=[1.80, 1.02, 0.01])
    board_mesh.unmerge_vertices()
    board_mesh.apply_translation([0, 0, 0.01])

    # Map face UVs: front face (+Z) maps to 0..1 in X,Y
    uvs = np.zeros((len(board_mesh.vertices), 2), dtype=np.float32)
    for i, v in enumerate(board_mesh.vertices):
        uvs[i, 0] = (v[0] / 1.80) + 0.5
        uvs[i, 1] = 0.5 - (v[1] / 1.02)
    board_mesh.visual = TextureVisuals(uv=uvs, material=mat_board)
    scene.add_geometry(board_mesh, node_name="BoardCanvas")

    return scene

# ----------------------------------------------------------------------
# 6. Mechanical Keyboard, Mouse & Deskmat
# ----------------------------------------------------------------------
def build_mechanical_keyboard():
    scene = trimesh.Scene()
    mat_mat = get_pbr_material("startup_desk_wood_veneer", [28, 30, 36, 255], roughness=0.85, metallic=0.0)
    mat_case = get_pbr_material("startup_brushed_dark_aluminum", [38, 40, 46, 255], roughness=0.35, metallic=0.8)
    mat_keys = get_pbr_material(None, [48, 52, 60, 255], roughness=0.5, metallic=0.0)
    mat_accent = get_pbr_material(None, [230, 90, 40, 255], roughness=0.4, metallic=0.0) # Orange escape & enter
    mat_mouse = get_pbr_material("startup_brushed_dark_aluminum", [30, 32, 36, 255], roughness=0.3, metallic=0.6)

    # Extended Deskmat: 0.85m x 0.38m x 0.003m
    mat_parts = [create_box([0.85, 0.003, 0.38], [0, 0.0015, 0])]
    scene.add_geometry(make_trimesh_node(mat_parts, mat_mat, uv_scale=1.5), node_name="Deskmat")

    # Keyboard Case: 0.32m x 0.13m x 0.02m (positioned on left/center of mat)
    kb_x, kb_z = -0.08, 0.02
    case_parts = [create_box([0.33, 0.018, 0.14], [kb_x, 0.012, kb_z])]
    scene.add_geometry(make_trimesh_node(case_parts, mat_case, uv_scale=2.0), node_name="KeyboardCase")

    # Keycaps grid (75% layout)
    key_parts = []
    accent_parts = []
    for r in range(5):
        kz = kb_z - 0.045 + r * 0.022
        for c in range(14):
            kx = kb_x - 0.14 + c * 0.021
            if (r == 0 and c == 0) or (r == 2 and c == 13):
                accent_parts.append(create_box([0.018, 0.010, 0.018], [kx, 0.024, kz]))
            elif r == 4 and (c in [4, 5, 6, 7]):
                pass # Spacebar handled below
            else:
                key_parts.append(create_box([0.018, 0.010, 0.018], [kx, 0.024, kz]))
    # Spacebar
    accent_parts.append(create_box([0.09, 0.010, 0.018], [kb_x - 0.02, 0.024, kb_z + 0.043]))

    scene.add_geometry(make_trimesh_node(key_parts, mat_keys), node_name="Keycaps")
    scene.add_geometry(make_trimesh_node(accent_parts, mat_accent), node_name="KeycapsAccent")

    # Ergonomic Gaming Mouse on right side of deskmat
    m_x, m_z = 0.24, 0.02
    mouse_parts = []
    mouse_parts.append(create_box([0.065, 0.035, 0.115], [m_x, 0.02, m_z]))
    # Mouse scroll wheel
    accent_parts_m = [create_box([0.008, 0.012, 0.022], [m_x, 0.038, m_z - 0.03])]

    scene.add_geometry(make_trimesh_node(mouse_parts, mat_mouse), node_name="Mouse")
    scene.add_geometry(make_trimesh_node(accent_parts_m, mat_accent), node_name="MouseWheel")

    return scene

# ----------------------------------------------------------------------
# 7. Articulated Cable Spine & Floor Power Strip
# ----------------------------------------------------------------------
def build_cable_spine():
    scene = trimesh.Scene()
    mat_spine = get_pbr_material("startup_brushed_dark_aluminum", [35, 36, 40, 255], roughness=0.6, metallic=0.2)
    mat_strip = get_pbr_material("startup_brushed_dark_aluminum", [220, 222, 228, 255], roughness=0.4, metallic=0.0)
    mat_led = get_pbr_material(None, [255, 30, 30, 255], roughness=0.1, metallic=0.0)

    # Vertebra cable management spine: 12 interlocking articulated segments from Y=0.02 to Y=0.70
    spine_parts = []
    for idx, y in enumerate(np.linspace(0.05, 0.68, 14)):
        # Slight organic curve
        curv_x = 0.04 * math.sin(idx * 0.35)
        spine_parts.append(create_box([0.07, 0.035, 0.05], [curv_x, y, 0]))

    scene.add_geometry(make_trimesh_node(spine_parts, mat_spine), node_name="SpineVertebrae")

    # Floor power strip with surge protector
    strip_parts = [create_box([0.10, 0.038, 0.32], [0.12, 0.019, 0])]
    # Red glowing rocker switch
    switch_parts = [create_box([0.025, 0.012, 0.035], [0.12, 0.042, -0.12])]

    scene.add_geometry(make_trimesh_node(strip_parts, mat_strip), node_name="PowerStrip")
    scene.add_geometry(make_trimesh_node(switch_parts, mat_led), node_name="SwitchLED")

    return scene

# ----------------------------------------------------------------------
# 8. Modern Articulated Architect Task Lamp
# ----------------------------------------------------------------------
def build_task_lamp_arm():
    scene = trimesh.Scene()
    mat_metal = get_pbr_material("startup_brushed_dark_aluminum", [40, 42, 48, 255], roughness=0.35, metallic=0.85)
    mat_bulb = get_pbr_material(None, [255, 248, 220, 255], roughness=0.1, metallic=0.0)

    parts = []
    # Base desk clamp
    parts.append(create_box([0.08, 0.03, 0.08], [0, 0.015, 0]))
    parts.append(create_cylinder(0.018, 0.08, 12, [0, 0.06, 0]))

    # Lower arm (angled 20 deg back)
    parts.append(create_box([0.018, 0.32, 0.018], [-0.04, 0.22, 0.04]))
    # Elbow hinge
    parts.append(create_cylinder(0.018, 0.03, 12, [-0.08, 0.37, 0.08], rotation=trimesh.transformations.rotation_matrix(math.pi/2, [0, 0, 1])))
    # Upper arm (angled forward towards desk center)
    parts.append(create_box([0.018, 0.28, 0.018], [0.02, 0.48, -0.02]))
    # Lamp cone shade
    parts.append(create_box([0.09, 0.06, 0.16], [0.12, 0.58, -0.08]))

    scene.add_geometry(make_trimesh_node(parts, mat_metal), node_name="LampBody")

    # Emissive LED light bar inside lamp shade
    bulb_parts = [create_box([0.07, 0.01, 0.13], [0.12, 0.55, -0.08])]
    scene.add_geometry(make_trimesh_node(bulb_parts, mat_bulb), node_name="LampBulb")

    return scene

# ----------------------------------------------------------------------
# Main Execution
# ----------------------------------------------------------------------
def main():
    print("Generating High-Tech Startup Studio 3D Assets (Milestone 3)...")

    # 1. Server Rack (Upgrade existing server_rack.glb)
    print("  -> assets/models/hardware/server_rack.glb")
    rack_scene = build_server_rack_42u()
    rack_scene.export(os.path.join(HARDWARE_DIR, "server_rack.glb"))

    # 2. Dual Monitors on Arm
    print("  -> assets/models/hardware/dual_monitors_arm.glb")
    mon_scene = build_dual_monitors_arm()
    mon_scene.export(os.path.join(HARDWARE_DIR, "dual_monitors_arm.glb"))
    # Also update props/monitor_upgrade.glb
    mon_scene.export(os.path.join(PROPS_DIR, "monitor_upgrade.glb"))

    # 3. PC Tower RGB
    print("  -> assets/models/hardware/pc_tower_rgb.glb")
    pc_scene = build_pc_tower_rgb()
    pc_scene.export(os.path.join(HARDWARE_DIR, "pc_tower_rgb.glb"))

    # 4. Modern Tech Desk
    print("  -> assets/models/furniture/desk_modern_tech.glb")
    desk_scene = build_desk_modern_tech()
    desk_scene.export(os.path.join(FURNITURE_DIR, "desk_modern_tech.glb"))

    # 5. Architecture Whiteboard
    print("  -> assets/models/furniture/whiteboard_tech.glb")
    wb_scene = build_whiteboard_tech()
    wb_scene.export(os.path.join(FURNITURE_DIR, "whiteboard_tech.glb"))

    # 6. Mechanical Keyboard & Mouse
    print("  -> assets/models/furniture/mechanical_keyboard.glb")
    kb_scene = build_mechanical_keyboard()
    kb_scene.export(os.path.join(FURNITURE_DIR, "mechanical_keyboard.glb"))

    # 7. Cable Spine & Power Strip
    print("  -> assets/models/furniture/cable_spine.glb")
    spine_scene = build_cable_spine()
    spine_scene.export(os.path.join(FURNITURE_DIR, "cable_spine.glb"))

    # 8. Task Lamp
    print("  -> assets/models/furniture/task_lamp_arm.glb")
    lamp_scene = build_task_lamp_arm()
    lamp_scene.export(os.path.join(FURNITURE_DIR, "task_lamp_arm.glb"))

    print("All High-Tech Startup Studio assets generated successfully!")

if __name__ == "__main__":
    main()
