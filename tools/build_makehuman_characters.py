#!/usr/bin/env python3
"""
tools/build_makehuman_characters.py

Generates lightweight (~5.5k-7.5k triangles), skeletal-rigged CC0 MakeHuman .glb
character archetypes for Startup Simulator (Torino v1.5):
  - Uses MakeHuman base mesh, female_young / male_young / male_old targets,
    helper-tights, helper-skirt, lowpoly eyes, and game_engine vertex weights.
  - Simplifies head/neck and each exposed forearm/hand independently via QEM with
    smooth anatomical importance weights so sculpted 5-finger hands, noses, chins
    and necks remain sharp while vertex counts stay lightweight for 60 FPS.
  - Computes every garment, collar, lapel, apron, skirt, hair cap and hat
    proportionally from morphed joint and surface queries so male and female
    archetypes fit cleanly with zero clipping or protruding polygons.
  - Exports GLTF 2.0 binary (.glb) with a 21-bone game rig, inverse bind matrices,
    and baked Idle, Sit_Chair_Idle, Interact & Cheer skeletal animations.
"""

from __future__ import annotations

import heapq
import json
import math
import os
from collections import defaultdict
from dataclasses import dataclass, field
from typing import Callable, Dict, List, Optional, Tuple

import numpy as np
import pygltflib

MH_ASSET_DIR = (
    "/home/antigravity/.gemini/jetski/brain/v1/default/jetski_remote_agents_3p/"
    "bacc9f0b-1921-49ab-9a99-c6feb4c7fe94/scratch/mh_assets"
)
OUT_DIR = "/home/antigravity/startup-simulator/assets/models/characters"

# 21-bone clean game skeleton collapsing MakeHuman's 53 game_engine bones (no 30 finger/toe micro-bones)
BONE_HIERARCHY: List[Tuple[str, Optional[str], str]] = [
    ("Root", None, "joint-ground"),
    ("pelvis", "Root", "joint-pelvis"),
    ("spine_01", "pelvis", "joint-spine-4"),
    ("spine_02", "spine_01", "joint-spine-3"),
    ("spine_03", "spine_02", "joint-spine-2"),
    ("neck_01", "spine_03", "joint-neck"),
    ("head", "neck_01", "joint-head"),
    ("clavicle_l", "spine_03", "joint-l-clavicle"),
    ("upperarm_l", "clavicle_l", "joint-l-shoulder"),
    ("lowerarm_l", "upperarm_l", "joint-l-elbow"),
    ("hand_l", "lowerarm_l", "joint-l-hand"),
    ("clavicle_r", "spine_03", "joint-r-clavicle"),
    ("upperarm_r", "clavicle_r", "joint-r-shoulder"),
    ("lowerarm_r", "upperarm_r", "joint-r-elbow"),
    ("hand_r", "lowerarm_r", "joint-r-hand"),
    ("thigh_l", "pelvis", "joint-l-upper-leg"),
    ("calf_l", "thigh_l", "joint-l-knee"),
    ("foot_l", "calf_l", "joint-l-ankle"),
    ("thigh_r", "pelvis", "joint-r-upper-leg"),
    ("calf_r", "thigh_r", "joint-r-knee"),
    ("foot_r", "calf_r", "joint-r-ankle"),
]

BONE_INDEX: Dict[str, int] = {name: i for i, (name, _, _) in enumerate(BONE_HIERARCHY)}

BONE_REMAP: Dict[str, str] = {name: name for name, _, _ in BONE_HIERARCHY}
for side in ("l", "r"):
    BONE_REMAP[f"ball_{side}"] = f"foot_{side}"
    for finger in ("thumb", "index", "middle", "ring", "pinky"):
        for seg in ("01", "02", "03"):
            BONE_REMAP[f"{finger}_{seg}_{side}"] = f"hand_{side}"


def quat_from_euler_xyz(rx: float, ry: float, rz: float) -> Tuple[float, float, float, float]:
    """Return quaternion (x, y, z, w) for Z*Y*X composition."""
    cx, sx = math.cos(rx * 0.5), math.sin(rx * 0.5)
    cy, sy = math.cos(ry * 0.5), math.sin(ry * 0.5)
    cz, sz = math.cos(rz * 0.5), math.sin(rz * 0.5)

    def mul(a, b):
        aw, ax, ay, az = a
        bw, bx, by, bz = b
        return (
            aw * bw - ax * bx - ay * by - az * bz,
            aw * bx + ax * bw + ay * bz - az * by,
            aw * by - ax * bz + ay * bw + az * bx,
            aw * bz + ax * by - ay * bx + az * bw,
        )

    w, x, y, z = mul((cz, 0.0, 0.0, sz), mul((cy, 0.0, sy, 0.0), (cx, sx, 0.0, 0.0)))
    return (x, y, z, w)


class MHBaseData:
    def __init__(self) -> None:
        verts: List[List[float]] = []
        faces_by_g: Dict[str, List[List[int]]] = defaultdict(list)
        cur_g = "default"
        with open(os.path.join(MH_ASSET_DIR, "mh_base.obj"), "r", encoding="utf-8") as f:
            for line in f:
                p = line.split()
                if not p:
                    continue
                if p[0] == "v":
                    verts.append([float(p[1]), float(p[2]), float(p[3])])
                elif p[0] in ("g", "o"):
                    cur_g = p[1] if len(p) > 1 else "default"
                elif p[0] == "f":
                    faces_by_g[cur_g].append([int(tok.split("/")[0]) - 1 for tok in p[1:]])

        self.base_verts = np.array(verts, dtype=np.float64)
        self.faces_by_g = dict(faces_by_g)

        self.targets: Dict[str, np.ndarray] = {}
        for tname in ("male_young", "female_young", "male_old"):
            delta = np.zeros_like(self.base_verts)
            with open(os.path.join(MH_ASSET_DIR, f"{tname}.target"), "r", encoding="utf-8") as f:
                for line in f:
                    s = line.strip()
                    if not s or s.startswith("#"):
                        continue
                    sp = s.split()
                    delta[int(sp[0])] = [float(sp[1]), float(sp[2]), float(sp[3])]
            self.targets[tname] = delta

        # Load collapsed 21-bone weights aligned to base_verts index
        with open(os.path.join(MH_ASSET_DIR, "weights_ge.json"), "r", encoding="utf-8") as f:
            raw_w = json.load(f)["weights"]

        per_v: List[Dict[int, float]] = [defaultdict(float) for _ in range(len(self.base_verts))]
        for raw_b, pairs in raw_w.items():
            mapped = BONE_REMAP.get(raw_b)
            if mapped is None or mapped not in BONE_INDEX:
                continue
            bi = BONE_INDEX[mapped]
            for vi, w in pairs:
                per_v[int(vi)][bi] += float(w)

        n_v = len(self.base_verts)
        self.base_joints = np.zeros((n_v, 4), dtype=np.int32)
        self.base_weights = np.zeros((n_v, 4), dtype=np.float32)
        self.base_weights[:, 0] = 1.0
        for vi, d in enumerate(per_v):
            if not d:
                continue
            items = sorted(d.items(), key=lambda x: -x[1])[:4]
            tot = sum(w for _, w in items)
            if tot <= 1e-7:
                continue
            self.base_weights[vi, :] = 0.0
            for k, (bi, w) in enumerate(items):
                self.base_joints[vi, k] = bi
                self.base_weights[vi, k] = w / tot

    def build_morphed_state(self, morph_mix: Dict[str, float]) -> Tuple[np.ndarray, Dict[str, np.ndarray]]:
        v = self.base_verts.copy()
        for tname, factor in morph_mix.items():
            if factor != 0.0 and tname in self.targets:
                v += self.targets[tname] * float(factor)
        v *= 0.1
        body_vi = np.unique([i for q in self.faces_by_g["body"] for i in q])
        min_y = v[body_vi, 1].min()
        v[:, 1] -= min_y

        joints_pos: Dict[str, np.ndarray] = {}
        for bname, _, cube_name in BONE_HIERARCHY:
            if cube_name == "joint-ground":
                joints_pos[bname] = np.array([0.0, 0.0, 0.0], dtype=np.float64)
            else:
                q_list = self.faces_by_g[cube_name]
                ci = np.unique([i for q in q_list for i in q])
                joints_pos[bname] = v[ci].mean(axis=0)
        return v, joints_pos


def compute_smooth_normals(verts: np.ndarray, tris: np.ndarray) -> np.ndarray:
    norms = np.zeros_like(verts, dtype=np.float64)
    if len(tris) == 0:
        return norms
    v0 = verts[tris[:, 0]]
    v1 = verts[tris[:, 1]]
    v2 = verts[tris[:, 2]]
    fn = np.cross(v1 - v0, v2 - v0)
    for k in range(3):
        np.add.at(norms, tris[:, k], fn)
    lens = np.linalg.norm(norms, axis=1, keepdims=True)
    norms = np.where(lens > 1e-10, norms / np.maximum(lens, 1e-10), np.array([0.0, 1.0, 0.0]))
    return norms


def decimate_surface(
    verts: np.ndarray,
    tris: np.ndarray,
    joints: np.ndarray,
    weights: np.ndarray,
    target_tris: int,
    vertex_importance: Optional[np.ndarray] = None,
) -> Tuple[np.ndarray, np.ndarray, np.ndarray, np.ndarray]:
    """
    Smooth feature-preserving quadric-error edge collapse decimation.
    Uses balanced importance weights (never hardlocking cliffs) + edge length penalty
    so triangles remain uniform and needle spikes never form.
    """
    if len(tris) <= target_tris or target_tris < 12:
        used = np.unique(tris.reshape(-1))
        remap = np.full(len(verts), -1, dtype=np.int32)
        remap[used] = np.arange(len(used), dtype=np.int32)
        return (
            verts[used].copy(),
            remap[tris].astype(np.int32),
            joints[used].copy(),
            weights[used].copy(),
        )

    v = verts.astype(np.float64).copy()
    f = tris.astype(np.int32).copy()
    j = joints.copy()
    w = weights.copy()
    n_v = len(v)
    n_f = len(f)

    imp = np.ones(n_v, dtype=np.float64) if vertex_importance is None else vertex_importance.astype(np.float64)

    Q = np.zeros((n_v, 4, 4), dtype=np.float64)
    v0, v1, v2 = v[f[:, 0]], v[f[:, 1]], v[f[:, 2]]
    fn = np.cross(v1 - v0, v2 - v0)
    area = np.linalg.norm(fn, axis=1)
    valid = area > 1e-12
    nn = np.zeros_like(fn)
    nn[valid] = fn[valid] / area[valid, None]
    dd = -np.sum(nn * v0, axis=1)
    planes = np.concatenate([nn, dd[:, None]], axis=1)
    Kp = np.einsum("fi,fj->fij", planes, planes) * np.maximum(area, 1e-8)[:, None, None]
    for k in range(3):
        np.add.at(Q, f[:, k], Kp)
    Q *= imp[:, None, None]

    edge_counts: Dict[Tuple[int, int], int] = defaultdict(int)
    for fi in range(n_f):
        a, b, c = int(f[fi, 0]), int(f[fi, 1]), int(f[fi, 2])
        for p, q in ((a, b), (b, c), (c, a)):
            e = (p, q) if p < q else (q, p)
            edge_counts[e] += 1
    is_boundary = np.zeros(n_v, dtype=bool)
    for (p, q), cnt in edge_counts.items():
        if cnt == 1:
            is_boundary[p] = True
            is_boundary[q] = True
    Q[is_boundary] *= 18.0

    v_faces: List[set] = [set() for _ in range(n_v)]
    for fi in range(n_f):
        v_faces[f[fi, 0]].add(fi)
        v_faces[f[fi, 1]].add(fi)
        v_faces[f[fi, 2]].add(fi)

    alive_f = np.ones(n_f, dtype=bool)
    alive_v = np.ones(n_v, dtype=bool)
    v_ver = np.zeros(n_v, dtype=np.int32)

    def edge_cost(u: int, z: int) -> Tuple[float, np.ndarray]:
        qsum = Q[u] + Q[z]
        best_p = 0.5 * (v[u] + v[z])
        mat = qsum[:3, :3]
        det = np.linalg.det(mat)
        if abs(det) > 1e-10:
            try:
                cand = np.linalg.solve(mat, -qsum[:3, 3])
                if np.linalg.norm(cand - best_p) < max(np.linalg.norm(v[u] - v[z]) * 1.25, 0.025):
                    best_p = cand
            except np.linalg.LinAlgError:
                pass
        else:
            p4u = np.append(v[u], 1.0)
            p4z = np.append(v[z], 1.0)
            p4m = np.append(best_p, 1.0)
            eu = float(p4u @ qsum @ p4u)
            ez = float(p4z @ qsum @ p4z)
            em = float(p4m @ qsum @ p4m)
            if eu <= ez and eu <= em:
                best_p = v[u].copy()
            elif ez <= eu and ez <= em:
                best_p = v[z].copy()
        p4 = np.append(best_p, 1.0)
        err = max(0.0, float(p4 @ qsum @ p4))
        if is_boundary[u] != is_boundary[z]:
            err += 0.04
        elen = float(np.linalg.norm(v[u] - v[z]))
        # Strong length penalty prevents long stretched spikes across chin/neck/wrists
        err += (elen ** 3) * 1.6
        return err, best_p

    heap: List[Tuple[float, int, int, int, int, float, float, float]] = []
    for (p, q) in edge_counts.keys():
        cost, pos = edge_cost(p, q)
        heapq.heappush(heap, (cost, p, q, v_ver[p], v_ver[q], pos[0], pos[1], pos[2]))

    cur_tris = n_f
    while cur_tris > target_tris and heap:
        cost, u, z, vu, vz, px, py, pz = heapq.heappop(heap)
        if not alive_v[u] or not alive_v[z] or u == z:
            continue
        if v_ver[u] != vu or v_ver[z] != vz:
            continue
        if is_boundary[u] and is_boundary[z] and np.linalg.norm(v[u] - v[z]) > 0.032:
            continue

        new_pos = np.array([px, py, pz], dtype=np.float64)
        flip = False
        common = v_faces[u] & v_faces[z]
        for fi in (v_faces[u] | v_faces[z]):
            if not alive_f[fi] or fi in common:
                continue
            a, b, c = int(f[fi, 0]), int(f[fi, 1]), int(f[fi, 2])
            old_n = np.cross(v[b] - v[a], v[c] - v[a])
            ol = np.linalg.norm(old_n)
            if ol < 1e-12:
                continue
            pa = new_pos if (a == u or a == z) else v[a]
            pb = new_pos if (b == u or b == z) else v[b]
            pc = new_pos if (c == u or c == z) else v[c]
            new_n = np.cross(pb - pa, pc - pa)
            nl = np.linalg.norm(new_n)
            if nl < 1e-12 or float(np.dot(old_n, new_n)) <= 0.18 * ol * nl:
                flip = True
                break
        if flip:
            continue

        # Collapse z into u
        v[u] = new_pos
        Q[u] = Q[u] + Q[z]
        is_boundary[u] = is_boundary[u] or is_boundary[z]
        imp[u] = max(imp[u], imp[z])
        alive_v[z] = False
        v_ver[u] += 1

        for fi in list(common):
            if alive_f[fi]:
                alive_f[fi] = False
                cur_tris -= 1
            v_faces[f[fi, 0]].discard(fi)
            v_faces[f[fi, 1]].discard(fi)
            v_faces[f[fi, 2]].discard(fi)

        for fi in list(v_faces[z]):
            if not alive_f[fi]:
                continue
            for k in range(3):
                if f[fi, k] == z:
                    f[fi, k] = u
            if f[fi, 0] == f[fi, 1] or f[fi, 1] == f[fi, 2] or f[fi, 2] == f[fi, 0]:
                alive_f[fi] = False
                cur_tris -= 1
                v_faces[f[fi, 0]].discard(fi)
                v_faces[f[fi, 1]].discard(fi)
                v_faces[f[fi, 2]].discard(fi)
            else:
                v_faces[u].add(fi)
        v_faces[z].clear()

        nbrs = set()
        for fi in v_faces[u]:
            if alive_f[fi]:
                nbrs.update((int(f[fi, 0]), int(f[fi, 1]), int(f[fi, 2])))
        nbrs.discard(u)
        for nb in nbrs:
            if alive_v[nb]:
                p, q = (u, nb) if u < nb else (nb, u)
                c_val, c_pos = edge_cost(p, q)
                heapq.heappush(heap, (c_val, p, q, v_ver[p], v_ver[q], c_pos[0], c_pos[1], c_pos[2]))

    kept_f = f[alive_f]
    used = np.unique(kept_f.reshape(-1))
    remap = np.full(n_v, -1, dtype=np.int32)
    remap[used] = np.arange(len(used), dtype=np.int32)
    return v[used].copy(), remap[kept_f].astype(np.int32), j[used].copy(), w[used].copy()


