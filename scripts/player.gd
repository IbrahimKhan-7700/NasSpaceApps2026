class_name Player
extends CharacterBody3D
## Third-person astronaut. Mars gravity, gravity zones, sprint, jump, orbit camera.

signal stepped(pos: Vector3, heading: float)
signal landed

var yaw := PI + 0.6
var pitch := 0.32
var cam_dist := 6.4
var cam_dist_t := 6.4
var enabled := false
var heading := PI
var phase := 0.0
var cam: Camera3D
var model: Node3D
var head: Node3D
var hips: Node3D
var upper: Node3D
var legs: Array = []
var arms: Array = []
var lamp: SpotLight3D
var beacon: MeshInstance3D
var cover := false          # inside greenhouse or ship: pull the camera in
var _last_step := 0
var _was_air := false
var _t := 0.0

func _ready() -> void:
	floor_snap_length = 0.6
	floor_max_angle = deg_to_rad(62.0)
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.4
	cap.height = 1.8
	cs.shape = cap
	cs.position.y = 0.9
	add_child(cs)
	_build_model()
	cam = Camera3D.new()
	cam.top_level = true
	cam.fov = 65.0
	cam.far = 1400.0
	add_child(cam)
	cam.make_current()

func _build_model() -> void:
	model = Node3D.new()
	add_child(model)
	var suit := Util.mat(Color("#d9d3c6"), 0.75)
	var grey := Util.mat(Color("#6b6e75"), 0.6, 0.3)
	var dark := Util.mat(Color("#17171a"), 0.6)
	var orange := Util.mat(Color("#e0541a"), 0.6)
	var gauze := Util.mat(Color("#e9e2d0"), 0.9)
	hips = Node3D.new()
	hips.position.y = 0.95
	model.add_child(hips)
	Util.sph(hips, 0.2, grey, Vector3.ZERO, Vector3(1.15, 0.7, 0.85), 12)
	for s in [-1, 1]:
		var leg := Node3D.new()
		leg.position = Vector3(s * 0.12, 0, 0)
		hips.add_child(leg)
		Util.cyl(leg, 0.082, 0.095, 0.42, suit, Vector3(0, -0.21, 0), Vector3.ZERO, 10)
		var knee := Node3D.new()
		knee.position.y = -0.42
		leg.add_child(knee)
		Util.cyl(knee, 0.07, 0.082, 0.4, suit, Vector3(0, -0.2, 0), Vector3.ZERO, 10)
		Util.sph(knee, 0.075, orange, Vector3(0, 0, 0.05), Vector3(1, 0.8, 0.8), 8)
		Util.box(knee, Vector3(0.17, 0.13, 0.3), dark, Vector3(0, -0.43, 0.06))
		Util.torus(knee, 0.062, 0.09, orange, Vector3(0, -0.34, 0))
		legs.append({"leg": leg, "knee": knee})
	upper = Node3D.new()
	hips.add_child(upper)
	Util.sph(upper, 0.29, suit, Vector3(0, 0.34, 0), Vector3(0.95, 1.1, 0.72), 16)
	Util.box(upper, Vector3(0.2, 0.14, 0.05), dark, Vector3(0, 0.4, 0.21))
	Util.box(upper, Vector3(0.15, 0.07, 0.01), Util.glow(Color("#ff2a1a"), 1.6), Vector3(0, 0.41, 0.238))
	Util.box(upper, Vector3(0.4, 0.5, 0.2), grey, Vector3(0, 0.38, -0.26))
	for s in [-1, 1]:
		Util.cyl(upper, 0.06, 0.06, 0.5, suit, Vector3(s * 0.12, 0.38, -0.4), Vector3.ZERO, 8)
	Util.cyl(upper, 0.008, 0.008, 0.35, dark, Vector3(0.15, 0.78, -0.26), Vector3(0, 0, -30), 5)
	beacon = Util.sph(upper, 0.025, Util.glow(Color("#ff2a1a"), 3.0), Vector3(0.19, 0.56, -0.37), Vector3.ONE, 8)
	# torn patch and bandaged arm for the battle-worn look
	Util.box(upper, Vector3(0.11, 0.09, 0.01), Util.mat(Color("#14151c"), 0.9), Vector3(-0.12, 0.34, 0.262), Vector3(0, -12, 0))
	Util.box(upper, Vector3(0.05, 0.04, 0.01), Util.mat(Color("#5a0d08"), 0.4), Vector3(-0.12, 0.34, 0.268), Vector3(0, -12, 0))
	head = Node3D.new()
	head.position.y = 0.84
	upper.add_child(head)
	Util.sph(head, 0.2, suit, Vector3.ZERO, Vector3(1, 1.03, 1), 16)
	var visor := Util.mat(Color("#6b3a08"), 0.12, 1.0, Color("#3a1a02"), 0.5)
	Util.sph(head, 0.165, visor, Vector3(0, -0.005, 0.07), Vector3(1.02, 0.82, 0.8), 14)
	Util.torus(head, 0.1, 0.16, dark, Vector3(0, -0.19, 0), Vector3.ZERO, false)
	lamp = SpotLight3D.new()
	lamp.position = Vector3(0, 0.02, 0.2)
	lamp.rotation.y = PI
	lamp.spot_range = 40.0
	lamp.spot_angle = 32.0
	lamp.light_energy = 0.0
	lamp.shadow_enabled = false
	head.add_child(lamp)
	for s in [-1, 1]:
		var arm := Node3D.new()
		arm.position = Vector3(s * 0.33, 0.58, 0)
		upper.add_child(arm)
		Util.sph(arm, 0.1, grey, Vector3.ZERO, Vector3.ONE, 10)
		Util.cyl(arm, 0.066, 0.075, 0.3, suit, Vector3(0, -0.15, 0), Vector3.ZERO, 10)
		var el := Node3D.new()
		el.position.y = -0.3
		arm.add_child(el)
		Util.cyl(el, 0.056, 0.066, 0.28, suit, Vector3(0, -0.14, 0), Vector3.ZERO, 10)
		Util.sph(el, 0.075, dark, Vector3(0, -0.32, 0), Vector3.ONE, 10)
		Util.torus(el, 0.05, 0.08, orange, Vector3(0, -0.26, 0), Vector3.ZERO, false)
		if s == -1:
			for k in 3:
				Util.torus(el, 0.055, 0.09, gauze, Vector3(0, -0.06 - k * 0.05, 0), Vector3.ZERO, false)
		arms.append({"arm": arm, "el": el})

