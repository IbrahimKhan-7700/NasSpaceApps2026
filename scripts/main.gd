extends Node3D
## Marooned on Mars: game controller. Builds the world, runs survival, thoughts, teleport.

var player: Player
var ui: CanvasLayer
var sun: DirectionalLight3D
var env: Environment
var sky_mat: ProceduralSkyMaterial
var interacts: Array = []
var anims: Array = []
var plants: Array = []
var pads: Array = []
var nightglow: Array = []
var ship_mats: Array = []
var ship_center := Vector2.ZERO
var waypoint: Dictionary = {}
var wp_label: Label3D
var footprints: Array = []
var fp_i := 0

var o2 := 64.0
var harvest := 0
var recorder := false
var found := {"base": true}
var g_pad := false
var g_float := false
var g_heavy := false
var prints := 0
var started := false
var done := false
var in_gh := false
var in_ship := false
var time := 0.0
var night := 0.0
var night_t := 0.0
var teleporting := false
var pad_cool := 0.0
var t_clock := 0.0
var _ship_clear := true

# thought bubbles
var thoughts: Array = []
var cur_thought: Dictionary = {}
var th_until := 0.0
var th_next := 6.0
var th_used := {}
var th_last := {}
var th_first := false

func _ready() -> void:
	_setup_input()
	_setup_environment()
	var terrain := Node3D.new()
	terrain.set_script(load("res://scripts/terrain.gd"))
	add_child(terrain)
	Sites.build_all(self)
	player = Player.new()
	player.position = Vector3(7, WorldData.height_at(7, 8) + 0.1, 8)
	add_child(player)
	player.stepped.connect(_on_step)
	player.landed.connect(func(): pass)
	_make_footprints()
	wp_label = Label3D.new()
	wp_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	wp_label.no_depth_test = true
	wp_label.fixed_size = true
	wp_label.pixel_size = 0.0012
	wp_label.font_size = 40
	wp_label.modulate = Color("#ffc857")
	wp_label.outline_size = 12
	wp_label.visible = false
	add_child(wp_label)
	ui = CanvasLayer.new()
	ui.set_script(load("res://scripts/ui.gd"))
	add_child(ui)
	ui.setup(self)
	ui.render_goals()
	_define_thoughts()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if "--autotest" in OS.get_cmdline_user_args():
		var at := Node.new()
		at.set_script(load("res://scripts/autotest.gd"))
		add_child(at)
		at.run(self)

func _setup_input() -> void:
	var map := {
		"move_forward": [KEY_W, KEY_UP], "move_back": [KEY_S, KEY_DOWN], "move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT], "jump": [KEY_SPACE], "sprint": [KEY_SHIFT], "interact": [KEY_E],
		"places": [KEY_M, KEY_P], "think": [KEY_T], "daynight": [KEY_N], "option1": [KEY_1], "option2": [KEY_2], "option3": [KEY_3],
	}
	for a in map:
		if not InputMap.has_action(a):
			InputMap.add_action(a)
		for k in map[a]:
			var e := InputEventKey.new()
			e.physical_keycode = k
			InputMap.action_add_event(a, e)

func _setup_environment() -> void:
	env = Environment.new()
	var sky := Sky.new()
	sky_mat = ProceduralSkyMaterial.new()
	sky.sky_material = sky_mat
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.9
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_density = 0.0042
	env.glow_enabled = true
	env.glow_intensity = 0.7
	env.glow_bloom = 0.1
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	sun = DirectionalLight3D.new()
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 140.0
	sun.shadow_bias = 0.04
	add_child(sun)
	_apply_light(0.0)

