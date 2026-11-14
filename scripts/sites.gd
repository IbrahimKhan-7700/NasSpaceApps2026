class_name Sites
extends RefCounted
## Builds every landmark from primitives. Replace any of these with Blender glTF models later.

static func gy(x: float, z: float) -> float:
	return WorldData.height_at(x, z)

static func build_all(main: Node3D) -> void:
	_rocks(main)
	_base(main)
	_greenhouse(main)
	_ship(main)
	_anomaly(main)
	_hollow(main)
	_pads(main)
	_ridge(main)
	_rover(main)
	_spring(main)

# ---------------------------------------------------------------- rocks
static func _rocks(main: Node3D) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 1.6
	mesh.radial_segments = 6
	mesh.rings = 3
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.roughness = 1.0
	var cols := [Color("#6b2f1b"), Color("#7d3b22"), Color("#4f2a22"), Color("#8a4a2c"), Color("#5a3a33"), Color("#98583a")]
	var keep_out := [[Vector2(0, 0), 16.0], [Vector2(64, -46), 26.0], [Vector2(-80, 37), 44.0], [Vector2(-44, -98), 26.0],
		[Vector2(98, 62), 34.0], [Vector2(26, 16), 14.0], [Vector2(116, -16), 16.0], [Vector2(-22, -132), 20.0], [Vector2(-58, 54), 16.0], [Vector2(-48, -18), 8.0]]
	var spots: Array = []
	for t in 3000:
		var a := rng.randf() * TAU
		var r := sqrt(rng.randf()) * WorldData.WORLD_R
		var p := Vector2(cos(a), sin(a)) * r
		var ok := true
		for k in keep_out:
			if p.distance_to(k[0]) < k[1]:
				ok = false
				break
		if ok and WorldData.seg_dist(p, WorldData.GOUGE_A, WorldData.GOUGE_B) < 5.0:
			ok = false
		if ok:
			spots.append(p)
		if spots.size() >= 560:
			break
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh
	mm.instance_count = spots.size()
	var body := StaticBody3D.new()
	main.add_child(body)
	for i in spots.size():
		var p: Vector2 = spots[i]
		var big := i % 12 == 0
		var s := rng.randf_range(1.6, 4.2) if big else pow(rng.randf(), 2.2) * 1.1 + 0.18
		var b := Basis.from_euler(Vector3(0, rng.randf() * TAU, 0))
		b = b.scaled(Vector3(s * rng.randf_range(0.9, 1.5), s * rng.randf_range(0.6, 1.0), s * rng.randf_range(0.9, 1.4)))
		mm.set_instance_transform(i, Transform3D(b, Vector3(p.x, gy(p.x, p.y) + s * 0.12, p.y)))
		mm.set_instance_color(i, cols[i % cols.size()])
		if big:
			Util.collider_sphere(body, s * 0.8, Vector3(p.x, gy(p.x, p.y) + s * 0.3, p.y))
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = m
	main.add_child(mmi)

