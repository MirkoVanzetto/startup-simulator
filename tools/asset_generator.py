#!/usr/bin/env python3
"""
Asset Generator for Startup Simulator.
Procedurally constructs stylized, high-quality low-poly 3D models (.glb)
with vertex colors, materials, and clean geometry:
- Laptop (opened 15-inch screen, keyboard, trackpad)
- Studio Desk & Office Chair
- Upgrade Props (Secondary Monitor 27", Ergonomic High-End Chair)
- Pizzeria Mario NPC (Pizzaiolo in apron, chef hat, mustache)
- Player Character Model (Graduate in hoodie/jeans/sneakers)
- Studio Interior (parquet, walls, window, door, lamp)
- Turin Street District (cobblestones, sidewalks, portici arches, lampposts, facades)
- Pizzeria Interior (brick wood-fired oven, counter, cash register, dining tables)
"""

import os
import math
import numpy as np
import trimesh
from trimesh.visual.color import ColorVisuals

def create_box(extents, translation=[0,0,0], color=[200, 200, 200, 255]):
    mesh = trimesh.creation.box(extents=extents)
    mesh.apply_translation(translation)
    colors = np.tile(np.array(color, dtype=np.uint8), (len(mesh.vertices), 1))
    mesh.visual = ColorVisuals(mesh=mesh, vertex_colors=colors)
    return mesh

def create_cylinder(radius, height, sections=16, translation=[0,0,0], rotation=None, color=[200, 200, 200, 255]):
    mesh = trimesh.creation.cylinder(radius=radius, height=height, sections=sections)
    if rotation is not None:
        mesh.apply_transform(rotation)
    mesh.apply_translation(translation)
    colors = np.tile(np.array(color, dtype=np.uint8), (len(mesh.vertices), 1))
    mesh.visual = ColorVisuals(mesh=mesh, vertex_colors=colors)
    return mesh

def combine_meshes(mesh_list):
    """Combines a list of meshes into a single trimesh with vertex colors preserved."""
    valid = [m for m in mesh_list if m is not None and len(m.vertices) > 0]
    if not valid:
        return trimesh.Trimesh()
    
    total_vertices = sum(len(m.vertices) for m in valid)
    total_faces = sum(len(m.faces) for m in valid)
    
    all_verts = np.zeros((total_vertices, 3), dtype=np.float64)
    all_faces = np.zeros((total_faces, 3), dtype=np.int64)
    all_colors = np.zeros((total_vertices, 4), dtype=np.uint8)
    
    v_offset = 0
    f_offset = 0
    for m in valid:
        v_count = len(m.vertices)
        f_count = len(m.faces)
        all_verts[v_offset : v_offset + v_count] = m.vertices
        all_faces[f_offset : f_offset + f_count] = m.faces + v_offset
        
        if hasattr(m.visual, 'vertex_colors') and len(m.visual.vertex_colors) == v_count:
            all_colors[v_offset : v_offset + v_count] = m.visual.vertex_colors
        else:
            all_colors[v_offset : v_offset + v_count] = [200, 200, 200, 255]
            
        v_offset += v_count
        f_offset += f_count
        
    combined = trimesh.Trimesh(vertices=all_verts, faces=all_faces)
    combined.visual = ColorVisuals(mesh=combined, vertex_colors=all_colors)
    return combined

