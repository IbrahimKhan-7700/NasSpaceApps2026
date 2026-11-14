class_name Util
extends RefCounted
## Small helpers for building meshes and colliders from code.

static func mat(color: Color, rough := 0.85, metal := 0.0, emis := Color.BLACK, emis_e := 0.0, alpha := 1.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(color.r, color.g, color.b, alpha)
	m.roughness = rough
	m.metallic = metal
	if emis_e > 0.0:
		m.emission_enabled = true
		m.emission = emis
		m.emission_energy_multiplier = emis_e
	if alpha < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m

static func glow(color: Color, energy := 2.4) -> StandardMaterial3D:
	return mat(color.darkened(0.8), 0.5, 0.0, color, energy)

static func add(parent: Node, mesh: Mesh, m: Material, pos := Vector3.ZERO, rot_deg := Vector3.ZERO, shadow := true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = m
	mi.position = pos
	mi.rotation_degrees = rot_deg
	if not shadow:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi

static func box(parent: Node, size: Vector3, m: Material, pos := Vector3.ZERO, rot_deg := Vector3.ZERO) -> MeshInstance3D:
	var b := BoxMesh.new()
	b.size = size
	return add(parent, b, m, pos, rot_deg)

static func cyl(parent: Node, r_top: float, r_bot: float, h: float, m: Material, pos := Vector3.ZERO, rot_deg := Vector3.ZERO, seg := 16) -> MeshInstance3D:
	var c := CylinderMesh.new()
	c.top_radius = r_top
	c.bottom_radius = r_bot
	c.height = h
	c.radial_segments = seg
	c.rings = 1
	return add(parent, c, m, pos, rot_deg)

static func sph(parent: Node, r: float, m: Material, pos := Vector3.ZERO, scl := Vector3.ONE, seg := 16, hemi := false) -> MeshInstance3D:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * (1.0 if hemi else 2.0)
	s.is_hemisphere = hemi
	s.radial_segments = seg
	s.rings = maxi(4, seg / 2)
	var mi := add(parent, s, m, pos)
	mi.scale = scl
	return mi

static func torus(parent: Node, inner: float, outer: float, m: Material, pos := Vector3.ZERO, rot_deg := Vector3.ZERO, shadow := true) -> MeshInstance3D:
	var t := TorusMesh.new()
	t.inner_radius = inner
	t.outer_radius = outer
	t.rings = 32
	t.ring_segments = 8
	return add(parent, t, m, pos, rot_deg, shadow)

## Cylinder between two points
static func strut(parent: Node, a: Vector3, b: Vector3, r: float, m: Material) -> MeshInstance3D:
	var d := b - a
	var up := d.normalized()
	var ref := Vector3.RIGHT if absf(up.dot(Vector3.RIGHT)) < 0.9 else Vector3.FORWARD
	var x := ref.cross(up).normalized()
	var z := x.cross(up)
	var mi := cyl(parent, r, r, d.length(), m, (a + b) * 0.5, Vector3.ZERO, 6)
	mi.basis = Basis(x, up, z)
	return mi

static func collider_box(body: Node, size: Vector3, pos: Vector3, rot_y := 0.0) -> void:
	var cs := CollisionShape3D.new()
	var s := BoxShape3D.new()
	s.size = size
	cs.shape = s
	cs.position = pos
	cs.rotation.y = rot_y
	body.add_child(cs)

static func collider_cyl(body: Node, r: float, h: float, pos: Vector3) -> void:
	var cs := CollisionShape3D.new()
	var s := CylinderShape3D.new()
	s.radius = r
	s.height = h
	cs.shape = s
	cs.position = pos
	body.add_child(cs)

static func collider_sphere(body: Node, r: float, pos: Vector3) -> void:
	var cs := CollisionShape3D.new()
	var s := SphereShape3D.new()
	s.radius = r
	cs.shape = s
	cs.position = pos
	body.add_child(cs)

## Open arc of a cylinder whose axis is X. Angle 0 points +Z and sweeps up through +Y.
static func arc_mesh(r: float, x0: float, x1: float, a0: float, a1: float, segs := 12) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in segs:
		var t0 := a0 + (a1 - a0) * float(i) / segs
		var t1 := a0 + (a1 - a0) * float(i + 1) / segs
		var p00 := Vector3(x0, r * sin(t0), r * cos(t0))
		var p10 := Vector3(x1, r * sin(t0), r * cos(t0))
		var p01 := Vector3(x0, r * sin(t1), r * cos(t1))
		var p11 := Vector3(x1, r * sin(t1), r * cos(t1))
		for v in [p00, p10, p01, p10, p11, p01]:
			st.add_vertex(v)
	st.generate_normals()
	return st.commit()

static func half_disc(r: float, x: float, segs := 20) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in segs:
		var t0 := PI * float(i) / segs
		var t1 := PI * float(i + 1) / segs
		st.add_vertex(Vector3(x, 0, 0))
		st.add_vertex(Vector3(x, r * sin(t0), r * cos(t0)))
		st.add_vertex(Vector3(x, r * sin(t1), r * cos(t1)))
	st.generate_normals()
	return st.commit()

static func particles(parent: Node, pos: Vector3, color: Color, amount: int, life: float, vel: Vector3, spread: float, size_a: float, size_b: float, additive := false, gravity := Vector3.ZERO) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.position = pos
	p.amount = amount
	p.lifetime = life
	p.local_coords = false
	p.direction = vel.normalized() if vel.length() > 0.001 else Vector3.UP
	p.spread = spread
	p.initial_velocity_min = vel.length() * 0.7
	p.initial_velocity_max = vel.length() * 1.2
	p.gravity = gravity
	p.scale_amount_min = size_a
	p.scale_amount_max = size_b
	var sm := SphereMesh.new()
	sm.radius = 0.5
	sm.height = 1.0
	sm.radial_segments = 6
	sm.rings = 3
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = color
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if additive:
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.vertex_color_use_as_albedo = true
	sm.material = m
	p.mesh = sm
	var curve := Curve.new()
	curve.add_point(Vector2(0, 0.4))
	curve.add_point(Vector2(1, 1.0))
	p.scale_amount_curve = curve
	var grad := Gradient.new()
	grad.set_color(0, Color(1, 1, 1, 0.8))
	grad.set_color(1, Color(1, 1, 1, 0.0))
	p.color_ramp = grad
	parent.add_child(p)
	return p