func _unhandled_input(e: InputEvent) -> void:
	if not enabled:
		return
	if e is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		yaw -= e.relative.x * 0.0035
		pitch = clampf(pitch + e.relative.y * 0.0035, 0.04, 1.25)
	elif e is InputEventMouseButton and e.pressed:
		if e.button_index == MOUSE_BUTTON_WHEEL_UP:
			cam_dist_t = clampf(cam_dist_t - 0.6, 3.0, 11.0)
		elif e.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			cam_dist_t = clampf(cam_dist_t + 0.6, 3.0, 11.0)

func _physics_process(delta: float) -> void:
	var gm := WorldData.grav_mult(global_position.x, global_position.z)
	var hw := smoothstep(1.4, 2.5, gm)
	var ix := 0.0
	var iy := 0.0
	if enabled:
		ix = Input.get_axis("move_left", "move_right")
		iy = Input.get_axis("move_back", "move_forward")
	var f := Vector3(sin(yaw), 0, cos(yaw))
	var r := Vector3(-cos(yaw), 0, sin(yaw))
	var dir := f * iy + r * ix
	if dir.length() > 1.0:
		dir = dir.normalized()
	var on_floor := is_on_floor()
	var maxs := (7.0 if (enabled and Input.is_action_pressed("sprint")) else 4.1) * (1.0 - 0.5 * hw)
	if on_floor and dir.length() > 0.05:
		var n := get_floor_normal()
		var uphill := dir.normalized().dot(Vector3(-n.x, 0, -n.z)) / maxf(n.y, 0.3)
		maxs *= clampf(1.0 - uphill * 1.1, 0.45, 1.25)
	var ac := 13.0 if on_floor else (2.4 if gm < 0.3 else 4.0)
	var k := clampf(ac * delta, 0.0, 1.0)
	velocity.x = lerpf(velocity.x, dir.x * maxs, k)
	velocity.z = lerpf(velocity.z, dir.z * maxs, k)
	if on_floor and velocity.y < 0.0:
		velocity.y = -1.0
	if enabled and on_floor and Input.is_action_just_pressed("jump"):
		velocity.y = 2.6 if gm < 0.3 else 4.5 * (1.0 - 0.3 * hw)
	elif not on_floor:
		velocity.y -= 3.71 * gm * delta
		if gm < 0.3:
			velocity.y *= 1.0 - 0.1 * delta
	var vy_before := velocity.y
	move_and_slide()
	var rr := Vector2(global_position.x, global_position.z)
	if rr.length() > WorldData.WORLD_R:
		rr = rr.normalized() * WorldData.WORLD_R
		global_position.x = rr.x
		global_position.z = rr.y
	if is_on_floor() and _was_air and vy_before < -3.0:
		landed.emit()
	_was_air = not is_on_floor()
	var sp := Vector2(velocity.x, velocity.z).length()
	if sp > 0.25:
		heading = lerp_angle(heading, atan2(velocity.x, velocity.z), clampf(delta * 12.0, 0.0, 1.0))
	if is_on_floor() and sp > 0.3:
		phase += sp * delta * 1.9
		var s := int(floor(phase / PI))
		if s != _last_step:
			_last_step = s
			stepped.emit(global_position, heading)