# -------------------------------------------------------------
# 1. LAPTOP PROP
# -------------------------------------------------------------
def build_laptop():
    parts = []
    # Base chassis (dark space gray aluminum)
    parts.append(create_box([0.36, 0.015, 0.25], [0, 0.0075, 0], [45, 48, 55, 255]))
    # Keyboard well (darker matte)
    parts.append(create_box([0.30, 0.002, 0.12], [0, 0.016, -0.02], [28, 30, 35, 255]))
    # Trackpad
    parts.append(create_box([0.11, 0.002, 0.07], [0, 0.016, 0.07], [65, 70, 78, 255]))
    # Screen bezel (angled at 110 degrees)
    screen_pitch = math.radians(20) # tilted backwards 20 deg from vertical
    rot_mat = trimesh.transformations.rotation_matrix(screen_pitch, [1, 0, 0])
    
    lid = trimesh.creation.box(extents=[0.36, 0.24, 0.012])
    lid.apply_transform(rot_mat)
    lid.apply_translation([0, 0.12 * math.cos(screen_pitch) + 0.01, -0.125 - 0.12 * math.sin(screen_pitch)])
    lid_colors = np.tile(np.array([40, 42, 48, 255], dtype=np.uint8), (len(lid.vertices), 1))
    lid.visual = ColorVisuals(mesh=lid, vertex_colors=lid_colors)
    parts.append(lid)
    
    # Glowing Display Panel ("TO-OS" blue-cyan glow)
    display = trimesh.creation.box(extents=[0.33, 0.21, 0.004])
    display.apply_transform(rot_mat)
    display.apply_translation([0, 0.12 * math.cos(screen_pitch) + 0.01, -0.125 - 0.12 * math.sin(screen_pitch) + 0.005])
    disp_colors = np.tile(np.array([45, 120, 220, 255], dtype=np.uint8), (len(display.vertices), 1))
    display.visual = ColorVisuals(mesh=display, vertex_colors=disp_colors)
    parts.append(display)
    
    return combine_meshes(parts)

# -------------------------------------------------------------
# 2. STUDIO DESK
# -------------------------------------------------------------
def build_desk():
    parts = []
    # Wooden desktop (warm oak)
    parts.append(create_box([1.4, 0.04, 0.75], [0, 0.74, 0], [180, 130, 85, 255]))
    # 4 Steel legs (black powder-coat)
    leg_pos = [
        [-0.64, 0.36, -0.32],
        [ 0.64, 0.36, -0.32],
        [-0.64, 0.36,  0.32],
        [ 0.64, 0.36,  0.32]
    ]
    for lp in leg_pos:
        parts.append(create_cylinder(0.022, 0.72, 12, lp, color=[35, 35, 40, 255]))
    # Crossbeam reinforcement
    parts.append(create_box([1.25, 0.03, 0.03], [0, 0.70, -0.30], [35, 35, 40, 255]))
    # Mouse pad
    parts.append(create_box([0.35, 0.003, 0.30], [0.35, 0.762, 0.05], [25, 25, 30, 255]))
    return combine_meshes(parts)

# -------------------------------------------------------------
# 3. OFFICE CHAIR
# -------------------------------------------------------------
def build_chair_office():
    parts = []
    # 5-star base center
    parts.append(create_cylinder(0.05, 0.10, 12, [0, 0.10, 0], color=[40, 40, 45, 255]))
    # Wheels / Spokes
    for angle in np.linspace(0, 2 * math.pi, 5, endpoint=False):
        spoke_rot = trimesh.transformations.rotation_matrix(angle, [0, 1, 0])
        spoke = trimesh.creation.box(extents=[0.03, 0.03, 0.28])
        spoke.apply_translation([0, 0, 0.14])
        spoke.apply_transform(spoke_rot)
        spoke.apply_translation([0, 0.08, 0])
        spoke_colors = np.tile(np.array([40, 40, 45, 255], dtype=np.uint8), (len(spoke.vertices), 1))
        spoke.visual = ColorVisuals(mesh=spoke, vertex_colors=spoke_colors)
        parts.append(spoke)
    # Gas lift cylinder (chrome)
    parts.append(create_cylinder(0.025, 0.32, 12, [0, 0.26, 0], color=[160, 165, 175, 255]))
    # Seat cushion (dark charcoal fabric)
    parts.append(create_box([0.46, 0.07, 0.44], [0, 0.45, 0], [55, 60, 70, 255]))
    # Backrest
    parts.append(create_box([0.42, 0.48, 0.05], [0, 0.73, -0.20], [45, 50, 60, 255]))
    # Armrests
    parts.append(create_box([0.06, 0.20, 0.24], [-0.24, 0.58, 0], [30, 32, 36, 255]))
    parts.append(create_box([0.06, 0.20, 0.24], [ 0.24, 0.58, 0], [30, 32, 36, 255]))
    return combine_meshes(parts)

