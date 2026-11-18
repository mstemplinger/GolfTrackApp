# GolfTrack – 3D-Ansichten der Bauzaunplanen (Flyeralarm „Planen für Bauzäune“, 340 × 173 cm, 20 Ösen)
# am echten Ort: 1. Abschlag Donau-Golf-Club Passau-Raßbach. Dort steht eine Stützmauer (≈ 0,5 m), darauf ein
# Doppelstabmattenzaun (1,83 m, Felder 2,5 m, RAL 6005). Zwei Planen umschließen den Zaun:
# vorne (−Y, vor dem Gitter) zum Abschlag und Weg, hinten (+Y) zur Driving Range hinter dem Ballfangnetz.
# Hinter der Mauer liegt das Gelände auf Höhe der Mauerkrone.
#
# Erst die Texturen erzeugen:   node fence-banner.mjs
# Dann rendern:
#   /Applications/Blender.app/Contents/MacOS/Blender -b -P fence-banner-3d.py -- [--quick] [--only=abschlag]
# Ausgabe: out/bauzaun/3d/<ansicht>.png   (--only=export: GLB, Web-glTF und .blend)
import bpy, bmesh, math, os, random, sys
from mathutils import Vector

ARGS = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
QUICK = "--quick" in ARGS
ONLY = next((a.split("=")[1] for a in ARGS if a.startswith("--only=")), "")
HERE = os.path.dirname(os.path.abspath(__file__))
TEX = os.path.join(HERE, "out", "bauzaun", "tex")
OUT = os.path.join(HERE, "out", "bauzaun", "3d")
os.makedirs(OUT, exist_ok=True)

# Maße in m (z = 0: Weg vor der Mauer)
PW, PH = 3.40, 1.73          # Plane
WALL = 0.5                   # Mauerhöhe = Geländehöhe auf der Range-Seite
FZ0, FZ1 = WALL + 0.02, WALL + 1.85   # Unter-/Oberkante Doppelstabmatte (1,83 m)
PANEL = 2.5                  # Feldbreite
POSTS = [-3.75, -1.25, 1.25, 3.75]
PZ0 = WALL + 0.12            # Unterkante Plane → Oberkante ≈ Zaunkrone, QR-Mitte ≈ 1,49 m über dem Weg
GAP = 0.042                  # Abstand Plane–Zaunmitte (Pfosten 60 × 40 mm + Luft)


def reset(exposure=0.0):
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
    sc.cycles.samples = 48 if QUICK else 320
    sc.cycles.use_denoising = True
    try:
        sc.cycles.denoiser = "OPENIMAGEDENOISE"
    except Exception:
        pass
    sc.view_settings.view_transform = "Standard"   # Druckfarben farbtreu (Filmic macht Grün limettig)
    sc.view_settings.look = "None"
    sc.view_settings.exposure = exposure
    sc.render.image_settings.file_format = "PNG"
    sc.render.image_settings.color_mode = "RGB"
    random.seed(7)
    return sc


def mat(name, rgb, rough=0.6, metal=0.0, spec=0.3):
    m = bpy.data.materials.get(name)
    if m:
        return m
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (*rgb, 1)
    b.inputs["Roughness"].default_value = rough
    b.inputs["Metallic"].default_value = metal
    b.inputs["Specular"].default_value = spec
    return m


def banner_mat(name, img):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    bsdf = nt.nodes["Principled BSDF"]
    tex = nt.nodes.new("ShaderNodeTexImage")
    tex.image = bpy.data.images.load(img)
    tex.interpolation = "Cubic"
    tex.extension = "EXTEND"
    nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Roughness"].default_value = 0.42      # PVC-Plane: leicht glänzend
    bsdf.inputs["Specular"].default_value = 0.35
    # feines Gewebe der Plane als Bump
    noise = nt.nodes.new("ShaderNodeTexNoise")
    noise.inputs["Scale"].default_value = 900.0
    bump = nt.nodes.new("ShaderNodeBump")
    bump.inputs["Strength"].default_value = 0.03
    nt.links.new(noise.outputs["Fac"], bump.inputs["Height"])
    nt.links.new(bump.outputs["Normal"], bsdf.inputs["Normal"])
    return m


