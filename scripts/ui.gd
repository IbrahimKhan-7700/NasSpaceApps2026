extends CanvasLayer
## All HUD: objectives, minimap, gauges, thought bubble, Places (teleport list), start card.

var main: Node3D
var goals_box: VBoxContainer
var o2_bar: ProgressBar
var o2_label: Label
var grav_label: Label
var coords: Label
var prompt: Label
var toasts: VBoxContainer
var mini: Control
var bubble: PanelContainer
var bubble_text: Label
var bubble_opts: HBoxContainer
var places: PanelContainer
var big_map: Control
var plist: VBoxContainer
var search: LineEdit
var sort_opt: OptionButton
var count_label: Label
var fade: ColorRect
var start_card: Control
var cat := "All"
var selected := ""
var cat_buttons: Array = []
var time_btn: Button

func _panel(alpha := 0.78) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.08, 0.045, 0.04, alpha)
	s.border_color = Color(1, 0.8, 0.63, 0.2)
	s.set_border_width_all(1)
	s.set_corner_radius_all(10)
	s.content_margin_left = 14
	s.content_margin_right = 14
	s.content_margin_top = 10
	s.content_margin_bottom = 10
	return s

func _btn(text: String, accent := false) -> Button:
	var b := Button.new()
	b.text = text
	var n := StyleBoxFlat.new()
	n.bg_color = Color("#e58a4f") if accent else Color(0.08, 0.045, 0.04, 0.8)
	n.border_color = Color(1, 0.8, 0.63, 0.25)
	n.set_border_width_all(1)
	n.set_corner_radius_all(8)
	n.content_margin_left = 12
	n.content_margin_right = 12
	n.content_margin_top = 7
	n.content_margin_bottom = 7
	var h: StyleBoxFlat = n.duplicate()
	h.bg_color = Color("#f19a63") if accent else Color(0.2, 0.11, 0.08, 0.95)
	b.add_theme_stylebox_override("normal", n)
	b.add_theme_stylebox_override("hover", h)
	b.add_theme_stylebox_override("pressed", h)
	b.add_theme_color_override("font_color", Color("#1a0b05") if accent else Color("#f8ebdd"))
	b.add_theme_color_override("font_hover_color", Color("#1a0b05") if accent else Color.WHITE)
	b.focus_mode = Control.FOCUS_NONE
	return b

func _lbl(text: String, size := 14, color := Color("#f8ebdd")) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l