# -------------------------------------------------------------
# 4. UPGRADE: SECONDARY MONITOR 27" ULTRAWIDE
# -------------------------------------------------------------
def build_monitor_upgrade():
    parts = []
    # Aluminum base plate
    parts.append(create_box([0.22, 0.012, 0.18], [0, 0.006, 0], [180, 185, 195, 255]))
    # Vertical arm / pillar
    parts.append(create_box([0.04, 0.38, 0.04], [0, 0.19, -0.05], [140, 145, 155, 255]))
    # Display frame (bezel-less edge)
    parts.append(create_box([0.62, 0.36, 0.02], [0, 0.32, 0], [35, 38, 42, 255]))
    # Screen panel (bright modern code editor glow - dark purple/blue theme)
    screen = create_box([0.60, 0.34, 0.004], [0, 0.32, 0.01], [30, 38, 55, 255])
    parts.append(screen)
    # Status LED
    parts.append(create_box([0.01, 0.01, 0.005], [0.28, 0.15, 0.01], [80, 240, 140, 255]))
    return combine_meshes(parts)

# -------------------------------------------------------------
# 5. UPGRADE: HIGH-END ERGONOMIC GAMING/PRO CHAIR
# -------------------------------------------------------------
def build_chair_gaming_upgrade():
    parts = []
    # 5-star base in glossy black
    parts.append(create_cylinder(0.06, 0.10, 12, [0, 0.10, 0], color=[25, 25, 28, 255]))
    for angle in np.linspace(0, 2 * math.pi, 5, endpoint=False):
        spoke_rot = trimesh.transformations.rotation_matrix(angle, [0, 1, 0])
        spoke = trimesh.creation.box(extents=[0.04, 0.03, 0.32])
        spoke.apply_translation([0, 0, 0.16])
        spoke.apply_transform(spoke_rot)
        spoke.apply_translation([0, 0.08, 0])
        spoke_colors = np.tile(np.array([25, 25, 28, 255], dtype=np.uint8), (len(spoke.vertices), 1))
        spoke.visual = ColorVisuals(mesh=spoke, vertex_colors=spoke_colors)
        parts.append(spoke)
    # Gas cylinder
    parts.append(create_cylinder(0.028, 0.34, 12, [0, 0.27, 0], color=[200, 40, 50, 255])) # Crimson ring
    # Bucket seat cushion with side bolsters (black & crimson red)
    parts.append(create_box([0.48, 0.09, 0.46], [0, 0.46, 0], [28, 28, 32, 255]))
    parts.append(create_box([0.06, 0.14, 0.44], [-0.22, 0.50, 0], [210, 35, 45, 255]))
    parts.append(create_box([0.06, 0.14, 0.44], [ 0.22, 0.50, 0], [210, 35, 45, 255]))
    # Tall ergonomic backrest with headrest pillow
    parts.append(create_box([0.44, 0.72, 0.07], [0, 0.88, -0.21], [28, 28, 32, 255]))
    parts.append(create_box([0.05, 0.70, 0.08], [-0.19, 0.88, -0.21], [210, 35, 45, 255]))
    parts.append(create_box([0.05, 0.70, 0.08], [ 0.19, 0.88, -0.21], [210, 35, 45, 255]))
    # Headrest cushion
    parts.append(create_box([0.24, 0.12, 0.06], [0, 1.18, -0.17], [210, 35, 45, 255]))
    # 3D adjustable armrests
    parts.append(create_box([0.08, 0.22, 0.26], [-0.26, 0.62, 0], [45, 45, 50, 255]))
    parts.append(create_box([0.08, 0.22, 0.26], [ 0.26, 0.62, 0], [45, 45, 50, 255]))
    return combine_meshes(parts)

