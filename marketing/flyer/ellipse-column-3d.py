# GolfTrack – 3D-Ansichten der elliptischen Werbesäulen (Flyeralarm „Werbesäulen Ellipse aus Wellpappe“).
# Baut die Säulen als zwei gewölbte Wellpappe-Flächen (Linsen-Querschnitt), legt die Druckmotive aus
# ellipse-column.mjs als Textur auf und rendert mehrere Ansichten mit Cycles.
#
# Erst die Texturen erzeugen:   node ellipse-column.mjs
# Dann rendern:
#   /Applications/Blender.app/Contents/MacOS/Blender -b -P ellipse-column-3d.py -- [--quick] [--only=studio]
# Ausgabe: out/ellipsensaeule/3d/<ansicht>.png
import bpy, bmesh, math, os, sys
from mathutils import Vector

ARGS = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
QUICK = "--quick" in ARGS
ONLY = next((a.split("=")[1] for a in ARGS if a.startswith("--only=")), "")
HERE = os.path.dirname(os.path.abspath(__file__))
TEX = os.path.join(HERE, "out", "ellipsensaeule", "tex")
OUT = os.path.join(HERE, "out", "ellipsensaeule", "3d")
os.makedirs(OUT, exist_ok=True)

THETA = 0.9  # halber Öffnungswinkel je Bogen (rad) → bei 60 cm Bahn ≈ 52 cm breit, 25 cm tief
SEG = 64


def reset(exposure=-1.8):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene
    sc.render.engine = "CYCLES"
    prefs = bpy.context.preferences.addons["cycles"].preferences
    try:
        prefs.compute_device_type = "METAL"
        prefs.get_devices()
        for d in prefs.devices:
            d.use = True
        sc.cycles.device = "GPU"
    except Exception as e:
        print("GPU nicht verfügbar:", e)
    sc.cycles.samples = 48 if QUICK else 384
    sc.cycles.use_denoising = True
    try:
        sc.cycles.denoiser = "OPENIMAGEDENOISE"
    except Exception:
        pass
    # Standard statt Filmic: Druckfarben (App-Grün/Gold) bleiben farbtreu
    sc.view_settings.view_transform = "Standard"
    sc.view_settings.look = "None"
    sc.view_settings.exposure = exposure
    sc.render.film_transparent = False
    sc.render.image_settings.file_format = "PNG"
    sc.render.image_settings.color_mode = "RGB"
    return sc


def paper_mat(name, img_path):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    bsdf = nt.nodes["Principled BSDF"]
    tex = nt.nodes.new("ShaderNodeTexImage")
    tex.image = bpy.data.images.load(img_path)
    tex.interpolation = "Cubic"
    nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Roughness"].default_value = 0.62
    bsdf.inputs["Specular"].default_value = 0.28
    # leichte Wellpappe-Riffelung (E-Welle, senkrecht) als Bump
    wave = nt.nodes.new("ShaderNodeTexWave")
    wave.wave_type = "BANDS"
    wave.bands_direction = "X"
    wave.inputs["Scale"].default_value = 140.0
    coord = nt.nodes.new("ShaderNodeTexCoord")
    nt.links.new(coord.outputs["UV"], wave.inputs["Vector"])
    bump = nt.nodes.new("ShaderNodeBump")
    bump.inputs["Strength"].default_value = 0.025
    nt.links.new(wave.outputs["Fac"], bump.inputs["Height"])
    nt.links.new(bump.outputs["Normal"], bsdf.inputs["Normal"])
    return m


def plain_mat(name, rgb, rough=0.8):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (*rgb, 1)
    b.inputs["Roughness"].default_value = rough
    b.inputs["Specular"].default_value = 0.2
    return m


def column(motif, W_cm, H_cm, loc, rot_deg):
    L = W_cm / 100.0
    H = H_cm / 100.0
    R = L / (2 * THETA)
    c0 = R * math.cos(THETA)
    bm = bmesh.new()
    uv = bm.loops.layers.uv.new()

    def arc(sign):
        # sign=-1: Vorderseite (wölbt zur Kamera, -Y), +1: Rückseite
        rows = []
        for i in range(SEG + 1):
            phi = -THETA + 2 * THETA * i / SEG
            x = R * math.sin(phi) * (1 if sign < 0 else -1)
            y = sign * (R * math.cos(phi) - c0)
            rows.append((bm.verts.new((x, y, 0)), bm.verts.new((x, y, H)), i / SEG))
        return rows

    for sign, mat in ((-1, 0), (1, 1)):
        rows = arc(sign)
        for (a0, a1, u0), (b0, b1, u1) in zip(rows, rows[1:]):
            f = bm.faces.new((a0, b0, b1, a1))
            f.material_index = mat
            f.smooth = True
            for loop, (u, v) in zip(f.loops, ((u0, 0), (u1, 0), (u1, 1), (u0, 1))):
                loop[uv].uv = (u, v)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    me = bpy.data.meshes.new(f"Saeule-{motif}")
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new(f"Saeule-{motif}", me)
    bpy.context.collection.objects.link(ob)
    for side in ("vorne", "hinten"):
        me.materials.append(paper_mat(f"{motif}-{side}", os.path.join(TEX, f"{motif}-{side}.png")))
    kraft = bpy.data.materials.get("Kraft") or plain_mat("Kraft", (0.42, 0.29, 0.17), 0.9)
    me.materials.append(kraft)
    me.materials.append(kraft)
    sol = ob.modifiers.new("Wellpappe", "SOLIDIFY")
    sol.thickness = 0.004
    sol.offset = -1
    sol.material_offset = 2
    sol.material_offset_rim = 2
    sol.use_even_offset = True
    ob.location = loc
    ob.rotation_euler = (0, 0, math.radians(rot_deg))
    return ob