def link(ob):
    bpy.context.collection.objects.link(ob)
    return ob


def tube(name, a, b, r, material, verts=12):
    a, b = Vector(a), Vector(b)
    d = b - a
    bpy.ops.mesh.primitive_cylinder_add(vertices=verts, radius=r, depth=d.length, location=(a + b) / 2)
    ob = bpy.context.active_object
    ob.name = name
    ob.rotation_euler = d.to_track_quat("Z", "Y").to_euler()
    ob.data.materials.append(material)
    for p in ob.data.polygons:
        p.use_smooth = True
    return ob


def box(name, loc, size, material, bevel=0.0):
    bpy.ops.mesh.primitive_cube_add(location=loc)
    ob = bpy.context.active_object
    ob.name = name
    ob.scale = (size[0] / 2, size[1] / 2, size[2] / 2)
    ob.data.materials.append(material)
    if bevel:
        bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
        mod = ob.modifiers.new("Fase", "BEVEL")
        mod.width = bevel
        mod.segments = 3
    return ob


def join(objs, name):
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.object.join()
    ob = bpy.context.active_object
    ob.name = name
    return ob


def banner(side):
    """side 'abschlag' → Vorderseite (−Y), 'range' → Rückseite (+Y). UV so, dass das Motiv von seiner Seite richtig herum steht."""
    sgn = -1 if side == "abschlag" else 1
    bm = bmesh.new()
    uv = bm.loops.layers.uv.new()
    x0, x1 = -PW / 2, PW / 2
    z0, z1 = PZ0, PZ0 + PH
    y = sgn * GAP
    v = [bm.verts.new((x0, y, z0)), bm.verts.new((x1, y, z0)), bm.verts.new((x1, y, z1)), bm.verts.new((x0, y, z1))]
    f = bm.faces.new(v if sgn < 0 else list(reversed(v)))
    for loop in f.loops:
        co = loop.vert.co
        u = (co.x - x0) / PW
        loop[uv].uv = (u if sgn < 0 else 1 - u, (co.z - z0) / PH)
    me = bpy.data.meshes.new(f"Plane-{side}")
    bm.to_mesh(me)
    bm.free()
    ob = link(bpy.data.objects.new(f"Plane-{side}", me))
    me.materials.append(banner_mat(f"Motiv-{side}", os.path.join(TEX, f"{side}.png")))
    me.materials.append(mat("Planenrücken", (0.82, 0.82, 0.8), 0.5))
    sol = ob.modifiers.new("Dicke", "SOLIDIFY")
    sol.thickness = 0.0015
    sol.offset = 1
    sol.material_offset = 1
    sol.material_offset_rim = 1

    # 20 Ösen: oben/unten je 7, links/rechts je 3 dazwischen; Spanngummis zum Rahmen
    steel = mat("Öse", (0.8, 0.8, 0.78), 0.25, 1.0)
    rubber = mat("Spanngummi", (0.03, 0.03, 0.035), 0.55)
    inset = 0.025
    pts = []
    for i in range(7):
        x = x0 + inset + (PW - 2 * inset) * i / 6
        pts += [(x, z1 - inset, "o"), (x, z0 + inset, "u")]
    for j in range(1, 4):
        z = z0 + inset + (PH - 2 * inset) * j / 4
        pts += [(x0 + inset, z, "l"), (x1 - inset, z, "r")]
    parts = []
    ye = y + sgn * 0.002
    for x, z, k in pts:
        bpy.ops.mesh.primitive_torus_add(major_radius=0.011, minor_radius=0.0035, major_segments=20, minor_segments=8,
                                         location=(x, ye, z), rotation=(math.pi / 2, 0, 0))
        e = bpy.context.active_object
        e.data.materials.append(steel)
        parts.append(e)
        # Spanngummi/Kabelbinder geradewegs zur Doppelstabmatte (y = 0)
        parts.append(tube("Gummi", (x, ye, z), (x, 0, z), 0.0035, rubber, 8))
    join(parts, f"Ösen-{side}")
    return ob