# -------------------------------------------------------------
# 6. NPC: MARIO (PIZZAIOLO DI TORINO)
# -------------------------------------------------------------
def build_character_mario():
    parts = []
    # Shoes (brown leather clogs)
    parts.append(create_box([0.14, 0.09, 0.24], [-0.15, 0.045, 0.04], [90, 55, 30, 255]))
    parts.append(create_box([0.14, 0.09, 0.24], [ 0.15, 0.045, 0.04], [90, 55, 30, 255]))
    # Trousers (dark navy blue)
    parts.append(create_cylinder(0.08, 0.75, 12, [-0.15, 0.44, 0], color=[35, 40, 55, 255]))
    parts.append(create_cylinder(0.08, 0.75, 12, [ 0.15, 0.44, 0], color=[35, 40, 55, 255]))
    # Torso (White Chef Double-breasted shirt)
    parts.append(create_box([0.48, 0.60, 0.32], [0, 1.08, 0], [245, 245, 248, 255]))
    # Red neckerchief (Fazzoletto da collo rosso)
    parts.append(create_box([0.22, 0.08, 0.20], [0, 1.36, 0.08], [210, 35, 40, 255]))
    # Apron front (Grembiule bianco con bordo tricolore italiano)
    parts.append(create_box([0.42, 0.85, 0.02], [0, 0.85, 0.165], [235, 235, 240, 255]))
    # Italian tricolor badge on apron
    parts.append(create_box([0.03, 0.05, 0.005], [-0.03, 1.15, 0.18], [0, 146, 70, 255]))  # Green
    parts.append(create_box([0.03, 0.05, 0.005], [ 0.00, 1.15, 0.18], [240, 240, 240, 255])) # White
    parts.append(create_box([0.03, 0.05, 0.005], [ 0.03, 1.15, 0.18], [206, 43, 55, 255]))  # Red
    # Arms (rolled up sleeves, skin on forearms)
    # Left shoulder & upper arm
    parts.append(create_cylinder(0.07, 0.30, 12, [-0.30, 1.18, 0], color=[245, 245, 248, 255]))
    parts.append(create_cylinder(0.06, 0.28, 12, [-0.30, 0.92, 0.05], color=[235, 185, 150, 255]))
    # Right shoulder & arm
    parts.append(create_cylinder(0.07, 0.30, 12, [ 0.30, 1.18, 0], color=[245, 245, 248, 255]))
    parts.append(create_cylinder(0.06, 0.28, 12, [ 0.30, 0.92, 0.05], color=[235, 185, 150, 255]))
    # Head & Neck (friendly stylized Italian face)
    parts.append(create_cylinder(0.08, 0.12, 12, [0, 1.42, 0], color=[235, 185, 150, 255]))
    parts.append(create_box([0.22, 0.24, 0.22], [0, 1.56, 0], [240, 190, 155, 255]))
    # Mustache (baffi neri curati da vero maestro pizzaiolo)
    parts.append(create_box([0.16, 0.04, 0.05], [0, 1.51, 0.12], [30, 28, 30, 255]))
    # Nose
    parts.append(create_box([0.05, 0.06, 0.05], [0, 1.57, 0.12], [230, 175, 140, 255]))
    # Eyes
    parts.append(create_box([0.03, 0.03, 0.02], [-0.06, 1.61, 0.11], [40, 40, 45, 255]))
    parts.append(create_box([0.03, 0.03, 0.02], [ 0.06, 1.61, 0.11], [40, 40, 45, 255]))
    # Chef Toque / Cappello da cuoco (classic pleated white hat)
    parts.append(create_cylinder(0.12, 0.08, 14, [0, 1.70, 0], color=[248, 248, 250, 255]))
    parts.append(create_cylinder(0.16, 0.22, 14, [0, 1.83, 0], color=[255, 255, 255, 255]))
    return combine_meshes(parts)