func setup(m: Node3D) -> void:
	main = m
	layer = 10
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	# goals
	var gp := PanelContainer.new()
	gp.add_theme_stylebox_override("panel", _panel())
	gp.position = Vector2(16, 16)
	gp.custom_minimum_size = Vector2(270, 0)
	root.add_child(gp)
	var gv := VBoxContainer.new()
	gp.add_child(gv)
	gv.add_child(_lbl("SURVIVAL LOG", 13, Color("#ffc857")))
	goals_box = VBoxContainer.new()
	gv.add_child(goals_box)
	# gauges
	var ga := PanelContainer.new()
	ga.add_theme_stylebox_override("panel", _panel())
	ga.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	ga.offset_left = 16
	ga.offset_bottom = -16
	ga.offset_top = -126
	ga.offset_right = 266
	root.add_child(ga)
	var gb := VBoxContainer.new()
	ga.add_child(gb)
	var r1 := HBoxContainer.new()
	r1.add_child(_lbl("OXYGEN", 11, Color("#c7ae9b")))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r1.add_child(sp)
	o2_label = _lbl("64%", 16)
	r1.add_child(o2_label)
	gb.add_child(r1)
	o2_bar = ProgressBar.new()
	o2_bar.show_percentage = false
	o2_bar.custom_minimum_size = Vector2(0, 8)
	o2_bar.modulate = Color("#6fe3cf")
	gb.add_child(o2_bar)
	var r2 := HBoxContainer.new()
	r2.add_child(_lbl("GRAVITY", 11, Color("#c7ae9b")))
	var sp2 := Control.new()
	sp2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r2.add_child(sp2)
	grav_label = _lbl("0.38 g", 16)
	r2.add_child(grav_label)
	gb.add_child(r2)
	coords = _lbl("", 11, Color("#c7ae9b"))
	gb.add_child(coords)
	# minimap and buttons
	mini = Control.new()
	mini.set_script(load("res://scripts/map_view.gd"))
	mini.main = main
	mini.custom_minimum_size = Vector2(172, 172)
	mini.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	mini.offset_left = -188
	mini.offset_right = -16
	mini.offset_top = 16
	mini.offset_bottom = 188
	mini.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(mini)
	var br := HBoxContainer.new()
	br.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	br.offset_left = -330
	br.offset_right = -16
	br.offset_top = 196
	br.alignment = BoxContainer.ALIGNMENT_END
	root.add_child(br)
	var bp := _btn("[M] Places", true)
	bp.pressed.connect(func(): toggle_places())
	br.add_child(bp)
	var bt := _btn("[T] Think")
	bt.pressed.connect(func(): main.force_thought())
	br.add_child(bt)
	time_btn = _btn("[N] Night")
	time_btn.pressed.connect(func(): main.toggle_night())
	br.add_child(time_btn)
	# prompt
	prompt = _lbl("", 15, Color("#ffc857"))
	prompt.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	prompt.offset_left = -200
	prompt.offset_right = 200
	prompt.offset_top = -80
	prompt.offset_bottom = -50
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_color_override("font_outline_color", Color.BLACK)
	prompt.add_theme_constant_override("outline_size", 6)
	root.add_child(prompt)
	# toasts
	toasts = VBoxContainer.new()
	toasts.set_anchors_preset(Control.PRESET_CENTER_TOP)
	toasts.offset_left = -230
	toasts.offset_right = 230
	toasts.offset_top = 16
	toasts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(toasts)
	# thought bubble
	bubble = PanelContainer.new()
	var bs := StyleBoxFlat.new()
	bs.bg_color = Color("#fff7ec")
	bs.set_corner_radius_all(22)
	bs.content_margin_left = 16
	bs.content_margin_right = 16
	bs.content_margin_top = 10
	bs.content_margin_bottom = 12
	bs.shadow_size = 8
	bs.shadow_color = Color(0, 0, 0, 0.35)
	bubble.add_theme_stylebox_override("panel", bs)
	bubble.visible = false
	bubble.custom_minimum_size = Vector2(220, 0)
	root.add_child(bubble)
	var bv := VBoxContainer.new()
	bubble.add_child(bv)
	bubble_text = _lbl("", 19, Color("#2a1610"))
	bubble_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bubble_text.custom_minimum_size = Vector2(240, 0)
	bv.add_child(bubble_text)
	bubble_opts = HBoxContainer.new()
	bv.add_child(bubble_opts)
	# places panel
	_build_places(root)
	# fade
	fade = ColorRect.new()
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.color = Color("#ffe9c8")
	fade.modulate.a = 0.0
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(fade)
	# start card
	start_card = ColorRect.new()
	(start_card as ColorRect).color = Color(0.05, 0.03, 0.03, 0.55)
	start_card.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(start_card)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	start_card.add_child(cc)
	var sc := PanelContainer.new()
	sc.add_theme_stylebox_override("panel", _panel(0.85))
	cc.add_child(sc)
	var sv := VBoxContainer.new()
	sv.custom_minimum_size = Vector2(540, 0)
	sv.add_theme_constant_override("separation", 12)
	sc.add_child(sv)
	sv.add_child(_lbl("SOL 41  ·  JEZERO BASIN", 12, Color("#ffc857")))
	sv.add_child(_lbl("MAROONED ON MARS", 44, Color("#e58a4f")))
	var story := _lbl("Vega crash-landed with Ares-7. The radio is static, the oxygen is dropping and something out there is still glowing. Find the greenhouse, search the wreck, and get a signal out.", 15)
	story.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sv.add_child(story)
	sv.add_child(_lbl("WASD walk   Shift sprint   Space jump   E interact\nM places and teleport   T hear a thought   N day or night\nMouse look   Wheel zoom   Esc free the mouse", 13, Color("#c7ae9b")))
	var go := _btn("Begin", true)
	go.pressed.connect(func(): main.begin())
	sv.add_child(go)

