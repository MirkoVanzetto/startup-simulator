#!/usr/bin/env python3
"""
Downloads high quality CC0 Kenney 3D assets:
- mini-characters (real 3D human character models for Elena, Davide, Luca, Sara, Marco)
- city-roads (zebra crossings, road markings)
- city-suburban (authentic 2-3 story neighborhood buildings)
"""
import os
import urllib.request

BASE_URL = "https://raw.githubusercontent.com/shorepine/kenney/main/3d/"

DOWNLOADS = {
    "mini-characters": {
        "folder": "mini-characters",
        "target": "assets/models/characters",
        "files": [
            "character-female-a.glb",
            "character-female-b.glb",
            "character-female-c.glb",
            "character-male-a.glb",
            "character-male-b.glb",
            "character-male-c.glb",
            "character-male-d.glb",
            "aid-glasses.glb"
        ]
    },
    "mini-characters-textures": {
        "folder": "mini-characters/Textures",
        "target": "assets/models/characters/Textures",
        "files": [
            "colormap.png"
        ]
    },
    "city-roads": {
        "folder": "city-roads",
        "target": "assets/models/city",
        "files": [
            "road-crossing.glb",
            "light-curved.glb",
            "construction-barrier.glb",
            "construction-cone.glb"
        ]
    },
    "city-suburban": {
        "folder": "city-suburban",
        "target": "assets/models/city",
        "files": [
            "building-type-a.glb",
            "building-type-b.glb",
            "building-type-c.glb",
            "building-type-d.glb",
            "building-type-e.glb",
            "building-type-f.glb"
        ]
    }
}

def main():
    for pack_key, cfg in DOWNLOADS.items():
        folder = cfg["folder"]
        target = cfg["target"]
        os.makedirs(target, exist_ok=True)
        for fname in cfg["files"]:
            url = f"{BASE_URL}{folder}/{fname}"
            dst = os.path.join(target, fname)
            if not os.path.exists(dst):
                print(f"Downloading {fname} from {url}...")
                try:
                    urllib.request.urlretrieve(url, dst)
                    print(f"✔ Saved {dst} ({os.path.getsize(dst)} bytes)")
                except Exception as e:
                    print(f"❌ Failed to download {fname}: {e}")
            else:
                print(f"Already exists: {dst}")

if __name__ == "__main__":
    main()