# ---------------------------------------------------------------- base camp
static func _base(main: Node3D) -> void:
	var g := Node3D.new()
	g.position = Vector3(0, gy(0, 0), 0)
	main.add_child(g)
	var hull := Util.mat(Color("#dcd8cf"), 0.55, 0.35)
	var dark := Util.mat(Color("#1d1c20"), 0.7, 0.3)
	var metal := Util.mat(Color("#6f7177"), 0.45, 0.7)
	var amber := Util.glow(Color("#ffb347"), 2.0)
	main.nightglow.append(amber)
	var col := StaticBody3D.new()
	g.add_child(col)
	Util.sph(g, 4.6, hull, Vector3(-7, 0, -6), Vector3.ONE, 28, true)
	Util.cyl(g, 4.8, 4.9, 0.5, dark, Vector3(-7, 0.25, -6), Vector3.ZERO, 28)
	Util.box(g, Vector3(1.8, 2.5, 0.4), amber, Vector3(-7, 1.25, -1.55))
	for i in 6:
		var a := -0.9 + i * 0.36 + 1.6
		Util.box(g, Vector3(0.8, 0.5, 0.1), amber, Vector3(-7 + cos(a) * 4.1, 2.7, -6 + sin(a) * 4.1), Vector3(0, rad_to_deg(-a + PI / 2), 0))
	Util.cyl(g, 1.8, 1.8, 8.4, hull, Vector3(1.2, 1.8, -6), Vector3(0, 0, 90), 20)
	Util.cyl(g, 0.5, 0.5, 0.6, metal, Vector3(1.2, 3.7, -6), Vector3.ZERO, 10)
	Util.collider_cyl(col, 5.0, 6.0, Vector3(-7, 3, -6))
	Util.collider_box(col, Vector3(8.4, 4, 3.8), Vector3(1.2, 2, -6))
	var panel := Util.mat(Color("#14234a"), 0.35, 0.6)
	for i in 5:
		var x := 9.0 + i * 3.8
		Util.cyl(g, 0.1, 0.1, 1.4, metal, Vector3(x, 0.7, -11), Vector3.ZERO, 6)
		Util.box(g, Vector3(3.4, 0.08, 2.2), panel, Vector3(x, 1.5, -11), Vector3(-32, 0, 0))
	# comms tower
	var tx := -14.0
	var tz := 7.0
	var lv := 6
	var rings: Array = []
	for i in lv + 1:
		var w := 1.3 - i * 0.14
		var y := i * 2.3
		rings.append([Vector3(tx - w, y, tz - w), Vector3(tx + w, y, tz - w), Vector3(tx + w, y, tz + w), Vector3(tx - w, y, tz + w)])
	for i in lv:
		for k in 4:
			Util.strut(g, rings[i][k], rings[i + 1][k], 0.07, metal)
			Util.strut(g, rings[i][k], rings[i][(k + 1) % 4], 0.04, metal)
			Util.strut(g, rings[i][k], rings[i + 1][(k + 1) % 4], 0.035, metal)
	Util.sph(g, 1.3, Util.mat(Color("#e9e5da"), 0.7), Vector3(tx, 14.4, tz), Vector3.ONE, 16, true).rotation_degrees = Vector3(-50, 20, 0)
	var bm := Util.glow(Color("#ff2a1a"), 3.0)
	Util.sph(g, 0.28, bm, Vector3(tx, 15.9, tz), Vector3.ONE, 8)
	main.anims.append(func(t: float, _dt: float): bm.emission_energy_multiplier = 4.0 if sin(t * 3.0) > 0.5 else 0.3)
	Util.collider_cyl(col, 1.7, 14.0, Vector3(tx, 7, tz))
	# crates
	var rust := Util.mat(Color("#8a4426"), 0.9, 0.2)
	var orange := Util.mat(Color("#e0541a"), 0.6)
	for c in [[5.0, 6.5, 1.4], [7.1, 5.6, 1.1], [5.4, 8.9, 1.2], [-2.0, 12.0, 1.3], [11.0, 3.0, 1.0]]:
		var s: float = c[2]
		Util.box(g, Vector3(s * 1.4, s, s * 1.1), rust if int(c[0]) % 2 == 0 else metal, Vector3(c[0], s / 2, c[1]), Vector3(0, c[0] * 23.0, 0))
		Util.box(g, Vector3(s * 1.42, 0.12, s * 1.12), orange, Vector3(c[0], s * 0.55, c[1]), Vector3(0, c[0] * 23.0, 0))
		Util.collider_box(col, Vector3(s * 1.4, s, s * 1.1), Vector3(c[0], s / 2, c[1]), deg_to_rad(c[0] * 23.0))
	for c in [Vector2(-3, 10), Vector2(-4.2, 10.8), Vector2(13, -3)]:
		Util.cyl(g, 0.5, 0.5, 1.2, orange, Vector3(c.x, 0.6, c.y), Vector3.ZERO, 12)
		Util.collider_cyl(col, 0.55, 1.2, Vector3(c.x, 0.6, c.y))
	# landing circle
	var ring := Util.torus(g, 3.3, 3.5, Util.mat(Color("#f0e6d6"), 0.9), Vector3(8, 0.06, 9), Vector3.ZERO, false)
	ring.scale = Vector3(1, 0.1, 1)
	main.add_interact(Vector3(-7, 0, -1), 3.6, "Refill suit oxygen", func(): 
		main.o2 = minf(100.0, main.o2 + 25.0)
		main.toast("[b]Hab air[/b]  Suit oxygen topped up."), func(): return main.o2 < 95.0)

