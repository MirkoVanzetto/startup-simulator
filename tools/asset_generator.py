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
    return trimesh.util.concatenate(valid)


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
    
    # ---------------------------------------------------------
    # FRONT WALL & GRAND TURIN PALAZZINA EXTERIOR FACADE (Z = +2.5)
    # ---------------------------------------------------------
    # Interior front wall sections
    parts.append(create_box([2.4, 3.0, 0.12], [-1.8, 1.5, 2.5], [230, 228, 222, 255]))
    parts.append(create_box([2.4, 3.0, 0.12], [ 1.8, 1.5, 2.5], [230, 228, 222, 255]))
    parts.append(create_box([1.2, 0.7, 0.14], [ 0.0, 2.65, 2.5], [210, 208, 202, 255]))
    
    # Garage Roll-up Shutter: Left Metal Rail Guide
    parts.append(create_box([0.10, 2.3, 0.22], [-0.58, 1.15, 2.52], [65, 70, 80, 255]))
    # Garage Roll-up Shutter: Right Metal Rail Guide
    parts.append(create_box([0.10, 2.3, 0.22], [ 0.58, 1.15, 2.52], [65, 70, 80, 255]))
    # Garage Roll-up Shutter: Top Roller Drum Casing (Industrial Steel)
    parts.append(create_box([1.36, 0.36, 0.32], [0, 2.36, 2.52], [55, 60, 70, 255]))
    # Garage Roll-up Shutter: Coiled Slats (Rolled Up)
    parts.append(create_box([1.16, 0.22, 0.18], [0, 2.12, 2.52], [115, 120, 130, 255]))
    # Garage Floor Threshold Plate (Industrial Ribbed Metal)
    parts.append(create_box([1.26, 0.03, 0.24], [0, 0.015, 2.52], [180, 150, 45, 255]))
    
    # EXTERIOR FACADE: Ground Floor Rusticated Stone Base (Bugnato Sabaudo)
    # Spans X = -8.0 to +8.0, Y = 0 to 3.2, Z = 2.58
    parts.append(create_box([6.8, 3.2, 0.18], [-4.6, 1.6, 2.58], [155, 150, 140, 255]))
    parts.append(create_box([6.8, 3.2, 0.18], [ 4.6, 1.6, 2.58], [155, 150, 140, 255]))
    # Architrave beam above garage door
    parts.append(create_box([1.5, 0.55, 0.22], [0, 2.72, 2.58], [140, 135, 125, 255]))
    # Signboard "GARAGE TECH - STARTUP STUDIO"
    parts.append(create_box([2.6, 0.38, 0.06], [0, 2.92, 2.68], [30, 50, 65, 255])) # Enamel plaque
    # House number plaque "12"
    parts.append(create_box([0.35, 0.25, 0.03], [-0.95, 2.1, 2.68], [240, 240, 245, 255]))
    parts.append(create_box([0.31, 0.21, 0.04], [-0.95, 2.1, 2.69], [25, 55, 120, 255]))
    # Condominium arched wooden door at X = -4.0
    parts.append(create_box([1.5, 2.5, 0.12], [-4.0, 1.25, 2.62], [75, 45, 30, 255]))
    parts.append(create_box([1.6, 0.15, 0.16], [-4.0, 2.55, 2.63], [130, 125, 115, 255]))
    # Ground floor display window at X = +4.0
    parts.append(create_box([1.8, 2.1, 0.12], [4.0, 1.45, 2.62], [35, 45, 55, 255]))
    parts.append(create_box([1.6, 1.9, 0.04], [4.0, 1.45, 2.64], [160, 205, 240, 200]))
    
    # EXTERIOR UPPER FLOORS: Floors 1, 2, 3 (Y = 3.2 to 12.0)
    # Warm Piedmontese ochre facade (X = -8.0 to +8.0, Y = 7.6, Z = 2.56)
    parts.append(create_box([16.0, 8.8, 0.16], [0, 7.6, 2.56], [215, 172, 122, 255]))
    # Horizontal stone stringcourses / moldings
    parts.append(create_box([16.4, 0.22, 0.28], [0, 3.25, 2.60], [185, 180, 170, 255]))
    parts.append(create_box([16.4, 0.18, 0.24], [0, 6.20, 2.58], [185, 180, 170, 255]))
    parts.append(create_box([16.4, 0.18, 0.24], [0, 9.15, 2.58], [185, 180, 170, 255]))
    
    # Windows & Shutters on upper floors
    win_x = [-5.5, -2.0, 2.0, 5.5]
    win_y = [4.7, 7.6, 10.5]
    for wy in win_y:
        for wx in win_x:
            # Window opening / dark glass
            parts.append(create_box([1.1, 1.7, 0.08], [wx, wy, 2.62], [30, 38, 48, 255]))
            # Stone frame sill
            parts.append(create_box([1.3, 0.14, 0.16], [wx, wy - 0.9, 2.64], [205, 200, 190, 255]))
            # Stone frame lintel
            parts.append(create_box([1.3, 0.14, 0.16], [wx, wy + 0.9, 2.64], [205, 200, 190, 255]))
            # Green Turin Shutters (Persiane Sabaude)
            parts.append(create_box([0.48, 1.65, 0.06], [wx - 0.72, wy, 2.63], [42, 75, 48, 255]))
            parts.append(create_box([0.48, 1.65, 0.06], [wx + 0.72, wy, 2.63], [42, 75, 48, 255]))
            
    # Classic Turin Wrought-Iron Balconies at Floors 1 & 2
    for by in [3.4, 6.35]:
        for bx in [-2.0, 2.0]:
            # Stone slab base
            parts.append(create_box([1.7, 0.14, 0.65], [bx, by, 2.85], [190, 185, 175, 255]))
            # Wrought-iron railing (front)
            parts.append(create_box([1.7, 0.75, 0.04], [bx, by + 0.42, 3.16], [35, 38, 42, 255]))
            # Wrought-iron railing (sides)
            parts.append(create_box([0.04, 0.75, 0.62], [bx - 0.83, by + 0.42, 2.85], [35, 38, 42, 255]))
            parts.append(create_box([0.04, 0.75, 0.62], [bx + 0.83, by + 0.42, 2.85], [35, 38, 42, 255]))
            
    # Stately Cornice & Mansard Roof at Top (Y = 12.0 to 13.8)
    parts.append(create_box([16.8, 0.45, 0.65], [0, 12.1, 2.70], [175, 170, 160, 255]))
    parts.append(create_box([16.8, 0.30, 0.85], [0, 12.4, 2.80], [160, 155, 145, 255]))
    # Slate Mansard Roof
    parts.append(create_box([16.6, 1.30, 1.40], [0, 13.1, 2.20], [60, 65, 75, 255]))
    
    # Exterior Side Returns (wings) to connect seamlessly to adjacent street buildings
    parts.append(create_box([0.3, 13.5, 3.5], [-8.0, 6.75, 3.8], [210, 168, 118, 255]))
    parts.append(create_box([0.3, 13.5, 3.5], [ 8.0, 6.75, 3.8], [210, 168, 118, 255]))
    
    # Studio Interior Ceiling
    parts.append(create_box([6.0, 0.10, 5.0], [0, 3.05, 0], [240, 240, 242, 255]))
    # Ceiling modern pendant lamp
    parts.append(create_cylinder(0.01, 0.60, 8, [0, 2.75, 0], color=[40, 40, 40, 255]))
    parts.append(create_cylinder(0.22, 0.12, 16, [0, 2.42, 0], color=[250, 220, 150, 255]))
    return combine_meshes(parts)