def stone_mat():
    m = bpy.data.materials.new("Bruchstein")
    m.use_nodes = True
    nt = m.node_tree
    bsdf = nt.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (0.32, 0.31, 0.29, 1)   # Grundfarbe auch für den glTF-Export
    bsdf.inputs["Roughness"].default_value = 0.9
    coord = nt.nodes.new("ShaderNodeTexCoord")
    vor = nt.nodes.new("ShaderNodeTexVoronoi")
    vor.feature = "DISTANCE_TO_EDGE"
    vor.inputs["Scale"].default_value = 6.0
    nt.links.new(coord.outputs["Object"], vor.inputs["Vector"])
    col = nt.nodes.new("ShaderNodeTexVoronoi")
    col.inputs["Scale"].default_value = 6.0
    nt.links.new(coord.outputs["Object"], col.inputs["Vector"])
    ramp = nt.nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.elements[0].color = (0.16, 0.15, 0.14, 1)
    ramp.color_ramp.elements[1].color = (0.45, 0.43, 0.4, 1)
    nt.links.new(col.outputs["Color"], ramp.inputs["Fac"])
    fug = nt.nodes.new("ShaderNodeMath"); fug.operation = "LESS_THAN"; fug.inputs[1].default_value = 0.035
    nt.links.new(vor.outputs["Distance"], fug.inputs[0])
    mix = nt.nodes.new("ShaderNodeMixRGB")
    mix.inputs["Color2"].default_value = (0.06, 0.06, 0.055, 1)
    nt.links.new(fug.outputs[0], mix.inputs["Fac"])
    nt.links.new(ramp.outputs["Color"], mix.inputs["Color1"])
    nt.links.new(mix.outputs["Color"], bsdf.inputs["Base Color"])
    bump = nt.nodes.new("ShaderNodeBump")
    bump.inputs["Strength"].default_value = 0.6
    nt.links.new(vor.outputs["Distance"], bump.inputs["Height"])
    nt.links.new(bump.outputs["Normal"], bsdf.inputs["Normal"])
    return m


def wall(x0=-6.0, x1=4.4):
    st = stone_mat()
    w = box("Mauer", ((x0 + x1) / 2, 0.0, WALL / 2), (x1 - x0, 0.45, WALL), st, 0.02)
    cap = box("Mauerkrone", ((x0 + x1) / 2, 0.0, WALL + 0.01), (x1 - x0, 0.47, 0.03), mat("Krone", (0.22, 0.21, 0.2), 0.85), 0.01)
    return w


def fence():
    """Doppelstabmatte: senkrechte Stäbe alle 5 cm, waagerecht Doppelstäbe alle 20 cm, Pfosten 60 × 40 mm."""
    green = mat("RAL6005", (0.008, 0.055, 0.03), 0.5, 0.2)
    parts = []
    for x in POSTS:
        parts.append(box("Pfosten", (x, 0, (FZ0 + FZ1) / 2 + 0.02), (0.06, 0.04, FZ1 - WALL + 0.04), green))
    for a, b in zip(POSTS, POSTS[1:]):
        n = int(PANEL / 0.05)
        for i in range(1, n):
            x = a + PANEL * i / n
            parts.append(tube("Stab", (x, 0, FZ0), (x, 0, FZ1), 0.0025, green, 6))
        z = FZ0 + 0.04
        while z < FZ1:
            for dy in (-0.006, 0.006):
                parts.append(tube("Doppelstab", (a, dy, z), (b, dy, z), 0.003, green, 6))
            z += 0.2
    return join(parts, "Doppelstabmatte")


def element(wall_x=(-6.0, 4.4)):
    wall(*wall_x)
    fence()
    banner("abschlag")
    banner("range")