@dataclass
class CharacterMeshBuilder:
    mh: MHBaseData
    verts: np.ndarray
    joints_pos: Dict[str, np.ndarray]
    surfaces: Dict[str, List[Tuple[np.ndarray, np.ndarray, np.ndarray, np.ndarray]]] = field(
        default_factory=lambda: defaultdict(list)
    )

    def add_chunk(
        self,
        surface: str,
        v_arr: np.ndarray,
        tris: np.ndarray,
        j_arr: np.ndarray,
        w_arr: np.ndarray,
    ) -> None:
        if len(tris) == 0 or len(v_arr) == 0:
            return
        self.surfaces[surface].append(
            (v_arr.astype(np.float32), tris.astype(np.int32), j_arr.astype(np.int32), w_arr.astype(np.float32))
        )

    def prepare_quad_group(
        self,
        quads: List[List[int]],
        target_tris: Optional[int] = None,
        offset_normal: float = 0.0,
        verts_override: Optional[np.ndarray] = None,
        importance: Optional[np.ndarray] = None,
    ) -> Tuple[np.ndarray, np.ndarray, np.ndarray, np.ndarray]:
        if not quads:
            empty_v = np.zeros((0, 3), dtype=np.float64)
            empty_t = np.zeros((0, 3), dtype=np.int32)
            return empty_v, empty_t, np.zeros((0, 4), dtype=np.int32), np.zeros((0, 4), dtype=np.float32)

        src_v = self.verts if verts_override is None else verts_override
        tris_raw: List[List[int]] = []
        for q in quads:
            if len(q) == 4:
                tris_raw.append([q[0], q[1], q[2]])
                tris_raw.append([q[0], q[2], q[3]])
            elif len(q) == 3:
                tris_raw.append([q[0], q[1], q[2]])
        t_arr = np.array(tris_raw, dtype=np.int32)
        used = np.unique(t_arr.reshape(-1))
        remap = np.full(len(src_v), -1, dtype=np.int32)
        remap[used] = np.arange(len(used), dtype=np.int32)
        lv = src_v[used].copy()
        lt = remap[t_arr].astype(np.int32)
        lj = self.mh.base_joints[used].copy()
        lw = self.mh.base_weights[used].copy()

        if abs(offset_normal) > 1e-6:
            ln = compute_smooth_normals(lv, lt)
            lv += ln * float(offset_normal)

        if target_tris is not None and len(lt) > target_tris:
            limp = None if importance is None else importance[used]
            lv, lt, lj, lw = decimate_surface(lv, lt, lj, lw, target_tris, limp)
        return lv, lt, lj, lw

    def add_quad_group_with_weights(
        self,
        surface: str,
        quads: List[List[int]],
        target_tris: Optional[int] = None,
        offset_normal: float = 0.0,
        verts_override: Optional[np.ndarray] = None,
        importance: Optional[np.ndarray] = None,
    ) -> None:
        lv, lt, lj, lw = self.prepare_quad_group(
            quads,
            target_tris=target_tris,
            offset_normal=offset_normal,
            verts_override=verts_override,
            importance=importance,
        )
        self.add_chunk(surface, lv, lt, lj, lw)

    def split_and_add_triangles(
        self,
        surface_true: str,
        surface_false: str,
        lv: np.ndarray,
        lt: np.ndarray,
        lj: np.ndarray,
        lw: np.ndarray,
        mask_fn: Callable[[np.ndarray, np.ndarray], np.ndarray],
    ) -> None:
        if len(lt) == 0:
            return
        centroids = (lv[lt[:, 0]] + lv[lt[:, 1]] + lv[lt[:, 2]]) / 3.0
        fn = np.cross(lv[lt[:, 1]] - lv[lt[:, 0]], lv[lt[:, 2]] - lv[lt[:, 0]])
        fl = np.linalg.norm(fn, axis=1, keepdims=True)
        fn = np.where(fl > 1e-10, fn / np.maximum(fl, 1e-10), np.array([0.0, 0.0, 1.0]))
        m = mask_fn(centroids, fn)
        for sname, mask in ((surface_true, m), (surface_false, ~m)):
            idx = np.where(mask)[0]
            if len(idx) == 0:
                continue
            sub_t = lt[idx]
            used = np.unique(sub_t.reshape(-1))
            remap = np.full(len(lv), -1, dtype=np.int32)
            remap[used] = np.arange(len(used), dtype=np.int32)
            self.add_chunk(sname, lv[used], remap[sub_t], lj[used], lw[used])

    def transfer_weights_nearest(self, pts: np.ndarray, ref_verts: Optional[np.ndarray] = None) -> Tuple[np.ndarray, np.ndarray]:
        if ref_verts is None:
            ref_idx = np.unique([i for q in self.mh.faces_by_g["body"] for i in q])
            ref_pts = self.verts[ref_idx]
        else:
            ref_idx = np.arange(len(ref_verts))
            ref_pts = ref_verts
        n = len(pts)
        j_out = np.zeros((n, 4), dtype=np.int32)
        w_out = np.zeros((n, 4), dtype=np.float32)
        chunk = 256
        for start in range(0, n, chunk):
            sub = pts[start : start + chunk]
            d2 = np.sum((sub[:, None, :] - ref_pts[None, :, :]) ** 2, axis=2)
            nearest = np.argmin(d2, axis=1)
            orig_i = ref_idx[nearest] if ref_verts is None else nearest
            j_out[start : start + chunk] = self.mh.base_joints[orig_i]
            w_out[start : start + chunk] = self.mh.base_weights[orig_i]
        return j_out, w_out

    def add_custom_rigid_bone_mesh(
        self, surface: str, pts: np.ndarray, tris: np.ndarray, bone_name: str
    ) -> None:
        bi = BONE_INDEX[bone_name]
        n = len(pts)
        j = np.zeros((n, 4), dtype=np.int32)
        j[:, 0] = bi
        w = np.zeros((n, 4), dtype=np.float32)
        w[:, 0] = 1.0
        self.add_chunk(surface, pts, tris, j, w)

    def add_tube(
        self,
        surface: str,
        path_pts: List[List[float]],
        radii: List[float],
        rings: int = 8,
        cap: bool = True,
        rigid_bone: Optional[str] = None,
    ) -> None:
        pts_c = [np.array(p, dtype=np.float64) for p in path_pts]
        n_seg = len(pts_c)
        all_v: List[np.ndarray] = []
        all_t: List[List[int]] = []
        up_ref = np.array([0.0, 1.0, 0.0], dtype=np.float64)
        for i in range(n_seg):
            if i == 0:
                tang = pts_c[1] - pts_c[0]
            elif i == n_seg - 1:
                tang = pts_c[-1] - pts_c[-2]
            else:
                tang = pts_c[i + 1] - pts_c[i - 1]
            tlen = np.linalg.norm(tang)
            tang = tang / max(tlen, 1e-8)
            ref = up_ref if abs(np.dot(tang, up_ref)) < 0.92 else np.array([0.0, 0.0, 1.0])
            side = np.cross(tang, ref)
            side /= max(np.linalg.norm(side), 1e-8)
            norm = np.cross(side, tang)
            r = radii[i]
            for k in range(rings):
                ang = (2.0 * math.pi * k) / rings
                all_v.append(pts_c[i] + (side * math.cos(ang) + norm * math.sin(ang)) * r)
        for i in range(n_seg - 1):
            b0, b1 = i * rings, (i + 1) * rings
            for k in range(rings):
                kn = (k + 1) % rings
                all_t.append([b0 + k, b1 + k, b1 + kn])
                all_t.append([b0 + k, b1 + kn, b0 + kn])
        if cap:
            c0 = len(all_v)
            all_v.append(pts_c[0].copy())
            c1 = len(all_v)
            all_v.append(pts_c[-1].copy())
            for k in range(rings):
                kn = (k + 1) % rings
                all_t.append([c0, kn, k])
                all_t.append([c1, (n_seg - 1) * rings + k, (n_seg - 1) * rings + kn])

        va = np.array(all_v, dtype=np.float64)
        ta = np.array(all_t, dtype=np.int32)
        if rigid_bone:
            self.add_custom_rigid_bone_mesh(surface, va, ta, rigid_bone)
        else:
            j, w = self.transfer_weights_nearest(va)
            self.add_chunk(surface, va, ta, j, w)

    def add_lathe_pleated(
        self,
        surface: str,
        origin: np.ndarray,
        profile: List[Tuple[float, float, float]],
        sx: float = 1.0,
        sz: float = 1.0,
        segs: int = 32,
        pleat_count: int = 16,
        pleat_amp: float = 0.006,
        rot_xyz: Tuple[float, float, float] = (0.0, 0.0, 0.0),
        rigid_bone: Optional[str] = None,
    ) -> None:
        all_v: List[np.ndarray] = []
        all_t: List[List[int]] = []
        rx, ry, rz = rot_xyz
        cx, srx = math.cos(rx), math.sin(rx)
        cy, sry = math.cos(ry), math.sin(ry)
        cz, srz = math.cos(rz), math.sin(rz)

        def rot_pt(p: np.ndarray) -> np.ndarray:
            x, y, z = p
            y, z = y * cx - z * srx, y * srx + z * cx
            x, z = x * cy + z * sry, -x * sry + z * cy
            x, y = x * cz - y * srz, x * srz + y * cz
            return np.array([x, y, z], dtype=np.float64)

        for r, yl, pw in profile:
            for s in range(segs):
                th = (2.0 * math.pi * s) / segs
                dr = math.cos(th * pleat_count) * pleat_amp * pw
                rr = max(0.001, r + dr)
                pt = rot_pt(np.array([math.cos(th) * rr * sx, yl, math.sin(th) * rr * sz])) + origin
                all_v.append(pt)
        for pi in range(len(profile) - 1):
            r0, r1 = pi * segs, (pi + 1) * segs
            for s in range(segs):
                sn = (s + 1) % segs
                all_t.append([r0 + s, r0 + sn, r1 + sn])
                all_t.append([r0 + s, r1 + sn, r1 + s])

        va = np.array(all_v, dtype=np.float64)
        ta = np.array(all_t, dtype=np.int32)
        if rigid_bone:
            self.add_custom_rigid_bone_mesh(surface, va, ta, rigid_bone)
        else:
            j, w = self.transfer_weights_nearest(va)
            self.add_chunk(surface, va, ta, j, w)

    def add_ellipsoid(
        self,
        surface: str,
        center: np.ndarray,
        radii: Tuple[float, float, float],
        rings: int = 8,
        segs: int = 16,
        rot_xyz: Tuple[float, float, float] = (0.0, 0.0, 0.0),
        rigid_bone: Optional[str] = None,
    ) -> None:
        all_v: List[np.ndarray] = []
        all_t: List[List[int]] = []
        rx, ry, rz = radii
        arx, ary, arz = rot_xyz
        cx, sx_r = math.cos(arx), math.sin(arx)
        cy, sy_r = math.cos(ary), math.sin(ary)
        cz, sz_r = math.cos(arz), math.sin(arz)

        def rot_pt(p: np.ndarray) -> np.ndarray:
            x, y, z = p
            y, z = y * cx - z * sx_r, y * sx_r + z * cx
            x, z = x * cy + z * sy_r, -x * sy_r + z * cy
            x, y = x * cz - y * sz_r, x * sz_r + y * cz
            return np.array([x, y, z], dtype=np.float64)

        for i in range(rings + 1):
            phi = math.pi * float(i) / float(rings)
            sp, cp = math.sin(phi), math.cos(phi)
            for s in range(segs):
                th = 2.0 * math.pi * float(s) / float(segs)
                local = np.array([math.cos(th) * sp * rx, cp * ry, math.sin(th) * sp * rz], dtype=np.float64)
                all_v.append(center + rot_pt(local))
        for i in range(rings):
            r0, r1 = i * segs, (i + 1) * segs
            for s in range(segs):
                sn = (s + 1) % segs
                all_t.append([r0 + s, r0 + sn, r1 + sn])
                all_t.append([r0 + s, r1 + sn, r1 + s])

        va = np.array(all_v, dtype=np.float64)
        ta = np.array(all_t, dtype=np.int32)
        if rigid_bone:
            self.add_custom_rigid_bone_mesh(surface, va, ta, rigid_bone)
        else:
            j, w = self.transfer_weights_nearest(va)
            self.add_chunk(surface, va, ta, j, w)

    def add_quad_grid(
        self,
        surface: str,
        grid_pts: np.ndarray,
        thickness: float = 0.0,
        rigid_bone: Optional[str] = None,
    ) -> None:
        """Emit clean skinned rectangular/curved cloth grid (H x W x 3), optionally thickened slightly."""
        rows, cols, _ = grid_pts.shape
        pts_flat = grid_pts.reshape(-1, 3)
        tris: List[List[int]] = []
        for r in range(rows - 1):
            for c in range(cols - 1):
                i00 = r * cols + c
                i01 = r * cols + (c + 1)
                i10 = (r + 1) * cols + c
                i11 = (r + 1) * cols + (c + 1)
                tris.append([i00, i10, i11])
                tris.append([i00, i11, i01])
        ta = np.array(tris, dtype=np.int32)
        if abs(thickness) > 1e-6:
            # Double-sided thin cloth shell (back wall + edge stitches not needed visually except back face)
            norms = compute_smooth_normals(pts_flat, ta)
            back_pts = pts_flat - norms * thickness
            n_front = len(pts_flat)
            all_v = np.concatenate([pts_flat, back_pts], axis=0)
            back_t = ta[:, [0, 2, 1]] + n_front
            # Stitch perimeter border so thickness shows cleanly along bib top & edges
            rim_t: List[List[int]] = []
            for c in range(cols - 1):
                for rr, rev in ((0, True), (rows - 1, False)):
                    a = rr * cols + c
                    b = rr * cols + c + 1
                    ba, bb = a + n_front, b + n_front
                    if rev:
                        rim_t.extend([[a, b, bb], [a, bb, ba]])
                    else:
                        rim_t.extend([[a, bb, b], [a, ba, bb]])
            for r in range(rows - 1):
                for cc, rev in ((0, False), (cols - 1, True)):
                    a = r * cols + cc
                    b = (r + 1) * cols + cc
                    ba, bb = a + n_front, b + n_front
                    if rev:
                        rim_t.extend([[a, b, bb], [a, bb, ba]])
                    else:
                        rim_t.extend([[a, bb, b], [a, ba, bb]])
            all_t = np.concatenate([ta, back_t, np.array(rim_t, dtype=np.int32)], axis=0)
        else:
            all_v = pts_flat
            all_t = ta

        if rigid_bone:
            self.add_custom_rigid_bone_mesh(surface, all_v, all_t, rigid_bone)
        else:
            j, w = self.transfer_weights_nearest(all_v)
            self.add_chunk(surface, all_v, all_t, j, w)