# ---------------------------------------------------------------- greenhouse
static func _greenhouse(main: Node3D) -> void:
	var C := WorldData.GH
	var y0 := gy(C.x, C.y)
	var g := Node3D.new()
	g.position = Vector3(C.x, y0, C.y)
	main.add_child(g)
	var col := StaticBody3D.new()
	col.position = g.position
	main.add_child(col)
	var metal := Util.mat(Color("#6f7177"), 0.45, 0.7)
	var conc := Util.mat(Color("#9a9187"), 0.95)
	var hullm := Util.mat(Color("#dcd8cf"), 0.55, 0.35)
	var dark := Util.mat(Color("#1d1c20"), 0.7, 0.3)
	var glass := Util.mat(Color("#9defe0"), 0.08, 0.1, Color.BLACK, 0.0, 0.2)
	glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	var soil := Util.mat(Color("#3a1f15"), 1.0)
	var sand := Util.mat(Color("#c07a4a"), 1.0)
	var R := 5.0
	var BL := 2.0
	var vault := Node3D.new()
	vault.scale = Vector3(1, 0.85, 1)
	g.add_child(vault)
	Util.box(g, Vector3(22.4, 0.1, 10.4), conc, Vector3(0, 0.05, 0))
	for i in 12:
		Util.torus(vault, R - 0.08, R + 0.06, metal, Vector3(-11 + i * BL, 0, 0), Vector3(0, 0, 90), false)
	Util.box(vault, Vector3(22, 0.14, 0.14), metal, Vector3(0, R, 0))
	var broken := [3, 8]
	for i in 11:
		var x := -10.0 + i * BL
		if i in broken:
			var sgn := -1.0 if i == 3 else 1.0
			Util.sph(g, 1.8, sand, Vector3(x, 0.1, sgn * 3.5), Vector3(1.3, 0.22, 1.0), 10)
			for k in 4:
				Util.box(g, Vector3(0.6 + k * 0.1, 0.03, 0.55), glass, Vector3(x + k * 0.4 - 0.7, 0.14 + k * 0.01, sgn * (3.2 + k * 0.3)), Vector3(k * 4, k * 40, k * 3))
			continue
		var cm := CylinderMesh.new()
		cm.top_radius = R
		cm.bottom_radius = R
		cm.height = BL - 0.06
		cm.radial_segments = 20
		cm.rings = 1
		cm.cap_top = false
		cm.cap_bottom = false
		Util.add(vault, cm, glass, Vector3(x, 0, 0), Vector3(0, 0, 90), false)
	# back wall (glass disc) and front wall with a doorway
	var back := CylinderMesh.new()
	back.top_radius = R
	back.bottom_radius = R
	back.height = 0.05
	back.radial_segments = 24
	Util.add(vault, back, glass, Vector3(11, 0, 0), Vector3(0, 0, 90), false)
	for s in [-1, 1]:
		Util.box(g, Vector3(0.4, 3.6, 3.0), hullm, Vector3(-11, 1.8, s * 3.5))
		Util.box(g, Vector3(0.4, 3.2, 0.3), metal, Vector3(-11.1, 1.6, s * 2.05))
	Util.box(g, Vector3(0.4, 1.4, 4.4), hullm, Vector3(-11, 3.9, 0))
	var sign := Label3D.new()
	sign.text = "GARDEN OF HOPE"
	sign.font_size = 96
	sign.pixel_size = 0.0075
	sign.modulate = Color("#ffe9c7")
	sign.outline_modulate = Color("#10261c")
	sign.outline_size = 24
	sign.position = Vector3(-11.4, 4.9, 0)
	sign.rotation.y = -PI / 2
	g.add_child(sign)
	# grow lights
	var pink := Util.glow(Color("#ff5fd8"), 2.8)
	main.nightglow.append(pink)
	for z in [-2.9, 2.9]:
		Util.box(g, Vector3(19, 0.1, 0.28), pink, Vector3(0, 3.45, z))
	for x in [-6.5, 0.0, 6.5]:
		var l := OmniLight3D.new()
		l.light_color = Color("#ff7fe0")
		l.light_energy = 1.6
		l.omni_range = 14.0
		l.position = Vector3(x, 3.2, 0)
		g.add_child(l)
	var warm := OmniLight3D.new()
	warm.light_color = Color("#ffe0b0")
	warm.light_energy = 0.8
	warm.omni_range = 12.0
	warm.position = Vector3(-8, 3.0, 0)
	g.add_child(warm)
	# beds and plants
	var leaf := Util.mat(Color("#3f9a4a"), 0.8)
	var leaf2 := Util.mat(Color("#76c95c"), 0.8)
	var fruit := Util.mat(Color("#d6301d"), 0.35)
	var corn := Util.mat(Color("#e8c64a"), 0.7)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for row in 2:
		var z := -2.9 if row == 0 else 2.9
		Util.box(g, Vector3(19, 0.55, 1.9), soil, Vector3(0, 0.32, z))
		Util.box(g, Vector3(19.3, 0.12, 2.1), metal, Vector3(0, 0.62, z))
		Util.collider_box(col, Vector3(19.3, 1.2, 2.1), Vector3(0, 0.6, z))
		for i in 8:
			var x := -8.2 + i * 2.35
			var kind := (i + row) % 3
			var p := Node3D.new()
			p.position = Vector3(x, 0.6, z + rng.randf_range(-0.3, 0.3))
			p.scale = Vector3.ONE * rng.randf_range(0.9, 1.25)
			g.add_child(p)
			if kind == 0:
				Util.cyl(p, 0.04, 0.05, 0.5, leaf, Vector3(0, 0.25, 0), Vector3.ZERO, 5)
				for k in 6:
					Util.sph(p, 0.22, leaf if k % 2 == 0 else leaf2, Vector3(rng.randf_range(-0.18, 0.18), 0.4 + rng.randf() * 0.35, rng.randf_range(-0.18, 0.18)), Vector3(1, 0.6, 1), 8)
				var fr := Node3D.new()
				p.add_child(fr)
				for k in 4:
					Util.sph(fr, 0.085, fruit, Vector3(rng.randf_range(-0.22, 0.22), 0.35 + rng.randf() * 0.3, rng.randf_range(-0.22, 0.22)), Vector3.ONE, 10)
				var wp := g.position + p.position
				var plant := {"fruit": fr, "ready": true, "t": 0.0}
				main.plants.append(plant)
				main.add_interact(wp, 2.5, "Harvest tomatoes", func():
					plant.ready = false
					plant.fruit.visible = false
					plant.t = 70.0
					main.harvest += 1
					main.o2 = minf(100.0, main.o2 + 4.0)
					main.toast("[b]+1 harvest[/b]  Tomatoes on Mars. Oxygen +4%.")
					main.check_goals()
					main.thought_now("harvest"), func(): return plant.ready)
			elif kind == 1:
				for k in 7:
					Util.sph(p, 0.2, leaf2 if k % 2 == 0 else leaf, Vector3(cos(k) * 0.16, 0.14, sin(k) * 0.16), Vector3(1, 0.4, 1), 8)
			else:
				for k in 3:
					var ox := rng.randf_range(-0.15, 0.15)
					var oz := rng.randf_range(-0.15, 0.15)
					Util.cyl(p, 0.025, 0.035, 1.3, leaf, Vector3(ox, 0.65, oz), Vector3.ZERO, 5)
					Util.cyl(p, 0.05, 0.04, 0.28, corn, Vector3(ox, 1.1, oz), Vector3.ZERO, 6)
	# tanks, pipes, terminal
	for i in 3:
		var tx := 14.0 + i * 2.8
		var tz := -3.0 + (i % 2) * 2.0
		Util.cyl(g, 1.3, 1.3, 3.4, Util.mat(Color("#e9e5da"), 0.7), Vector3(tx, 1.7, tz), Vector3.ZERO, 20)
		Util.collider_cyl(col, 1.4, 3.4, Vector3(tx, 1.7, tz))
	Util.strut(g, Vector3(11.5, 1, -1), Vector3(14, 1, -3), 0.12, metal)
	Util.strut(g, Vector3(11.5, 2.6, 0), Vector3(16, 3.2, -1.2), 0.1, metal)
	Util.box(g, Vector3(0.5, 1.2, 0.9), dark, Vector3(9.4, 0.6, -0.3))
	var scr := Util.glow(Color("#7dff9a"), 2.0)
	Util.box(g, Vector3(0.04, 0.5, 0.7), scr, Vector3(9.12, 1.1, -0.3))
	Util.collider_box(col, Vector3(0.6, 1.2, 1.0), Vector3(9.4, 0.6, -0.3))
	main.add_interact(g.position + Vector3(8.2, 0, -0.3), 2.2, "Read crop terminal", func():
		main.toast("[b]Crop log[/b]  Day 41. Water recycler 71%. Last watering: 4 hours ago. Vega, you are not the only one here."))
	# walls
	Util.collider_box(col, Vector3(22.8, 3.0, 0.4), Vector3(0, 1.5, -5.05))
	Util.collider_box(col, Vector3(22.8, 3.0, 0.4), Vector3(0, 1.5, 5.05))
	Util.collider_box(col, Vector3(0.5, 3.0, 10.4), Vector3(11.1, 1.5, 0))
	Util.collider_box(col, Vector3(0.5, 3.0, 3.0), Vector3(-11.1, 1.5, -3.5))
	Util.collider_box(col, Vector3(0.5, 3.0, 3.0), Vector3(-11.1, 1.5, 3.5))