# -------------------------------------------------------------
# 9. TURIN STREET DISTRICT ROADWAY & SIDEWALKS
# -------------------------------------------------------------
def build_street_roadway():
    parts = []
    # Main Roadway Asphalt (5.2m wide, spans X = -2.6 to +2.6, Z = -3.0 to 25.0)
    parts.append(create_box([5.2, 0.15, 28.0], [0, -0.075, 11.0], [52, 55, 60, 255]))
    
    # Painted Dashed White Center Line (Z = -2.0 to 24.0)
    for z in range(-1, 24, 3):
        # Skip pedestrian crossing zone (Z = 15 to 18)
        if 14 <= z <= 18:
            continue
        parts.append(create_box([0.18, 0.005, 1.8], [0, 0.003, z], [245, 245, 250, 255]))
        
    # Pedestrian Zebra Crossing (Strisce Pedonali) in front of Pizzeria Da Mario (Z = 16.5)
    for x in [-2.0, -1.2, -0.4, 0.4, 1.2, 2.0]:
        parts.append(create_box([0.5, 0.006, 2.2], [x, 0.003, 16.5], [245, 245, 250, 255]))
        
    # Yellow Parking Markings along Curb
    for z in range(3, 14, 4):
        parts.append(create_box([0.12, 0.005, 3.6], [-2.35, 0.003, z], [235, 195, 45, 255]))
        parts.append(create_box([0.12, 0.005, 3.6], [ 2.35, 0.003, z + 2], [235, 195, 45, 255]))
        
    # Cast Iron Manhole Covers (Tombini Torino)
    parts.append(create_cylinder(0.42, 0.01, 16, [0.8, 0.003, 5.0], color=[40, 42, 45, 255]))
    parts.append(create_cylinder(0.42, 0.01, 16, [-0.6, 0.003, 12.0], color=[40, 42, 45, 255]))
    
    # Storm Drain Grates (Caditoie Stradali) along curbs
    parts.append(create_box([0.35, 0.01, 0.6], [-2.35, 0.003, 7.5], [35, 38, 42, 255]))
    parts.append(create_box([0.35, 0.01, 0.6], [ 2.35, 0.003, 14.5], [35, 38, 42, 255]))
    
    # LEFT SIDEWALK (West, X from -2.6 to -6.8, width 4.2m, height 0.16m)
    # Sidewalk granite pavement
    parts.append(create_box([4.2, 0.16, 28.0], [-4.7, 0.08, 11.0], [195, 192, 185, 255]))
    # Raised granite curb stone along road edge
    parts.append(create_box([0.22, 0.18, 28.0], [-2.6, 0.09, 11.0], [165, 162, 155, 255]))
    
    # RIGHT SIDEWALK (East, X from +2.6 to +6.8, width 4.2m, height 0.16m)
    # Sidewalk granite pavement
    parts.append(create_box([4.2, 0.16, 28.0], [ 4.7, 0.08, 11.0], [195, 192, 185, 255]))
    # Raised granite curb stone along road edge
    parts.append(create_box([0.22, 0.18, 28.0], [ 2.6, 0.09, 11.0], [165, 162, 155, 255]))
    
    # SOUTH PIAZZA PAVING (Capping past Z = 24.0, from Z = 24.0 to 30.0, width 14.0m)
    parts.append(create_box([14.0, 0.16, 6.0], [0, 0.08, 27.0], [185, 180, 172, 255]))
    
    return combine_meshes(parts)