func _build_places(root: Control) -> void:
	places = PanelContainer.new()
	places.add_theme_stylebox_override("panel", _panel(0.94))
	places.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	places.offset_right = 400
	places.visible = false
	root.add_child(places)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	places.add_child(v)
	var head := HBoxContainer.new()
	head.add_child(_lbl("PLACES", 22))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(sp)
	var cb := _btn("Esc  Close")
	cb.pressed.connect(func(): close_places())
	head.add_child(cb)
	v.add_child(head)
	big_map = Control.new()
	big_map.set_script(load("res://scripts/map_view.gd"))
	big_map.main = main
	big_map.big = true
	big_map.custom_minimum_size = Vector2(0, 250)
	big_map.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			var id: String = big_map.pick(e.position)
			if id != "":
				selected = id
				render_places())
	v.add_child(big_map)
	search = LineEdit.new()
	search.placeholder_text = "Search places, wrecks, anomalies"
	search.text_changed.connect(func(_t): render_places())
	v.add_child(search)
	var chips := HFlowContainer.new()
	v.add_child(chips)
	for c in ["All", "Habitat", "Wreck", "Gravity", "Scenic", "Nature", "History"]:
		var b := _btn(c)
		b.toggle_mode = true
		b.button_pressed = c == "All"
		b.pressed.connect(func():
			cat = c
			for o in cat_buttons:
				o.button_pressed = (o.text == c)
			render_places())
		cat_buttons.append(b)
		chips.add_child(b)
	var sr := HBoxContainer.new()
	count_label = _lbl("", 11, Color("#c7ae9b"))
	count_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sr.add_child(count_label)
	sort_opt = OptionButton.new()
	sort_opt.add_item("Nearest")
	sort_opt.add_item("Top rated")
	sort_opt.add_item("A to Z")
	sort_opt.item_selected.connect(func(_i): render_places())
	sr.add_child(sort_opt)
	v.add_child(sr)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	plist = VBoxContainer.new()
	plist.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	plist.add_theme_constant_override("separation", 8)
	scroll.add_child(plist)

func render_places() -> void:
	for c in plist.get_children():
		c.queue_free()
	var q := search.text.strip_edges().to_lower()
	var items: Array = []
	for l in WorldData.LM:
		if (cat == "All" or l["cat"] == cat) and (q == "" or (l["name"] + " " + l["cat"] + " " + l["desc"]).to_lower().contains(q)):
			items.append(l)
	var pp := Vector2(main.player.global_position.x, main.player.global_position.z)
	match sort_opt.selected:
		0: items.sort_custom(func(a, b): return pp.distance_to(a["pos"]) < pp.distance_to(b["pos"]))
		1: items.sort_custom(func(a, b): return a["rate"] > b["rate"])
		2: items.sort_custom(func(a, b): return a["name"] < b["name"])
	count_label.text = "%d PLACES" % items.size()
	big_map.selected = selected
	for l in items:
		var card := PanelContainer.new()
		var sb := _panel(0.5)
		if l["id"] == selected:
			sb.border_color = Color("#ffc857")
		card.add_theme_stylebox_override("panel", sb)
		var cv := VBoxContainer.new()
		card.add_child(cv)
		var d := int(pp.distance_to(l["pos"]))
		var visited: String = "   ✓ visited" if main.found.has(l["id"]) else ""
		var head := Button.new()
		head.flat = true
		head.alignment = HORIZONTAL_ALIGNMENT_LEFT
		head.text = "%s\n★ %.1f   %s explorers   %s\n%d m away · about %d s on foot%s" % [l["name"], l["rate"], _commas(l["n"]), l["cat"], d, maxi(1, int(d / 4.2)), visited]
		head.add_theme_color_override("font_color", WorldData.CAT_COLORS[l["cat"]])
		head.add_theme_color_override("font_hover_color", Color.WHITE)
		head.focus_mode = Control.FOCUS_NONE
		var id: String = l["id"]
		head.pressed.connect(func():
			selected = "" if selected == id else id
			render_places())
		cv.add_child(head)
		if l["id"] == selected:
			var ds := _lbl(l["desc"], 13)
			ds.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			cv.add_child(ds)
			var hb := HBoxContainer.new()
			var tpb := _btn("Teleport", true)
			tpb.pressed.connect(func(): main.teleport_to(id))
			var wpb := _btn("Clear waypoint" if main.waypoint.size() > 0 and main.waypoint["id"] == id else "Waypoint")
			wpb.pressed.connect(func():
				main.set_waypoint(id)
				render_places())
			hb.add_child(tpb)
			hb.add_child(wpb)
			cv.add_child(hb)
		plist.add_child(card)

