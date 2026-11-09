#!/usr/bin/env python3
import os
import urllib.request

URBAN_TEXTURES = [
    "asphalt.png", "bars.png", "concrete.png", "dirt.png", "doors.png",
    "grass.png", "metal.png", "metal_wall.png", "planks.png", "rock.png",
    "roof.png", "roof_plates.png", "signs.png", "tiles.png", "treeA.png",
    "treeB.png", "truck.png", "truck_alien.png", "wall.png", "wall_garage.png",
    "wall_lines.png", "windows.png"
]

SPACE_TEXTURES = [
    "colormap.png"
]

def download_textures():
    urban_dir = "assets/models/urban/Textures"
    os.makedirs(urban_dir, exist_ok=True)
    base_urban = "https://raw.githubusercontent.com/shorepine/kenney/main/3d/retro-urban/Textures/"
    for t in URBAN_TEXTURES:
        dst = os.path.join(urban_dir, t)
        if not os.path.exists(dst):
            print(f"Downloading {t}...")
            urllib.request.urlretrieve(base_urban + t, dst)

    hw_dir = "assets/models/hardware/Textures"
    os.makedirs(hw_dir, exist_ok=True)
    base_space = "https://raw.githubusercontent.com/shorepine/kenney/main/3d/space-station/Textures/"
    for t in SPACE_TEXTURES:
        dst = os.path.join(hw_dir, t)
        if not os.path.exists(dst):
            print(f"Downloading {t}...")
            urllib.request.urlretrieve(base_space + t, dst)

    print("All textures downloaded successfully.")

if __name__ == "__main__":
    download_textures()