# ── Umgebung ─────────────────────────────────────────────────────────────────────────────
def grass_mat(name, c1, c2, stripe=3.0, bump=0.25):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    bsdf = nt.nodes["Principled BSDF"]
    coord = nt.nodes.new("ShaderNodeTexCoord")
    wave = nt.nodes.new("ShaderNodeTexWave")      # Mähstreifen
    wave.wave_type = "BANDS"
    wave.bands_direction = "X"
    wave.wave_profile = "SIN"
    wave.inputs["Scale"].default_value = 1.0 / (2 * stripe)
    nt.links.new(coord.outputs["Object"], wave.inputs["Vector"])
    ramp = nt.nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.elements[0].position = 0.3
    ramp.color_ramp.elements[1].position = 0.7
    ramp.color_ramp.elements[0].color = (*c1, 1)
    ramp.color_ramp.elements[1].color = (*c2, 1)
    nt.links.new(wave.outputs["Fac"], ramp.inputs["Fac"])
    noise = nt.nodes.new("ShaderNodeTexNoise")
    noise.inputs["Scale"].default_value = 0.6
    nt.links.new(coord.outputs["Object"], noise.inputs["Vector"])
    mix = nt.nodes.new("ShaderNodeMixRGB")
    mix.blend_type = "MULTIPLY"
    mix.inputs["Fac"].default_value = 0.25
    nt.links.new(ramp.outputs["Color"], mix.inputs["Color1"])
    nt.links.new(noise.outputs["Color"], mix.inputs["Color2"])
    nt.links.new(mix.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Roughness"].default_value = 0.95
    bsdf.inputs["Specular"].default_value = 0.15
    fine = nt.nodes.new("ShaderNodeTexNoise")
    fine.inputs["Scale"].default_value = 260.0
    nt.links.new(coord.outputs["Object"], fine.inputs["Vector"])
    bp = nt.nodes.new("ShaderNodeBump")
    bp.inputs["Strength"].default_value = bump
    nt.links.new(fine.outputs["Fac"], bp.inputs["Height"])
    nt.links.new(bp.outputs["Normal"], bsdf.inputs["Normal"])
    return m


def ground():
    bpy.ops.mesh.primitive_plane_add(size=600, location=(0, -300, 0))
    g = bpy.context.active_object
    g.name = "Rasen-vorne"
    g.data.materials.append(grass_mat("Rough", (0.045, 0.11, 0.025), (0.06, 0.135, 0.032), 4.0))
    # Gelände hinter der Mauer auf Höhe der Mauerkrone
    bpy.ops.mesh.primitive_plane_add(size=600, location=(0, 300.22, WALL))
    g2 = bpy.context.active_object
    g2.name = "Rasen-hinten"
    g2.data.materials.append(grass_mat("RangeGras", (0.05, 0.125, 0.03), (0.065, 0.15, 0.038), 5.0))
    # Weg entlang der Mauer
    box("Weg", (-1.0, -1.35, 0.005), (16, 2.2, 0.02), mat("Asphalt", (0.07, 0.07, 0.072), 0.8))
    # Abschlag: feiner gemäht, unterhalb des Wegs
    box("Abschlag", (2.5, -8.0, -0.02), (12, 9, 0.06), grass_mat("Tee", (0.05, 0.13, 0.03), (0.065, 0.16, 0.04), 1.2, 0.15), 0.03)
    # Hecke links
    hb = box("Hecke", (-7.2, -1.2, 1.5), (1.6, 2.2, 3.0), grass_mat("Laubhecke", (0.03, 0.08, 0.02), (0.035, 0.09, 0.025), 0.15, 0.9), 0.15)


def tee_markers():
    # Weiße Abschlagmarken wie im Foto (längliche Kunststoffmarken)
    white = mat("Teemarke", (0.85, 0.85, 0.82), 0.35)
    for x in (1.2, 4.6):
        bpy.ops.mesh.primitive_uv_sphere_add(radius=0.12, location=(x, -6.0, 0.02), segments=24, ring_count=12)
        s = bpy.context.active_object
        s.scale = (1.4, 0.8, 0.55)
        s.data.materials.append(white)
        for p in s.data.polygons:
            p.use_smooth = True
    # Grünes Infoschild vor dem Zaun links
    green = mat("Schildgrün", (0.02, 0.09, 0.05), 0.5)
    box("Infotafel", (-4.5, -0.6, 1.0), (1.0, 0.05, 1.4), green, 0.02)
    box("Tafelpfosten", (-3.95, -0.6, 0.8), (0.05, 0.05, 1.6), mat("Schwarz", (0.03, 0.03, 0.03), 0.4))


def net_mat():
    m = bpy.data.materials.new("Netz")
    m.use_nodes = True
    m.blend_method = "HASHED"
    nt = m.node_tree
    out = nt.nodes["Material Output"]
    bsdf = nt.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (0.02, 0.025, 0.02, 1)
    bsdf.inputs["Roughness"].default_value = 0.7
    coord = nt.nodes.new("ShaderNodeTexCoord")
    sep = nt.nodes.new("ShaderNodeSeparateXYZ")
    nt.links.new(coord.outputs["Object"], sep.inputs["Vector"])
    lines = []
    for comp in ("X", "Z"):
        sc = nt.nodes.new("ShaderNodeMath"); sc.operation = "MULTIPLY"; sc.inputs[1].default_value = 1 / 0.045  # 4,5 cm Masche
        nt.links.new(sep.outputs[comp], sc.inputs[0])
        fr = nt.nodes.new("ShaderNodeMath"); fr.operation = "FRACT"
        nt.links.new(sc.outputs[0], fr.inputs[0])
        lt = nt.nodes.new("ShaderNodeMath"); lt.operation = "LESS_THAN"; lt.inputs[1].default_value = 0.07
        nt.links.new(fr.outputs[0], lt.inputs[0])
        lines.append(lt)
    mx = nt.nodes.new("ShaderNodeMath"); mx.operation = "MAXIMUM"
    nt.links.new(lines[0].outputs[0], mx.inputs[0])
    nt.links.new(lines[1].outputs[0], mx.inputs[1])
    tr = nt.nodes.new("ShaderNodeBsdfTransparent")
    mix = nt.nodes.new("ShaderNodeMixShader")
    nt.links.new(mx.outputs[0], mix.inputs["Fac"])
    nt.links.new(tr.outputs[0], mix.inputs[1])
    nt.links.new(bsdf.outputs[0], mix.inputs[2])
    nt.links.new(mix.outputs[0], out.inputs["Surface"])
    return m


def range_net(y=3.2, h=6.0, length=40.0):
    """Ballfangnetz zwischen Zaun und Range – durch das Netz ist der QR-Code nicht erreichbar."""
    bpy.ops.mesh.primitive_plane_add(size=1, location=(0, y, WALL + h / 2), rotation=(math.pi / 2, 0, 0))
    n = bpy.context.active_object
    n.name = "Ballfangnetz"
    n.scale = (length, h, 1)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)  # Maschen nutzen Objektkoordinaten = Welt
    n.data.materials.append(net_mat())
    pole = mat("Mast", (0.35, 0.36, 0.36), 0.5, 0.8)
    x = -length / 2
    while x <= length / 2 + 0.01:
        tube("Mast", (x, y + 0.08, WALL), (x, y + 0.08, WALL + h + 0.1), 0.05, pole)
        x += 8.0
    tube("Seil", (-length / 2, y, WALL + h), (length / 2, y, WALL + h), 0.008, pole)