func _commas(n: int) -> String:
	var s := str(n)
	return s.substr(0, s.length() - 3) + "," + s.substr(s.length() - 3) if s.length() > 3 else s

func toggle_places() -> void:
	if places.visible:
		close_places()
	else:
		open_places()

func open_places() -> void:
	places.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	render_places()

func close_places() -> void:
	if not places.visible:
		return
	places.visible = false
	if main.started:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func render_goals() -> void:
	for c in goals_box.get_children():
		c.queue_free()
	for g in main.goals():
		var done: bool = g["cur"] >= g["max"]
		var t: String = ("[x] " if done else "[ ] ") + g["txt"] + ("   %d/%d" % [min(g["cur"], g["max"]), g["max"]] if g["max"] > 1 else "")
		goals_box.add_child(_lbl(t, 13, Color("#86e39a") if done else Color("#f8ebdd")))

func toast(bb: String) -> void:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _panel())
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.text = bb
	r.custom_minimum_size = Vector2(420, 0)
	r.add_theme_font_size_override("normal_font_size", 14)
	r.add_theme_font_size_override("bold_font_size", 14)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(r)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toasts.add_child(p)
	while toasts.get_child_count() > 3:
		toasts.get_child(0).queue_free()
		toasts.remove_child(toasts.get_child(0))
	var tw := p.create_tween()
	tw.tween_interval(5.0)
	tw.tween_property(p, "modulate:a", 0.0, 0.4)
	tw.tween_callback(p.queue_free)

func show_bubble(text: String, opts: Array) -> void:
	bubble_text.text = text
	for c in bubble_opts.get_children():
		c.queue_free()
	for i in opts.size():
		var b := _btn("%d  %s" % [i + 1, opts[i][0]])
		var idx := i
		b.pressed.connect(func(): main.run_option(idx))
		bubble_opts.add_child(b)
	bubble.visible = true
	bubble.reset_size()

func hide_bubble() -> void:
	bubble.visible = false

func update(delta: float) -> void:
	var o := int(round(main.o2))
	o2_label.text = "%d%%" % o
	o2_bar.value = main.o2
	o2_bar.modulate = Color("#ff5a47") if o < 20 else Color("#6fe3cf")
	var gm := WorldData.grav_mult(main.player.global_position.x, main.player.global_position.z)
	grav_label.text = "%.2f g" % (3.71 * gm / 9.81)
	grav_label.add_theme_color_override("font_color", Color("#6fe3cf") if gm < 0.3 else (Color("#ff5a47") if gm > 1.6 else Color("#f8ebdd")))
	var p: Vector3 = main.player.global_position
	var brg := fposmod(180.0 - rad_to_deg(main.player.yaw), 360.0)
	var names := ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
	coords.text = "X %d   Z %d   HDG %s" % [round(p.x), round(p.z), names[int(round(brg / 45.0)) % 8]]
	mini.queue_redraw()
	if places.visible:
		big_map.queue_redraw()
	# bubble follows head
	if bubble.visible:
		var head: Vector3 = p + Vector3(0, 2.2, 0)
		var cam: Camera3D = main.player.cam
		if cam.is_position_behind(head):
			bubble.modulate.a = 0.0
		else:
			bubble.modulate.a = 1.0
			var s := cam.unproject_position(head)
			var vp := get_viewport().get_visible_rect().size
			bubble.position = Vector2(clampf(s.x - bubble.size.x * 0.5, 8, vp.x - bubble.size.x - 8), clampf(s.y - bubble.size.y - 24, 8, vp.y - bubble.size.y - 120))