# ------------------------------------------------------------------------------ ARCHETYPE ASSEMBLY
def assemble_archetype(mh: MHBaseData, cfg: Dict) -> CharacterMeshBuilder:
    verts, joints_pos = mh.build_morphed_state(cfg["morph"])
    cb = CharacterMeshBuilder(mh=mh, verts=verts, joints_pos=joints_pos)

    neck_style: str = cfg.get("neck_style", "collar")
    short_sleeves: bool = bool(cfg.get("short_sleeves", False))
    rolled_sleeves: bool = bool(cfg.get("rolled_sleeves", False))
    skirt: bool = bool(cfg.get("skirt", False))
    apron: bool = bool(cfg.get("apron", False))
    vest: bool = bool(cfg.get("vest", False))
    suit_jacket: bool = bool(cfg.get("suit_jacket", False))
    tie: bool = bool(cfg.get("tie", False))
    hat: str = cfg.get("hat", "")
    hair_style: str = cfg.get("hair_style", "short")
    mustache: bool = bool(cfg.get("mustache", False))
    glasses: bool = bool(cfg.get("glasses", False))
    shoe_style: str = cfg.get("shoe_style", "leather")

    # Proportionally measured anatomical joints (valid for male_old, male_young & female_young)
    pelvis_y = float(joints_pos["pelvis"][1])
    spine3_y = float(joints_pos["spine_03"][1])
    neck_y = float(joints_pos["neck_01"][1])
    head_c = joints_pos["head"].copy()
    head_y = float(head_c[1])
    knee_y = float(joints_pos["calf_l"][1])
    ankle_y = float(joints_pos["foot_l"][1])
    torso_h = max(neck_y - pelvis_y, 0.25)

    shoulder_x = abs(float(joints_pos["upperarm_l"][0]))
    elbow_x = abs(float(joints_pos["lowerarm_l"][0]))
    hand_x = abs(float(joints_pos["hand_l"][0]))

    l_eye_c = verts[np.unique([i for q in mh.faces_by_g["helper-l-eye"] for i in q])].mean(axis=0)
    r_eye_c = verts[np.unique([i for q in mh.faces_by_g["helper-r-eye"] for i in q])].mean(axis=0)

    body_vi = np.unique([i for q in mh.faces_by_g["body"] for i in q])
    body_pts = verts[body_vi]
    head_only = body_pts[body_pts[:, 1] > neck_y + 0.025]
    # Measure true cranial width ABOVE eye height so ears do not inflate hair crown / hat radii!
    skull_only = head_only[head_only[:, 1] > float(l_eye_c[1]) + 0.024]
    rx_skull = float(skull_only[:, 0].max() - skull_only[:, 0].min()) * 0.5 if len(skull_only) > 10 else 0.070
    rx_head = rx_skull
    head_top_y = float(head_only[:, 1].max())
    head_z_min = float(head_only[:, 2].min())
    head_z_mid = float((head_only[:, 2].min() + head_only[:, 2].max()) * 0.5)

    # Exact MakeHuman topological landmarks (constant vertex indices across all MakeHuman morphs!)
    # 302 = nose tip, 455 = upper lip peak, 520 = mouth slit center, 495 = lower lip peak
    nose_tip = verts[302].copy()
    upper_lip_y = float(verts[455, 1])
    lower_lip_y = float(verts[495, 1])
    mouth_y = float(verts[520, 1])
    mouth_slit_z = float(verts[520, 2])
    mouth_front_z = max(float(verts[455, 2]), float(verts[495, 2]))

    # Torso surface helper queries so all collars/lapels/straps/aprons hug actual chest/shoulders
    tights_q = mh.faces_by_g["helper-tights"]
    tights_vi = np.unique([i for q in tights_q for i in q])
    tights_pts = verts[tights_vi]
    front_torso_pts = tights_pts[(tights_pts[:, 1] >= pelvis_y - 0.14) & (tights_pts[:, 1] <= neck_y + 0.04) & (tights_pts[:, 2] > -0.02)]
    torso_core_pts = tights_pts[(tights_pts[:, 1] >= pelvis_y - 0.10) & (tights_pts[:, 1] <= neck_y + 0.03) & (np.abs(tights_pts[:, 0]) < shoulder_x + 0.02)]

    def query_front_z(qx: float, qy: float, z_bias: float = 0.008) -> float:
        sub = front_torso_pts[(np.abs(front_torso_pts[:, 0] - qx) < 0.028) & (np.abs(front_torso_pts[:, 1] - qy) < 0.028)]
        if len(sub) == 0:
            sub = front_torso_pts[(np.abs(front_torso_pts[:, 0] - qx) < 0.045) & (np.abs(front_torso_pts[:, 1] - qy) < 0.045)]
        if len(sub) == 0:
            sub = front_torso_pts[np.abs(front_torso_pts[:, 1] - qy) < 0.06]
        if len(sub) == 0:
            return 0.12 + z_bias
        return float(sub[:, 2].max()) + z_bias

    def query_back_z(qx: float, qy: float, z_bias: float = 0.008) -> float:
        sub = torso_core_pts[(np.abs(torso_core_pts[:, 0] - qx) < 0.030) & (np.abs(torso_core_pts[:, 1] - qy) < 0.030) & (torso_core_pts[:, 2] < 0.02)]
        if len(sub) == 0:
            return -0.095 - z_bias
        return float(sub[:, 2].min()) - z_bias

    def query_shoulder_pt(qx: float, qz: float, y_bias: float = 0.005) -> List[float]:
        # Tight column query prevents neighboring neck trapezius vertices from lifting the outer strap
        sub = torso_core_pts[
            (np.abs(torso_core_pts[:, 0] - qx) < 0.015)
            & (np.abs(torso_core_pts[:, 2] - qz) < 0.020)
            & (torso_core_pts[:, 1] > spine3_y + 0.05)
        ]
        if len(sub) == 0:
            sub = torso_core_pts[
                (np.abs(torso_core_pts[:, 0] - qx) < 0.025)
                & (np.abs(torso_core_pts[:, 2] - qz) < 0.030)
                & (torso_core_pts[:, 1] > spine3_y + 0.05)
            ]
        if len(sub) == 0:
            return [qx, neck_y - 0.020 + y_bias, qz]
        return [qx, float(sub[:, 1].max()) + y_bias, qz]

    def project_outward_torso(target_pt: np.ndarray, offset: float = 0.007) -> np.ndarray:
        d2 = np.sum((torso_core_pts - target_pt[None, :]) ** 2, axis=1)
        idx = np.argsort(d2)[:6]
        surf_p = torso_core_pts[idx].mean(axis=0)
        center_spine = np.array([0.0, surf_p[1], 0.0], dtype=np.float64)
        out_dir = surf_p - center_spine
        if target_pt[1] > neck_y - 0.045 and abs(target_pt[0]) > 0.055 and abs(target_pt[2]) < 0.05:
            out_dir = np.array([surf_p[0] * 0.25, 1.0, surf_p[2] * 0.35], dtype=np.float64)
        nlen = np.linalg.norm(out_dir)
        out_dir = out_dir / max(nlen, 1e-6)
        return surf_p + out_dir * float(offset)

    # 1. ANATOMICAL EYES (sclera, limbal_dark, iris) FITTED IN MAKEHUMAN EYE ORBIT
    eye_r = 0.0101
    rings_e, segs_e = 10, 18
    for ec in (l_eye_c, r_eye_c):
        e_center = np.array([ec[0], ec[1], ec[2] + 0.0002], dtype=np.float64)
        ev_list: List[np.ndarray] = []
        for ir in range(rings_e + 1):
            phi = math.pi * float(ir) / float(rings_e)
            cp, sp = math.cos(phi), math.sin(phi)
            for isg in range(segs_e):
                th = 2.0 * math.pi * float(isg) / float(segs_e)
                ev_list.append(e_center + np.array([
                    math.cos(th) * sp * eye_r,
                    math.sin(th) * sp * eye_r,
                    cp * eye_r,
                ], dtype=np.float64))
        ev = np.array(ev_list, dtype=np.float64)
        tris_sclera, tris_limbal, tris_iris = [], [], []
        for ir in range(rings_e):
            r0, r1 = ir * segs_e, (ir + 1) * segs_e
            for isg in range(segs_e):
                isn = (isg + 1) % segs_e
                t1 = [r0 + isg, r1 + isg, r1 + isn]
                t2 = [r0 + isg, r1 + isn, r0 + isn]
                for t in (t1, t2):
                    cz = (ev[t[0], 2] + ev[t[1], 2] + ev[t[2], 2]) / 3.0 - e_center[2]
                    fwd = cz / eye_r
                    if fwd > 0.89:
                        tris_limbal.append(t)
                    elif fwd > 0.72:
                        tris_iris.append(t)
                    elif fwd > 0.65:
                        tris_limbal.append(t)
                    else:
                        tris_sclera.append(t)
        for sname, tl in (("eye_white", tris_sclera), ("limbal_dark", tris_limbal), ("iris", tris_iris)):
            if tl:
                cb.add_custom_rigid_bone_mesh(sname, ev, np.array(tl, dtype=np.int32), "head")

    # 2. CONTINUOUS MAKEHUMAN SKIN & LIPS + WATERTIGHT CLOSED MOUTH + BONE-AXIS ARM DECIMATION
    body_quads = mh.faces_by_g["body"]
    qv = np.array(body_quads, dtype=np.int32)
    qc = verts[qv].mean(axis=1)

    # Exact skeletal cut planes perpendicular to A-pose arm segments (fixes crooked cuffs & hanging wrist flaps)
    arm_cut_planes: Dict[float, Tuple[np.ndarray, np.ndarray, str]] = {}
    for side_s, suf in ((1.0, "l"), (-1.0, "r")):
        j_sh = joints_pos[f"upperarm_{suf}"]
        j_el = joints_pos[f"lowerarm_{suf}"]
        j_ha = joints_pos[f"hand_{suf}"]
        if short_sleeves:
            d = j_el - j_sh
            d /= max(float(np.linalg.norm(d)), 1e-6)
            cut_o = j_sh + d * (0.46 * float(np.linalg.norm(j_el - j_sh)))
            bone_a = f"upperarm_{suf}"
        elif rolled_sleeves:
            d = j_ha - j_el
            d /= max(float(np.linalg.norm(d)), 1e-6)
            cut_o = j_el + d * (0.26 * float(np.linalg.norm(j_ha - j_el)))
            bone_a = f"lowerarm_{suf}"
        else:
            d = j_ha - j_el
            d /= max(float(np.linalg.norm(d)), 1e-6)
            cut_o = j_el + d * (0.82 * float(np.linalg.norm(j_ha - j_el)))
            bone_a = f"lowerarm_{suf}"
        arm_cut_planes[side_s] = (cut_o, d, bone_a)

    def arm_signed_dist(pts_arr: np.ndarray, side_s: float) -> Tuple[np.ndarray, np.ndarray]:
        cut_o, cut_d, _ = arm_cut_planes[side_s]
        s_dist = np.sum((pts_arr - cut_o[None, :]) * cut_d[None, :], axis=1)
        is_side_arm = (pts_arr[:, 0] * side_s > shoulder_x + 0.008) & (pts_arr[:, 1] < neck_y + 0.02)
        return s_dist, is_side_arm

    collar_top_y = neck_y - 0.012 if neck_style == "open_v" else neck_y + 0.010
    v_bot_y = neck_y - 0.064

    # Face quad normals (keep ALL exterior +Z cheek/chin/lip quads; strip ONLY inner oral pouch behind lip rim!)
    fn_body = np.cross(verts[qv[:, 1]] - verts[qv[:, 0]], verts[qv[:, 2]] - verts[qv[:, 0]])
    fn_blen = np.linalg.norm(fn_body, axis=1, keepdims=True)
    fn_body = np.where(fn_blen > 1e-10, fn_body / np.maximum(fn_blen, 1e-10), np.array([0.0, 0.0, 1.0]))

    lower_lip_front_z = float(verts[495, 2])
    mouth_inner_cut_z = min(float(verts[455, 2]), lower_lip_front_z) - 0.0022
    is_deep_eye_bag = (qc[:, 1] > neck_y + 0.03) & (qc[:, 2] < float(l_eye_c[2]) + 0.002) & (
        ((np.linalg.norm(qc[:, :2] - l_eye_c[:2], axis=1) < 0.0120))
        | ((np.linalg.norm(qc[:, :2] - r_eye_c[:2], axis=1) < 0.0120))
    )
    is_deep_mouth_pouch = (
        (np.abs(qc[:, 0]) < 0.032)
        & (qc[:, 1] >= lower_lip_y - 0.015)
        & (qc[:, 1] <= upper_lip_y + 0.015)
        & (qc[:, 2] > float(l_eye_c[2]) - 0.025)
        & (
            (fn_body[:, 2] < -0.05)
            | ((qc[:, 2] < mouth_inner_cut_z) & (fn_body[:, 2] < 0.42))
        )
    )
    hat_hide_scalp = (hat != "") & (qc[:, 1] > float(l_eye_c[1]) + 0.044)

    in_v_chest = (
        (neck_style == "open_v")
        & (qc[:, 2] > 0.00)
        & (qc[:, 1] >= v_bot_y - 0.026)
        & (qc[:, 1] <= collar_top_y + 0.015)
        & (np.abs(qc[:, 0]) < 0.048)
    )
    in_head_neck = (
        (qc[:, 1] >= collar_top_y - 0.025)
        | ((qc[:, 1] >= neck_y - 0.075) & (np.abs(qc[:, 0]) < 0.095))
    ) & (np.abs(qc[:, 0]) < shoulder_x + 0.01)

    head_mask = (~is_deep_eye_bag) & (~is_deep_mouth_pouch) & (~hat_hide_scalp) & (in_head_neck | in_v_chest)
    head_quads = [body_quads[k] for k in np.where(head_mask)[0]]

    # Gently settle ONLY hidden interior mouth slit vertices strictly behind the exterior lower-lip ridge
    head_verts_edit = verts.copy()
    eye_z_ref = float(l_eye_c[2])
    inner_slit_mask = (
        (np.abs(head_verts_edit[:, 0]) < 0.024)
        & (head_verts_edit[:, 1] >= mouth_y - 0.0022)
        & (head_verts_edit[:, 1] <= upper_lip_y - 0.0010)
        & (head_verts_edit[:, 2] > mouth_slit_z - 0.012)
        & (head_verts_edit[:, 2] < lower_lip_front_z - 0.0010)
    )
    x_fade = np.clip(1.0 - (head_verts_edit[inner_slit_mask, 0] / 0.024) ** 2, 0.0, 1.0)
    head_verts_edit[inner_slit_mask, 1] = (
        head_verts_edit[inner_slit_mask, 1] * (1.0 - 0.55 * x_fade) + mouth_y * (0.55 * x_fade)
    )

    head_imp = np.full(len(verts), 1.8, dtype=np.float64)
    neck_band = (verts[:, 1] >= neck_y - 0.08) & (verts[:, 1] <= float(l_eye_c[1]) + 0.05)
    head_imp[neck_band] = 4.5
    front_face = (verts[:, 1] > neck_y + 0.01) & (verts[:, 2] > eye_z_ref - 0.025)
    head_imp[front_face] = 14.0
    features_band = (
        (verts[:, 1] > lower_lip_y - 0.012)
        & (verts[:, 1] < float(l_eye_c[1]) + 0.028)
        & (verts[:, 2] > eye_z_ref - 0.002)
        & (np.abs(verts[:, 0]) < 0.058)
    )
    head_imp[features_band] = 36.0
    eye_lid_imp = (
        (verts[:, 2] > eye_z_ref - 0.005)
        & (
            (np.linalg.norm(verts[:, :2] - l_eye_c[:2], axis=1) < 0.025)
            | (np.linalg.norm(verts[:, :2] - r_eye_c[:2], axis=1) < 0.025)
        )
    )
    head_imp[eye_lid_imp] = 125.0
    mouth_high_imp = (
        (verts[:, 1] >= lower_lip_y - 0.007)
        & (verts[:, 1] <= upper_lip_y + 0.007)
        & (verts[:, 2] > eye_z_ref + 0.006)
        & (np.abs(verts[:, 0]) < 0.034)
    )
    head_imp[mouth_high_imp] = 220.0

    # Decimate sealed watertight head+neck mesh preserving eyelid & lip fidelity
    hv, ht, hj, hw = cb.prepare_quad_group(
        head_quads, target_tris=3050, verts_override=head_verts_edit, importance=head_imp
    )
    centroids_h = (hv[ht[:, 0]] + hv[ht[:, 1]] + hv[ht[:, 2]]) / 3.0
    fn_h = np.cross(hv[ht[:, 1]] - hv[ht[:, 0]], hv[ht[:, 2]] - hv[ht[:, 0]])
    fl_h = np.linalg.norm(fn_h, axis=1, keepdims=True)
    fn_h = np.where(fl_h > 1e-10, fn_h / np.maximum(fl_h, 1e-10), np.array([0.0, 0.0, 1.0]))

    lip_mid_y = 0.5 * (upper_lip_y + lower_lip_y)
    lip_half_h = max(0.45 * (upper_lip_y - lower_lip_y), 0.0038)
    lip_z_min = mouth_slit_z + 0.0006
    dy_l = (centroids_h[:, 1] - lip_mid_y) / lip_half_h
    dx_l = centroids_h[:, 0] / 0.0165
    is_outer_lip = (dy_l * dy_l + dx_l * dx_l <= 1.0) & (centroids_h[:, 2] > lip_z_min) & (fn_h[:, 2] > 0.35)
    is_skin_h = ~is_outer_lip
    for sname, mask in (("lip", is_outer_lip), ("skin", is_skin_h)):
        idx = np.where(mask)[0]
        if len(idx) == 0:
            continue
        sub_t = ht[idx]
        used_sub = np.unique(sub_t.reshape(-1))
        rmp = np.full(len(hv), -1, dtype=np.int32)
        rmp[used_sub] = np.arange(len(used_sub), dtype=np.int32)
        cb.add_chunk(sname, hv[used_sub], rmp[sub_t], hj[used_sub], hw[used_sub])

    # Recessed narrow +Z lip-seal backing safely behind closed mouth slit -> ZERO holes & ZERO protruding teeth!
    seal_rows, seal_cols = 5, 9
    seal_grid = np.zeros((seal_rows, seal_cols, 3), dtype=np.float64)
    seal_x_half = 0.0160
    seal_y0 = mouth_y - 0.0016
    seal_y1 = mouth_y + 0.0016
    for ri in range(seal_rows):
        vy = seal_y0 + (float(ri) / float(seal_rows - 1)) * (seal_y1 - seal_y0)
        for ci in range(seal_cols):
            ux = 1.0 - 2.0 * float(ci) / float(seal_cols - 1)
            vx = ux * seal_x_half
            curve = max(0.0, 1.0 - (ux * ux))
            vz = mouth_slit_z - 0.0022 + 0.0012 * curve
            seal_grid[ri, ci] = [vx, vy, vz]
    cb.add_quad_grid("skin_crevice", seal_grid, thickness=0.0, rigid_bone="head")

    # Per-arm / per-hand decimation cut perpendicular to arm bone (+3.5cm overlap proximal inside sleeve)
    arm_budget = 660 if (short_sleeves or rolled_sleeves) else 540
    arm_imp = np.full(len(verts), 2.5, dtype=np.float64)
    arm_imp[np.abs(verts[:, 0]) >= hand_x - 0.018] = 10.0
    for side_s in (1.0, -1.0):
        sd_arm, on_arm_side = arm_signed_dist(qc, side_s)
        arm_mask = (~is_deep_eye_bag) & on_arm_side & (sd_arm >= -0.036)
        arm_quads = [body_quads[k] for k in np.where(arm_mask)[0]]
        cb.add_quad_group_with_weights("skin", arm_quads, target_tris=arm_budget, importance=arm_imp)

    if skirt:
        calf_min_y = ankle_y + 0.005
        calf_max_y = knee_y + 0.04
        calf_mask = (qc[:, 1] >= calf_min_y) & (qc[:, 1] <= calf_max_y) & (np.abs(qc[:, 0]) < shoulder_x)
        cb.add_quad_group_with_weights("skin", [body_quads[k] for k in np.where(calf_mask)[0]], target_tris=340)

    # 3. SHIRT / HOODIE / COLLARS / VEST / SUIT JACKET
    tqv = np.array(tights_q, dtype=np.int32)
    tqc = verts[tqv].mean(axis=1)
    pelvis_cut_y = pelvis_y + 0.012

    tqc_over_cut = np.zeros(len(tqc), dtype=bool)
    for side_s in (1.0, -1.0):
        sd_q, on_arm_q = arm_signed_dist(tqc, side_s)
        tqc_over_cut |= on_arm_q & (sd_q > 0.002)

    shirt_v_cut = (neck_style == "open_v") & (tqc[:, 2] > 0.025) & (tqc[:, 1] >= v_bot_y + 0.008) & (
        np.abs(tqc[:, 0]) < 0.014 * (tqc[:, 1] - v_bot_y) / max(collar_top_y - v_bot_y, 0.01) + 0.001
    )
    shirt_top_max_y = (neck_y + 0.009) if suit_jacket else (neck_y + 0.006 if neck_style == "collar" else neck_y + 0.002)

    if suit_jacket:
        # Tailored V-wedge shirt front filling the collar/lapel opening without poking out blazer outer shoulders
        v_open_bot_y_s = pelvis_y + 0.42 * torso_h
        is_shirt_front = (
            (tqc[:, 1] >= v_open_bot_y_s)
            & (tqc[:, 1] <= shirt_top_max_y)
            & (tqc[:, 2] > 0.025)
            & (np.abs(tqc[:, 0]) <= 0.056 * (tqc[:, 1] - (v_open_bot_y_s - 0.01)) / max(neck_y - v_open_bot_y_s + 0.01, 0.05) + 0.012)
        )
        is_shirt_q = is_shirt_front
        shirt_tris = 260
    else:
        is_shirt_q = (
            (tqc[:, 1] >= pelvis_cut_y - 0.025)
            & (tqc[:, 1] <= shirt_top_max_y)
            & (~tqc_over_cut)
            & (~shirt_v_cut)
        )
        shirt_tris = 920

    # Project sleeve hem vertices cleanly onto the perpendicular bone cut plane -> zero crooked flaps or sawtooth tips!
    shirt_v = verts.copy()
    shirt_imp = np.ones(len(verts), dtype=np.float64)
    if not suit_jacket:
        for side_s in (1.0, -1.0):
            cut_o, cut_d, _ = arm_cut_planes[side_s]
            sd_v, on_arm_v = arm_signed_dist(shirt_v, side_s)
            over_mask = on_arm_v & (sd_v > 0.0)
            if np.any(over_mask):
                shirt_v[over_mask] -= sd_v[over_mask, None] * cut_d[None, :]
            near_cut = on_arm_v & (np.abs(sd_v) < 0.030)
            shirt_imp[near_cut] = 32.0
    shirt_imp[(verts[:, 1] >= v_bot_y - 0.01) & (verts[:, 1] <= neck_y + 0.02) & (np.abs(verts[:, 0]) < 0.09)] = 16.0
    shirt_ease = 0.009 if neck_style == "hoodie" else (0.003 if suit_jacket else 0.0055)
    cb.add_quad_group_with_weights(
        "shirt",
        [tights_q[k] for k in np.where(is_shirt_q)[0]],
        target_tris=shirt_tris,
        offset_normal=shirt_ease,
        verts_override=shirt_v,
        importance=shirt_imp,
    )

    if suit_jacket:
        # Crisp white dress-shirt wrist cuffs aligned strictly with forearm axis
        for side_s, suf in ((1.0, "l"), (-1.0, "r")):
            j_el = joints_pos[f"lowerarm_{suf}"]
            j_ha = joints_pos[f"hand_{suf}"]
            ax = j_ha - j_el
            flen = float(np.linalg.norm(ax))
            ax /= max(flen, 1e-6)
            c0 = j_el + ax * (0.85 * flen)
            sd_pts = np.sum((tights_pts - c0[None, :]) * ax[None, :], axis=1)
            arm_c = tights_pts[(tights_pts[:, 0] * side_s > shoulder_x + 0.01) & (np.abs(sd_pts) < 0.024)]
            if len(arm_c) > 4:
                rel = arm_c - c0[None, :]
                axial = np.sum(rel * ax[None, :], axis=1)[:, None] * ax[None, :]
                perp = rel - axial
                cuff_r = float(np.max(np.linalg.norm(perp, axis=1))) * 1.12 + 0.004
                cuff_r = max(0.034, min(0.046, cuff_r))
                cb.add_tube("shirt", [
                    (c0 - ax * 0.024).tolist(),
                    (c0 + ax * 0.008).tolist(),
                ], [cuff_r, cuff_r * 0.96], rings=14, cap=False, rigid_bone=f"lowerarm_{suf}")

    baked_shirt_pts = (
        np.concatenate([c[0] for c in cb.surfaces["shirt"]], axis=0)
        if "shirt" in cb.surfaces
        else torso_core_pts
    )

    # Clean surface-hugging collars (no floating wire-edged chest rectangles!)
    def sample_neck_ring_pt(th_rad: float, y_abs: float, radial_bias: float, neck_cz: float) -> np.ndarray:
        band = torso_core_pts[(np.abs(torso_core_pts[:, 1] - y_abs) < 0.014) & (np.abs(torso_core_pts[:, 0]) < 0.11)]
        if len(band) < 6:
            band = body_pts[(np.abs(body_pts[:, 1] - y_abs) < 0.014) & (np.abs(body_pts[:, 0]) < 0.11)]
        dir_x, dir_z = math.sin(th_rad), math.cos(th_rad)
        r_surf = 0.064
        if len(band) > 0:
            dx_b = band[:, 0]
            dz_b = band[:, 2] - neck_cz
            ang_b = np.arctan2(dx_b, dz_b)
            d_ang = np.abs(np.arctan2(np.sin(ang_b - th_rad), np.cos(ang_b - th_rad)))
            sub_b = band[d_ang < 0.42]
            if len(sub_b) == 0:
                sub_b = band[d_ang < 0.78]
            if len(sub_b) > 0:
                proj = sub_b[:, 0] * dir_x + (sub_b[:, 2] - neck_cz) * dir_z
                r_surf = max(0.052, float(np.percentile(proj, 85)))
        r_tot = r_surf + radial_bias
        return np.array([dir_x * r_tot, y_abs, neck_cz + dir_z * r_tot], dtype=np.float64)

    def push_over_surface(pt: np.ndarray, ref_pts: np.ndarray, pad_f: float = 0.0055, pad_b: float = 0.0055, pad_top: float = 0.0055, exclude_collar: bool = False) -> np.ndarray:
        p = np.array(pt, dtype=np.float64)
        src = ref_pts[ref_pts[:, 1] <= neck_y + 0.002] if exclude_collar else ref_pts
        sub_fb = src[(np.abs(src[:, 0] - p[0]) < 0.024) & (np.abs(src[:, 1] - p[1]) < 0.024)]
        if len(sub_fb) > 0:
            if p[2] >= 0.015:
                sub_f = sub_fb[sub_fb[:, 2] >= 0.0]
                if len(sub_f) > 0:
                    p[2] = max(p[2], float(sub_f[:, 2].max()) + pad_f)
            elif p[2] <= -0.015:
                sub_b = sub_fb[sub_fb[:, 2] <= 0.0]
                if len(sub_b) > 0:
                    p[2] = min(p[2], float(sub_b[:, 2].min()) - pad_b)
        if p[1] > neck_y - 0.055 and abs(p[2]) < 0.060:
            sub_t = src[(np.abs(src[:, 0] - p[0]) < 0.014) & (np.abs(src[:, 2] - p[2]) < 0.018)]
            if len(sub_t) > 0:
                p[1] = max(p[1], float(sub_t[:, 1].max()) + pad_top)
        return p

    if neck_style == "open_v":
        # Anatomically fitted folded polo collar seated flush over shirt collarband + continuous Y/V placket
        neck_cz = 0.5 * (query_front_z(0.0, neck_y + 0.012, 0.0) + query_back_z(0.0, neck_y + 0.012, 0.0))
        c_segs = 23
        th0, th1 = math.radians(10.0), math.radians(350.0)
        polo_grid = np.zeros((3, c_segs, 3), dtype=np.float64)
        for ci in range(c_segs):
            th = th0 + (float(ci) / float(c_segs - 1)) * (th1 - th0)
            frontness = max(0.0, math.cos(th))
            polo_grid[0, ci] = sample_neck_ring_pt(th, neck_y + 0.008, shirt_ease + 0.0005, neck_cz)
            polo_grid[1, ci] = sample_neck_ring_pt(th, neck_y + 0.021, shirt_ease + 0.0055, neck_cz)
            y_outer = (neck_y - 0.003) - 0.015 * frontness
            p_out = sample_neck_ring_pt(th, y_outer, shirt_ease + 0.0080 + 0.0015 * frontness, neck_cz)
            polo_grid[2, ci] = push_over_surface(p_out, baked_shirt_pts, pad_f=0.0036, pad_b=0.0036, pad_top=0.0040)
        cb.add_quad_grid("shirt", polo_grid, thickness=0.0028)

        # Crisp front V-placket bands joining smoothly below polo front tips down to one stitched button
        for side_s in (-1.0, 1.0):
            lap_v = np.zeros((6, 3, 3), dtype=np.float64)
            tip_pt = polo_grid[2, 0 if side_s > 0.0 else (c_segs - 1)]
            top_x = float(abs(tip_pt[0]))
            top_y = float(tip_pt[1]) + 0.006
            for ri in range(6):
                u = float(ri) / 5.0
                yl = (v_bot_y - 0.004) + u * (top_y - (v_bot_y - 0.004))
                xl_in = side_s * (0.0004 + u * max(0.005, top_x - 0.004))
                xl_out = xl_in + side_s * (0.012 + u * 0.010)
                p_i = push_over_surface(np.array([xl_in, yl, query_front_z(xl_in, yl, shirt_ease + 0.0038)]), baked_shirt_pts, pad_f=0.0036)
                p_o = push_over_surface(np.array([xl_out, yl, query_front_z(xl_out, yl, shirt_ease + 0.0034)]), baked_shirt_pts, pad_f=0.0032)
                lap_v[ri, 0] = p_i
                lap_v[ri, 1] = 0.5 * (p_i + p_o) + np.array([0.0, 0.0, 0.0014])
                lap_v[ri, 2] = p_o
            if side_s > 0.0:
                lap_v = lap_v[:, ::-1, :]
            cb.add_quad_grid("shirt", lap_v, thickness=0.0026)
        btn_y = v_bot_y - 0.014
        btn_p = push_over_surface(np.array([0.0, btn_y, query_front_z(0.0, btn_y, shirt_ease + 0.0068)]), baked_shirt_pts, pad_f=0.0068)
        cb.add_ellipsoid("hat", btn_p, (0.0044, 0.0044, 0.0022), rings=5, segs=10)
    elif neck_style == "collar":
        neck_cz = 0.5 * (query_front_z(0.0, neck_y + 0.012, 0.0) + query_back_z(0.0, neck_y + 0.012, 0.0))
        c_segs = 21
        col_grid = np.zeros((3, c_segs, 3), dtype=np.float64)
        col_r_bias = 0.0025 if suit_jacket else shirt_ease + 0.0025
        for ci in range(c_segs):
            th = (2.0 * math.pi * float(ci)) / float(c_segs - 1)
            col_grid[0, ci] = sample_neck_ring_pt(th, neck_y - 0.006, col_r_bias + 0.0035, neck_cz)
            col_grid[1, ci] = sample_neck_ring_pt(th, neck_y + 0.012, col_r_bias + 0.0020, neck_cz)
            col_grid[2, ci] = sample_neck_ring_pt(th, neck_y + 0.026, col_r_bias, neck_cz)
        cb.add_quad_grid("shirt", col_grid, thickness=0.0025)
    elif neck_style == "crew":
        cb.add_lathe_pleated("shirt", np.array([0.0, neck_y - 0.020, 0.012]), [
            (0.070, 0.0, 0.0), (0.064, 0.020, 0.0)
        ], sx=1.03, sz=1.05, segs=20, pleat_amp=0.0)
    elif neck_style == "hoodie":
        cb.add_ellipsoid("shirt", np.array([0.0, neck_y - 0.022, -0.030]), (0.110, 0.046, 0.076), rings=6, segs=16)
        hz = query_front_z(0.024, neck_y - 0.03, 0.016)
        for side_s in (-1.0, 1.0):
            cb.add_tube("hat", [
                [side_s * 0.024, neck_y - 0.022, hz],
                [side_s * 0.026, neck_y - 0.090, hz + 0.016],
                [side_s * 0.028, neck_y - 0.160, hz + 0.018],
            ], [0.0038, 0.0034, 0.0032], rings=6)

    # Flush directional elliptical sleeve cuffs hugging exact arm cross-section (zero bicep wings)
    if not suit_jacket:
        for side_s in (1.0, -1.0):
            cut_o, ax, bone_a = arm_cut_planes[side_s]
            sd_pts = np.sum((tights_pts - cut_o[None, :]) * ax[None, :], axis=1)
            base_mask = (tights_pts[:, 0] * side_s > shoulder_x + 0.01) & (np.linalg.norm(tights_pts - cut_o[None, :], axis=1) < 0.082)
            arm_pts = tights_pts[base_mask & (np.abs(sd_pts) < 0.024)]
            if len(arm_pts) < 10:
                arm_pts = tights_pts[base_mask & (np.abs(sd_pts) < 0.036)]
            if len(arm_pts) > 4:
                rel = arm_pts - cut_o[None, :]
                axial = np.sum(rel * ax[None, :], axis=1)
                perp = rel - axial[:, None] * ax[None, :]
                ref_up = np.array([0.0, 0.0, 1.0], dtype=np.float64)
                if abs(float(np.dot(ax, ref_up))) > 0.9:
                    ref_up = np.array([0.0, 1.0, 0.0], dtype=np.float64)
                e1 = np.cross(ax, ref_up)
                e1 /= max(float(np.linalg.norm(e1)), 1e-6)
                e2 = np.cross(ax, e1)
                e2 /= max(float(np.linalg.norm(e2)), 1e-6)
                p1 = np.sum(perp * e1[None, :], axis=1)
                p2 = np.sum(perp * e2[None, :], axis=1)
                p_ang = np.arctan2(p2, p1)
                p_rad = np.hypot(p1, p2)
                med_r = float(np.median(p_rad))
                n_sec = 16
                raw_sec = np.empty(n_sec, dtype=np.float64)
                for si in range(n_sec):
                    th_s = (2.0 * math.pi * si) / n_sec
                    da = np.abs(np.arctan2(np.sin(p_ang - th_s), np.cos(p_ang - th_s)))
                    cand = p_rad[da < 0.65]
                    if len(cand) > 0:
                        raw_sec[si] = float(np.percentile(cand, 75))
                    else:
                        raw_sec[si] = med_r
                sm_sec = np.array([
                    0.25 * raw_sec[(si - 1) % n_sec] + 0.50 * raw_sec[si] + 0.25 * raw_sec[(si + 1) % n_sec]
                    for si in range(n_sec)
                ], dtype=np.float64)
                min_clamp = 0.036 if (short_sleeves or rolled_sleeves) else 0.030
                max_clamp = 0.060 if (short_sleeves or rolled_sleeves) else 0.044
                sm_sec = np.clip(sm_sec, min_clamp, max_clamp)

                cuff_rows = [
                    (-0.020, shirt_ease + 0.0012),
                    (-0.007, shirt_ease + 0.0028),
                    (0.004, shirt_ease + 0.0016),
                ]
                cuff_grid = np.zeros((len(cuff_rows), n_sec + 1, 3), dtype=np.float64)
                for ri, (s_ax, r_add) in enumerate(cuff_rows):
                    c_ctr = cut_o + ax * s_ax
                    for si in range(n_sec + 1):
                        si_w = si % n_sec
                        th_s = (2.0 * math.pi * si_w) / n_sec
                        dir_r = math.cos(th_s) * e1 + math.sin(th_s) * e2
                        rr = float(sm_sec[si_w]) + r_add
                        cuff_grid[ri, si] = c_ctr + dir_r * rr
                v0 = cuff_grid[0, 0]
                v1 = cuff_grid[0, 1]
                v2 = cuff_grid[1, 0]
                n_est = np.cross(v2 - v0, v1 - v0)
                if float(np.dot(n_est, v0 - cut_o)) < 0.0:
                    cuff_grid = cuff_grid[::-1, :, :]
                cb.add_quad_grid("shirt", cuff_grid, thickness=0.0022, rigid_bone=None)

    # Tie seated cleanly forward of white shirt along sternum profile
    if tie:
        tie_pts = [
            push_over_surface(np.array([0.0, neck_y + 0.004, query_front_z(0.0, neck_y, 0.012)]), baked_shirt_pts, pad_f=0.008),
            push_over_surface(np.array([0.0, neck_y - 0.080, query_front_z(0.0, neck_y - 0.080, 0.014)]), baked_shirt_pts, pad_f=0.008),
            push_over_surface(np.array([0.0, neck_y - 0.195, query_front_z(0.0, neck_y - 0.195, 0.014)]), baked_shirt_pts, pad_f=0.008),
            push_over_surface(np.array([0.0, neck_y - 0.340, query_front_z(0.0, neck_y - 0.340, 0.014)]), baked_shirt_pts, pad_f=0.008),
        ]
        cb.add_tube("tie", [p.tolist() for p in tie_pts], [0.013, 0.013, 0.018, 0.009], rings=6)

    # 4. TAILORED PANTS OR SKIRT
    if skirt:
        sk_q = mh.faces_by_g["helper-skirt"]
        skqv = np.array(sk_q, dtype=np.int32)
        skqc = verts[skqv].mean(axis=1)
        sk_verts = verts.copy()
        sk_used = np.unique(skqv.reshape(-1))
        skirt_top_y = pelvis_y + 0.08
        skirt_bot_y = knee_y + 0.02
        skirt_span = max(skirt_top_y - skirt_bot_y, 0.25)
        for vi in sk_used:
            p = sk_verts[vi]
            th = math.atan2(p[2], p[0])
            pleat = math.cos(th * 14.0) * 0.006 * max(0.0, (skirt_top_y - p[1]) / skirt_span)
            rn = math.hypot(p[0], p[2])
            if rn > 1e-4:
                sk_verts[vi, 0] += (p[0] / rn) * (0.006 + pleat)
                sk_verts[vi, 2] += (p[2] / rn) * (0.006 + pleat)
        sk_keep = [sk_q[k] for k in np.where((skqc[:, 1] >= skirt_bot_y) & (skqc[:, 1] <= skirt_top_y))[0]]
        cb.add_quad_group_with_weights("pants", sk_keep, target_tris=460, verts_override=sk_verts)
    else:
        p_mask = (tqc[:, 1] >= ankle_y - 0.005) & (tqc[:, 1] <= pelvis_cut_y + 0.03)
        cb.add_quad_group_with_weights("pants", [tights_q[k] for k in np.where(p_mask)[0]], target_tris=780, offset_normal=0.009)

    # 5. TAILORED VEST / SUIT BLAZER (perpendicular forearm cuff + flared hem + tailored suit collar & lapels)
    if vest or suit_jacket:
        v_open_bot_y = pelvis_y + 0.44 * torso_h
        v_open = (tqc[:, 2] > 0.02) & (tqc[:, 1] >= v_open_bot_y) & (
            np.abs(tqc[:, 0]) < 0.042 * (tqc[:, 1] - (v_open_bot_y - 0.03)) / max(neck_y - v_open_bot_y + 0.03, 0.05) + 0.008
        )
        j_bot_y = pelvis_y - (0.11 if suit_jacket else 0.03)
        jacket_v = verts.copy()
        jacket_imp = np.ones(len(verts), dtype=np.float64)
        jacket_over = np.zeros(len(tqc), dtype=bool)
        if suit_jacket:
            flare_idx = np.unique(tqv)
            for vi in flare_idx:
                p = jacket_v[vi]
                if p[1] < pelvis_y + 0.05 and abs(p[0]) < shoulder_x + 0.02:
                    t = min(1.0, max(0.0, (pelvis_y + 0.05 - p[1]) / 0.16))
                    rn = math.hypot(p[0], p[2])
                    if rn > 1e-4:
                        jacket_v[vi, 0] += (p[0] / rn) * (0.018 * t)
                        jacket_v[vi, 2] += (p[2] / rn) * (0.018 * t)
            for side_s, suf in ((1.0, "l"), (-1.0, "r")):
                j_el = joints_pos[f"lowerarm_{suf}"]
                j_ha = joints_pos[f"hand_{suf}"]
                jd = j_ha - j_el
                jlen = float(np.linalg.norm(jd))
                jd /= max(jlen, 1e-6)
                j_cut = j_el + jd * (0.78 * jlen)
                sd_jq = np.sum((tqc - j_cut[None, :]) * jd[None, :], axis=1)
                on_arm_jq = (tqc[:, 0] * side_s > shoulder_x + 0.01) & (tqc[:, 1] < neck_y + 0.02)
                jacket_over |= on_arm_jq & (sd_jq > 0.002)
                sd_jv = np.sum((jacket_v - j_cut[None, :]) * jd[None, :], axis=1)
                on_arm_jv = (jacket_v[:, 0] * side_s > shoulder_x + 0.01) & (jacket_v[:, 1] < neck_y + 0.02)
                over_jv = on_arm_jv & (sd_jv > 0.0)
                if np.any(over_jv):
                    jacket_v[over_jv] -= sd_jv[over_jv, None] * jd[None, :]
                jacket_imp[on_arm_jv & (np.abs(sd_jv) < 0.03)] = 28.0
        else:
            jacket_over = np.abs(tqc[:, 0]) > shoulder_x - 0.004

        vest_mask = (tqc[:, 1] >= j_bot_y) & (tqc[:, 1] <= neck_y + 0.004) & (~jacket_over) & (~v_open)
        cb.add_quad_group_with_weights(
            "vest",
            [tights_q[k] for k in np.where(vest_mask)[0]],
            target_tris=720 if suit_jacket else 400,
            offset_normal=0.018 if suit_jacket else 0.013,
            verts_override=jacket_v,
            importance=jacket_imp,
        )
        # Wide flat tailored blazer/vest lapel trims cleanly overlapping V-edge & shirt seam
        for side_s in (-1.0, 1.0):
            lap_grid = np.zeros((6, 3, 3), dtype=np.float64)
            for ri in range(6):
                u = float(ri) / 5.0
                yl = (v_open_bot_y - 0.015) + u * (neck_y - v_open_bot_y + 0.015)
                xl_in = side_s * (0.008 + u * 0.042)
                xl_out = xl_in + side_s * (0.024 + u * 0.022)
                p_in = np.array([xl_in, yl, query_front_z(xl_in, yl, 0.0205)], dtype=np.float64)
                p_out = np.array([xl_out, yl, query_front_z(xl_out, yl, 0.0195)], dtype=np.float64)
                lap_grid[ri, 0] = p_in
                lap_grid[ri, 1] = 0.5 * (p_in + p_out) + np.array([0.0, 0.0, 0.002])
                lap_grid[ri, 2] = p_out
            cb.add_quad_grid("vest", lap_grid, thickness=0.0045)

        if suit_jacket:
            neck_cz_s = 0.5 * (query_front_z(0.0, neck_y + 0.012, 0.0) + query_back_z(0.0, neck_y + 0.012, 0.0))
            sc_segs = 17
            sc_grid = np.zeros((2, sc_segs, 3), dtype=np.float64)
            for ci in range(sc_segs):
                th = math.radians(24.0 + (312.0 * float(ci) / float(sc_segs - 1)))
                sc_grid[0, ci] = sample_neck_ring_pt(th, neck_y - 0.006, 0.018, neck_cz_s)
                sc_grid[1, ci] = sample_neck_ring_pt(th, neck_y + 0.015, 0.009, neck_cz_s)
            cb.add_quad_grid("vest", sc_grid, thickness=0.0045)
            for by in (v_open_bot_y - 0.045, v_open_bot_y - 0.130):
                bz = query_front_z(0.0, by, 0.023)
                cb.add_ellipsoid("leather" if "leather" in cb.surfaces else "hat", np.array([0.0, by, bz]), (0.0065, 0.0065, 0.0035), rings=4, segs=8)

    # Gather ALL actual baked torso clothing vertices (shirt + vest) so aprons never poke through decimated triangles!
    cloth_chunks: List[np.ndarray] = []
    for _ck in ("shirt", "vest"):
        if _ck in cb.surfaces:
            for _cv, _ct, _cj, _cw in cb.surfaces[_ck]:
                cloth_chunks.append(_cv)
    cloth_verts = np.concatenate(cloth_chunks, axis=0) if cloth_chunks else torso_core_pts

    # 6. SHOES FROM FOOT SILHOUETTE
    for foot_bone, sign_x in (("foot_l", 1.0), ("foot_r", -1.0)):
        fp = tights_pts[(tights_pts[:, 1] <= ankle_y + 0.025) & (tights_pts[:, 0] * sign_x > 0.04)]
        if len(fp) > 5:
            fmin, fmax = fp.min(axis=0), fp.max(axis=0)
            fc = (fmin + fmax) * 0.5
            rx_s = max(0.046, (fmax[0] - fmin[0]) * 0.52)
            rz_s = max(0.112, (fmax[2] - fmin[2]) * 0.52)
            cb.add_ellipsoid("shoes", np.array([fc[0], 0.042, fc[2] + 0.006]), (rx_s, 0.040, rz_s), rings=6, segs=14, rigid_bone=foot_bone)
            sole_mat = "hat" if shoe_style == "sneaker_white" else "shoes"
            cb.add_ellipsoid(sole_mat, np.array([fc[0], 0.014, fc[2] + 0.006]), (rx_s * 1.05, 0.014, rz_s * 1.04), rings=4, segs=12, rigid_bone=foot_bone)

    # 7. TAILORED BIB APRON (cloth_verts surface clearance on bib/belt/straps + deeper waist overlap + pocket)
    if apron:
        waist_y = pelvis_y + 0.065
        apron_bot_y = knee_y + (0.38 if skirt else 0.28) * (pelvis_y - knee_y)
        bib_top_y = waist_y + 0.53 * (neck_y - waist_y)
        bib_half_top = 0.090
        bib_half_waist = 0.145

        sk_q = mh.faces_by_g["helper-skirt"]
        skqv = np.array(sk_q, dtype=np.int32)
        skqc = verts[skqv].mean(axis=1)
        sk_angles = np.arctan2(np.abs(skqc[:, 0]), skqc[:, 2])
        ap_skirt_mask = (skqc[:, 1] >= apron_bot_y) & (skqc[:, 1] <= waist_y + 0.036) & (sk_angles < 1.92)
        ap_sv = verts.copy()
        for vi in np.unique(skqv[ap_skirt_mask].reshape(-1)):
            p = ap_sv[vi]
            fold = math.sin(p[0] * 36.0 + p[1] * 6.0) * 0.0025
            ap_sv[vi, 2] += 0.005 + fold
        ap_offset = 0.019 if skirt else 0.016
        cb.add_quad_group_with_weights(
            "apron",
            [sk_q[k] for k in np.where(ap_skirt_mask)[0]],
            target_tris=300,
            offset_normal=ap_offset,
            verts_override=ap_sv,
        )

        # Clean smooth curved bib panel overlapping deeply under waist belt (zero waist hairline!)
        rows_b, cols_b = 8, 9
        bib_grid = np.zeros((rows_b, cols_b, 3), dtype=np.float64)
        bib_y_bot = waist_y - 0.048
        for ri in range(rows_b):
            vr = float(ri) / float(rows_b - 1)
            yb = bib_y_bot + vr * (bib_top_y - bib_y_bot)
            half_w = bib_half_waist + vr * (bib_half_top - bib_half_waist)
            for ci in range(cols_b):
                ur = -1.0 + 2.0 * float(ci) / float(cols_b - 1)
                xb = ur * half_w
                zb = query_front_z(xb, yb, 0.0125)
                bib_grid[ri, ci] = push_over_surface(np.array([xb, yb, zb]), cloth_verts, pad_f=0.0065, exclude_collar=True)
        cb.add_quad_grid("apron", bib_grid, thickness=0.0040)

        # Flush surface-sampled waist tie belt cleared against actual baked cloth_verts
        w_cols = 17
        w_grid = np.zeros((2, w_cols, 3), dtype=np.float64)
        waist_ring = cloth_verts[np.abs(cloth_verts[:, 1] - waist_y) < 0.016]
        if len(waist_ring) < 12:
            waist_ring = torso_core_pts[np.abs(torso_core_pts[:, 1] - waist_y) < 0.016]
        for ci in range(w_cols):
            ang = math.radians(-116.0 + (232.0 * float(ci) / float(w_cols - 1)))
            dir_v = np.array([math.sin(ang), math.cos(ang)], dtype=np.float64)
            proj_r = waist_ring[:, 0] * dir_v[0] + waist_ring[:, 2] * dir_v[1]
            align = proj_r / np.maximum(np.hypot(waist_ring[:, 0], waist_ring[:, 2]), 1e-5)
            cand_r = proj_r[align > 0.85]
            rr = (float(np.percentile(cand_r, 90)) if len(cand_r) > 0 else 0.140) + 0.005
            wx, wz = dir_v[0] * rr, dir_v[1] * rr
            w_grid[0, ci] = push_over_surface(np.array([wx, waist_y - 0.016, wz]), cloth_verts, pad_f=0.0045, pad_b=0.0045, exclude_collar=True)
            w_grid[1, ci] = push_over_surface(np.array([wx, waist_y + 0.016, wz]), cloth_verts, pad_f=0.0045, pad_b=0.0045, exclude_collar=True)
        cb.add_quad_grid("apron", w_grid, thickness=0.0036)

        # Collarbone-routed flush shoulder straps (smooth spline centerline + smoothed grid so ribbons stay crisp over chest!)
        strap_sh_x = min(0.115, max(0.104, shoulder_x * 0.62))
        for side_s in (-1.0, 1.0):
            top_x = side_s * (bib_half_top - 0.010)
            sh_top = query_shoulder_pt(side_s * strap_sh_x, 0.000, y_bias=0.0048)
            ctrl_pts = [
                push_over_surface(np.array([top_x, bib_top_y - 0.006, query_front_z(top_x, bib_top_y - 0.006, 0.010)], dtype=np.float64), cloth_verts, pad_f=0.0068, exclude_collar=True),
                push_over_surface(project_outward_torso(np.array([side_s * (strap_sh_x - 0.006), bib_top_y + 0.042, query_front_z(side_s * (strap_sh_x - 0.006), bib_top_y + 0.042, 0.010)], dtype=np.float64), offset=0.0080), cloth_verts, pad_f=0.0065, pad_top=0.0048, exclude_collar=True),
                push_over_surface(project_outward_torso(np.array([side_s * strap_sh_x, float(sh_top[1]) - 0.010, 0.044], dtype=np.float64), offset=0.0080), cloth_verts, pad_f=0.0065, pad_top=0.0048, exclude_collar=True),
                push_over_surface(np.array(sh_top, dtype=np.float64), cloth_verts, pad_top=0.0048, exclude_collar=True),
                push_over_surface(project_outward_torso(np.array([side_s * (strap_sh_x - 0.005), float(sh_top[1]) - 0.020, -0.052], dtype=np.float64), offset=0.0080), cloth_verts, pad_b=0.0065, pad_top=0.0048, exclude_collar=True),
                push_over_surface(np.array([side_s * 0.068, neck_y - 0.115, query_back_z(side_s * 0.068, neck_y - 0.115, 0.010)], dtype=np.float64), cloth_verts, pad_b=0.0068, exclude_collar=True),
                push_over_surface(np.array([0.0, neck_y - 0.155, query_back_z(0.0, neck_y - 0.155, 0.010)], dtype=np.float64), cloth_verts, pad_b=0.0068, exclude_collar=True),
            ]
            s_rows = 29
            n_ctrl = len(ctrl_pts)
            c_pts = np.zeros((s_rows, 3), dtype=np.float64)
            for ri in range(s_rows):
                u = float(ri) / float(s_rows - 1) * float(n_ctrl - 1)
                idx0 = min(int(u), n_ctrl - 2)
                frac = u - float(idx0)
                pt_c = ctrl_pts[idx0] * (1.0 - frac) + ctrl_pts[idx0 + 1] * frac
                if idx0 < n_ctrl - 2 and 0 < ri < s_rows - 1:
                    pt_c = project_outward_torso(pt_c, offset=0.0078)
                c_pts[ri] = push_over_surface(pt_c, cloth_verts, pad_f=0.0065, pad_b=0.0065, pad_top=0.0048, exclude_collar=True)
            # 4 passes of Laplacian smoothing remove piecewise breakpoint kinks & vertex-snap jitter
            for _ in range(4):
                sm_c = c_pts.copy()
                sm_c[1:-1] = 0.25 * c_pts[:-2] + 0.50 * c_pts[1:-1] + 0.25 * c_pts[2:]
                for ri in range(1, s_rows - 1):
                    sm_c[ri] = push_over_surface(sm_c[ri], cloth_verts, pad_f=0.0058, pad_b=0.0058, pad_top=0.0044, exclude_collar=True)
                c_pts = sm_c

            strap_grid = np.zeros((s_rows, 3, 3), dtype=np.float64)
            for ri in range(s_rows):
                pt_c = c_pts[ri]
                tang = c_pts[min(ri + 1, s_rows - 1)] - c_pts[max(ri - 1, 0)]
                lat_x = np.array([1.0, 0.0, 0.0], dtype=np.float64)
                smooth_top = max(0.0, 1.0 - abs(float(pt_c[2])) / 0.075)
                n_out = np.array([pt_c[0] * 0.25, 0.14 + 0.86 * smooth_top, pt_c[2]], dtype=np.float64)
                n_out /= max(np.linalg.norm(n_out), 1e-6)
                lat = np.cross(tang, n_out)
                llen = np.linalg.norm(lat)
                if llen < 1e-6:
                    lat = lat_x
                else:
                    lat = (-lat if float(np.dot(lat, lat_x)) < 0.0 else lat) / llen
                half_sw = 0.0110
                for ci, lat_m in ((0, -half_sw), (1, 0.0), (2, half_sw)):
                    strap_grid[ri, ci] = push_over_surface(pt_c + lat * lat_m, cloth_verts, pad_f=0.0060, pad_b=0.0060, pad_top=0.0046, exclude_collar=True)
            # Final 2 light passes keeping center & edges collinearly crisp
            for _ in range(2):
                sg = strap_grid.copy()
                sg[1:-1] = 0.22 * strap_grid[:-2] + 0.56 * strap_grid[1:-1] + 0.22 * strap_grid[2:]
                strap_grid = sg
            cb.add_quad_grid("apron", strap_grid, thickness=0.0034)

        # Crisp front apron pocket right below waist band
        pkt_rows, pkt_cols = 4, 7
        pkt_grid = np.zeros((pkt_rows, pkt_cols, 3), dtype=np.float64)
        pkt_bot = waist_y - 0.19
        pkt_top = waist_y - 0.035
        sk_front = ap_sv[np.unique(skqv[ap_skirt_mask].reshape(-1))]
        for ri in range(pkt_rows):
            vr = float(ri) / float(pkt_rows - 1)
            yp = pkt_bot + vr * (pkt_top - pkt_bot)
            for ci in range(pkt_cols):
                ur = -1.0 + 2.0 * float(ci) / float(pkt_cols - 1)
                xp = ur * 0.105
                sub_p = sk_front[(np.abs(sk_front[:, 0] - xp) < 0.04) & (np.abs(sk_front[:, 1] - yp) < 0.04)]
                zp = (float(sub_p[:, 2].max()) if len(sub_p) > 0 else 0.125) + ap_offset + 0.0055
                pkt_grid[ri, ci] = [xp, yp, zp]
        cb.add_quad_grid("apron", pkt_grid, thickness=0.003)

    # 8. EYEBROWS, CONTINUOUS MUSTACHE & GLASSES
    brow_y = float(l_eye_c[1]) + 0.020
    brow_z = float(l_eye_c[2]) + 0.025
    for side_s in (-1.0, 1.0):
        bx0 = float(l_eye_c[0]) * side_s
        cb.add_tube("eyebrow", [
            [bx0 - 0.015 * side_s, brow_y - 0.001, brow_z + 0.002],
            [bx0 + 0.002 * side_s, brow_y + 0.003, brow_z],
            [bx0 + 0.018 * side_s, brow_y - 0.002, brow_z - 0.007],
        ], [0.0024, 0.0026, 0.0016], rings=6, rigid_bone="head")

    if mustache:
        must_y = float(nose_tip[1]) - 0.0135
        must_z = float(nose_tip[2]) - 0.007
        cb.add_tube("hair", [
            [-0.024, must_y - 0.007, must_z - 0.012],
            [-0.012, must_y - 0.001, must_z - 0.003],
            [-0.004, must_y + 0.001, must_z + 0.001],
            [0.0,    must_y + 0.0015, must_z + 0.002],
            [0.004,  must_y + 0.001, must_z + 0.001],
            [0.012,  must_y - 0.001, must_z - 0.003],
            [0.024,  must_y - 0.007, must_z - 0.012],
        ], [0.0022, 0.0052, 0.0046, 0.0044, 0.0046, 0.0052, 0.0022], rings=8, cap=True, rigid_bone="head")

    if glasses:
        gz = float(l_eye_c[2]) + 0.036
        gy = float(l_eye_c[1])
        gr = 0.0015
        for ex_s in (float(l_eye_c[0]), float(r_eye_c[0])):
            w_g, h_g = 0.019, 0.012
            corners = [
                [ex_s - w_g, gy + h_g, gz],
                [ex_s + w_g, gy + h_g, gz],
                [ex_s + w_g, gy - h_g, gz],
                [ex_s - w_g, gy - h_g, gz],
                [ex_s - w_g, gy + h_g, gz],
            ]
            cb.add_tube("glass_frame", corners, [gr] * 5, rings=5, cap=False, rigid_bone="head")
        cb.add_tube("glass_frame", [[-0.011, gy + 0.003, gz + 0.001], [0.011, gy + 0.003, gz + 0.001]], [gr, gr], rings=5, rigid_bone="head")
        for side_s in (-1.0, 1.0):
            cb.add_tube("glass_frame", [
                [side_s * 0.048, gy + 0.005, gz],
                [side_s * (rx_skull * 1.04), gy + 0.002, head_z_mid],
            ], [gr, gr], rings=5, rigid_bone="head")

    # 9. SKULL-FITTED SCALP HAIR & HATS (strictly exclude ears; continuous temple/above-ear/nape hairline)
    forehead_hair_y = float(l_eye_c[1]) + 0.032
    temple_back_z = float(l_eye_c[2]) - 0.024
    jaw_line_y = float(l_eye_c[1]) - (0.018 if hat != "" else 0.022)
    q_max_abs_x = np.max(np.abs(verts[qv][:, :, 0]), axis=1)

    is_ear_quad = (
        (q_max_abs_x > rx_skull * 0.94)
        & (qc[:, 1] >= float(l_eye_c[1]) - 0.052)
        & (qc[:, 1] <= float(l_eye_c[1]) + 0.0185)
        & (qc[:, 2] >= float(l_eye_c[2]) - 0.116)
        & (qc[:, 2] <= float(l_eye_c[2]) - 0.048)
    )
    is_crown_scalp = (
        (qc[:, 1] >= forehead_hair_y)
        & ((qc[:, 1] >= forehead_hair_y + 0.018) | (qc[:, 2] < float(l_eye_c[2]) + 0.022))
    )
    is_nape_sideburns = (
        (qc[:, 1] >= jaw_line_y)
        & (qc[:, 1] < forehead_hair_y + 0.018)
        & (qc[:, 2] < float(l_eye_c[2]) - 0.044)
        & ((qc[:, 2] < float(l_eye_c[2]) - 0.088) | (np.abs(qc[:, 0]) > rx_skull * 0.86))
        & ((np.abs(qc[:, 0]) > rx_skull * 0.68) | (qc[:, 2] < head_z_mid - 0.020))
    )
    is_side_temple_band = (
        (qc[:, 1] >= float(l_eye_c[1]) + 0.018)
        & (qc[:, 1] < forehead_hair_y + 0.016)
        & (qc[:, 2] < temple_back_z)
        & ((qc[:, 2] < float(l_eye_c[2]) - 0.048) | (np.abs(qc[:, 0]) > rx_skull * 0.80))
    )
    is_sideburn_fill = (
        (qc[:, 1] >= float(l_eye_c[1]) - 0.010)
        & (qc[:, 1] < forehead_hair_y + 0.020)
        & (qc[:, 2] >= float(l_eye_c[2]) - 0.084)
        & (qc[:, 2] <= float(l_eye_c[2]) - 0.016)
        & (np.abs(qc[:, 0]) > rx_skull * 0.72)
    )

    crown_band_y = float(l_eye_c[1]) + 0.034
    if hat != "":
        hair_cap_mask = (
            is_nape_sideburns
            & (~is_ear_quad)
            & (qc[:, 1] >= jaw_line_y)
            & (qc[:, 2] < float(l_eye_c[2]) - 0.056)
            & (qc[:, 1] <= crown_band_y - 0.022)
        )
        hair_cap_offset = 0.0018
    else:
        hair_cap_mask = (is_crown_scalp | is_nape_sideburns | is_side_temple_band | is_sideburn_fill) & (~is_ear_quad)
        hair_cap_offset = 0.0055

    hair_quads = [body_quads[k] for k in np.where(hair_cap_mask)[0]]
    cb.add_quad_group_with_weights("hair", hair_quads, target_tris=340, offset_normal=hair_cap_offset)

    if hat == "chef":
        toque_o = np.array([0.0, crown_band_y, head_z_mid + 0.002])
        cb.add_lathe_pleated("hat", toque_o, [
            (rx_skull * 1.11, -0.016, 0.0),
            (rx_skull * 1.13, 0.012, 0.0),
            (rx_skull * 1.14, 0.056, 0.0),
        ], sx=1.03, sz=1.15, segs=24, pleat_amp=0.0, rot_xyz=(-0.10, 0.0, 0.0), rigid_bone="head")
        cb.add_lathe_pleated("hat", toque_o + np.array([0.0, 0.050, -0.004]), [
            (rx_skull * 1.12, 0.000, 0.25),
            (rx_skull * 1.36, 0.036, 0.85),
            (rx_skull * 1.50, 0.082, 1.00),
            (rx_skull * 1.38, 0.124, 0.65),
            (rx_skull * 0.86, 0.148, 0.25),
            (0.004, 0.158, 0.0),
        ], sx=1.03, sz=1.12, segs=28, pleat_count=18, pleat_amp=0.008, rot_xyz=(-0.10, 0.0, 0.0), rigid_bone="head")
    elif hat == "baker":
        b_o = np.array([0.0, crown_band_y, head_z_mid + 0.002])
        cb.add_lathe_pleated("hat", b_o, [
            (rx_skull * 1.11, -0.016, 0.0),
            (rx_skull * 1.13, 0.010, 0.0),
            (rx_skull * 1.14, 0.042, 0.0),
        ], sx=1.03, sz=1.15, segs=22, pleat_amp=0.0, rot_xyz=(-0.10, 0.0, -0.08), rigid_bone="head")
        cb.add_lathe_pleated("hat", b_o + np.array([0.004, 0.036, -0.004]), [
            (rx_skull * 1.12, 0.000, 0.25),
            (rx_skull * 1.35, 0.028, 0.85),
            (rx_skull * 1.38, 0.056, 1.00),
            (rx_skull * 0.98, 0.080, 0.45),
            (0.004, 0.092, 0.0),
        ], sx=1.04, sz=1.14, segs=24, pleat_count=14, pleat_amp=0.005, rot_xyz=(-0.10, 0.0, -0.08), rigid_bone="head")
    elif hat == "hardhat":
        hh_o = np.array([0.0, crown_band_y + 0.004, head_z_mid + 0.002])
        cb.add_lathe_pleated("hat", hh_o, [
            (rx_skull * 1.10, -0.006, 0.0),
            (rx_skull * 1.22, 0.012, 0.0),
            (rx_skull * 1.22, 0.038, 0.0),
            (rx_skull * 1.06, 0.072, 0.0),
            (rx_skull * 0.62, 0.100, 0.0),
            (0.004, 0.110, 0.0),
        ], sx=1.04, sz=1.18, segs=22, pleat_amp=0.0, rigid_bone="head")
        cb.add_ellipsoid("hat", hh_o + np.array([0.0, 0.056, 0.0]), (0.015, 0.056, 0.098), rings=5, segs=10, rigid_bone="head")
        cb.add_ellipsoid("hat", hh_o + np.array([0.0, 0.008, 0.102]), (0.088, 0.010, 0.048), rings=5, segs=12, rot_xyz=(0.14, 0.0, 0.0), rigid_bone="head")
    else:
        # Compact skull-hugged hair silhouettes (strictly within cranial outline -> smooth contours, zero horn bumps)
        crown_top_z = head_z_mid - 0.010
        crown_high_y = head_top_y - 0.024
        if hair_style == "updo_wavy":
            cb.add_ellipsoid("hair", np.array([0.0, crown_high_y + 0.002, crown_top_z]), (rx_skull * 0.80, 0.020, 0.068), rings=6, segs=14, rigid_bone="head")
            cb.add_ellipsoid("hair", np.array([0.0, head_c[1] + 0.040, head_z_min - 0.020]), (0.044, 0.042, 0.036), rings=6, segs=14, rigid_bone="head")
        elif hair_style == "ponytail":
            cb.add_ellipsoid("hair", np.array([0.0, crown_high_y + 0.001, crown_top_z]), (rx_skull * 0.78, 0.018, 0.066), rings=6, segs=14, rigid_bone="head")
            tail_z = head_z_min - 0.016
            tail_y = float(l_eye_c[1]) + 0.022
            cb.add_ellipsoid("ribbon", np.array([0.0, tail_y, tail_z]), (0.019, 0.017, 0.017), rings=5, segs=10, rigid_bone="head")
            cb.add_tube("hair", [
                [0.0, tail_y - 0.004, tail_z - 0.006],
                [0.006, tail_y - 0.075, tail_z - 0.036],
                [0.008, tail_y - 0.155, tail_z - 0.042],
            ], [0.027, 0.023, 0.013], rings=9, rigid_bone="head")
        elif hair_style == "bob":
            cb.add_ellipsoid("hair", np.array([0.0, crown_high_y + 0.002, crown_top_z + 0.004]), (rx_skull * 0.82, 0.020, 0.070), rings=6, segs=14, rigid_bone="head")
            for side_s in (-1.0, 1.0):
                cb.add_tube("hair", [
                    [side_s * 0.042, crown_high_y - 0.008, temple_back_z - 0.004],
                    [side_s * (rx_skull * 0.98), float(l_eye_c[1]) + 0.035, temple_back_z - 0.008],
                    [side_s * (rx_skull * 1.04), float(l_eye_c[1]) - 0.030, temple_back_z - 0.022],
                    [side_s * (rx_skull * 0.92), float(l_eye_c[1]) - 0.105, temple_back_z - 0.030],
                ], [0.016, 0.021, 0.022, 0.014], rings=8, rigid_bone="head")
        elif hair_style == "quiff":
            cb.add_ellipsoid("hair", np.array([0.0, crown_high_y + 0.001, crown_top_z]), (rx_skull * 0.80, 0.020, 0.068), rings=6, segs=14, rigid_bone="head")
            cb.add_ellipsoid("hair", np.array([0.008, crown_high_y + 0.014, crown_top_z + 0.026]), (rx_skull * 0.64, 0.020, 0.045), rings=6, segs=12, rot_xyz=(-0.18, 0.12, -0.05), rigid_bone="head")
        else:
            cb.add_ellipsoid("hair", np.array([0.0, crown_high_y, crown_top_z]), (rx_skull * 0.78, 0.018, 0.066), rings=6, segs=14, rigid_bone="head")

    return cb