func _apply_light(n: float) -> void:
	var d_top := Color("#6d587a"); var n_top := Color("#03040c")
	var d_hor := Color("#d99466"); var n_hor := Color("#2a1424")
	sky_mat.sky_top_color = d_top.lerp(n_top, n)
	sky_mat.sky_horizon_color = d_hor.lerp(n_hor, n)
	sky_mat.ground_horizon_color = sky_mat.sky_horizon_color
	sky_mat.ground_bottom_color = Color("#5a2616").lerp(Color("#140b1a"), n)
	env.fog_light_color = Color("#d7936a").lerp(Color("#140b1a"), n)
	env.ambient_light_color = Color("#c98a6a").lerp(Color("#3a4c8c"), n)
	env.ambient_light_energy = lerpf(0.7, 0.55, n)
	sun.light_color = Color("#ffa96b").lerp(Color("#86a3ff"), n)
	sun.light_energy = lerpf(1.7, 0.5, n)
	var qd := Basis.looking_at(Vector3(0.62, -0.34, 0.55), Vector3.UP).get_rotation_quaternion()
	var qn := Basis.looking_at(Vector3(-0.45, -0.7, -0.5), Vector3.UP).get_rotation_quaternion()
	sun.basis = Basis(qd.slerp(qn, n))
	for m in nightglow:
		m.emission_energy_multiplier = 2.4 * (1.0 + n * 1.0)
	if player:
		player.lamp.light_energy = n * 5.0

# ---------------------------------------------------------------- API used by sites and UI
func add_interact(pos: Vector3, r: float, label: String, fn: Callable, ok: Callable = Callable()) -> void:
	interacts.append({"pos": pos, "r": r, "label": label, "fn": fn, "ok": ok})

func toast(bb: String) -> void:
	if ui:
		ui.toast(bb)

func goals() -> Array:
	return [
		{"txt": "Discover 6 places", "cur": found.size(), "max": 6},
		{"txt": "Harvest 3 tomatoes", "cur": harvest, "max": 3},
		{"txt": "Recover the flight recorder", "cur": 1 if recorder else 0, "max": 1},
		{"txt": "Feel all three gravity zones", "cur": int(g_pad) + int(g_float) + int(g_heavy), "max": 3},
	]

func check_goals() -> void:
	ui.render_goals()
	if done:
		return
	for g in goals():
		if g["cur"] < g["max"]:
			return
	done = true
	await get_tree().create_timer(0.6).timeout
	toast("[b]Signal sent[/b]  The recorder beacon is transmitting. Rescue is coming. Keep exploring.")
	thought_now("done")

func discover(id: String) -> void:
	if found.has(id):
		return
	found[id] = true
	toast("[b]Discovered[/b]  " + WorldData.get_lm(id)["name"])
	check_goals()

func set_waypoint(id: String) -> void:
	var l := WorldData.get_lm(id)
	if l.is_empty():
		return
	if waypoint.size() > 0 and waypoint["id"] == id:
		waypoint = {}
		wp_label.visible = false
		return
	waypoint = l
	toast("[b]Waypoint[/b]  " + l["name"])

func toggle_night() -> void:
	night_t = 0.0 if night_t > 0.5 else 1.0
	ui.time_btn.text = "[N] Day" if night_t > 0.5 else "[N] Night"

func begin() -> void:
	started = true
	player.enabled = true
	ui.start_card.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	player.cam_dist_t = 6.4

func teleport_to(id: String) -> void:
	var l := WorldData.get_lm(id)
	if l.is_empty() or teleporting:
		return
	teleporting = true
	var tw := create_tween()
	tw.tween_property(ui.fade, "modulate:a", 1.0, 0.25)
	tw.tween_callback(func():
		var tp: Vector2 = l["tp"]
		player.global_position = Vector3(tp.x, WorldData.height_at(tp.x, tp.y) + 0.3, tp.y)
		player.velocity = Vector3.ZERO
		player.yaw = atan2(l["pos"].x - tp.x, l["pos"].y - tp.y)
		player.pitch = 0.3
		player.heading = player.yaw
		ui.close_places()
		discover(id)
		toast("[b]Teleported[/b]  " + l["name"]))
	tw.tween_property(ui.fade, "modulate:a", 0.0, 0.35)
	tw.tween_callback(func(): teleporting = false)

# ---------------------------------------------------------------- footprints
func _make_footprints() -> void:
	var qm := QuadMesh.new()
	qm.size = Vector2(0.2, 0.42)
	qm.orientation = PlaneMesh.FACE_Y
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.12, 0.05, 0.03, 0.55)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for i in 300:
		var mi := MeshInstance3D.new()
		mi.mesh = qm
		mi.material_override = m
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.visible = false
		add_child(mi)
		footprints.append(mi)