# ---------------------------------------------------------------- crashed ship
static func _ship(main: Node3D) -> void:
	var S := WorldData.SHIP
	var a := WorldData.SHIP_ANGLE
	var R := 4.4
	var BAYS := 9
	var BL := 1.9
	var rng := RandomNumberGenerator.new()
	rng.seed = 12
	var g := Node3D.new()
	g.position = Vector3(S.x, gy(S.x, S.y) - 0.2, S.y)
	g.rotation = Vector3(0.05, -a, -0.07)
	main.add_child(g)
	var hull := Util.mat(Color("#dcd8cf"), 0.55, 0.35)
	var burnt := Util.mat(Color("#3a322e"), 0.8, 0.3)
	hull.cull_mode = BaseMaterial3D.CULL_DISABLED
	burnt.cull_mode = BaseMaterial3D.CULL_DISABLED
	main.ship_mats = [hull, burnt]
	var metal := Util.mat(Color("#6f7177"), 0.45, 0.7)
	var cable := Util.mat(Color("#101012"), 0.5)
	var red := Util.glow(Color("#ff3a2a"), 2.4)
	var amber := Util.glow(Color("#ffb347"), 2.2)
	main.nightglow.append(red)
	# hull plates with tears
	for i in BAYS:
		var x := (i - (BAYS - 1) / 2.0) * BL
		var arcs: Array
		var torn := 2 if i >= 7 else (1 if i <= 1 else (1 if rng.randf() < 0.3 else 0))
		if i == BAYS - 1:
			arcs = [[0.0, 0.28 * PI], [0.82 * PI, 0.18 * PI]]
		elif torn == 0:
			arcs = [[0.0, PI]]
		else:
			var g0 := rng.randf_range(0.25, 0.6) * PI
			var gl := (rng.randf_range(0.5, 0.8) if torn == 2 else rng.randf_range(0.2, 0.42)) * PI
			arcs = [[0.0, g0]]
			var s2 := g0 + gl
			if PI - s2 > 0.06:
				arcs.append([s2, PI - s2])
		for k in arcs.size():
			var ar: Array = arcs[k]
			var burnt_plate := i < 2 or (i + k) % 4 == 3
			Util.add(g, Util.arc_mesh(R, x - BL / 2.0 + 0.025, x + BL / 2.0 - 0.025, ar[0], ar[0] + ar[1], 10), burnt if burnt_plate else hull)
		if torn > 0:
			for f in (2 if torn == 2 else 1):
				var th := rng.randf_range(0.2, 0.9) * PI
				Util.box(g, Vector3(BL * 0.75, 0.07, rng.randf_range(1.0, 1.8)), hull, Vector3(x, R * sin(th) * 1.04, R * cos(th) * 1.04), Vector3(rad_to_deg(-th) + (1 if rng.randf() < 0.5 else -1) * rng.randf_range(35, 70), rng.randf_range(-15, 15), 0))
	for i in BAYS + 1:
		Util.add(g, Util.arc_mesh(R - 0.05, (i - BAYS / 2.0) * BL - 0.07, (i - BAYS / 2.0) * BL + 0.07, 0.0, PI, 14), metal)
	# mission lettering
	var lab := Label3D.new()
	lab.text = "ARES-7"
	lab.font_size = 90
	lab.pixel_size = 0.014
	lab.modulate = Color("#1a1a1d")
	lab.double_sided = true
	var th2 := 0.5
	lab.position = Vector3(-3, R * sin(th2) * 1.02, R * cos(th2) * 1.02)
	lab.rotation.x = -th2 - PI / 2.0 * 0.0
	lab.rotation = Vector3(-th2, 0, 0)
	g.add_child(lab)
	Util.box(g, Vector3(17, 0.12, 0.04), Util.mat(Color("#e0541a"), 0.6), Vector3(0, R * sin(0.28) * 1.005, R * cos(0.28) * 1.005), Vector3(rad_to_deg(-0.28), 0, 0))
	# rear bulkhead and engines
	Util.add(g, Util.half_disc(R, -8.6, 24), burnt)
	for e in [[-10.2, 1.5, -1.8], [-10.2, 1.5, 1.8], [-10.0, 3.1, 0.0]]:
		Util.cyl(g, 0.55, 1.2, 2.8, burnt, Vector3(e[0], e[1], e[2]), Vector3(0, 0, -90), 14)
		Util.torus(g, 1.1, 1.3, metal, Vector3(e[0] - 1.4, e[1], e[2]), Vector3(0, 0, 90), false)
	Util.cyl(g, 0.55, 1.2, 2.8, burnt, Vector3(-12.5, 0.7, 6.5), Vector3(20, 40, 30), 14)
	# broken tail fin
	Util.box(g, Vector3(4.0, 4.6, 0.25), hull, Vector3(-8.0, R + 1.6, 0), Vector3(0, 0, 25))
	# interior
	for i in 5:
		var c := Util.box(g, Vector3(rng.randf_range(0.9, 1.5), rng.randf_range(0.8, 1.2), rng.randf_range(0.9, 1.4)), metal if i % 2 == 0 else Util.mat(Color("#8a4426"), 0.9), Vector3(rng.randf_range(-6, 3), 0.5, rng.randf_range(-2.6, 2.6)), Vector3(rng.randf_range(-10, 10), rng.randf() * 360, rng.randf_range(-12, 12)))
	for i in 6:
		var an := rng.randf_range(0.25, 0.75) * PI
		var x := rng.randf_range(-7, 6)
		var p0 := Vector3(x, R * sin(an) - 0.2, R * cos(an) - 0.2)
		var p1 := p0 + Vector3(rng.randf_range(-0.6, 0.6), -rng.randf_range(1.0, 2.4), rng.randf_range(-0.6, 0.6))
		Util.strut(g, p0, p1, 0.03, cable)
		Util.sph(g, 0.05, amber if i % 2 == 0 else red, p1, Vector3.ONE, 6)
	for sp in [[-6.0, -2.8], [-4.3, 2.9], [-1.8, -3.0]]:
		Util.box(g, Vector3(0.9, 0.15, 0.8), Util.mat(Color("#1d1c20"), 0.7), Vector3(sp[0], 0.9, sp[1]))
		Util.box(g, Vector3(0.9, 1.0, 0.12), Util.mat(Color("#1d1c20"), 0.7), Vector3(sp[0], 1.4, sp[1] + (0.35 if sp[1] > 0 else -0.35)))
	# buried-edge mounds
	var sand := Util.mat(Color("#c07a4a"), 1.0)
	for i in 9:
		for s in [-1, 1]:
			Util.sph(g, 1.7, sand, Vector3((i - 4) * BL * 1.05, -0.25, s * (R + 0.2)), Vector3(1.2, 0.55, 1.0), 8)
	# flight recorder
	var bb := Node3D.new()
	bb.position = Vector3(1.5, 0.25, 1.2)
	g.add_child(bb)
	Util.box(bb, Vector3(0.6, 0.4, 0.4), Util.mat(Color("#e0541a"), 0.5), Vector3.ZERO)
	Util.box(bb, Vector3(0.62, 0.1, 0.42), Util.mat(Color("#e9e5da"), 0.6), Vector3(0, 0.05, 0))
	var bl := Util.sph(bb, 0.06, red, Vector3(0, 0.3, 0), Vector3.ONE, 6)
	main.anims.append(func(t: float, _dt: float):
		bl.visible = (not main.recorder) and sin(t * 5.0) > 0.0
		bb.visible = not main.recorder)
	g.force_update_transform()
	var bw := g.to_global(bb.position)
	main.add_interact(Vector3(bw.x, 0, bw.z), 2.6, "Recover the flight recorder", func():
		main.recorder = true
		main.toast("[b]Flight recorder recovered[/b]  Final log: \"...hull breach, all hands to the lifeboat, I repeat...\"")
		main.check_goals()
		main.thought_now("recorder"), func(): return not main.recorder)
	var il := OmniLight3D.new()
	il.light_color = Color("#ff3a2a")
	il.light_energy = 2.0
	il.omni_range = 16.0
	il.position = Vector3(0, 3, 0)
	g.add_child(il)
	main.anims.append(func(t: float, _dt: float): il.light_energy = 2.0 if sin(t * 3.0) > 0.0 else 0.4)
	# colliders (side walls and rear), rotated with the ship's heading
	var col := StaticBody3D.new()
	col.position = Vector3(S.x, 0, S.y)
	col.rotation.y = -a
	main.add_child(col)
	for s in [-1, 1]:
		Util.collider_box(col, Vector3(17.0, 12.0, 1.0), Vector3(0, 6, s * (R - 0.35)))
	Util.collider_box(col, Vector3(1.0, 12.0, 8.8), Vector3(-8.7, 6, 0))
	Util.collider_box(col, Vector3(4.0, 12.0, 6.8), Vector3(-12, 6, 0))
	main.ship_center = S
	# cockpit section lying on its side
	var dir := Vector2(cos(a), sin(a))
	var per := Vector2(-sin(a), cos(a))
	var cp := S + dir * 26.0 + per * 9.0
	var cg := Node3D.new()
	cg.position = Vector3(cp.x, gy(cp.x, cp.y) + 0.4, cp.y)
	cg.rotation = Vector3(0.9, -(a + 0.7), -0.25)
	main.add_child(cg)
	Util.cyl(cg, 0.9, 3.7, 8.5, hull, Vector3.ZERO, Vector3(0, 0, -90), 20)
	Util.sph(cg, 0.9, Util.mat(Color("#0b1118"), 0.12, 0.9, Color("#0a2a38"), 0.5), Vector3(3.0, 0.2, 1.0), Vector3(1.6, 0.9, 1.1), 12)
	var cc := StaticBody3D.new()
	main.add_child(cc)
	Util.collider_sphere(cc, 3.4, Vector3(cp.x, gy(cp.x, cp.y) + 1.5, cp.y))
	# debris along the trench
	var dm := [hull, burnt, metal]
	for i in 34:
		var t := rng.randf()
		var p := Vector2(lerpf(WorldData.GOUGE_A.x, WorldData.GOUGE_B.x + 14.0, t) + rng.randf_range(-7, 7), lerpf(WorldData.GOUGE_A.y, WorldData.GOUGE_B.y + 4.0, t) + rng.randf_range(-8, 8))
		if p.distance_to(S) < 9.0 or p.distance_to(cp) < 6.0:
			continue
		Util.box(main, Vector3(rng.randf_range(0.5, 2.4), 0.07, rng.randf_range(0.4, 1.8)), dm[i % 3], Vector3(p.x, gy(p.x, p.y) + rng.randf_range(0, 0.5), p.y), Vector3(rng.randf_range(-50, 50), rng.randf() * 360, rng.randf_range(-50, 50)))
	# fire and smoke
	var eng := g.to_global(Vector3(-10.5, 1.6, 0))
	Util.particles(main, eng, Color("#ff8a2a"), 40, 0.9, Vector3(0, 3, 0), 25.0, 1.6, 3.0, true)
	Util.particles(main, eng + Vector3(0, 1, 0), Color("#1c1512"), 40, 7.0, Vector3(1.5, 3, 0.3), 20.0, 3.0, 9.0)
	Util.particles(main, g.to_global(Vector3(-9, 3, 1.5)), Color("#241a16"), 28, 6.0, Vector3(1.6, 2.6, 0.4), 20.0, 2.0, 6.0)
	var fl := OmniLight3D.new()
	fl.light_color = Color("#ff7a2a")
	fl.light_energy = 3.0
	fl.omni_range = 34.0
	fl.position = eng + Vector3(0, 1.5, 0)
	main.add_child(fl)
	main.anims.append(func(t: float, _dt: float): fl.light_energy = 3.0 * (0.85 + sin(t * 17.0) * 0.1 + sin(t * 9.3) * 0.1))