# ------------------------------------------------------------------------------ GLTF EXPORT WITH SKIN + ANIMATIONS
def _pad4(b: bytes) -> bytes:
    rem = len(b) % 4
    return b if rem == 0 else b + b"\x00" * (4 - rem)


def export_character_glb(cb: CharacterMeshBuilder, out_path: str) -> Tuple[int, int]:
    """Pack merged surfaces into a multi-primitive skinned GLTF 2.0 binary (.glb) with animations."""
    bin_buf = bytearray()
    buffer_views: List[pygltflib.BufferView] = []
    accessors: List[pygltflib.Accessor] = []
    primitives: List[pygltflib.Primitive] = []
    materials: List[pygltflib.Material] = []

    def add_bv(data: bytes, target: Optional[int] = None) -> int:
        offset = len(bin_buf)
        bin_buf.extend(_pad4(data))
        bv = pygltflib.BufferView(buffer=0, byteOffset=offset, byteLength=len(data))
        if target is not None:
            bv.target = target
        idx = len(buffer_views)
        buffer_views.append(bv)
        return idx

    def add_acc(bv: int, comp_type: int, count: int, acc_type: str, vmin=None, vmax=None) -> int:
        acc = pygltflib.Accessor(bufferView=bv, componentType=comp_type, count=count, type=acc_type)
        if vmin is not None:
            acc.min = vmin
        if vmax is not None:
            acc.max = vmax
        idx = len(accessors)
        accessors.append(acc)
        return idx

    total_verts = 0
    total_tris = 0
    for sname in sorted(cb.surfaces.keys()):
        chunks = cb.surfaces[sname]
        v_list, t_list, j_list, w_list = [], [], [], []
        base = 0
        for cv, ct, cj, cw in chunks:
            v_list.append(cv)
            t_list.append(ct + base)
            j_list.append(cj)
            w_list.append(cw)
            base += len(cv)
        va = np.concatenate(v_list, axis=0).astype(np.float32)
        ta_raw = np.concatenate(t_list, axis=0).astype(np.int32)
        e1 = va[ta_raw[:, 1]].astype(np.float64) - va[ta_raw[:, 0]].astype(np.float64)
        e2 = va[ta_raw[:, 2]].astype(np.float64) - va[ta_raw[:, 0]].astype(np.float64)
        tri_area = np.linalg.norm(np.cross(e1, e2), axis=1)
        ta_clean = ta_raw[tri_area > 1e-10]
        if len(ta_clean) == 0:
            continue
        ta = ta_clean.astype(np.uint16)
        ja = np.concatenate(j_list, axis=0).astype(np.uint16)
        wa = np.concatenate(w_list, axis=0).astype(np.float32)
        na = compute_smooth_normals(va.astype(np.float64), ta.astype(np.int32)).astype(np.float32)
        uva = np.stack([va[:, 0] * 1.4 + va[:, 2] * 0.7, va[:, 1] * 1.4], axis=1).astype(np.float32)

        n64 = na.astype(np.float64)
        ref_x = np.array([1.0, 0.0, 0.0], dtype=np.float64)
        ref_z = np.array([0.0, 0.0, 1.0], dtype=np.float64)
        use_z = np.abs(n64[:, 0]) > 0.88
        ref = np.where(use_z[:, None], ref_z[None, :], ref_x[None, :])
        t_orth = ref - n64 * np.sum(ref * n64, axis=1, keepdims=True)
        t_len = np.linalg.norm(t_orth, axis=1, keepdims=True)
        t_orth = np.where(t_len > 1e-8, t_orth / np.maximum(t_len, 1e-8), np.array([1.0, 0.0, 0.0]))
        tan4 = np.concatenate([t_orth, np.ones((len(va), 1), dtype=np.float64)], axis=1).astype(np.float32)

        total_verts += len(va)
        total_tris += len(ta)

        bv_p = add_bv(va.tobytes(), pygltflib.ARRAY_BUFFER)
        bv_n = add_bv(na.tobytes(), pygltflib.ARRAY_BUFFER)
        bv_t = add_bv(tan4.tobytes(), pygltflib.ARRAY_BUFFER)
        bv_uv = add_bv(uva.tobytes(), pygltflib.ARRAY_BUFFER)
        bv_j = add_bv(ja.tobytes(), pygltflib.ARRAY_BUFFER)
        bv_w = add_bv(wa.tobytes(), pygltflib.ARRAY_BUFFER)
        bv_i = add_bv(ta.reshape(-1).tobytes(), pygltflib.ELEMENT_ARRAY_BUFFER)

        acc_p = add_acc(bv_p, pygltflib.FLOAT, len(va), pygltflib.VEC3, va.min(axis=0).tolist(), va.max(axis=0).tolist())
        acc_n = add_acc(bv_n, pygltflib.FLOAT, len(na), pygltflib.VEC3)
        acc_t = add_acc(bv_t, pygltflib.FLOAT, len(tan4), pygltflib.VEC4)
        acc_uv = add_acc(bv_uv, pygltflib.FLOAT, len(uva), pygltflib.VEC2)
        acc_j = add_acc(bv_j, pygltflib.UNSIGNED_SHORT, len(ja), pygltflib.VEC4)
        acc_w = add_acc(bv_w, pygltflib.FLOAT, len(wa), pygltflib.VEC4)
        acc_i = add_acc(bv_i, pygltflib.UNSIGNED_SHORT, len(ta) * 3, pygltflib.SCALAR)

        mat_idx = len(materials)
        materials.append(pygltflib.Material(
            name=sname,
            pbrMetallicRoughness=pygltflib.PbrMetallicRoughness(
                baseColorFactor=[0.85, 0.85, 0.85, 1.0],
                metallicFactor=0.0,
                roughnessFactor=0.75,
            ),
        ))
        primitives.append(pygltflib.Primitive(
            attributes=pygltflib.Attributes(
                POSITION=acc_p, NORMAL=acc_n, TANGENT=acc_t, TEXCOORD_0=acc_uv, JOINTS_0=acc_j, WEIGHTS_0=acc_w
            ),
            indices=acc_i,
            material=mat_idx,
            mode=pygltflib.TRIANGLES,
        ))

    n_bones = len(BONE_HIERARCHY)
    nodes: List[pygltflib.Node] = []
    bone_children: Dict[int, List[int]] = defaultdict(list)
    for bi, (bname, parent_name, _) in enumerate(BONE_HIERARCHY):
        if parent_name is not None:
            bone_children[BONE_INDEX[parent_name]].append(bi)

    for bi, (bname, parent_name, _) in enumerate(BONE_HIERARCHY):
        pos = cb.joints_pos[bname]
        local_t = pos if parent_name is None else pos - cb.joints_pos[parent_name]
        node = pygltflib.Node(
            name=bname,
            translation=[float(local_t[0]), float(local_t[1]), float(local_t[2])],
            rotation=[0.0, 0.0, 0.0, 1.0],
        )
        if bone_children[bi]:
            node.children = bone_children[bi]
        nodes.append(node)

    ibms = np.zeros((n_bones, 4, 4), dtype=np.float32)
    for bi, (bname, _, _) in enumerate(BONE_HIERARCHY):
        m = np.eye(4, dtype=np.float32)
        p = cb.joints_pos[bname]
        m[0, 3] = float(-p[0])
        m[1, 3] = float(-p[1])
        m[2, 3] = float(-p[2])
        ibms[bi] = m.T
    bv_ibm = add_bv(ibms.tobytes())
    acc_ibm = add_acc(bv_ibm, pygltflib.FLOAT, n_bones, pygltflib.MAT4)

    mesh_node_idx = len(nodes)
    nodes.append(pygltflib.Node(name="BodyMesh", mesh=0, skin=0))
    root_node_idx = len(nodes)
    nodes.append(pygltflib.Node(name="CharacterRoot", children=[0, mesh_node_idx]))

    skins = [pygltflib.Skin(name="Skeleton3D", joints=list(range(n_bones)), skeleton=0, inverseBindMatrices=acc_ibm)]

    pelvis_rest = cb.joints_pos["pelvis"]
    animations: List[pygltflib.Animation] = []

    def build_anim(name: str, times: List[float], rot_tracks: Dict[str, List[Tuple[float, float, float]]], trans_tracks: Optional[Dict[str, List[np.ndarray]]] = None) -> pygltflib.Animation:
        t_arr = np.array(times, dtype=np.float32)
        bv_t = add_bv(t_arr.tobytes())
        acc_t = add_acc(bv_t, pygltflib.FLOAT, len(times), pygltflib.SCALAR, [float(t_arr.min())], [float(t_arr.max())])
        samplers: List[pygltflib.AnimationSampler] = []
        channels: List[pygltflib.AnimationChannel] = []

        for bname, eulers in rot_tracks.items():
            q_arr = np.array([quat_from_euler_xyz(*e) for e in eulers], dtype=np.float32)
            bv_q = add_bv(q_arr.tobytes())
            acc_q = add_acc(bv_q, pygltflib.FLOAT, len(eulers), pygltflib.VEC4)
            s_idx = len(samplers)
            samplers.append(pygltflib.AnimationSampler(input=acc_t, output=acc_q, interpolation="LINEAR"))
            channels.append(pygltflib.AnimationChannel(sampler=s_idx, target=pygltflib.AnimationChannelTarget(node=BONE_INDEX[bname], path="rotation")))

        if trans_tracks:
            for bname, pos_list in trans_tracks.items():
                p_arr = np.array(pos_list, dtype=np.float32)
                bv_tp = add_bv(p_arr.tobytes())
                acc_tp = add_acc(bv_tp, pygltflib.FLOAT, len(pos_list), pygltflib.VEC3)
                s_idx = len(samplers)
                samplers.append(pygltflib.AnimationSampler(input=acc_t, output=acc_tp, interpolation="LINEAR"))
                channels.append(pygltflib.AnimationChannel(sampler=s_idx, target=pygltflib.AnimationChannelTarget(node=BONE_INDEX[bname], path="translation")))

        return pygltflib.Animation(name=name, samplers=samplers, channels=channels)

    animations.append(build_anim(
        "Idle",
        [0.0, 1.3, 2.6],
        {
            "upperarm_l": [(0.04, 0.0, -0.56), (0.04, 0.0, -0.53), (0.04, 0.0, -0.56)],
            "upperarm_r": [(0.04, 0.0, 0.56), (0.04, 0.0, 0.53), (0.04, 0.0, 0.56)],
            "lowerarm_l": [(-0.14, 0.0, 0.0), (-0.18, 0.0, 0.0), (-0.14, 0.0, 0.0)],
            "lowerarm_r": [(-0.14, 0.0, 0.0), (-0.18, 0.0, 0.0), (-0.14, 0.0, 0.0)],
            "thigh_l": [(0.0, 0.0, -0.05), (0.0, 0.0, -0.05), (0.0, 0.0, -0.05)],
            "thigh_r": [(0.0, 0.0, 0.05), (0.0, 0.0, 0.05), (0.0, 0.0, 0.05)],
            "spine_02": [(0.0, 0.0, 0.0), (0.018, 0.0, 0.0), (0.0, 0.0, 0.0)],
            "head": [(0.0, -0.05, 0.0), (-0.02, 0.06, 0.0), (0.0, -0.05, 0.0)],
        },
        {"pelvis": [pelvis_rest, pelvis_rest, pelvis_rest]},
    ))

    pelvis_seat = np.array([pelvis_rest[0], pelvis_rest[1] * 0.52, -0.04], dtype=np.float32)
    animations.append(build_anim(
        "Sit_Chair_Idle",
        [0.0, 0.65, 1.3, 1.95, 2.6],
        {
            "thigh_l": [(-1.46, 0.0, -0.04)] * 5,
            "thigh_r": [(-1.46, 0.0, 0.04)] * 5,
            "calf_l": [(1.46, 0.0, 0.0)] * 5,
            "calf_r": [(1.46, 0.0, 0.0)] * 5,
            "spine_01": [(0.05, 0.0, 0.0), (0.06, 0.0, 0.0), (0.05, 0.0, 0.0), (0.06, 0.0, 0.0), (0.05, 0.0, 0.0)],
            "upperarm_l": [(-0.28, -0.05, -0.60)] * 5,
            "upperarm_r": [(-0.28, 0.05, 0.60)] * 5,
            "lowerarm_l": [(-0.34, -0.78, -0.20), (-0.28, -0.78, -0.20), (-0.36, -0.78, -0.20), (-0.29, -0.78, -0.20), (-0.34, -0.78, -0.20)],
            "lowerarm_r": [(-0.28, 0.78, 0.20), (-0.36, 0.78, 0.20), (-0.29, 0.78, 0.20), (-0.34, 0.78, 0.20), (-0.28, 0.78, 0.20)],
            "hand_l": [(0.08, 0.05, 0.55)] * 5,
            "hand_r": [(0.08, -0.05, -0.55)] * 5,
            "head": [(0.08, -0.04, 0.0), (0.10, 0.0, 0.0), (0.08, 0.04, 0.0), (0.10, 0.0, 0.0), (0.08, -0.04, 0.0)],
        },
        {"pelvis": [pelvis_seat] * 5},
    ))

    animations.append(build_anim(
        "Interact",
        [0.0, 0.35, 0.65, 1.0],
        {
            "upperarm_l": [(0.04, 0.0, -0.56)] * 4,
            "upperarm_r": [(0.04, 0.0, 0.56), (-0.52, -0.15, 0.42), (-0.48, 0.05, 0.45), (0.04, 0.0, 0.56)],
            "lowerarm_r": [(-0.14, 0.0, 0.0), (-0.95, 0.0, 0.0), (-0.80, 0.0, 0.12), (-0.14, 0.0, 0.0)],
            "thigh_l": [(0.0, 0.0, -0.05)] * 4,
            "thigh_r": [(0.0, 0.0, 0.05)] * 4,
            "head": [(0.0, 0.0, 0.0), (-0.06, 0.03, 0.0), (-0.04, -0.02, 0.0), (0.0, 0.0, 0.0)],
        },
        {"pelvis": [pelvis_rest] * 4},
    ))

    animations.append(build_anim(
        "Cheer",
        [0.0, 0.35, 0.70, 1.0],
        {
            "upperarm_l": [(0.04, 0.0, -0.56), (-0.85, 0.0, -0.25), (-0.75, 0.0, -0.35), (0.04, 0.0, -0.56)],
            "upperarm_r": [(0.04, 0.0, 0.56), (-0.85, 0.0, 0.25), (-0.75, 0.0, 0.35), (0.04, 0.0, 0.56)],
            "lowerarm_l": [(-0.14, 0.0, 0.0), (-0.55, 0.0, 0.0), (-0.45, 0.0, 0.0), (-0.14, 0.0, 0.0)],
            "lowerarm_r": [(-0.14, 0.0, 0.0), (-0.55, 0.0, 0.0), (-0.45, 0.0, 0.0), (-0.14, 0.0, 0.0)],
            "thigh_l": [(0.0, 0.0, -0.05)] * 4,
            "thigh_r": [(0.0, 0.0, 0.05)] * 4,
            "head": [(0.0, 0.0, 0.0), (-0.08, 0.0, 0.0), (-0.06, 0.0, 0.0), (0.0, 0.0, 0.0)],
        },
        {"pelvis": [pelvis_rest] * 4},
    ))

    gltf = pygltflib.GLTF2(
        asset=pygltflib.Asset(version="2.0", generator="StartupSimulator-MakeHuman-Pipeline"),
        buffers=[pygltflib.Buffer(byteLength=len(bin_buf))],
        bufferViews=buffer_views,
        accessors=accessors,
        meshes=[pygltflib.Mesh(name="CharacterMesh", primitives=primitives)],
        materials=materials,
        nodes=nodes,
        skins=skins,
        animations=animations,
        scenes=[pygltflib.Scene(nodes=[root_node_idx])],
        scene=0,
    )
    gltf.set_binary_blob(bytes(bin_buf))
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    gltf.save_binary(out_path)
    return total_verts, total_tris


