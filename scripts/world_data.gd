class_name WorldData
extends RefCounted
## Shared world definition: landmark list, terrain height function, gravity zones.
## Same maths as the web version, so the two worlds match.

const WORLD_R := 176.0
const GH := Vector2(64, -46)
const SHIP := Vector2(-80, 37.3)
const SHIP_ANGLE := 0.322
const ANOM := Vector2(-44, -98)
const HOL := Vector2(98, 62)
const HOL_R := 24.0
const RIDGE := Vector2(-22, -132)
const ROVER := Vector2(-48, -18)
const SPR := Vector2(116, -16)
const PADS := Vector2(26, 16)
const GOUGE_A := Vector2(-150, 14)
const GOUGE_B := Vector2(-72, 40)

const CAT_COLORS := {
	"Habitat": Color("#ffc857"), "Wreck": Color("#ff6b4a"), "Gravity": Color("#7fe3d0"),
	"Scenic": Color("#ff9fd0"), "Nature": Color("#8fd3ff"), "History": Color("#c9b3a2"),
}

const LM: Array = [
	{"id": "base", "name": "Base Camp Vega", "cat": "Habitat", "pos": Vector2(0, 0), "tp": Vector2(8, 9), "r": 20.0, "rate": 4.4, "n": 2318, "desc": "Your hab, solar field and comms mast. Supplies are thin, but the lights are on and the air is breathable inside."},
	{"id": "greenhouse", "name": "Garden of Hope Greenhouse", "cat": "Habitat", "pos": Vector2(64, -46), "tp": Vector2(44, -44), "r": 24.0, "rate": 4.9, "n": 1876, "desc": "A vaulted glass greenhouse that still grows tomatoes. It also makes oxygen. Someone has been watering it."},
	{"id": "crash", "name": "Ares-7 Crash Site", "cat": "Wreck", "pos": Vector2(-80, 37), "tp": Vector2(-62, 41), "r": 30.0, "rate": 4.6, "n": 3204, "desc": "The split hull of your ship, still smoking. The flight recorder should be somewhere inside."},
	{"id": "anomaly", "name": "Gravity Anomaly", "cat": "Gravity", "pos": Vector2(-44, -98), "tp": Vector2(-44, -78), "r": 22.0, "rate": 4.8, "n": 2741, "desc": "Boulders orbit a glowing core and gravity almost vanishes. Jump and keep floating."},
	{"id": "hollow", "name": "Heavy Hollow", "cat": "Gravity", "pos": Vector2(98, 62), "tp": Vector2(70, 56), "r": 26.0, "rate": 3.9, "n": 964, "desc": "A crater where gravity is more than doubled. Every step is a decision."},
	{"id": "pads", "name": "Bounce Pads", "cat": "Gravity", "pos": Vector2(26, 16), "tp": Vector2(18, 10), "r": 12.0, "rate": 4.7, "n": 1502, "desc": "Four launch pads of unknown origin. Step on one and Mars lets go of you for a while."},
	{"id": "ridge", "name": "Beacon Ridge Overlook", "cat": "Scenic", "pos": Vector2(-22, -132), "tp": Vector2(-22, -125), "r": 18.0, "rate": 4.9, "n": 2120, "desc": "The highest point in the basin, with a comms tower and a telescope."},
	{"id": "rover", "name": "Spirit-9 Rover Wreck", "cat": "History", "pos": Vector2(-48, -18), "tp": Vector2(-41, -10), "r": 14.0, "rate": 4.2, "n": 688, "desc": "An older rover, tipped on its side and buried to the axles. Its log is still readable."},
	{"id": "spring", "name": "Frozen Spring", "cat": "Nature", "pos": Vector2(116, -16), "tp": Vector2(102, -12), "r": 18.0, "rate": 4.8, "n": 1390, "desc": "A pocket of real water ice ringed with glowing crystals. Quiet, cold, and very blue."},
]

# [x, z, flat radius, blend width]
const ZONES: Array = [
	[0.0, 0.0, 16.0, 10.0], [26.0, 16.0, 9.0, 8.0], [64.0, -46.0, 18.0, 12.0],
	[-44.0, -98.0, 12.0, 14.0], [-48.0, -18.0, 5.0, 6.0], [-22.0, -132.0, 5.0, 8.0], [116.0, -16.0, 6.0, 6.0],
]

static var _noise: FastNoiseLite
static var _flat: Array = []

static func get_lm(id: String) -> Dictionary:
	for l in LM:
		if l["id"] == id:
			return l
	return {}

static func _n() -> FastNoiseLite:
	if _noise == null:
		_noise = FastNoiseLite.new()
		_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
		_noise.seed = 20261114
		_noise.frequency = 1.0
		_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
		_noise.fractal_octaves = 4
	return _noise

