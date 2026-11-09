#!/usr/bin/env python3
"""
Downloads high quality CC0 Kenney 3D models (Furniture and Retro-Urban)
from shorepine/kenney into assets/models/
"""
import os
import urllib.request

BASE_URL = "https://raw.githubusercontent.com/shorepine/kenney/main/3d/"

FURNITURE_MODELS = [
    "chairDesk.glb",
    "desk.glb",
    "computerScreen.glb",
    "computerKeyboard.glb",
    "computerMouse.glb",
    "laptop.glb",
    "bookcaseClosed.glb",
    "bookcaseOpen.glb",
    "books.glb",
    "pottedPlant.glb",
    "lampRoundTable.glb",
    "rugRectangle.glb",
    "speakerSmall.glb",
]

URBAN_MODELS = [
    "wall-a-garage.glb",
    "wall-a-open.glb",
    "wall-a-door.glb",
    "wall-a-window.glb",
    "wall-a-roof-detailed.glb",
    "wall-a-painted.glb",
    "wall-b-corner.glb",
    "balcony-type-a.glb",
    "detail-awning-wide.glb",
    "detail-awning-small.glb",
    "road-asphalt-straight.glb",
    "road-asphalt-pavement.glb",
    "tree-large.glb",
    "detail-bench.glb",
    "detail-light-single.glb",
    "detail-dumpster-closed.glb",
]

def download_list(folder, items, target_dir):
    os.makedirs(target_dir, exist_ok=True)
    for item in items:
        url = f"{BASE_URL}{folder}/{item}"
        dst = os.path.join(target_dir, item)
        if not os.path.exists(dst):
            print(f"Downloading {item}...")
            try:
                urllib.request.urlretrieve(url, dst)
                print(f"✔ Saved to {dst}")
            except Exception as e:
                print(f"❌ Failed to download {item}: {e}")
        else:
            print(f"Already exists: {item}")

if __name__ == "__main__":
    download_list("furniture", FURNITURE_MODELS, "assets/models/furniture")
    download_list("retro-urban", URBAN_MODELS, "assets/models/urban")
    print("Done downloading models.")