ARCHETYPES: Dict[str, Dict] = {
    "mh_chef_mario": {
        "morph": {"male_young": 0.60, "male_old": 0.40},
        "neck_style": "open_v",
        "short_sleeves": True,
        "apron": True,
        "hat": "chef",
        "mustache": True,
    },
    "mh_baker_bruno": {
        "morph": {"male_young": 0.30, "male_old": 0.70},
        "neck_style": "open_v",
        "rolled_sleeves": True,
        "apron": True,
        "hat": "baker",
        "mustache": True,
    },
    "mh_female_skirt_apron": {
        "morph": {"female_young": 1.0},
        "neck_style": "crew",
        "skirt": True,
        "apron": True,
        "hair_style": "updo_wavy",
    },
    "mh_female_ponytail_apron": {
        "morph": {"female_young": 1.0},
        "neck_style": "crew",
        "apron": True,
        "hair_style": "ponytail",
    },
    "mh_female_bob_vest": {
        "morph": {"female_young": 1.0},
        "neck_style": "collar",
        "vest": True,
        "hair_style": "bob",
        "glasses": True,
    },
    "mh_female_seated": {
        "morph": {"female_young": 1.0},
        "neck_style": "crew",
        "hair_style": "ponytail",
        "shoe_style": "sneaker_white",
    },
    "mh_male_tech_vest": {
        "morph": {"male_young": 1.0},
        "neck_style": "collar",
        "vest": True,
        "hair_style": "quiff",
        "glasses": True,
        "shoe_style": "sneaker_white",
    },
    "mh_male_engineer_hardhat": {
        "morph": {"male_young": 0.35, "male_old": 0.65},
        "neck_style": "collar",
        "rolled_sleeves": True,
        "vest": True,
        "hat": "hardhat",
        "mustache": True,
        "glasses": True,
    },
    "mh_male_suit": {
        "morph": {"male_young": 0.60, "male_old": 0.40},
        "neck_style": "collar",
        "suit_jacket": True,
        "tie": True,
        "hair_style": "short",
        "glasses": True,
    },
    "mh_male_hoodie": {
        "morph": {"male_young": 1.0},
        "neck_style": "hoodie",
        "hair_style": "quiff",
        "glasses": True,
        "shoe_style": "sneaker_white",
    },
}


def main() -> None:
    print("Loading MakeHuman CC0 base assets from:", MH_ASSET_DIR)
    mh = MHBaseData()
    for name, cfg in ARCHETYPES.items():
        cb = assemble_archetype(mh, cfg)
        out_path = os.path.join(OUT_DIR, f"{name}.glb")
        nv, nt = export_character_glb(cb, out_path)
        size_kb = os.path.getsize(out_path) / 1024.0
        print(f"  Generated {name}.glb -> {nv} verts, {nt} tris, {size_kb:.1f} KB")


if __name__ == "__main__":
    main()