def range_extras(cam_y):
    # Distanzfahnen auf der Range
    for d, x, col in ((50, -6, (0.8, 0.05, 0.05)), (100, 4, (0.85, 0.7, 0.05)), (150, -2, (0.05, 0.25, 0.7))):
        y = 2.6 + d * 0.55
        tube("Fahnenstange", (x, y, WALL), (x, y, WALL + 2.2), 0.015, mat("Weiß", (0.9, 0.9, 0.88), 0.4))
        box("Fahne", (x + 0.25, y, WALL + 1.95), (0.5, 0.01, 0.35), mat(f"Fahne{d}", col, 0.6))
    return cam_y


def range_mat_and_balls(loc):
    x, y = loc
    box("Abschlagmatte", (x, y, 0.012), (1.5, 1.5, 0.025), grass_mat("Matte", (0.05, 0.22, 0.08), (0.06, 0.24, 0.09), 0.2, 0.6), 0.005)
    tube("Gummitee", (x + 0.2, y - 0.3, 0.02), (x + 0.2, y - 0.3, 0.06), 0.008, mat("Schwarz", (0.03, 0.03, 0.03), 0.4))
    box("Korb", (x - 0.55, y + 0.55, 0.12), (0.32, 0.32, 0.24), mat("Korbgrün", (0.04, 0.2, 0.08), 0.5), 0.02)
    white = mat("Ball", (0.92, 0.92, 0.9), 0.35)
    for i in range(14):
        bx = x - 0.55 + random.uniform(-0.12, 0.12)
        by = y + 0.55 + random.uniform(-0.12, 0.12)
        bpy.ops.mesh.primitive_uv_sphere_add(radius=0.0214, location=(bx, by, 0.245 + random.uniform(0, 0.03)), segments=16, ring_count=8)
        bpy.context.active_object.data.materials.append(white)
    for i in range(6):
        bpy.ops.mesh.primitive_uv_sphere_add(radius=0.0214, location=(x + random.uniform(-0.6, 0.6), y + random.uniform(-0.6, 0.2), 0.045), segments=16, ring_count=8)
        bpy.context.active_object.data.materials.append(white)