# ---------------------------------------------------------------- gravity anomaly
static func _anomaly(main: Node3D) -> void:
	var C := WorldData.ANOM
	var g := Node3D.new()
	g.position = Vector3(C.x, gy(C.x, C.y), C.y)
	main.add_child(g)
	var dark := Util.mat(Color("#1d1c20"), 0.7, 0.3)
	var rune := Util.glow(Color("#5ff0ff"), 2.2)
	main.nightglow.append(rune)
	Util.cyl(g, 13, 14, 0.5, dark, Vector3(0, 0.25, 0), Vector3.ZERO, 40)
	Util.torus(g, 12.4, 12.6, rune, Vector3(0, 0.56, 0), Vector3.ZERO, false)
	var orb_m := Util.mat(Color("#0a3038"), 0.3, 0.0, Color("#5ff0ff"), 2.6)
	var orb := Util.sph(g, 1.7, orb_m, Vector3(0, 6.5, 0), Vector3.ONE, 20)
	var rings: Array = []
	for r in [5.0, 8.5, 12.0]:
		rings.append(Util.torus(g, r - 0.06, r + 0.06, rune, Vector3(0, 6.5, 0), Vector3(randf() * 170, randf() * 170, 0), false))
	var beam_m := Util.mat(Color("#5ff0ff"), 1.0, 0.0, Color.BLACK, 0.0, 0.13)
	beam_m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	beam_m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	beam_m.cull_mode = BaseMaterial3D.CULL_DISABLED
	Util.cyl(g, 0.35, 2.8, 60.0, beam_m, Vector3(0, 30, 0), Vector3.ZERO, 20).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var l := OmniLight3D.new()
	l.light_color = Color("#5ff0ff")
	l.light_energy = 2.4
	l.omni_range = 48.0
	l.position = Vector3(0, 6.5, 0)
	g.add_child(l)
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	var floaters: Array = []
	var rm := SphereMesh.new()
	rm.radius = 1.0
	rm.height = 1.6
	rm.radial_segments = 6
	rm.rings = 3
	for i in 18:
		var s := rng.randf_range(0.5, 2.2)
		var mm := Util.mat(Color("#6a3a2a") if i % 3 != 0 else Color("#4f3a44"), 0.9)
		var mi := Util.add(g, rm, mm)
		mi.scale = Vector3(s, s * 0.8, s)
		floaters.append({"m": mi, "r": rng.randf_range(5, 13.5), "a": rng.randf() * TAU, "sp": rng.randf_range(0.08, 0.25) * (1 if i % 2 == 0 else -1), "h": rng.randf_range(1.5, 10), "ph": rng.randf() * 6})
	var mote := Util.particles(g, Vector3(0, 0, 0), Color("#9ffaff"), 120, 5.0, Vector3(0, 3, 0), 40.0, 0.12, 0.3, true)
	mote.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	mote.emission_sphere_radius = 12.0
	var body := StaticBody3D.new()
	main.add_child(body)
	Util.collider_cyl(body, 1.6, 8.0, Vector3(C.x, g.position.y + 4.0, C.y))
	main.anims.append(func(t: float, dt: float):
		orb.rotation.y += dt * 0.6
		orb.scale = Vector3.ONE * (1.0 + sin(t * 2.0) * 0.06)
		for i in rings.size():
			rings[i].rotation.x += dt * 0.1 * (i + 1)
			rings[i].rotation.y += dt * 0.3
		for f in floaters:
			f.a += f.sp * dt
			f.m.position = Vector3(cos(f.a) * f.r, f.h + sin(t * 0.8 + f.ph) * 0.8, sin(f.a) * f.r)
			f.m.rotation.x += dt * 0.2)