# -------------------------------------------------------------
# 7. PROTAGONIST PLAYER CHARACTER MODEL
# -------------------------------------------------------------
def build_character_player():
    parts = []
    # Sneakers (modern white and teal running shoes)
    parts.append(create_box([0.12, 0.08, 0.26], [-0.14, 0.04, 0.04], [240, 240, 245, 255]))
    parts.append(create_box([0.12, 0.08, 0.26], [ 0.14, 0.04, 0.04], [240, 240, 245, 255]))
    parts.append(create_box([0.125, 0.02, 0.24], [-0.14, 0.01, 0.04], [40, 180, 180, 255]))
    parts.append(create_box([0.125, 0.02, 0.24], [ 0.14, 0.01, 0.04], [40, 180, 180, 255]))
    # Jeans (modern denim blue)
    parts.append(create_cylinder(0.075, 0.78, 12, [-0.14, 0.44, 0], color=[45, 75, 120, 255]))
    parts.append(create_cylinder(0.075, 0.78, 12, [ 0.14, 0.44, 0], color=[45, 75, 120, 255]))
    # Hoodie (slate dark grey / teal tech startup hoodie)
    parts.append(create_box([0.44, 0.58, 0.28], [0, 1.08, 0], [45, 52, 62, 255]))
    # Arms
    parts.append(create_cylinder(0.065, 0.56, 12, [-0.28, 1.04, 0], color=[45, 52, 62, 255]))
    parts.append(create_cylinder(0.065, 0.56, 12, [ 0.28, 1.04, 0], color=[45, 52, 62, 255]))
    # Hands (skin)
    parts.append(create_box([0.07, 0.09, 0.09], [-0.28, 0.72, 0], [235, 190, 155, 255]))
    parts.append(create_box([0.07, 0.09, 0.09], [ 0.28, 0.72, 0], [235, 190, 155, 255]))
    # Head & modern hair
    parts.append(create_box([0.20, 0.22, 0.20], [0, 1.54, 0], [240, 195, 160, 255]))
    parts.append(create_box([0.22, 0.10, 0.23], [0, 1.68, -0.01], [65, 45, 30, 255])) # Brown styled hair
    # Glasses (modern tech rim)
    parts.append(create_box([0.18, 0.04, 0.02], [0, 1.57, 0.11], [25, 25, 30, 255]))
    return combine_meshes(parts)