def cyclorama(color, size=14.0):
    # Hohlkehle: Boden geht mit Radius in die Rückwand über
    bm = bmesh.new()
    prof = [(-size / 2, 0.0)]
    r, y0 = 2.0, 3.0
    for i in range(17):
        a = math.pi / 2 * i / 16
        prof.append((y0 + r * math.sin(a), r - r * math.cos(a)))
    prof.append((y0 + r, 8.0))
    left, right = [], []
    for y, z in prof:
        left.append(bm.verts.new((-size, y, z)))
        right.append(bm.verts.new((size, y, z)))
    for i in range(len(prof) - 1):
        f = bm.faces.new((left[i], right[i], right[i + 1], left[i + 1]))
        f.smooth = True
    me = bpy.data.meshes.new("Hohlkehle")
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new("Hohlkehle", me)
    bpy.context.collection.objects.link(ob)
    me.materials.append(plain_mat("Hintergrund", color, 0.9))
    return ob


def area(name, loc, target, size, power, color=(1, 1, 1)):
    d = bpy.data.lights.new(name, "AREA")
    d.shape = "RECTANGLE"
    d.size, d.size_y = size, size * 0.7
    d.energy = power
    d.color = color
    ob = bpy.data.objects.new(name, d)
    bpy.context.collection.objects.link(ob)
    ob.location = loc
    ob.rotation_euler = (Vector(target) - Vector(loc)).to_track_quat("-Z", "Y").to_euler()
    return ob


def camera(loc, target, lens, res=(2000, 1500)):
    cd = bpy.data.cameras.new("Kamera")
    cd.lens = lens
    cd.sensor_width = 36
    ob = bpy.data.objects.new("Kamera", cd)
    bpy.context.collection.objects.link(ob)
    ob.location = loc
    ob.rotation_euler = (Vector(target) - Vector(loc)).to_track_quat("-Z", "Y").to_euler()
    sc = bpy.context.scene
    sc.camera = ob
    sc.render.resolution_x, sc.render.resolution_y = res
    sc.render.resolution_percentage = 50 if QUICK else 100
    return ob


def world(rgb, strength):
    w = bpy.data.worlds.new("Welt")
    w.use_nodes = True
    bg = w.node_tree.nodes["Background"]
    bg.inputs["Color"].default_value = (*rgb, 1)
    bg.inputs["Strength"].default_value = strength
    bpy.context.scene.world = w


def render(name):
    bpy.context.scene.render.filepath = os.path.join(OUT, f"{name}.png")
    bpy.ops.render.render(write_still=True)
    print("OK ->", name)


TRIO = [("golf", 60, 200), ("minigolf", 60, 180), ("lernen", 50, 155)]


def scene_studio():
    # Wie das Flyeralarm-Produktfoto: drei Säulen nebeneinander auf hellem Grund
    reset()
    world((0.9, 0.9, 0.9), 0.35)
    cyclorama((0.86, 0.86, 0.85))
    column("golf", 60, 200, (-0.78, 0.15, 0), 18)
    column("minigolf", 60, 180, (0.02, -0.12, 0), -4)
    column("lernen", 50, 155, (0.78, 0.1, 0), -20)
    area("Key", (-2.6, -3.2, 3.2), (0, 0, 1), 3.0, 900)
    area("Fill", (3.2, -2.6, 1.8), (0, 0, 1), 3.0, 200)
    area("Top", (0, 0.6, 4.5), (0, 0, 0), 3.0, 260)
    area("Rim", (1.2, 2.6, 2.4), (0, 0, 1.2), 1.5, 260)
    camera((0.15, -5.4, 1.15), (0.0, 0, 1.0), 58)
    render("01-trio-studio")


def scene_trio_dark():
    # Dunkle Bühne in App-Grün, leichte Untersicht
    reset(-1.75)
    world((0.02, 0.05, 0.03), 0.4)
    cyclorama((0.035, 0.09, 0.055))
    column("lernen", 50, 155, (-0.82, 0.12, 0), 22)
    column("golf", 60, 200, (0.0, -0.1, 0), 0)
    column("minigolf", 60, 180, (0.82, 0.12, 0), -22)
    area("Key", (-2.2, -3.4, 3.0), (0, 0, 1), 2.4, 1000, (1.0, 0.95, 0.86))
    area("Fill", (2.8, -3.0, 1.4), (0, 0, 1), 3.0, 300)
    area("Gold-Rim-L", (-2.2, 1.8, 2.2), (0, 0, 1.2), 1.2, 420, (1.0, 0.8, 0.4))
    area("Gold-Rim-R", (2.2, 1.8, 2.2), (0, 0, 1.2), 1.2, 420, (1.0, 0.8, 0.4))
    camera((0.0, -5.3, 0.8), (0, 0, 1.05), 45)
    render("02-trio-buehne")