func _on_step(pos: Vector3, heading: float) -> void:
	var side := 1.0 if (fp_i % 2 == 0) else -1.0
	var p := pos + Vector3(-cos(heading), 0, sin(heading)) * side * 0.15
	var fp: MeshInstance3D = footprints[fp_i % footprints.size()]
	fp_i += 1
	prints += 1
	var y := WorldData.height_at(p.x, p.z) + 0.04
	var e := 0.4
	var n := Vector3(WorldData.height_at(p.x - e, p.z) - WorldData.height_at(p.x + e, p.z), 2 * e, WorldData.height_at(p.x, p.z - e) - WorldData.height_at(p.x, p.z + e)).normalized()
	var b := Basis(Quaternion(Vector3.UP, n)) * Basis(Vector3.UP, heading)
	fp.global_transform = Transform3D(b, Vector3(p.x, y, p.z))
	fp.visible = true

# ---------------------------------------------------------------- thoughts
func _near(id: String, d: float) -> bool:
	var l := WorldData.get_lm(id)
	return Vector2(player.global_position.x, player.global_position.z).distance_to(l["pos"]) < d

func _gm() -> float:
	return WorldData.grav_mult(player.global_position.x, player.global_position.z)

func _define_thoughts() -> void:
	thoughts = [
		{"id": "start", "text": "Sol 41. The radio is still just static.", "opts": [["Open the places map", "places"], ["Keep walking", "dismiss"]], "once": true},
		{"id": "o2low", "when": func(): return o2 < 38.0, "text": "Oxygen is getting low. The greenhouse makes air. I should go there.", "opts": [["Mark the greenhouse", "wp:greenhouse"], ["Teleport there", "tp:greenhouse"]], "w": 6.0, "cd": 50.0},
		{"id": "o2crit", "when": func(): return o2 < 16.0, "text": "Vision going grey. Greenhouse. Now.", "opts": [["Teleport now", "tp:greenhouse"], ["Mark it", "wp:greenhouse"]], "w": 12.0, "cd": 30.0},
		{"id": "ghnear", "when": func(): return _near("greenhouse", 34.0), "text": "Grow lights are on. Somebody has been watering these tomatoes.", "opts": [["Go take a look", "wp:greenhouse"], ["Later", "dismiss"]], "once": true, "w": 4.0},
		{"id": "ghin", "when": func(): return in_gh, "text": "Tomatoes. On Mars. I am going to be insufferable about this.", "opts": [["Harvest some", "dismiss"]], "once": true, "w": 5.0},
		{"id": "harvest", "trigger": true, "text": "Warm, red, and absolutely not freeze-dried.", "opts": [["Nice", "dismiss"]], "once": true},
		{"id": "crashnear", "when": func(): return _near("crash", 46.0), "text": "Ares-7. Hull split like a tin can. The recorder might still be in there.", "opts": [["Mark the wreck", "wp:crash"], ["Not yet", "dismiss"]], "once": true, "w": 5.0},
		{"id": "ship", "when": func(): return in_ship, "text": "Cold in here. Quiet. Where did the crew go?", "opts": [["Look for the recorder", "dismiss"]], "once": true, "w": 5.0},
		{"id": "recorder", "trigger": true, "text": "It is still recording. Somebody should hear this.", "opts": [["Keep it safe", "dismiss"]], "once": true},
		{"id": "float", "when": func(): return _gm() < 0.2, "text": "Why am I floating? Gravity has gone soft here.", "opts": [["Jump!", "dismiss"], ["Okay, go back", "tp:base"]], "once": true, "w": 6.0},
		{"id": "heavy", "when": func(): return _gm() > 1.6, "text": "Every step weighs a ton. Twice the gravity.", "opts": [["Get me out of here", "tp:base"], ["Push on", "dismiss"]], "once": true, "w": 6.0},
		{"id": "pad", "when": func(): return g_pad, "text": "Someone built a playground out here. Why?", "opts": [["Bounce again", "wp:pads"], ["Nah", "dismiss"]], "once": true, "w": 3.0},
		{"id": "ridge", "when": func(): return _near("ridge", 22.0), "text": "From up here you can see everything. And everything is very far away.", "opts": [["Look for smoke", "wp:crash"]], "once": true, "w": 5.0},
		{"id": "rover", "when": func(): return _near("rover", 14.0), "text": "Spirit-9. Another one that did not make it.", "opts": [["Read its log", "dismiss"]], "once": true, "w": 4.0},
		{"id": "spring", "when": func(): return _near("spring", 16.0), "text": "Ice. Real ice. Water means a future.", "opts": [["Take a sample", "dismiss"]], "once": true, "w": 4.0},
		{"id": "night", "when": func(): return night > 0.7, "text": "Cold. The headlamp battery is not infinite.", "opts": [["Switch to day", "night"], ["Stay out", "dismiss"]], "once": true, "w": 4.0},
		{"id": "prints", "when": func(): return prints > 60, "text": "My boots are the only footprints for a thousand kilometres.", "opts": [["Keep walking", "dismiss"]], "once": true},
		{"id": "smoke", "when": func(): return not _near("crash", 60.0) and not found.has("crash"), "text": "Is that smoke on the horizon, or am I just hopeful?", "opts": [["Mark Ares-7", "wp:crash"], ["Hopeful", "dismiss"]], "once": true, "w": 3.0},
		{"id": "done", "trigger": true, "text": "Signal is out. Now we wait. Or explore.", "opts": [["Open the map", "places"], ["Stay here", "dismiss"]], "once": true},
		{"id": "idle", "text": "Dust gets everywhere. Everywhere.", "opts": [["Same", "dismiss"]], "cd": 200.0},
		{"id": "idle2", "text": "Maybe I should name the rocks.", "opts": [["Good plan", "dismiss"]], "cd": 200.0},
	]

