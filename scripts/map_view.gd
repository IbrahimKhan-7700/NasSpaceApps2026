extends Control
## Top-down map. Used as the minimap and, larger, in the Places panel.

const EXTENT := 210.0
var main: Node3D
var big := false
var selected := ""
static var _tex: ImageTexture

static func make_texture() -> ImageTexture:
	if _tex != null:
		return _tex
	var n := 200
	var img := Image.create(n, n, false, Image.FORMAT_RGB8)
	for j in n:
		for i in n:
			var x := (float(i) / (n - 1) * 2.0 - 1.0) * EXTENT
			var z := (float(j) / (n - 1) * 2.0 - 1.0) * EXTENT
			var h := WorldData.height_at(x, z)
			var hx := WorldData.height_at(x + 4, z) - WorldData.height_at(x - 4, z)
			var sh := clampf(0.5 - hx * 0.05, 0.15, 1.0)
			var r := Vector2(x, z).length()
			var k := (0.55 + sh * 0.65) * (1.0 - smoothstep(150.0, 205.0, r) * 0.55)
			img.set_pixel(i, j, Color(clampf((140.0 + h * 3.5) * k / 255.0, 0, 1), clampf((70.0 + h * 2.0) * k / 255.0, 0, 1), clampf((40.0 + h) * k / 255.0, 0, 1)))
	_tex = ImageTexture.create_from_image(img)
	return _tex

func _to_px(p: Vector2) -> Vector2:
	var side := minf(size.x, size.y)
	var off := (size - Vector2(side, side)) * 0.5
	return off + (p + Vector2(EXTENT, EXTENT)) / (2.0 * EXTENT) * side

func pick(local: Vector2) -> String:
	var best := ""
	var bd := 22.0
	for l in WorldData.LM:
		var d := _to_px(l["pos"]).distance_to(local)
		if d < bd:
			bd = d
			best = l["id"]
	return best

func _draw() -> void:
	if main == null:
		return
	var side := minf(size.x, size.y)
	var off := (size - Vector2(side, side)) * 0.5
	draw_rect(Rect2(Vector2.ZERO, size), Color("#120a08"))
	draw_texture_rect(make_texture(), Rect2(off, Vector2(side, side)), false)
	var sc := side / 344.0
	for l in WorldData.LM:
		var c: Color = WorldData.CAT_COLORS[l["cat"]]
		var p := _to_px(l["pos"])
		var sel: bool = l["id"] == selected
		draw_circle(p, (11.0 if sel else 7.0) * sc, Color("#120a08"))
		draw_circle(p, (9.0 if sel else 5.0) * sc, c)
		if sel:
			var f := ThemeDB.fallback_font
			draw_string(f, p + Vector2(-60, -14 * sc), l["name"], HORIZONTAL_ALIGNMENT_CENTER, 120, int(13 * maxf(sc, 1.0)), Color.WHITE)
	if main.waypoint.size() > 0:
		draw_arc(_to_px(main.waypoint["pos"]), 13.0 * sc, 0, TAU, 20, Color("#ffc857"), 2.0)
	var pp := _to_px(Vector2(main.player.global_position.x, main.player.global_position.z))
	var ang := atan2(cos(main.player.yaw), sin(main.player.yaw))
	var fwd := Vector2(cos(ang), sin(ang))
	var rgt := Vector2(-fwd.y, fwd.x)
	draw_colored_polygon(PackedVector2Array([pp + fwd * 10 * sc, pp - fwd * 7 * sc + rgt * 7 * sc, pp - fwd * 3 * sc, pp - fwd * 7 * sc - rgt * 7 * sc]), Color.WHITE)