def scene_hero():
    # Einzelsäule Golf, 3/4-Ansicht, nah – zeigt Wölbung und QR auf Greifhöhe
    reset()
    world((0.92, 0.92, 0.9), 0.35)
    cyclorama((0.84, 0.85, 0.82))
    column("golf", 60, 200, (0, 0, 0), 28)
    column("minigolf", 60, 180, (1.05, 0.9, 0), -10)
    area("Key", (-2.4, -2.6, 2.8), (0, 0, 1.1), 2.6, 750)
    area("Fill", (2.6, -2.2, 1.4), (0, 0, 1), 2.6, 240)
    area("Rim", (-0.8, 2.4, 2.4), (0, 0, 1.2), 1.4, 300)
    camera((1.05, -3.3, 1.35), (0.05, 0, 1.02), 40, (1500, 2000))
    render("03-golf-nah")


def scene_backs():
    # Rückseiten: senkrechter Schriftzug wirkt aus der Ferne
    reset()
    world((0.9, 0.9, 0.9), 0.35)
    cyclorama((0.86, 0.86, 0.85))
    for (m, w, h), x, r in zip(TRIO, (-0.8, 0.0, 0.8), (180 + 16, 180, 180 - 16)):
        column(m, w, h, (x, 0, 0), r)
    area("Key", (-2.6, -3.2, 3.2), (0, 0, 1), 3.0, 900)
    area("Fill", (3.2, -2.6, 1.8), (0, 0, 1), 3.0, 200)
    area("Top", (0, 0.6, 4.5), (0, 0, 0), 3.0, 260)
    camera((0.15, -5.4, 1.15), (0.0, 0, 1.0), 58)
    render("04-rueckseiten")


def scene_export():
    # Zum Selbst-Anschauen: GLB (Browser/AR) je Trio und Einzelsäule + Blender-Datei der Studio-Szene
    def glb(name):
        common = dict(export_apply=True, export_image_format="JPEG", export_cameras=False, export_lights=False)
        bpy.ops.export_scene.gltf(filepath=os.path.join(OUT, f"{name}.glb"), export_format="GLB", **common)
        # Für die Web-Ansicht (Artifact): glTF mit eingebetteten Daten als .json – .glb wird dort nicht ausgeliefert
        web = os.path.join(OUT, "web")
        os.makedirs(web, exist_ok=True)
        bpy.ops.export_scene.gltf(filepath=os.path.join(web, f"{name}.gltf"), export_format="GLTF_EMBEDDED", **common)
        os.replace(os.path.join(web, f"{name}.gltf"), os.path.join(web, f"{name}.gltf.json"))
        print("OK ->", name)

    reset()
    column("golf", 60, 200, (-0.78, 0.15, 0), 18)
    column("minigolf", 60, 180, (0.02, -0.12, 0), -4)
    column("lernen", 50, 155, (0.78, 0.1, 0), -20)
    glb("GolfTrack-Saeulen-Trio")
    for m, w, h in TRIO:
        reset()
        column(m, w, h, (0, 0, 0), 0)
        glb(f"GolfTrack-Saeule-{m}")
    # Blender-Datei: Studio-Szene mit Licht und Kamera, Texturen eingepackt
    reset()
    world((0.9, 0.9, 0.9), 0.35)
    cyclorama((0.86, 0.86, 0.85))
    column("golf", 60, 200, (-0.78, 0.15, 0), 18)
    column("minigolf", 60, 180, (0.02, -0.12, 0), -4)
    column("lernen", 50, 155, (0.78, 0.1, 0), -20)
    area("Key", (-2.6, -3.2, 3.2), (0, 0, 1), 3.0, 900)
    area("Fill", (3.2, -2.6, 1.8), (0, 0, 1), 3.0, 200)
    area("Top", (0, 0.6, 4.5), (0, 0, 0), 3.0, 260)
    area("Rim", (1.2, 2.6, 2.4), (0, 0, 1.2), 1.5, 260)
    camera((0.15, -5.4, 1.15), (0.0, 0, 1.0), 58)
    bpy.ops.file.pack_all()
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT, "GolfTrack-Saeulen.blend"), compress=True)
    print("OK -> blend")


SCENES = {"studio": scene_studio, "buehne": scene_trio_dark, "nah": scene_hero, "rueck": scene_backs, "export": scene_export}
for k, fn in SCENES.items():
    # Export nur auf ausdrücklichen Wunsch (--only=export)
    if ONLY == k or (not ONLY and k != "export"):
        fn()