def build_street_district():
    # Retain old signature for backward compatibility
    return build_street_roadway()


# -------------------------------------------------------------
# 10. PIZZERIA INTERIOR & WOOD-FIRED OVEN
# -------------------------------------------------------------
def build_pizzeria_interior():
    parts = []
    # Terracotta Floor (7m x 6m)
    parts.append(create_box([7.0, 0.10, 6.0], [0, -0.05, 0], [195, 105, 65, 255]))
    # Walls (rustic brick and warm plaster)
    parts.append(create_box([7.0, 3.2, 0.15], [0, 1.6, -3.0], [152, 58, 40, 255])) # Back
    parts.append(create_box([0.15, 3.2, 6.0], [-3.5, 1.6, 0], [152, 58, 40, 255])) # Left
    parts.append(create_box([0.15, 3.2, 6.0], [ 3.5, 1.6, 0], [152, 58, 40, 255])) # Right
    parts.append(create_box([7.0, 0.10, 6.0], [0, 3.25, 0], [235, 225, 205, 255])) # Ceiling
    
    # ---------------------------------------------------------
    # PIZZERIA EXTERIOR FACADE & ENTRANCE (Z = +3.0)
    # ---------------------------------------------------------
    # Rustic Terracotta Brick Base Wall (Left & Right of entrance)
    parts.append(create_box([2.8, 3.2, 0.18], [-2.1, 1.6, 3.0], [152, 58, 40, 255]))
    parts.append(create_box([2.8, 3.2, 0.18], [ 2.1, 1.6, 3.0], [152, 58, 40, 255]))
    parts.append(create_box([1.4, 0.9, 0.18], [ 0.0, 2.75, 3.0], [152, 58, 40, 255]))
    
    # Ground floor facade extensions to seamlessly join street buildings (width 14.0, X = -7.0 to +7.0)
    parts.append(create_box([3.5, 3.2, 0.20], [-5.25, 1.6, 3.0], [152, 58, 40, 255]))
    parts.append(create_box([3.5, 3.2, 0.20], [ 5.25, 1.6, 3.0], [152, 58, 40, 255]))
    # Ground floor display windows on flanking palazzo extensions
    parts.append(create_box([1.8, 1.8, 0.08], [-5.25, 1.5, 3.08], [65, 42, 28, 255]))
    parts.append(create_box([1.6, 1.6, 0.02], [-5.25, 1.5, 3.09], [170, 215, 245, 190]))
    parts.append(create_box([1.8, 1.8, 0.08], [ 5.25, 1.5, 3.08], [65, 42, 28, 255]))
    parts.append(create_box([1.6, 1.6, 0.02], [ 5.25, 1.5, 3.09], [170, 215, 245, 190]))
    
    # Large Traditional Italian Pizzeria Windows (Vetrina Saletta)
    # Left display window (X = -2.1)
    parts.append(create_box([1.8, 1.8, 0.08], [-2.1, 1.5, 3.08], [65, 42, 28, 255])) # Dark Walnut Frame
    parts.append(create_box([1.6, 1.6, 0.02], [-2.1, 1.5, 3.09], [170, 215, 245, 190])) # Glass
    # Right display window (X = +2.1)
    parts.append(create_box([1.8, 1.8, 0.08], [ 2.1, 1.5, 3.08], [65, 42, 28, 255]))
    parts.append(create_box([1.6, 1.6, 0.02], [ 2.1, 1.5, 3.09], [170, 215, 245, 190]))
    
    # Heavy Timber Lintel beam above doorway
    parts.append(create_box([1.8, 0.32, 0.22], [0, 2.40, 3.04], [68, 40, 24, 255]))
    # Exterior Signboard "PIZZERIA DA MARIO"
    parts.append(create_box([2.8, 0.52, 0.10], [0, 2.85, 3.10], [168, 36, 26, 255])) # Napoli Red
    parts.append(create_box([2.9, 0.06, 0.12], [0, 3.12, 3.10], [215, 175, 55, 255])) # Gold trim top
    parts.append(create_box([2.9, 0.06, 0.12], [0, 2.58, 3.10], [215, 175, 55, 255])) # Gold trim bottom
    
    # UPPER FLOORS ABOVE PIZZERIA (Y = 3.2 to 12.0) - Encloses vertical sky completely!
    parts.append(create_box([14.0, 8.8, 0.20], [0, 7.6, 3.0], [205, 155, 105, 255])) # Warm Piedmontese ochre
    # Horizontal stone stringcourses
    parts.append(create_box([14.4, 0.20, 0.26], [0, 3.25, 3.04], [180, 175, 165, 255]))
    parts.append(create_box([14.4, 0.18, 0.24], [0, 6.20, 3.04], [180, 175, 165, 255]))
    parts.append(create_box([14.4, 0.18, 0.24], [0, 9.15, 3.04], [180, 175, 165, 255]))
    
    # Upper windows & shutters above pizzeria
    for wy in [4.7, 7.6, 10.5]:
        for wx in [-4.5, -1.8, 1.8, 4.5]:
            parts.append(create_box([1.0, 1.6, 0.08], [wx, wy, 3.08], [30, 38, 48, 255]))
            parts.append(create_box([1.2, 0.12, 0.14], [wx, wy - 0.85, 3.10], [195, 190, 180, 255]))
            parts.append(create_box([0.45, 1.55, 0.06], [wx - 0.65, wy, 3.09], [38, 72, 42, 255])) # Green shutters
            parts.append(create_box([0.45, 1.55, 0.06], [wx + 0.65, wy, 3.09], [38, 72, 42, 255]))
            
    # Stately Cornice and Mansard Roof at top
    parts.append(create_box([14.8, 0.40, 0.60], [0, 12.1, 3.20], [170, 165, 155, 255]))
    parts.append(create_box([14.6, 1.20, 1.40], [0, 13.0, 2.70], [55, 60, 70, 255]))
    
    # Side exterior wings
    parts.append(create_box([0.3, 13.0, 3.5], [-7.0, 6.5, 1.5], [205, 155, 105, 255]))
    parts.append(create_box([0.3, 13.0, 3.5], [ 7.0, 6.5, 1.5], [205, 155, 105, 255]))

    
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