# ---------------------------------------------------------------- heavy hollow
static func _hollow(main: Node3D) -> void:
	var C := WorldData.HOL
	var g := Node3D.new()
	main.add_child(g)
	var y := gy(C.x, C.y)
	var dark := Util.mat(Color("#1d1c20"), 0.7, 0.3)
	var metal := Util.mat(Color("#6f7177"), 0.45, 0.7)
	var body := StaticBody3D.new()
	main.add_child(body)
	Util.cyl(g, 1.2, 2.4, 9.0, dark, Vector3(C.x, y + 4.5, C.y), Vector3.ZERO, 14)
	Util.collider_cyl(body, 2.4, 9.0, Vector3(C.x, y + 4.5, C.y))
	var rmats: Array = []
	for i in 5:
		var m := Util.glow(Color("#ff3a2a"), 2.4)
		rmats.append(m)
		Util.torus(g, 1.8 + i * 0.15 - 0.1, 1.8 + i * 0.15 + 0.1, m, Vector3(C.x, y + 1.5 + i * 1.6, C.y), Vector3.ZERO, false)
	var dash := Util.glow(Color("#ff3a2a"), 2.6)
	main.nightglow.append(dash)
	for i in 52:
		var a := float(i) / 52.0 * TAU
		var x := C.x + cos(a) * 19.5
		var z := C.y + sin(a) * 19.5
		Util.box(g, Vector3(1.3, 0.1, 0.3), dash, Vector3(x, gy(x, z) + 0.12, z), Vector3(0, rad_to_deg(-a + PI / 2), 0))
	var red := Util.glow(Color("#ff3a2a"), 2.4)
	for i in 8:
		var a := float(i) / 8.0 * TAU + 0.2
		var x := C.x + cos(a) * 22.5
		var z := C.y + sin(a) * 22.5
		var yy := gy(x, z)
		Util.cyl(g, 0.2, 0.3, 3.6, metal, Vector3(x, yy + 1.8, z), Vector3.ZERO, 6)
		Util.sph(g, 0.22, red, Vector3(x, yy + 3.8, z), Vector3.ONE, 8)
		Util.collider_cyl(body, 0.35, 3.6, Vector3(x, yy + 1.8, z))
	var white := Util.mat(Color("#e9e5da"), 0.7)
	var wx := C.x - 7.0
	var wz := C.y + 4.0
	Util.box(g, Vector3(2.4, 0.5, 1.5), white, Vector3(wx, gy(wx, wz) + 0.25, wz))
	var pl := OmniLight3D.new()
	pl.light_color = Color("#ff3a2a")
	pl.light_energy = 2.0
	pl.omni_range = 40.0
	pl.position = Vector3(C.x, y + 9, C.y)
	g.add_child(pl)
	var dust := Util.particles(g, Vector3(C.x, y + 12, C.y), Color("#ff8a6a"), 100, 1.6, Vector3(0, -8, 0), 5.0, 0.1, 0.2, false)
	dust.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	dust.emission_sphere_radius = 18.0
	main.anims.append(func(t: float, _dt: float):
		for i in rmats.size():
			rmats[i].emission_energy_multiplier = 1.2 + maxf(0.0, sin(t * 3.0 - i * 0.7)) * 3.0)