# -------------------------------------------------------------
# 8. STUDIO ROOM INTERIOR
# -------------------------------------------------------------
def build_studio_room():
    parts = []
    # Parquet Floor (6m x 5m, 0.1m depth)
    parts.append(create_box([6.0, 0.10, 5.0], [0, -0.05, 0], [175, 125, 80, 255]))
    # Baseboards (battiscopa)
    parts.append(create_box([6.0, 0.08, 0.04], [0, 0.04, -2.48], [120, 80, 50, 255]))
    parts.append(create_box([0.04, 0.08, 5.0], [-2.98, 0.04, 0], [120, 80, 50, 255]))
    parts.append(create_box([0.04, 0.08, 5.0], [ 2.98, 0.04, 0], [120, 80, 50, 255]))
    # Back Wall with Window (Z = -2.5)
    parts.append(create_box([2.2, 3.0, 0.12], [-1.9, 1.5, -2.5], [230, 228, 222, 255]))
    parts.append(create_box([2.2, 3.0, 0.12], [ 1.9, 1.5, -2.5], [230, 228, 222, 255]))
    parts.append(create_box([1.6, 0.9, 0.12], [ 0.0, 0.45, -2.5], [230, 228, 222, 255]))
    parts.append(create_box([1.6, 0.7, 0.12], [ 0.0, 2.65, -2.5], [230, 228, 222, 255]))
    # Window Frame & Glass looking outside
    parts.append(create_box([1.58, 1.4, 0.06], [0, 1.6, -2.5], [140, 95, 60, 255])) # Frame
    parts.append(create_box([1.46, 1.28, 0.02], [0, 1.6, -2.5], [160, 210, 245, 200])) # Glass
    # Left Wall (solid)
    parts.append(create_box([0.12, 3.0, 5.0], [-3.0, 1.5, 0], [225, 223, 218, 255]))
    # Right Wall (with tech startup poster)
    parts.append(create_box([0.12, 3.0, 5.0], [ 3.0, 1.5, 0], [225, 223, 218, 255]))
    # Tech Poster on right wall
    parts.append(create_box([0.02, 0.9, 0.6], [2.93, 1.7, 0.5], [230, 70, 60, 255]))
    # Front Wall with Door Opening (Z = +2.5)
    # Left of door
    parts.append(create_box([2.4, 3.0, 0.12], [-1.8, 1.5, 2.5], [230, 228, 222, 255]))
    # Right of door
    parts.append(create_box([2.4, 3.0, 0.12], [ 1.8, 1.5, 2.5], [230, 228, 222, 255]))
    # Above door
    parts.append(create_box([1.2, 0.8, 0.12], [ 0.0, 2.6, 2.5], [230, 228, 222, 255]))
    # Door Frame (wooden)
    parts.append(create_box([1.24, 2.22, 0.14], [0, 1.11, 2.5], [110, 70, 45, 255]))
    # Ceiling
    parts.append(create_box([6.0, 0.10, 5.0], [0, 3.05, 0], [240, 240, 242, 255]))
    # Ceiling modern pendant lamp
    parts.append(create_cylinder(0.01, 0.60, 8, [0, 2.75, 0], color=[40, 40, 40, 255]))
    parts.append(create_cylinder(0.22, 0.12, 16, [0, 2.42, 0], color=[250, 220, 150, 255]))
    return combine_meshes(parts)

# -------------------------------------------------------------
# 9. TURIN STREET DISTRICT (OUTDOOR)
# -------------------------------------------------------------
def build_street_district():
    parts = []
    # Cobblestone Street Roadway (18m long x 8m wide)
    parts.append(create_box([18.0, 0.15, 8.0], [0, -0.08, 7.5], [75, 78, 85, 255]))
    # Sidewalk curbs (granite grey)
    parts.append(create_box([18.0, 0.22, 2.5], [0, 0.01, 2.25], [165, 168, 175, 255]))
    parts.append(create_box([18.0, 0.22, 2.5], [0, 0.01, 12.75], [165, 168, 175, 255]))
    # Historic Turin Portico / Building Facade along north sidewalk
    # 4 Stone Arches & Pillars (stile sabaudo / via Po)
    pillar_x = [-7.0, -2.5, 2.5, 7.0]
    for px in pillar_x:
        # Pillar
        parts.append(create_box([0.55, 3.6, 0.55], [px, 1.8, 3.2], [215, 210, 195, 255]))
        # Capital / Base
        parts.append(create_box([0.70, 0.25, 0.70], [px, 0.12, 3.2], [195, 190, 175, 255]))
        parts.append(create_box([0.70, 0.25, 0.70], [px, 3.50, 3.2], [195, 190, 175, 255]))
    # Arch lintel across pillars
    parts.append(create_box([18.0, 0.6, 0.65], [0, 3.8, 3.2], [210, 205, 190, 255]))
    # Upper facade with windows and shutters
    parts.append(create_box([18.0, 4.0, 0.3], [0, 6.0, 3.2], [225, 195, 160, 255])) # Warm Turin ocher facade
    # Windows on upper facade
    for wx in [-5.0, 0.0, 5.0]:
        parts.append(create_box([1.1, 1.6, 0.1], [wx, 5.8, 3.35], [40, 50, 65, 255])) # Window
        parts.append(create_box([0.45, 1.6, 0.06], [wx - 0.7, 5.8, 3.36], [60, 95, 65, 255])) # Green Shutter Left
        parts.append(create_box([0.45, 1.6, 0.06], [wx + 0.7, 5.8, 3.36], [60, 95, 65, 255])) # Green Shutter Right
    # Street Lampposts (Turin classic cast-iron lantern)
    for lx in [-5.5, 4.5]:
        parts.append(create_cylinder(0.06, 3.4, 10, [lx, 1.7, 4.2], color=[35, 42, 45, 255]))
        parts.append(create_box([0.35, 0.50, 0.35], [lx, 3.5, 4.2], [255, 230, 130, 255])) # Glowing lantern
    # Street Sign "Via Po"
    parts.append(create_box([0.8, 0.22, 0.03], [-6.8, 2.6, 3.5], [30, 65, 130, 255])) # Blue Turin street sign
    return combine_meshes(parts)