func _process(delta: float) -> void:
	_t += delta
	_animate(delta)
	_update_camera(delta)

func _animate(delta: float) -> void:
	model.rotation.y = heading
	var sp := Vector2(velocity.x, velocity.z).length()
	var run := clampf(sp / 7.0, 0.0, 1.0)
	var gm := WorldData.grav_mult(global_position.x, global_position.z)
	beacon.visible = sin(_t * 4.0) > 0.0
	if is_on_floor() and sp > 0.3:
		var s := sin(phase)
		var amp := 0.45 + run * 0.55
		legs[0].leg.rotation.x = -s * amp
		legs[1].leg.rotation.x = s * amp
		legs[0].knee.rotation.x = maxf(0.0, s) * (0.7 + run * 0.5)
		legs[1].knee.rotation.x = maxf(0.0, -s) * (0.7 + run * 0.5)
		arms[0].arm.rotation.x = s * amp * 0.8
		arms[1].arm.rotation.x = -s * amp * 0.8
		arms[0].el.rotation.x = -0.35 - run * 0.5
		arms[1].el.rotation.x = -0.35 - run * 0.5
		hips.position.y = 0.95 + absf(cos(phase)) * 0.045 * (1.0 + run)
		upper.rotation.x = 0.06 + run * 0.16
	elif not is_on_floor():
		var fl := gm < 0.3
		var w := clampf(delta * 5.0, 0, 1)
		legs[0].leg.rotation.x = lerpf(legs[0].leg.rotation.x, -0.5, w)
		legs[1].leg.rotation.x = lerpf(legs[1].leg.rotation.x, 0.4, w)
		legs[0].knee.rotation.x = lerpf(legs[0].knee.rotation.x, 0.8, w)
		legs[1].knee.rotation.x = lerpf(legs[1].knee.rotation.x, 0.4, w)
		for a in arms:
			a.arm.rotation.x = lerpf(a.arm.rotation.x, -1.2 if fl else -0.6, w)
		upper.rotation.x = lerpf(upper.rotation.x, 0.25 if fl else 0.08, clampf(delta * 4.0, 0, 1))
		hips.position.y = 0.95
	else:
		var w := clampf(delta * 8.0, 0, 1)
		for l in legs:
			l.leg.rotation.x = lerpf(l.leg.rotation.x, 0.0, w)
			l.knee.rotation.x = lerpf(l.knee.rotation.x, 0.0, w)
		for a in arms:
			a.arm.rotation.x = lerpf(a.arm.rotation.x, 0.0, w)
			a.el.rotation.x = lerpf(a.el.rotation.x, -0.15, w)
		upper.rotation.x = lerpf(upper.rotation.x, 0.04, w)
		hips.position.y = 0.95 + sin(_t * 1.6) * 0.012

func _update_camera(delta: float) -> void:
	if not enabled:
		yaw = PI + 0.8 + sin(_t * 0.12) * 0.35
		pitch = 0.22
		cam_dist_t = 7.2
	var want := minf(cam_dist_t, 3.9) if cover else cam_dist_t
	cam_dist = lerpf(cam_dist, want, clampf(delta * 4.0, 0.0, 1.0))
	var target := global_position + Vector3(0, 1.45, 0)
	var cp := cos(pitch)
	var pos := target + Vector3(-sin(yaw) * cp, sin(pitch), -cos(yaw) * cp) * cam_dist
	var floor_y := WorldData.height_at(pos.x, pos.z) + 0.7
	pos.y = maxf(pos.y, floor_y)
	cam.global_position = pos
	cam.look_at(target + Vector3(0, 0.1, 0), Vector3.UP)