# ---------------------------------------------------------------- bounce pads
static func _pads(main: Node3D) -> void:
	var C := WorldData.PADS
	var y := gy(C.x, C.y)
	var g := Node3D.new()
	g.position = Vector3(C.x, y, C.y)
	main.add_child(g)
	var dark := Util.mat(Color("#1d1c20"), 0.7, 0.3)
	for i in 4:
		var a := float(i) / 4.0 * TAU + 0.4
		var p := Vector2(cos(a), sin(a)) * 5.5
		var col := Color("#7dff9a") if i % 2 == 1 else Color("#5ff0ff")
		var gm := Util.glow(col, 2.4)
		main.nightglow.append(gm)
		Util.cyl(g, 1.8, 2.0, 0.3, dark, Vector3(p.x, 0.15, p.y), Vector3.ZERO, 24)
		Util.torus(g, 1.35, 1.55, gm, Vector3(p.x, 0.34, p.y), Vector3.ZERO, false)
		var cone := Util.cyl(g, 0.0, 0.5, 0.5, gm, Vector3(p.x, 1.0, p.y), Vector3.ZERO, 4)
		main.pads.append({"pos": Vector3(C.x + p.x, y, C.y + p.y), "mat": gm, "flash": 0.0, "cone": cone})
	main.anims.append(func(t: float, dt: float):
		for i in main.pads.size():
			var pd: Dictionary = main.pads[i]
			pd.flash = maxf(0.0, pd.flash - dt * 2.0)
			pd.mat.emission_energy_multiplier = 2.2 + pd.flash * 5.0
			pd.cone.position.y = 0.7 + fmod(t * 1.4 + i * 0.2, 1.4) * 0.9)