# -------------------------------------------------------------
# 10. PIZZERIA INTERIOR & WOOD-FIRED OVEN
# -------------------------------------------------------------
def build_pizzeria_interior():
    parts = []
    # Terracotta Floor (7m x 6m)
    parts.append(create_box([7.0, 0.10, 6.0], [0, -0.05, 0], [195, 105, 65, 255]))
    # Walls (warm rustic Tuscan/Piedmont plaster)
    parts.append(create_box([7.0, 3.2, 0.15], [0, 1.6, -3.0], [240, 230, 210, 255])) # Back
    parts.append(create_box([0.15, 3.2, 6.0], [-3.5, 1.6, 0], [240, 230, 210, 255])) # Left
    parts.append(create_box([0.15, 3.2, 6.0], [ 3.5, 1.6, 0], [240, 230, 210, 255])) # Right
    parts.append(create_box([7.0, 0.10, 6.0], [0, 3.25, 0], [235, 225, 205, 255])) # Ceiling
    
    # Entrance wall with door (Z = +3.0)
    parts.append(create_box([2.8, 3.2, 0.15], [-2.1, 1.6, 3.0], [240, 230, 210, 255]))
    parts.append(create_box([2.8, 3.2, 0.15], [ 2.1, 1.6, 3.0], [240, 230, 210, 255]))
    parts.append(create_box([1.4, 0.9, 0.15], [ 0.0, 2.75, 3.0], [240, 230, 210, 255]))
    # Sign above entrance "PIZZERIA DA MARIO"
    parts.append(create_box([2.4, 0.45, 0.08], [0, 2.45, 2.9], [175, 45, 35, 255]))
    
    # Authentic Wood-Fired Brick Pizza Oven (back right corner)
    # Base block
    parts.append(create_box([1.8, 0.9, 1.8], [2.2, 0.45, -1.8], [140, 60, 45, 255]))
    # Domed oven shell
    dome = trimesh.creation.cylinder(radius=0.85, height=0.7, sections=16)
    dome.apply_translation([2.2, 1.25, -1.8])
    dome_colors = np.tile(np.array([160, 75, 55, 255], dtype=np.uint8), (len(dome.vertices), 1))
    dome.visual = ColorVisuals(mesh=dome, vertex_colors=dome_colors)
    parts.append(dome)
    # Oven mouth & glowing fire embers
    parts.append(create_box([0.7, 0.45, 0.3], [2.2, 1.05, -0.9], [40, 30, 28, 255]))
    parts.append(create_box([0.5, 0.25, 0.1], [2.2, 1.00, -0.85], [255, 120, 25, 255])) # Fiery emissive glow
    # Chimney
    parts.append(create_cylinder(0.18, 1.3, 12, [2.2, 2.2, -1.8], color=[130, 55, 40, 255]))
    
    # Service Counter (L-shape or straight counter)
    parts.append(create_box([2.4, 1.05, 0.7], [-0.8, 0.525, -1.2], [120, 75, 45, 255]))
    # Marble counter top
    parts.append(create_box([2.5, 0.06, 0.8], [-0.8, 1.08, -1.2], [235, 235, 240, 255]))
    # Cash Register (registratore di cassa vintage / POS)
    parts.append(create_box([0.38, 0.24, 0.32], [-0.3, 1.23, -1.2], [65, 70, 75, 255]))
    parts.append(create_box([0.22, 0.12, 0.02], [-0.3, 1.35, -1.08], [80, 220, 130, 255])) # Display
    # Pizza peel (pala per infornare appoggiata)
    peel_rot = trimesh.transformations.rotation_matrix(math.radians(-15), [0, 0, 1])
    peel = trimesh.creation.cylinder(radius=0.015, height=1.9, sections=8)
    peel.apply_transform(peel_rot)
    peel.apply_translation([1.1, 1.0, -1.2])
    peel_colors = np.tile(np.array([170, 125, 75, 255], dtype=np.uint8), (len(peel.vertices), 1))
    peel.visual = ColorVisuals(mesh=peel, vertex_colors=peel_colors)
    parts.append(peel)
    
    # Dining Tables & Chairs
    table_pos = [[-1.8, 0, 0.8], [1.2, 0, 1.2]]
    for tp in table_pos:
        # Table top with red-and-white checkered vibe (warm wood top)
        parts.append(create_box([1.1, 0.05, 1.1], [tp[0], 0.75, tp[2]], [210, 50, 50, 255]))
        parts.append(create_cylinder(0.04, 0.72, 8, [tp[0], 0.36, tp[2]], color=[45, 45, 50, 255]))
        parts.append(create_cylinder(0.24, 0.03, 12, [tp[0], 0.015, tp[2]], color=[45, 45, 50, 255]))
        # 2 chairs per table
        parts.append(create_box([0.4, 0.45, 0.4], [tp[0], 0.45, tp[2] - 0.7], [130, 85, 50, 255]))
        parts.append(create_box([0.4, 0.45, 0.4], [tp[0], 0.45, tp[2] + 0.7], [130, 85, 50, 255]))
        
    return combine_meshes(parts)