func _pick_thought() -> Dictionary:
	var el: Array = []
	for t in thoughts:
		if t.get("trigger", false):
			continue
		if t.get("once", false) and th_used.has(t["id"]):
			continue
		if t.has("cd") and time - th_last.get(t["id"], -999.0) <= t["cd"]:
			continue
		if t.has("when") and not t["when"].call():
			continue
		el.append(t)
	if el.is_empty():
		return {}
	var tot := 0.0
	for t in el:
		tot += t.get("w", 1.0)
	var r := randf() * tot
	for t in el:
		r -= t.get("w", 1.0)
		if r <= 0.0:
			return t
	return el[0]

func show_thought(t: Dictionary) -> void:
	if t.is_empty():
		return
	cur_thought = t
	th_used[t["id"]] = true
	th_last[t["id"]] = time
	th_until = time + 11.0
	ui.show_bubble(t["text"], t["opts"])

func thought_now(id: String) -> void:
	for t in thoughts:
		if t["id"] == id and not (t.get("once", false) and th_used.has(id)):
			await get_tree().create_timer(0.9).timeout
			show_thought(t)
			return

func force_thought() -> void:
	if not started:
		return
	if not cur_thought.is_empty():
		hide_thought()
	show_thought(_pick_thought())

func hide_thought() -> void:
	cur_thought = {}
	ui.hide_bubble()
	th_next = time + randf_range(12.0, 22.0)

func run_option(i: int) -> void:
	if cur_thought.is_empty() or i >= cur_thought["opts"].size():
		return
	var a: String = cur_thought["opts"][i][1]
	hide_thought()
	if a == "places":
		ui.open_places()
	elif a == "night":
		toggle_night()
	elif a.begins_with("wp:"):
		set_waypoint(a.substr(3))
	elif a.begins_with("tp:"):
		teleport_to(a.substr(3))

# ---------------------------------------------------------------- frame update
func _unhandled_input(e: InputEvent) -> void:
	if not started:
		return
	if e.is_action_pressed("places"):
		ui.toggle_places()
	elif e is InputEventKey and e.pressed and e.keycode == KEY_ESCAPE:
		if ui.places.visible:
			ui.close_places()
		else:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED
	elif e.is_action_pressed("daynight"):
		toggle_night()
	elif e.is_action_pressed("think"):
		force_thought()
	for k in 3:
		if e.is_action_pressed("option%d" % (k + 1)) and not cur_thought.is_empty():
			run_option(k)