## 0..1 fractal noise at frequency f
static func fbm(x: float, z: float, f: float) -> float:
	return _n().get_noise_2d(x * f, z * f) * 0.5 + 0.5

static func seg_dist(p: Vector2, a: Vector2, b: Vector2) -> float:
	var d := b - a
	var t := clampf((p - a).dot(d) / d.dot(d), 0.0, 1.0)
	return p.distance_to(a + d * t)

static func base_h(x: float, z: float) -> float:
	var p := Vector2(x, z)
	var r := p.length()
	var h := (fbm(x, z, 0.011) - 0.5) * 16.0
	h += (fbm(x + 40.0, z + 17.0, 0.05) - 0.5) * 2.4
	h += sin(x * 0.33 + fbm(x, z, 0.02) * 9.0) * 0.11 + sin(z * 0.27 + x * 0.1) * 0.07
	h += smoothstep(150.0, 215.0, r) * (26.0 + fbm(x, z, 0.02) * 22.0)
	var dr := p.distance_to(RIDGE)
	h += 17.0 * exp(-(dr * dr) / (2.0 * 13.0 * 13.0))
	var dh := p.distance_to(HOL)
	h -= 7.5 * (1.0 - smoothstep(3.0, HOL_R, dh))
	h += 1.8 * exp(-pow((dh - HOL_R - 1.0) / 4.5, 2.0))
	h -= 1.6 * (1.0 - smoothstep(2.0, 11.0, p.distance_to(SPR)))
	h -= 1.4 * (1.0 - smoothstep(0.0, 4.2, seg_dist(p, GOUGE_A, GOUGE_B)))
	return h

static func height_at(x: float, z: float) -> float:
	if _flat.is_empty():
		for zn in ZONES:
			_flat.append(base_h(zn[0], zn[1]))
	var h := base_h(x, z)
	for i in ZONES.size():
		var zn: Array = ZONES[i]
		var d := Vector2(x - zn[0], z - zn[1]).length()
		if d < zn[2] + zn[3]:
			h = lerpf(h, _flat[i], 1.0 - smoothstep(zn[2], zn[2] + zn[3], d))
	return h

## 1.0 = normal Mars gravity. Near 0 inside the anomaly, about 2.7 in the Hollow.
static func grav_mult(x: float, z: float) -> float:
	var p := Vector2(x, z)
	var m := 1.0
	m = lerpf(m, 0.05, 1.0 - smoothstep(16.0 * 0.55, 16.0, p.distance_to(ANOM)))
	m = lerpf(m, 2.7, 1.0 - smoothstep(HOL_R * 0.6, HOL_R - 1.0, p.distance_to(HOL)))
	return m

static func color_at(x: float, z: float, h: float) -> Color:
	var p := Vector2(x, z)
	var low := Color("#7a3218"); var mid := Color("#b0502a"); var high := Color("#d08650")
	var pale := Color("#dcad7c"); var dark := Color("#3a1f19"); var soot := Color("#1b1411")
	var ice := Color("#d4ecf5"); var conc := Color("#9d9489"); var hol := Color("#4d1b14"); var teal := Color("#3d6068")
	var n1 := fbm(x + 50.0, z + 20.0, 0.03)
	var n2 := fbm(x, z, 0.3)
	var n3 := fbm(x + 20.0, z, 0.07)
	var c := low.lerp(mid, smoothstep(-5.0, 3.0, h))
	c = c.lerp(high, smoothstep(2.0, 12.0, h) * 0.8)
	c = c.lerp(pale, smoothstep(0.55, 0.75, n1) * 0.55)
	c = c.lerp(dark, smoothstep(0.62, 0.8, n3) * 0.75)
	c = c.lerp(soot, (1.0 - smoothstep(0.0, 5.5, seg_dist(p, GOUGE_A, GOUGE_B))) * 0.85)
	c = c.lerp(hol, (1.0 - smoothstep(7.0, HOL_R + 5.0, p.distance_to(HOL))) * 0.7)
	c = c.lerp(ice, (1.0 - smoothstep(5.0, 11.0, p.distance_to(SPR))) * 0.9)
	c = c.lerp(conc, (1.0 - smoothstep(11.0, 16.0, p.length())) * 0.55)
	var dg := maxf(absf(x - GH.x) - 13.0, absf(z - GH.y) - 8.0)
	c = c.lerp(conc, (1.0 - smoothstep(0.0, 5.0, dg)) * 0.5)
	c = c.lerp(teal, (1.0 - smoothstep(7.0, 17.0, p.distance_to(ANOM))) * 0.4)
	var k := 0.88 + n2 * 0.24
	return Color(c.r * k, c.g * k, c.b * k)