def export_glb(mesh, filepath):
    os.makedirs(os.path.dirname(filepath), exist_ok=True)
    # trimesh export as glb
    scene = trimesh.Scene(mesh)
    glb_data = trimesh.exchange.gltf.export_glb(scene)
    with open(filepath, 'wb') as f:
        f.write(glb_data)
    print(f"Exported GLB: {filepath} ({len(mesh.vertices)} vertices, {len(mesh.faces)} faces)")


def main():
    base_dir = "/home/antigravity/startup-simulator/assets"
    
    generators = {
        f"{base_dir}/props/laptop_prop.glb": build_laptop,
        f"{base_dir}/props/desk_prop.glb": build_desk,
        f"{base_dir}/props/chair_office.glb": build_chair_office,
        f"{base_dir}/props/monitor_upgrade.glb": build_monitor_upgrade,
        f"{base_dir}/props/chair_gaming_upgrade.glb": build_chair_gaming_upgrade,
        f"{base_dir}/characters/character_mario.glb": build_character_mario,
        f"{base_dir}/characters/character_player.glb": build_character_player,
        f"{base_dir}/environments/studio_room.glb": build_studio_room,
        f"{base_dir}/environments/street_district.glb": build_street_district,
        f"{base_dir}/environments/pizzeria_interior.glb": build_pizzeria_interior,
    }
    
    for path, gen_func in generators.items():
        mesh = gen_func()
        export_glb(mesh, path)
        
    print("\nAll 3D models generated successfully!")

if __name__ == "__main__":
    main()