def trees(exclude_range=True):
    trunk = mat("Stamm", (0.12, 0.08, 0.05), 0.9)
    leaves = [mat(f"Laub{i}", c, 0.85) for i, c in enumerate([(0.05, 0.14, 0.04), (0.07, 0.17, 0.05), (0.04, 0.11, 0.035)])]
    for i in range(70):
        a = random.uniform(0, 2 * math.pi)
        r = random.uniform(32, 90)
        x, y = r * math.cos(a), r * math.sin(a)
        if exclude_range and abs(x) < 34 and y > 0:
            y = 115 + random.uniform(0, 30)   # hinter der Range
        h = random.uniform(9, 17)
        tube("Stamm", (x, y, 0), (x, y, h * 0.45), 0.25, trunk, 8)
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=3, radius=h * 0.32, location=(x, y, h * 0.62))
        c = bpy.context.active_object
        c.scale = (1, 1, random.uniform(1.1, 1.5))
        c.data.materials.append(random.choice(leaves))
        for p in c.data.polygons:
            p.use_smooth = True


def sky(sun_elev=38, sun_rot=215, strength=0.22, sun=3.2):
    w = bpy.data.worlds.new("Himmel")
    w.use_nodes = True
    nt = w.node_tree
    bg = nt.nodes["Background"]
    s = nt.nodes.new("ShaderNodeTexSky")
    s.sky_type = "NISHITA"
    s.sun_elevation = math.radians(sun_elev)
    s.sun_rotation = math.radians(sun_rot)
    s.sun_disc = False
    s.air_density = 1.2
    s.dust_density = 1.6
    nt.links.new(s.outputs["Color"], bg.inputs["Color"])
    bg.inputs["Strength"].default_value = strength
    bpy.context.scene.world = w
    ld = bpy.data.lights.new("Sonne", "SUN")
    ld.energy = sun
    ld.angle = math.radians(1.2)
    ld.color = (1.0, 0.96, 0.88)
    ob = link(bpy.data.objects.new("Sonne", ld))
    # Sonnenrichtung passend zum Himmel
    el, rot = math.radians(sun_elev), math.radians(sun_rot)
    d = Vector((math.sin(rot) * math.cos(el), math.cos(rot) * math.cos(el), math.sin(el)))
    ob.rotation_euler = (-d).to_track_quat("-Z", "Y").to_euler()


def camera(loc, target, lens, res=(2400, 1350), dof=None):
    cd = bpy.data.cameras.new("Kamera")
    cd.lens = lens
    cd.sensor_width = 36
    if dof:
        cd.dof.use_dof = True
        cd.dof.focus_distance = (Vector(target) - Vector(loc)).length
        cd.dof.aperture_fstop = dof
    ob = link(bpy.data.objects.new("Kamera", cd))
    ob.location = loc
    ob.rotation_euler = (Vector(target) - Vector(loc)).to_track_quat("-Z", "Y").to_euler()
    sc = bpy.context.scene
    sc.camera = ob
    sc.render.resolution_x, sc.render.resolution_y = res
    sc.render.resolution_percentage = 50 if QUICK else 100
    return ob


def render(name):
    bpy.context.scene.render.filepath = os.path.join(OUT, f"{name}.png")
    bpy.ops.render.render(write_still=True)
    print("OK ->", name)


def world_scene():
    ground()
    element()
    tee_markers()
    range_net()
    range_extras(0)
    trees()


# ── Ansichten ────────────────────────────────────────────────────────────────────────────
def scene_abschlag():
    # Vom Abschlag hoch zum Zaun auf der Mauer: wartende Spieler sehen die Vorderseite
    reset()
    world_scene()
    sky(sun_elev=34, sun_rot=200)
    camera((4.2, -10.5, 1.65), (0.3, 0, 1.45), 32)
    render("01-abschlag")