func _process(delta: float) -> void:
	t_clock += delta
	if started:
		time += delta
	night = lerpf(night, night_t, clampf(delta * 1.6, 0.0, 1.0))
	_apply_light(night)
	for f in anims:
		f.call(t_clock, delta)
	_update_survival(delta)
	_update_interact()
	_update_ship_fade(delta)
	_update_waypoint()
	ui.update(delta)
	if started and not ui.places.visible:
		if cur_thought.is_empty():
			if time > th_next:
				if th_first:
					show_thought(_pick_thought())
				else:
					th_first = true
					show_thought(thoughts[0])
		elif time > th_until:
			hide_thought()
	elif ui.places.visible and not cur_thought.is_empty():
		hide_thought()

func _update_survival(delta: float) -> void:
	var p := player.global_position
	var p2 := Vector2(p.x, p.z)
	in_gh = absf(p.x - WorldData.GH.x) < 11.2 and absf(p.z - WorldData.GH.y) < 5.2
	var gm := _gm()
	if gm < 0.2 and not g_float:
		g_float = true
		check_goals()
	if gm > 1.8 and not g_heavy:
		g_heavy = true
		check_goals()
	pad_cool -= delta
	for pd in pads:
		var pp: Vector3 = pd["pos"]
		if pad_cool <= 0.0 and Vector2(p.x - pp.x, p.z - pp.z).length() < 1.5 and p.y - pp.y < 1.4:
			player.velocity.y = 14.5
			pad_cool = 0.6
			pd["flash"] = 1.0
			if not g_pad:
				g_pad = true
				check_goals()
	var near_hab := p2.distance_to(Vector2(-7, -4)) < 9.0
	o2 += (1.6 if in_gh else (0.7 if near_hab else -0.07)) * delta
	o2 = clampf(o2, 0.0, 100.0)
	if o2 <= 0.0 and not teleporting:
		o2 = 40.0
		toast("[b]Suit failure[/b]  You blacked out and woke up at base camp.")
		teleport_to("base")
	for l in WorldData.LM:
		if not found.has(l["id"]) and p2.distance_to(l["pos"]) < l["r"]:
			discover(l["id"])
	for pl in plants:
		if not pl["ready"]:
			pl["t"] -= delta
			if pl["t"] <= 0.0:
				pl["ready"] = true
				pl["fruit"].visible = true
	player.cover = in_gh or in_ship

func _update_interact() -> void:
	var best: Dictionary = {}
	var bd := 1e9
	var p := player.global_position
	for it in interacts:
		if it["ok"].is_valid() and not it["ok"].call():
			continue
		var d := Vector2(p.x - it["pos"].x, p.z - it["pos"].z).length()
		if d < it["r"] and d < bd:
			bd = d
			best = it
	if not best.is_empty() and started and not ui.places.visible:
		ui.prompt.text = "[E]  " + best["label"]
		if Input.is_action_just_pressed("interact") and not teleporting:
			best["fn"].call()
	else:
		ui.prompt.text = ""

func _update_ship_fade(delta: float) -> void:
	var p := player.global_position
	var d := Vector2(p.x, p.z) - ship_center
	var a := WorldData.SHIP_ANGLE
	var lx := d.x * cos(a) + d.y * sin(a)
	var lz := -d.x * sin(a) + d.y * cos(a)
	in_ship = absf(lx) < 8.8 and absf(lz) < 4.6
	var want := 0.18 if in_ship else 1.0
	for m in ship_mats:
		var c: Color = m.albedo_color
		var na := lerpf(c.a, want, clampf(delta * 5.0, 0.0, 1.0))
		m.albedo_color = Color(c.r, c.g, c.b, na)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if na < 0.98 else BaseMaterial3D.TRANSPARENCY_DISABLED

func _update_waypoint() -> void:
	if waypoint.is_empty():
		wp_label.visible = false
		return
	var wp: Vector2 = waypoint["pos"]
	var p := player.global_position
	var d := Vector2(p.x, p.z).distance_to(wp)
	if d < 8.0:
		waypoint = {}
		wp_label.visible = false
		toast("[b]Arrived[/b]")
		return
	wp_label.visible = true
	wp_label.position = Vector3(wp.x, WorldData.height_at(wp.x, wp.y) + 9.0, wp.y)
	wp_label.text = "◆ %s · %d m" % [waypoint["name"], int(d)]