# ---------------------------------------------------------------- beacon ridge
static func _ridge(main: Node3D) -> void:
	var C := WorldData.RIDGE
	var g := Node3D.new()
	g.position = Vector3(C.x, gy(C.x, C.y), C.y)
	main.add_child(g)
	var metal := Util.mat(Color("#6f7177"), 0.45, 0.7)
	var white := Util.mat(Color("#e9e5da"), 0.7)
	var lv := 7
	var rings: Array = []
	for i in lv + 1:
		var w := 1.5 - i * 0.15
		var y := i * 2.2
		rings.append([Vector3(-w, y, -w), Vector3(w, y, -w), Vector3(w, y, w), Vector3(-w, y, w)])
	for i in lv:
		for k in 4:
			Util.strut(g, rings[i][k], rings[i + 1][k], 0.08, metal)
			Util.strut(g, rings[i][k], rings[i][(k + 1) % 4], 0.045, metal)
			Util.strut(g, rings[i][k], rings[i + 1][(k + 1) % 4], 0.04, metal)
	Util.sph(g, 1.8, white, Vector3(0, 15.2, 0), Vector3.ONE, 20, true).rotation_degrees = Vector3(-60, 35, 0)
	var bm := Util.glow(Color("#ff2a1a"), 3.0)
	Util.sph(g, 0.3, bm, Vector3(0, 16.9, 0), Vector3.ONE, 8)
	main.anims.append(func(t: float, _dt: float): bm.emission_energy_multiplier = 4.0 if sin(t * 2.4) > 0.4 else 0.2)
	var body := StaticBody3D.new()
	main.add_child(body)
	Util.collider_cyl(body, 2.2, 17.0, g.position + Vector3(0, 8.5, 0))
	var tp := Vector3(3.5, 0, 2.5)
	Util.cyl(g, 0.08, 0.12, 1.4, metal, tp + Vector3(0, 0.7, 0), Vector3.ZERO, 6)
	Util.cyl(g, 0.18, 0.12, 1.1, white, tp + Vector3(0, 1.6, 0), Vector3(50, -50, 0), 12)
	Util.box(g, Vector3(2.6, 1.7, 2.0), white, Vector3(-4, 0.85, -3))
	Util.collider_box(body, Vector3(2.6, 1.7, 2.0), g.position + Vector3(-4, 0.85, -3))
	main.add_interact(g.position + tp, 2.6, "Look through the telescope", func():
		main.toast("[b]Telescope[/b]  Smoke to the south-west, over the dunes. That is Ares-7.")
		main.set_waypoint("crash"))

# ---------------------------------------------------------------- Spirit-9 rover
static func _rover(main: Node3D) -> void:
	var C := WorldData.ROVER
	var g := Node3D.new()
	g.position = Vector3(C.x, gy(C.x, C.y) + 0.4, C.y)
	g.rotation = Vector3(0.35, 0.6, 0.5)
	main.add_child(g)
	var dust := Util.mat(Color("#b98a62"), 1.0, 0.1)
	var dk := Util.mat(Color("#4a4038"), 0.9)
	Util.box(g, Vector3(2.4, 0.7, 1.5), dust, Vector3(0, 0.5, 0))
	for s in [-1, 1]:
		for q in [-1, 0, 1]:
			Util.cyl(g, 0.38, 0.38, 0.28, dk, Vector3(q * 0.95, 0.15, s * 0.95), Vector3(90, 0, 0), 14)
	Util.cyl(g, 0.05, 0.05, 1.2, Util.mat(Color("#6f7177"), 0.45, 0.7), Vector3(0.8, 1.4, 0), Vector3.ZERO, 6)
	Util.box(g, Vector3(2.2, 0.05, 1.3), Util.mat(Color("#27355a"), 0.5, 0.4), Vector3(-0.4, 0.95, -1.7), Vector3(30, 10, 22))
	var body := StaticBody3D.new()
	main.add_child(body)
	Util.collider_sphere(body, 1.8, g.position + Vector3(0, 0.6, 0))
	main.add_interact(Vector3(C.x, 0, C.y), 3.4, "Read the rover log", func():
		main.toast("[b]Spirit-9 log[/b]  \"Sol 1,204. Dust on the panels. Battery 3%. If anyone reads this, the water is to the east.\"")
		main.set_waypoint("spring"))

# ---------------------------------------------------------------- frozen spring
static func _spring(main: Node3D) -> void:
	var C := WorldData.SPR
	var y := gy(C.x, C.y)
	var g := Node3D.new()
	g.position = Vector3(C.x, y, C.y)
	main.add_child(g)
	var ice := Util.mat(Color("#b9e6f6"), 0.12, 0.25, Color.BLACK, 0.0, 0.92)
	Util.cyl(g, 7.2, 7.2, 0.1, ice, Vector3(0, 0.35, 0), Vector3.ZERO, 40)
	var cm := Util.glow(Color("#8fe6ff"), 2.4)
	main.nightglow.append(cm)
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	for i in 14:
		var a := rng.randf() * TAU
		var r := rng.randf_range(5.5, 9.0)
		var h := rng.randf_range(1.0, 3.6)
		Util.cyl(g, 0.0, rng.randf_range(0.25, 0.55), h, cm, Vector3(cos(a) * r, h / 2.0 + 0.2, sin(a) * r), Vector3(rng.randf_range(-15, 15), rng.randf() * 360, rng.randf_range(-15, 15)), 5)
	var l := OmniLight3D.new()
	l.light_color = Color("#8fe6ff")
	l.light_energy = 1.8
	l.omni_range = 28.0
	l.position = Vector3(0, 3, 0)
	g.add_child(l)
	Util.particles(g, Vector3(0, 0.8, 0), Color("#d9f2ff"), 20, 5.0, Vector3(0.3, 0.7, 0), 20.0, 1.2, 3.5)
	var taken := [false]
	main.add_interact(Vector3(C.x, 0, C.y), 9.0, "Collect an ice sample", func():
		taken[0] = true
		main.o2 = minf(100.0, main.o2 + 12.0)
		main.toast("[b]Ice sample[/b]  Melted and filtered. Oxygen +12%."), func(): return not taken[0])