def scene_nah():
    # Vom Weg an der Mauer: QR auf Augenhöhe (Mitte ≈ 1,49 m über dem Weg)
    reset()
    world_scene()
    sky(sun_elev=34, sun_rot=200)
    camera((0.9, -1.75, 1.65), (1.0, 0, 1.45), 30, (1600, 2000), dof=4.0)
    render("02-qr-nah")


def scene_range():
    # Von der Range (≈ 24 m) durchs Ballfangnetz
    reset()
    world_scene()
    sky(sun_elev=34, sun_rot=200)
    camera((3.0, 24.0, WALL + 1.6), (0.0, 0.0, 1.5), 75)
    render("03-range-fern")


def scene_range_nah():
    # Direkt am Ballfangnetz: näher kommt man von der Range nicht heran
    reset()
    world_scene()
    sky(sun_elev=34, sun_rot=200)
    white = mat("Ball", (0.92, 0.92, 0.9), 0.35)
    for i in range(18):
        bpy.ops.mesh.primitive_uv_sphere_add(radius=0.0214, location=(random.uniform(-3, 4), random.uniform(3.35, 7.5), WALL + 0.02), segments=16, ring_count=8)
        bpy.context.active_object.data.materials.append(white)
    camera((2.6, 8.8, WALL + 1.6), (0.2, 0, 1.5), 32)
    render("05-range-am-netz")


def scene_aufbau():
    # Schräg von der Seite: zwei Planen umschließen die Doppelstabmatte, Ösen und Spanngummis
    reset()
    world_scene()
    sky(sun_elev=34, sun_rot=200)
    camera((3.6, -1.9, 2.1), (1.2, 0.05, 1.45), 30)
    render("04-aufbau-seitlich")


def scene_export():
    def gltf(name):
        common = dict(export_apply=True, export_image_format="JPEG", export_cameras=False, export_lights=False)
        bpy.ops.export_scene.gltf(filepath=os.path.join(OUT, f"{name}.glb"), export_format="GLB", **common)
        web = os.path.join(OUT, "web")
        os.makedirs(web, exist_ok=True)
        bpy.ops.export_scene.gltf(filepath=os.path.join(web, f"{name}.gltf"), export_format="GLTF_EMBEDDED", **common)
        os.replace(os.path.join(web, f"{name}.gltf"), os.path.join(web, f"{name}.gltf.json"))
        print("OK ->", name)

    # Web: Texturen auf 4096 px (WebGL-Grenze), Text bleibt nah gut lesbar
    global TEX
    full = TEX
    small = os.path.join(OUT, "tex-web")
    os.makedirs(small, exist_ok=True)
    for s in ("abschlag", "range"):
        os.system(f'sips -Z 4096 "{os.path.join(full, s + ".png")}" --out "{os.path.join(small, s + ".png")}" >/dev/null')
    TEX = small
    reset()
    element(wall_x=(-3.85, 3.85))   # Web-Modell: Mauer nur so lang wie die drei Zaunfelder
    # Prozedurales Mauerwerk übersteht den glTF-Export nicht (käme weiß an) → schlichtes Steingrau
    grey = mat("MauerExport", (0.3, 0.29, 0.27), 0.9)
    for ob in bpy.data.objects:
        if ob.name.startswith("Mauer"):
            ob.data.materials.clear()
            ob.data.materials.append(grey)
    gltf("GolfTrack-Bauzaun")
    TEX = full
    # Blender-Datei mit der kompletten Abschlag-Szene
    reset()
    world_scene()
    sky(sun_elev=34, sun_rot=200)
    camera((-3.6, -10.5, 1.62), (0.15, 0, 1.15), 32)
    bpy.ops.file.pack_all()
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT, "GolfTrack-Bauzaun.blend"), compress=True)
    print("OK -> blend")


SCENES = {"abschlag": scene_abschlag, "nah": scene_nah, "range": scene_range, "aufbau": scene_aufbau, "rangenah": scene_range_nah, "export": scene_export}
for k, fn in SCENES.items():
    if ONLY == k or (not ONLY and k != "export"):
        fn()
